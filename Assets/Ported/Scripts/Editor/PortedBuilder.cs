using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.InputSystem.UI;
using UnityEngine.UI;

namespace Ported.EditorTools
{
    // 把移植进来的资源装配成可玩的内容：角色预制体（带技能）、登录场景、游戏场景，并写进 Build Settings。
    public static class PortedBuilder
    {
        const string Art = "Assets/Ported/Qq13/Art/";
        const string HeroDir = Art + "Character/CH_Hero/";
        const string DataDir = "Assets/Ported/Data/";
        const string OutHeroes = "Assets/Ported/Heroes/";
        const string GameScenePath = "Assets/Ported/Scenes/Ported_Game.unity";
        const string LoginScenePath = "Assets/Ported/Scenes/Ported_Login.unity";
        const string SourceScene = Art + "Scene/sc_10001002_xcb_lyq/sc_10001002_xcb_lyq.unity";
        const string LoginPanelPrefab = Art + "Prefab/Login/LoginPanel.prefab";
        const string LoginBg = Art + "UI/Sprite/BG/bg_login.png";

        class HeroSpec
        {
            public string id, display, folder, roleId;
            public string[] parts;
            public HeroSpec(string id, string display, string folder, string roleId, params string[] parts)
            {
                this.id = id; this.display = display; this.folder = folder; this.roleId = roleId; this.parts = parts;
            }
            public string PrefabPath => HeroDir + folder + "/" + folder + ".prefab";
        }

        static readonly HeroSpec[] Heroes =
        {
            new HeroSpec("zhurengong_A", "Protagonist A", "Ch_11501_zhurengong_A", "11501",
                "prefab_face/ch_A_face_A.prefab", "prefab_hair/ch_A_2_hair.prefab", "prefab_brow/ch_A_meimao_A.prefab"),
            new HeroSpec("aocunlin", "Aocunlin", "Ch_11001_aocunlin", "11001"),
            new HeroSpec("shihuimei", "Shihuimei", "Ch_11003_shihuimei", "11003"),
            new HeroSpec("shenmuchuyun", "Shenmuchuyun", "Ch_11005_shenmuchuyun", "11005"),
            new HeroSpec("nuoyihaosi", "Nuoyihaosi", "Ch_11008_nuoyihaosi", "11008"),
        };

        static string ShotDir => Path.GetFullPath(Application.dataPath + "/../../../port_tools/shots");

        [MenuItem("Tools/Ported/Build All")]
        public static void BuildAll()
        {
            if (EditorApplication.isPlayingOrWillChangePlaymode)
            {
                Debug.LogWarning("[PortedBuilder] 播放模式下不能装配，先退出播放");
                return;
            }
            try
            {
                Directory.CreateDirectory(ShotDir);
                var prefabs = BuildHeroPrefabs();
                BuildGameScene(prefabs);
                BuildLoginScene();
                UpdateBuildSettings();
                AssetDatabase.SaveAssets();
                Debug.Log("[PortedBuilder] 完成。登录场景 " + LoginScenePath + "，游戏场景 " + GameScenePath);
            }
            catch (Exception e)
            {
                Debug.LogError("[PortedBuilder] 失败: " + e);
            }
        }

        // ---------- 角色 ----------

        static GameObject[] BuildHeroPrefabs()
        {
            Directory.CreateDirectory(OutHeroes);
            var list = new List<GameObject>();
            foreach (var spec in Heroes)
            {
                var src = AssetDatabase.LoadAssetAtPath<GameObject>(spec.PrefabPath);
                if (src == null)
                {
                    Debug.LogError("[PortedBuilder] 找不到角色预制体 " + spec.PrefabPath);
                    continue;
                }

                var root = new GameObject("Hero_" + spec.id);
                var model = (GameObject)PrefabUtility.InstantiatePrefab(src);
                model.transform.SetParent(root.transform, false);
                AttachParts(root, model, spec);

                var cc = root.AddComponent<CharacterController>();
                cc.center = new Vector3(0f, 0.9f, 0f);
                cc.height = 1.8f;
                cc.radius = 0.3f;
                cc.stepOffset = 0.35f;

                var hc = root.AddComponent<HeroController>();
                hc.actions = BuildActionSet(spec);

                var path = OutHeroes + root.name + ".prefab";
                var saved = PrefabUtility.SaveAsPrefabAsset(root, path);
                UnityEngine.Object.DestroyImmediate(root);
                list.Add(saved);

            }
            return list.ToArray();
        }

        // 主角的头发/脸/眉毛是独立预制体，原项目运行时按骨骼名绑到身体骨架上，这里在装配时做同样的事
        static void AttachParts(GameObject root, GameObject model, HeroSpec spec)
        {
            if (spec.parts == null || spec.parts.Length == 0) return;

            var bones = new Dictionary<string, Transform>();
            foreach (var tr in model.GetComponentsInChildren<Transform>(true))
                if (!bones.ContainsKey(tr.name)) bones[tr.name] = tr;

            foreach (var rel in spec.parts)
            {
                var part = AssetDatabase.LoadAssetAtPath<GameObject>(HeroDir + spec.folder + "/" + rel);
                if (part == null) { Debug.LogWarning("[PortedBuilder] 找不到部件 " + rel); continue; }

                var inst = (GameObject)PrefabUtility.InstantiatePrefab(part);
                inst.transform.SetParent(root.transform, false);
                foreach (var a in inst.GetComponentsInChildren<Animator>(true)) a.enabled = false;

                foreach (var smr in inst.GetComponentsInChildren<SkinnedMeshRenderer>(true))
                {
                    var old = smr.bones;
                    var mapped = new Transform[old.Length];
                    var hit = 0;
                    for (var i = 0; i < old.Length; i++)
                    {
                        if (old[i] != null && bones.TryGetValue(old[i].name, out var b)) { mapped[i] = b; hit++; }
                    }
                    smr.bones = mapped;
                    if (smr.rootBone != null && bones.TryGetValue(smr.rootBone.name, out var rb)) smr.rootBone = rb;
                    smr.updateWhenOffscreen = true;
                    Debug.Log($"[PortedBuilder] 部件 {Path.GetFileName(rel)}/{smr.name}: 骨骼匹配 {hit}/{old.Length}");
                }
            }
        }

        // 读 export_actions.py 导出的动作数据，生成 HeroActionSet 资源，并把原项目路径换成移植后的预制体引用
        static HeroActionSet BuildActionSet(HeroSpec spec)
        {
            var jsonPath = DataDir + "actions_" + spec.roleId + ".json";
            if (!File.Exists(jsonPath))
            {
                Debug.LogError("[PortedBuilder] 缺少动作数据 " + jsonPath + "，先运行 port_tools/export_actions.py");
                return null;
            }

            var assetPath = OutHeroes + "Actions_" + spec.id + ".asset";
            var set = AssetDatabase.LoadAssetAtPath<HeroActionSet>(assetPath);
            if (set == null)
            {
                set = ScriptableObject.CreateInstance<HeroActionSet>();
                AssetDatabase.CreateAsset(set, assetPath);
            }
            JsonUtility.FromJsonOverwrite(File.ReadAllText(jsonPath), set);

            var missing = new HashSet<string>();
            var fxCount = 0;
            foreach (var a in AllActions(set))
            {
                foreach (var fx in a.fx) { fx.prefab = LoadFx(fx.path, missing); if (fx.prefab != null) fxCount++; }
                foreach (var h in a.hits) h.hitFxPrefab = LoadFx(h.hitFx, missing);
            }
            foreach (var e in set.emitters)
            {
                e.assetPrefab = LoadFx(e.asset, missing);
                e.hurtFxPrefab = LoadFx(e.hurtFx, missing);
            }
            EditorUtility.SetDirty(set);

            var summary = string.Join("  ", AllActions(set).Select(a => $"{a.clip}(特效{a.fx.Length}/伤害{a.hits.Length}/子弹{a.bullets.Length})"));
            Debug.Log($"[PortedBuilder] 角色 {spec.display}: 挂上特效 {fxCount} 个。{summary}");
            foreach (var m in missing) Debug.LogWarning("[PortedBuilder] 特效没拷过来: " + m);
            return set;
        }

        static IEnumerable<ActionData> AllActions(HeroActionSet set)
        {
            foreach (var a in set.combo) if (a != null && a.IsValid) yield return a;
            foreach (var a in new[] { set.heavy, set.skill1, set.skill2, set.ultimate })
                if (a != null && a.IsValid) yield return a;
        }

        static GameObject LoadFx(string qqPath, HashSet<string> missing)
        {
            if (string.IsNullOrEmpty(qqPath) || !qqPath.StartsWith("Assets/")) return null;
            var path = "Assets/Ported/Qq13/" + qqPath.Substring("Assets/".Length);
            var go = AssetDatabase.LoadAssetAtPath<GameObject>(path);
            if (go == null) missing.Add(qqPath);
            return go;
        }

        // ---------- 游戏场景 ----------

        static void BuildGameScene(GameObject[] heroPrefabs)
        {
            Directory.CreateDirectory("Assets/Ported/Scenes");
            if (AssetDatabase.LoadAssetAtPath<SceneAsset>(GameScenePath) != null) AssetDatabase.DeleteAsset(GameScenePath);
            if (!AssetDatabase.CopyAsset(SourceScene, GameScenePath))
                throw new Exception("复制场景失败: " + SourceScene);
            AssetDatabase.Refresh();

            var scene = EditorSceneManager.OpenScene(GameScenePath, OpenSceneMode.Single);
            FixLighting();

            var renderers = UnityEngine.Object.FindObjectsByType<Renderer>(FindObjectsSortMode.None)
                .Where(r => r.enabled && r.gameObject.activeInHierarchy).ToArray();
            Debug.Log($"[PortedBuilder] 场景渲染器 {renderers.Length} 个");

            var colliderCount = AddGroundColliders(renderers);

            Vector3 spawn;
            float groundY;
            EstimateSpawn(renderers, out spawn, out groundY);
            Debug.Log($"[PortedBuilder] 出生点 {spawn}，地面高度估计 {groundY}，补了 {colliderCount} 个地面碰撞体");
            DiagnoseGround(renderers, spawn);

            var go = new GameObject("PortedGame");
            var boot = go.AddComponent<PortedGameBootstrap>();
            boot.heroPrefabs = heroPrefabs;
            boot.heroNames = Heroes.Select(h => h.display).ToArray();
            boot.spawnPoint = spawn;
            boot.fallbackGroundY = groundY;
            boot.fxBloomShader = AssetDatabase.LoadAssetAtPath<Shader>("Assets/Ported/Shaders/FXBloom.shader");

            Physics.SyncTransforms();
            CaptureGame(scene, heroPrefabs, spawn);

            EditorSceneManager.SaveScene(scene);
        }

        // 原场景用烘焙光照，光照数据在旧版本生成，Unity 6 里不能用：改成实时光，并给一个中性的环境光
        static void FixLighting()
        {
            Lightmapping.lightingDataAsset = null;

            var lights = UnityEngine.Object.FindObjectsByType<Light>(FindObjectsSortMode.None);
            Light sun = null;
            foreach (var l in lights)
            {
                l.lightmapBakeType = LightmapBakeType.Realtime;
                if (l.type == LightType.Directional && (sun == null || l.intensity > sun.intensity)) sun = l;
            }

            if (sun == null)
            {
                var go = new GameObject("Sun");
                sun = go.AddComponent<Light>();
                sun.type = LightType.Directional;
            }

            sun.enabled = true;
            sun.intensity = 1.3f;
            sun.color = new Color(1f, 0.96f, 0.88f);
            sun.shadows = LightShadows.Soft;
            sun.transform.rotation = Quaternion.Euler(50f, -30f, 0f);
            RenderSettings.sun = sun;

            RenderSettings.ambientMode = UnityEngine.Rendering.AmbientMode.Trilight;
            RenderSettings.ambientSkyColor = new Color(0.72f, 0.78f, 0.9f);
            RenderSettings.ambientEquatorColor = new Color(0.55f, 0.58f, 0.62f);
            RenderSettings.ambientGroundColor = new Color(0.38f, 0.36f, 0.33f);
            RenderSettings.ambientIntensity = 1f;
            RenderSettings.fog = false;
            Debug.Log($"[PortedBuilder] 光照已改为实时，场景灯光 {lights.Length} 盏");
        }

        // 把又大又扁的网格当成地面，补 MeshCollider
        // 地面碰撞：原场景的碰撞体在子场景里，没拷过来。场景自带的 NavMesh 是按真实地面烘焙的，
        // 把它的三角面做成一张网格碰撞体，角色就站在可走区域上。HLOD 远景模型、水面这些不是地面，不加碰撞
        static int AddGroundColliders(Renderer[] renderers)
        {
            var tri = UnityEngine.AI.NavMesh.CalculateTriangulation();
            if (tri.vertices == null || tri.vertices.Length == 0)
            {
                Debug.LogWarning("[PortedBuilder] 场景里没有 NavMesh，地面碰撞体用不了");
                return 0;
            }

            var mesh = new Mesh { name = "PortedNavGround", indexFormat = UnityEngine.Rendering.IndexFormat.UInt32 };
            mesh.vertices = tri.vertices;
            mesh.triangles = tri.indices;
            mesh.RecalculateNormals();
            mesh.RecalculateBounds();
            const string meshPath = "Assets/Ported/Scenes/Ported_NavGround.asset";
            AssetDatabase.DeleteAsset(meshPath);
            AssetDatabase.CreateAsset(mesh, meshPath);

            var go = new GameObject("PortedNavGround");
            go.AddComponent<MeshCollider>().sharedMesh = mesh;
            Debug.Log($"[PortedBuilder] 用 NavMesh 生成地面碰撞：{tri.indices.Length / 3} 个三角面，范围 {mesh.bounds.size}");
            return 1;
        }

        // 诊断：出生点正下方，看得见的模型表面在多高，和 NavMesh 高度是否一致。
        // 临时给附近的模型加碰撞体做射线检测，测完删掉，不影响场景
        static void DiagnoseGround(Renderer[] renderers, Vector3 spawn)
        {
            var nav = GameObject.Find("navmesh");
            if (nav != null)
                Debug.Log($"[PortedBuilder] 诊断 navmesh 物体 位置 {nav.transform.position} 旋转 {nav.transform.eulerAngles} 缩放 {nav.transform.lossyScale}");

            var temp = new List<MeshCollider>();
            foreach (var r in renderers)
            {
                if (!(r is MeshRenderer)) continue;
                var b = r.bounds;
                if (Mathf.Abs(b.center.x - spawn.x) > b.extents.x + 3f || Mathf.Abs(b.center.z - spawn.z) > b.extents.z + 3f) continue;
                var mf = r.GetComponent<MeshFilter>();
                if (mf == null || mf.sharedMesh == null || r.GetComponent<Collider>() != null) continue;
                var mc = r.gameObject.AddComponent<MeshCollider>();
                mc.sharedMesh = mf.sharedMesh;
                temp.Add(mc);
            }
            Physics.SyncTransforms();

            var origin = new Vector3(spawn.x, spawn.y + 300f, spawn.z);
            var hits = Physics.RaycastAll(origin, Vector3.down, 1000f, ~0, QueryTriggerInteraction.Ignore)
                .OrderBy(h => -h.point.y).Take(8).ToArray();
            Debug.Log($"[PortedBuilder] 诊断 出生点正下方命中 {hits.Length} 个（候选模型 {temp.Count} 个），从高到低：");
            foreach (var h in hits)
            {
                var tr = h.collider.transform;
                var path = tr.name;
                for (var p = tr.parent; p != null && path.Length < 120; p = p.parent) path = p.name + "/" + path;
                var mat = h.collider.GetComponent<Renderer>()?.sharedMaterial;
                Debug.Log($"[PortedBuilder] 诊断   y={h.point.y:0.00} {path} 材质 {(mat != null ? mat.name : "-")}");
            }

            foreach (var mc in temp) UnityEngine.Object.DestroyImmediate(mc);
            Physics.SyncTransforms();
        }

        // 出生点放在 NavMesh 上：取所有渲染器中心附近离 NavMesh 最近的点
        static void EstimateSpawn(Renderer[] renderers, out Vector3 spawn, out float groundY)
        {
            var center = Vector3.zero;
            if (renderers.Length > 0)
            {
                var xs = renderers.Select(r => r.bounds.center.x).OrderBy(v => v).ToArray();
                var zs = renderers.Select(r => r.bounds.center.z).OrderBy(v => v).ToArray();
                var ys = renderers.Select(r => r.bounds.center.y).OrderBy(v => v).ToArray();
                center = new Vector3(xs[xs.Length / 2], ys[ys.Length / 2], zs[zs.Length / 2]);
            }

            if (UnityEngine.AI.NavMesh.SamplePosition(center, out var hit, 500f, UnityEngine.AI.NavMesh.AllAreas))
            {
                spawn = hit.position + Vector3.up * 0.5f;
                groundY = hit.position.y;
                return;
            }

            Debug.LogWarning("[PortedBuilder] 场景中心附近没有 NavMesh，出生点只能估计");
            spawn = center + Vector3.up * 20f;
            groundY = center.y;
        }

        static void CaptureGame(UnityEngine.SceneManagement.Scene scene, GameObject[] heroPrefabs, Vector3 spawn)
        {
            var camGo = new GameObject("__ShotCam", typeof(Camera));
            var cam = camGo.GetComponent<Camera>();
            cam.farClipPlane = 800f;
            cam.clearFlags = CameraClearFlags.SolidColor;
            cam.backgroundColor = new Color(0.55f, 0.7f, 0.9f);
            camGo.AddComponent<PortedFXBloom>().shader = AssetDatabase.LoadAssetAtPath<Shader>("Assets/Ported/Shaders/FXBloom.shader");

            var ground = spawn;
            if (Physics.Raycast(new Vector3(spawn.x, spawn.y + 300f, spawn.z), Vector3.down, out var hit, 1000f))
                ground = hit.point;
            else
                Debug.LogWarning("[PortedBuilder] 出生点下方没有碰撞体（游戏里会补隐形地面）");

            camGo.transform.position = ground + new Vector3(-25f, 22f, -25f);
            camGo.transform.LookAt(ground + Vector3.up * 2f);
            Capture(cam, Path.Combine(ShotDir, "scene_overview.png"), 1280, 720);

            for (var i = 0; i < heroPrefabs.Length; i++)
            {
                var inst = (GameObject)PrefabUtility.InstantiatePrefab(heroPrefabs[i]);
                inst.transform.position = ground;
                var animator = inst.GetComponentInChildren<Animator>();
                if (animator != null)
                {
                    animator.applyRootMotion = false;
                    if (animator.HasState(0, Animator.StringToHash("idle"))) animator.Play("idle", 0, 0.2f);
                    animator.Update(0.05f);
                }

                camGo.transform.position = ground + new Vector3(0.6f, 1.4f, 3.6f);
                camGo.transform.LookAt(ground + Vector3.up * 1.0f);
                cam.fieldOfView = 40f;
                Capture(cam, Path.Combine(ShotDir, "hero_" + Heroes[i].id + ".png"), 720, 960);

                var set = inst.GetComponent<HeroController>().actions;
                if (set != null)
                {
                    cam.fieldOfView = 50f;
                    foreach (var a in AllActions(set))
                        CaptureAction(cam, inst, set, a, ground, Heroes[i].id);
                }
                UnityEngine.Object.DestroyImmediate(inst);
            }

            UnityEngine.Object.DestroyImmediate(camGo);
        }

        // 编辑器里把动作停在某一时刻：动画采样到该时间，特效按配置挂好并模拟到对应进度，用来检查特效位置和材质
        static void CaptureAction(Camera cam, GameObject hero, HeroActionSet set, ActionData a, Vector3 ground, string heroId)
        {
            var animator = hero.GetComponentInChildren<Animator>();
            if (animator == null || !animator.HasState(0, Animator.StringToHash(a.clip))) return;

            var t = a.fx.Length > 0 ? a.fx.Min(f => f.start) + 0.3f : a.duration * 0.4f;
            if (a.bullets.Length > 0) t = Mathf.Max(t, a.bullets.Min(b => b.start) + 0.15f);
            t = Mathf.Min(t, a.duration);

            hero.transform.SetPositionAndRotation(ground, Quaternion.identity);
            animator.Rebind();
            animator.Play(a.clip, 0, 0f);
            animator.Update(0f);
            animator.Update(t);

            var spawned = new List<GameObject>();
            foreach (var fx in a.fx)
            {
                if (fx.prefab == null || fx.start > t || fx.end < t) continue;
                var go = PortedFx.SpawnEvent(fx, PortedFx.ResolveSocket(hero.transform, set, fx.socket));
                Simulate(go, t - fx.start);
                spawned.Add(go);
            }
            foreach (var b in a.bullets)
            {
                var e = set.FindEmitter(b.emitter);
                if (e == null || e.assetPrefab == null || b.start > t) continue;
                var dt = Mathf.Min(t - b.start, e.life);
                var pos = hero.transform.TransformPoint(e.pos) + hero.transform.forward * e.speed * dt;
                var go = PortedFx.Spawn(e.assetPrefab, pos, hero.transform.rotation * Quaternion.Euler(e.rot));
                go.transform.localScale = Vector3.one * e.assetScale;
                Simulate(go, dt);
                spawned.Add(go);
            }

            cam.transform.position = ground + new Vector3(4.5f, 3f, 6.5f);
            cam.transform.LookAt(ground + new Vector3(0f, 1f, 1.5f));
            Capture(cam, Path.Combine(ShotDir, $"skill_{heroId}_{a.clip}.png"), 960, 640);

            foreach (var go in spawned) UnityEngine.Object.DestroyImmediate(go);
            foreach (var s in hero.GetComponentsInChildren<Transform>(true).Where(x => x.name.StartsWith("socket_")).ToArray())
                UnityEngine.Object.DestroyImmediate(s.gameObject);
        }

        static void Simulate(GameObject fx, float time)
        {
            if (fx == null) return;
            foreach (var ps in fx.GetComponentsInChildren<ParticleSystem>())
                ps.Simulate(Mathf.Max(0.01f, time), false, true, true);
            foreach (var an in fx.GetComponentsInChildren<Animator>())
            {
                an.Rebind();
                an.Update(time);
            }
        }

        static void Capture(Camera cam, string file, int w, int h)
        {
            var rt = new RenderTexture(w, h, 24, RenderTextureFormat.ARGB32);
            var prevActive = RenderTexture.active;
            try
            {
                cam.targetTexture = rt;
                cam.Render();
                RenderTexture.active = rt;
                var tex = new Texture2D(w, h, TextureFormat.RGB24, false);
                tex.ReadPixels(new Rect(0, 0, w, h), 0, 0);
                tex.Apply();
                File.WriteAllBytes(file, tex.EncodeToPNG());
                UnityEngine.Object.DestroyImmediate(tex);
            }
            finally
            {
                cam.targetTexture = null;
                RenderTexture.active = prevActive;
                rt.Release();
                UnityEngine.Object.DestroyImmediate(rt);
            }
        }

        // ---------- 登录场景 ----------

        static void BuildLoginScene()
        {
            var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);

            var camGo = new GameObject("Main Camera", typeof(Camera), typeof(AudioListener));
            camGo.tag = "MainCamera";
            var cam = camGo.GetComponent<Camera>();
            cam.clearFlags = CameraClearFlags.SolidColor;
            cam.backgroundColor = Color.black;
            cam.orthographic = true;

            var canvasGo = new GameObject("Canvas", typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
            var canvas = canvasGo.GetComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceCamera;
            canvas.worldCamera = cam;
            canvas.planeDistance = 10f;
            var scaler = canvasGo.GetComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1920f, 1080f);
            scaler.matchWidthOrHeight = 0.5f;

            var bgSprite = AssetDatabase.LoadAssetAtPath<Sprite>(LoginBg);
            if (bgSprite != null)
            {
                var bg = new GameObject("Background", typeof(RectTransform), typeof(Image));
                bg.transform.SetParent(canvasGo.transform, false);
                Stretch((RectTransform)bg.transform);
                var img = bg.GetComponent<Image>();
                img.sprite = bgSprite;
                img.preserveAspect = false;
            }
            else
            {
                Debug.LogWarning("[PortedBuilder] 没找到登录背景 " + LoginBg);
            }

            var panelSrc = AssetDatabase.LoadAssetAtPath<GameObject>(LoginPanelPrefab);
            if (panelSrc == null) throw new Exception("找不到 " + LoginPanelPrefab);
            var panel = (GameObject)PrefabUtility.InstantiatePrefab(panelSrc, canvasGo.transform);
            Stretch((RectTransform)panel.transform);

            var ctrlGo = new GameObject("PortedLogin");
            var ctrl = ctrlGo.AddComponent<PortedLoginController>();
            ctrl.loginPanel = panel;
            ctrl.heroNames = Heroes.Select(h => h.display).ToArray();

            new GameObject("EventSystem", typeof(EventSystem), typeof(InputSystemUIInputModule));

            Capture(cam, Path.Combine(ShotDir, "login.png"), 1280, 720);
            EditorSceneManager.SaveScene(scene, LoginScenePath);
        }

        static void Stretch(RectTransform rt)
        {
            rt.anchorMin = Vector2.zero;
            rt.anchorMax = Vector2.one;
            rt.offsetMin = Vector2.zero;
            rt.offsetMax = Vector2.zero;
        }

        // ---------- Build Settings ----------

        static void UpdateBuildSettings()
        {
            var scenes = EditorBuildSettings.scenes.ToList();
            foreach (var path in new[] { LoginScenePath, GameScenePath })
            {
                if (scenes.Any(s => s.path == path)) continue;
                scenes.Add(new EditorBuildSettingsScene(path, true));
            }
            EditorBuildSettings.scenes = scenes.ToArray();
        }
    }

    // 色彩空间切换。qq13 的特效都是在 Gamma 下调的，切到 Gamma 后移植的特效 shader 会按原版方式计算（Gamma 模拟代码自动关闭）。
    // 这是整个项目的设置，会重新导入全部贴图，项目里其他内容的显示也会跟着变。
    public static class PortedColorSpace
    {
        [MenuItem("Tools/Ported/Color Space/Gamma (与 qq13 一致)")]
        public static void ToGamma() => Set(ColorSpace.Gamma);

        [MenuItem("Tools/Ported/Color Space/Linear (切回原设置)")]
        public static void ToLinear() => Set(ColorSpace.Linear);

        static void Set(ColorSpace space)
        {
            if (PlayerSettings.colorSpace == space)
            {
                Debug.Log("[PortedBuilder] 色彩空间已经是 " + space);
                return;
            }
            PlayerSettings.colorSpace = space;
            AssetDatabase.SaveAssets();
            Debug.Log("[PortedBuilder] 色彩空间已切换为 " + space);
        }
    }

    // 放一个 run_build.flag 文件到本目录，编辑器下次编译完成后自动跑一次 Build All
    [InitializeOnLoad]
    static class PortedBuilderAutoRun
    {
        const string Flag = "Assets/Ported/Scripts/Editor/run_build.flag";
        const string GammaFlag = "Assets/Ported/Scripts/Editor/gamma.flag";

        static PortedBuilderAutoRun()
        {
            EditorApplication.delayCall += TryRun;
            // 播放模式下不能开关场景，退出播放后再跑
            EditorApplication.playModeStateChanged += s =>
            {
                if (s == PlayModeStateChange.EnteredEditMode) EditorApplication.delayCall += TryRun;
            };
        }

        static void TryRun()
        {
            if (EditorApplication.isPlayingOrWillChangePlaymode) return;

            // gamma.flag：切换到 Gamma 色彩空间
            if (File.Exists(GammaFlag))
            {
                File.Delete(GammaFlag);
                if (File.Exists(GammaFlag + ".meta")) File.Delete(GammaFlag + ".meta");
                PortedColorSpace.ToGamma();
            }

            if (!File.Exists(Flag)) return;
            File.Delete(Flag);
            if (File.Exists(Flag + ".meta")) File.Delete(Flag + ".meta");
            AssetDatabase.Refresh();
            PortedBuilder.BuildAll();
        }
    }
}



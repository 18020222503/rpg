using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.SceneManagement;

namespace Ported
{
    // 放在移植场景里：生成选中的角色、跟随相机和几个练习用的木桩
    public class PortedGameBootstrap : MonoBehaviour
    {
        public GameObject[] heroPrefabs;
        public string[] heroNames;
        public Vector3 spawnPoint = new Vector3(0f, 5f, 0f);

        [Tooltip("场景里查不到地面碰撞体时，在这个高度补一块看不见的地面")]
        public float fallbackGroundY = 0f;

        public bool spawnDummies = true;
        public Shader fxBloomShader;
        public Shader blobShadowShader;

        HeroController hero;
        string heroName = "";

        void Start()
        {
            if (heroPrefabs == null || heroPrefabs.Length == 0)
            {
                Debug.LogError("[Ported] heroPrefabs 为空，先执行 Tools/Ported/Build All");
                return;
            }

            var index = Mathf.Clamp(PortedSession.HeroIndex, 0, heroPrefabs.Length - 1);
            if (heroNames != null && index < heroNames.Length) heroName = heroNames[index];

            var pos = FindGround(spawnPoint);
            var go = Instantiate(heroPrefabs[index], pos, Quaternion.identity);
            go.name = heroPrefabs[index].name;
            hero = go.GetComponent<HeroController>();

            var cam = Camera.main;
            if (cam == null)
            {
                var camGo = new GameObject("Main Camera", typeof(Camera), typeof(AudioListener));
                camGo.tag = "MainCamera";
                cam = camGo.GetComponent<Camera>();
                cam.nearClipPlane = 0.1f;
                cam.farClipPlane = 600f;
            }

            // 原项目的特效 Bloom，参数在相机的 PortedFXBloom 组件上调
            var bloom = cam.GetComponent<PortedFXBloom>();
            if (bloom == null) bloom = cam.gameObject.AddComponent<PortedFXBloom>();
            if (bloom.shader == null) bloom.shader = fxBloomShader;

            // 原项目的角色脚下阴影
            var blob = cam.GetComponent<PortedBlobShadow>();
            if (blob == null) blob = cam.gameObject.AddComponent<PortedBlobShadow>();
            if (blob.applyShader == null) blob.applyShader = blobShadowShader;

            var follow = cam.GetComponent<PortedFollowCamera>();
            if (follow == null) follow = cam.gameObject.AddComponent<PortedFollowCamera>();
            follow.target = go.transform;
            follow.Pose(pos, out var camPos, out var camRot);
            cam.transform.SetPositionAndRotation(camPos, camRot);
            cam.farClipPlane = Mathf.Max(cam.farClipPlane, 600f);
            if (hero != null) hero.cameraTransform = cam.transform;

            if (spawnDummies) SpawnDummies(pos);
        }

        Vector3 FindGround(Vector3 from)
        {
            var origin = new Vector3(from.x, from.y + 300f, from.z);
            if (Physics.Raycast(origin, Vector3.down, out var hit, 1000f, ~0, QueryTriggerInteraction.Ignore))
                return hit.point + Vector3.up * 0.1f;

            Debug.LogWarning("[Ported] 出生点下方没有碰撞体，补一块隐形地面");
            var ground = new GameObject("PortedFallbackGround", typeof(BoxCollider));
            ground.transform.position = new Vector3(from.x, fallbackGroundY - 0.5f, from.z);
            ground.GetComponent<BoxCollider>().size = new Vector3(500f, 1f, 500f);
            return new Vector3(from.x, fallbackGroundY + 0.1f, from.z);
        }

        void SpawnDummies(Vector3 around)
        {
            for (var i = 0; i < 3; i++)
            {
                var dummy = GameObject.CreatePrimitive(PrimitiveType.Capsule);
                dummy.name = $"Dummy_{i + 1}";
                var p = around + new Vector3((i - 1) * 2.5f, 0f, 5f);
                // 木桩是 2 米高的胶囊，中心放在地面上方 1 米
                if (Physics.Raycast(p + Vector3.up * 20f, Vector3.down, out var hit, 60f, ~0, QueryTriggerInteraction.Ignore)) p = hit.point;
                dummy.transform.position = p + Vector3.up;
                dummy.AddComponent<Damageable>();
            }
        }

        void Update()
        {
            var kb = Keyboard.current;
            if (kb != null && kb.escapeKey.wasPressedThisFrame) SceneManager.LoadScene(PortedSession.LoginScene);
        }

        void OnGUI()
        {
            if (hero == null) return;

            var lines = new System.Text.StringBuilder();
            lines.AppendLine($"{heroName}   WASD 移动  右键/QE 转镜头  Esc 返回登录");
            lines.AppendLine($"[{hero.comboKey}] 连招  [{hero.heavyKey}] 重击  [{hero.skill1Key}/1] 技能1  [{hero.skill2Key}/2] 技能2  [{hero.ultimateKey}/3] 大招");
            if (!string.IsNullOrEmpty(hero.LastSkill)) lines.AppendLine("最近: " + hero.LastSkill);

            GUI.Box(new Rect(10, 10, 460, 74), GUIContent.none);
            GUI.Label(new Rect(18, 14, 450, 70), lines.ToString());
        }
    }
}

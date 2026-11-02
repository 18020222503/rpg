using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;

public static class DungeonSceneBuilder
{
    const string ModelDir = "Assets/Artist/Dungeon/Models/";
    const string CharacterDir = "Assets/Artist/Adventurers/Characters/";
    const string ScenePath = "Assets/Scenes/Dungeon.unity";
    const string ZoneMatPath = "Assets/Artist/Dungeon/ExtractionZone.mat";

    // 房间边长48：8x8块6米地砖，每边12段4米长的墙
    const float RoomHalf = 24f;
    static readonly float[] TileCenters = { -21f, -15f, -9f, -3f, 3f, 9f, 15f, 21f };
    static readonly float[] WallSegments = { -22f, -18f, -14f, -10f, -6f, -2f, 2f, 6f, 10f, 14f, 18f, 22f };

    [MenuItem("Tools/Dungeon/BuildScene")]
    public static void Build()
    {
        if (!EditorSceneManager.SaveCurrentModifiedScenesIfUserWantsTo()) return;

        EditorSceneManager.NewScene(NewSceneSetup.DefaultGameObjects, NewSceneMode.Single);

        var root = new GameObject("Dungeon").transform;
        var floor = NewGroup("Floor", root);
        var walls = NewGroup("Walls", root);
        var props = NewGroup("Props", root);

        BuildFloor(floor);
        BuildWalls(walls);
        BuildProps(props);
        BuildExtractionZone(root);
        var player = BuildPlayer();
        SetupCamera(player.transform);
        SetupLight();

        EditorSceneManager.SaveScene(EditorSceneManager.GetActiveScene(), ScenePath);
        Debug.Log($"[Dungeon] 场景已生成：{ScenePath}");
    }

    static void BuildFloor(Transform parent)
    {
        // 地砖厚1米，底部放在 y=-1，让表面正好在 y=0
        foreach (var x in TileCenters)
        {
            foreach (var z in TileCenters)
            {
                Place("tileBrickB_large", new Vector3(x, -1f, z), 0f, parent);
            }
        }
    }

    static void BuildWalls(Transform parent)
    {
        foreach (var s in WallSegments)
        {
            // x=2 这一段换成大门，作为撤离口
            Place(Mathf.Approximately(s, 2f) ? "wall_gate" : "wall", new Vector3(s, 0f, RoomHalf), 0f, parent);
            Place("wall", new Vector3(s, 0f, -RoomHalf), 180f, parent);
            Place("wall", new Vector3(RoomHalf, 0f, s), 90f, parent);
            Place("wall", new Vector3(-RoomHalf, 0f, s), -90f, parent);
        }

        // 四个角用柱子盖住墙的接缝
        foreach (var x in new[] { -RoomHalf, RoomHalf })
        {
            foreach (var z in new[] { -RoomHalf, RoomHalf })
            {
                Place("pillar", new Vector3(x, 0f, z), 0f, parent);
            }
        }
    }

    static void BuildProps(Transform parent)
    {
        // 宝箱：品质从普通到稀有
        Place("chest_common", At(-8f, 8f), 135f, parent);
        Place("chest_common", At(0f, -9f), 0f, parent);
        Place("chest_uncommon", At(8f, -6f), -45f, parent);
        Place("chest_rare", At(-8f, -9f), 30f, parent);

        // 箱子桶子
        Place("crate", At(-9.5f, -3.5f), 10f, parent);
        Place("crate", At(-9.5f, -3.5f, 1.05f), 40f, parent);
        Place("crateDark", At(9f, 3f), 0f, parent);
        Place("barrel", At(9.5f, 6f), 0f, parent);
        Place("barrelDark", At(-10f, 2f), 0f, parent);
        Place("lootSackA", At(6f, -9f), 20f, parent);

        // 桌子和桌上的战利品，战利品相对桌子定位，不跟着放大
        var table = At(-3f, 3f);
        Place("tableLarge", table, 0f, parent);
        Place("potionMedium_red", table + new Vector3(-0.6f, 0.71f, 0f), 0f, parent, false);
        Place("coinsMedium", table + new Vector3(0.6f, 0.71f, 0.2f), 0f, parent, false);

        // 家具
        Place("bookcaseFilled", At(-10.5f, 7f), 90f, parent);
        Place("weaponRack", At(10.5f, -2f), -90f, parent);
        Place("pillar", At(-5f, -4f), 0f, parent);
        Place("pillar", At(5f, 4f), 0f, parent);

        // 火把，带一盏暖色点光源
        foreach (var p in new[] { new Vector3(-22f, 0f, 22f), new Vector3(22f, 0f, 22f), new Vector3(-22f, 0f, -22f), new Vector3(22f, 0f, -22f) })
        {
            var torch = Place("torch", p, 0f, parent, false);
            if (torch == null) continue;

            var lightGo = new GameObject("TorchLight");
            lightGo.transform.SetParent(torch.transform, false);
            lightGo.transform.position = torch.transform.position + Vector3.up * 1.8f;
            var light = lightGo.AddComponent<Light>();
            light.type = LightType.Point;
            light.color = new Color(1f, 0.65f, 0.3f);
            light.range = 9f;
            light.intensity = 4f;
        }
    }

    static void BuildExtractionZone(Transform parent)
    {
        // 大门前的撤离点，先用绿色圆盘做标记，还没有撤离逻辑
        var zone = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
        zone.name = "ExtractionZone";
        zone.transform.SetParent(parent, false);
        zone.transform.position = new Vector3(2f, 0.02f, RoomHalf - 3.5f);
        zone.transform.localScale = new Vector3(5f, 0.02f, 5f);
        Object.DestroyImmediate(zone.GetComponent<Collider>());

        var mat = AssetDatabase.LoadAssetAtPath<Material>(ZoneMatPath);
        if (mat == null)
        {
            var shader = Shader.Find("Universal Render Pipeline/Lit");
            mat = new Material(shader);
            mat.color = new Color(0.2f, 0.9f, 0.4f);
            AssetDatabase.CreateAsset(mat, ZoneMatPath);
        }
        zone.GetComponent<Renderer>().sharedMaterial = mat;
    }

    static GameObject BuildPlayer()
    {
        var player = new GameObject("Player");
        player.transform.position = new Vector3(-2f, 0f, -RoomHalf + 4f);

        var model = Place("Knight", player.transform.position, 0f, player.transform, false, CharacterDir);
        var controller = player.AddComponent<CharacterController>();

        if (model != null)
        {
            // FBX 是 Generic 骨骼时导入后自带 Animator，没有就补一个
            var animator = model.GetComponentInChildren<Animator>();
            if (animator == null) animator = model.AddComponent<Animator>();
            animator.runtimeAnimatorController = PlayerAnimatorBuilder.GetOrCreate();
            animator.applyRootMotion = false;
        }

        if (model != null)
        {
            // 按模型实际大小设置碰撞胶囊
            var b = GetBounds(model);
            controller.height = b.size.y;
            controller.radius = Mathf.Min(b.size.x, b.size.z) * 0.4f;
            controller.center = b.center - player.transform.position;
        }
        else
        {
            controller.height = 2f;
            controller.radius = 0.4f;
            controller.center = Vector3.up;
        }

        player.AddComponent<PlayerController>();
        return player;
    }

    static void SetupCamera(Transform target)
    {
        var cam = Camera.main;
        if (cam == null) return;

        var follow = cam.gameObject.AddComponent<TopDownCamera>();
        follow.target = target;
        cam.transform.position = target.position + follow.offset;
        cam.transform.rotation = Quaternion.LookRotation(-follow.offset);
    }

    static void SetupLight()
    {
        var light = Object.FindFirstObjectByType<Light>();
        if (light == null || light.type != LightType.Directional) return;

        light.transform.rotation = Quaternion.Euler(50f, -30f, 0f);
        light.intensity = 0.8f;
    }

    // 摆件位置按房间放大倍数拉开，y（高度）不放大，模型本身也不放大
    const float PropSpread = 2f;

    static Vector3 At(float x, float z, float y = 0f)
    {
        return new Vector3(x * PropSpread, y, z * PropSpread);
    }

    static Transform NewGroup(string name, Transform parent)
    {
        var go = new GameObject(name);
        go.transform.SetParent(parent, false);
        return go.transform;
    }

    // pos.y 是模型底部的高度，不同模型的轴点不一样，这里按包围盒统一贴地
    static GameObject Place(string name, Vector3 pos, float yaw, Transform parent, bool addCollider = true, string dir = null)
    {
        var path = (dir ?? ModelDir) + name + ".fbx";
        var prefab = AssetDatabase.LoadAssetAtPath<GameObject>(path);
        if (prefab == null)
        {
            Debug.LogError($"[Dungeon] 找不到模型：{path}");
            return null;
        }

        var go = (GameObject)PrefabUtility.InstantiatePrefab(prefab, parent);
        go.transform.SetPositionAndRotation(pos, Quaternion.Euler(0f, yaw, 0f));
        go.transform.position += Vector3.up * (pos.y - GetBounds(go).min.y);

        if (addCollider)
        {
            foreach (var mf in go.GetComponentsInChildren<MeshFilter>())
            {
                if (mf.GetComponent<Collider>() == null) mf.gameObject.AddComponent<MeshCollider>();
            }
        }

        return go;
    }

    static Bounds GetBounds(GameObject go)
    {
        var renderers = go.GetComponentsInChildren<Renderer>();
        if (renderers.Length == 0) return new Bounds(go.transform.position, Vector3.zero);

        var b = renderers[0].bounds;
        for (int i = 1; i < renderers.Length; i++) b.Encapsulate(renderers[i].bounds);
        return b;
    }
}

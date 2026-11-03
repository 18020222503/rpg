using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.InputSystem.UI;
using UnityEngine.UI;

// 在 Entry 场景里生成 UIRoot（Canvas + UIManager）和第一个界面 UIStartPanel
public static class EntryUIBuilder
{
    const string ScenePath = "Assets/Scenes/Entry.unity";
    const string RootName = "UIRoot";
    const string LegacyCanvasName = "Canvas";

    [MenuItem("Tools/UI/RebuildEntryUI")]
    public static void Rebuild()
    {
        if (!EditorSceneManager.SaveCurrentModifiedScenesIfUserWantsTo()) return;

        var scene = EditorSceneManager.OpenScene(ScenePath, OpenSceneMode.Single);
        Apply(scene, true);
        EditorSceneManager.SaveScene(scene, ScenePath);
    }

    // rebuild=false 时，UIRoot 已存在就不动，避免覆盖你手动换过美术的界面
    public static void Apply(UnityEngine.SceneManagement.Scene scene, bool rebuild)
    {
        foreach (var go in scene.GetRootGameObjects())
        {
            if (go.name != RootName) continue;
            if (!rebuild) return;
            Object.DestroyImmediate(go);
        }

        DisableLegacyCanvas(scene);
        EnsureEventSystem();

        var root = CreateRoot();
        CreateStartPanel(root.transform);
        Debug.Log($"[UI] 已生成 {RootName}");
    }

    // 旧的测试界面（蓝色面板、测试按钮）只停用，不删除，需要时勾回来即可
    static void DisableLegacyCanvas(UnityEngine.SceneManagement.Scene scene)
    {
        foreach (var go in scene.GetRootGameObjects())
        {
            if (go.name != LegacyCanvasName || !go.activeSelf) continue;
            go.SetActive(false);
            Debug.Log("[UI] 旧的测试 Canvas 已停用（没有删除）");
        }
    }

    static void EnsureEventSystem()
    {
        if (Object.FindFirstObjectByType<EventSystem>() != null) return;
        new GameObject("EventSystem", typeof(EventSystem), typeof(InputSystemUIInputModule));
    }

    static GameObject CreateRoot()
    {
        var go = new GameObject(RootName, typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster), typeof(UIManager));

        var canvas = go.GetComponent<Canvas>();
        canvas.renderMode = RenderMode.ScreenSpaceOverlay;

        // 按屏幕尺寸缩放，参考 1920x1080，宽高各占一半权重
        var scaler = go.GetComponent<CanvasScaler>();
        scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
        scaler.referenceResolution = new Vector2(1920f, 1080f);
        scaler.screenMatchMode = CanvasScaler.ScreenMatchMode.MatchWidthOrHeight;
        scaler.matchWidthOrHeight = 0.5f;
        return go;
    }

    static void CreateStartPanel(Transform parent)
    {
        var panelGo = new GameObject("StartPanel", typeof(RectTransform), typeof(UIStartPanel));
        var panelRect = (RectTransform)panelGo.transform;
        panelRect.SetParent(parent, false);
        Stretch(panelRect);

        // 半透明遮罩，让背后的地图透出来
        var dim = panelGo.AddComponent<Image>();
        dim.color = new Color(0f, 0f, 0f, 0.35f);
        dim.raycastTarget = true;

        CreateText("Title", panelRect, "EXTRACTION", 110, new Vector2(0.5f, 0.68f), new Vector2(1200f, 180f));
        var button = CreateButton("StartButton", panelRect, "START", new Vector2(0.5f, 0.32f), new Vector2(460f, 130f));

        var panel = panelGo.GetComponent<UIStartPanel>();
        panel.layer = UILayer.Popup;
        panel.startButton = button;
    }

    internal static Button CreateButton(string name, Transform parent, string label, Vector2 anchor, Vector2 size)
    {
        var resources = new DefaultControls.Resources
        {
            standard = AssetDatabase.GetBuiltinExtraResource<Sprite>("UI/Skin/UISprite.psd"),
        };

        var go = DefaultControls.CreateButton(resources);
        go.name = name;
        go.transform.SetParent(parent, false);

        var rect = (RectTransform)go.transform;
        rect.anchorMin = rect.anchorMax = anchor;
        rect.sizeDelta = size;
        rect.anchoredPosition = Vector2.zero;

        var text = go.GetComponentInChildren<Text>();
        text.text = label;
        text.fontSize = 56;
        text.fontStyle = FontStyle.Bold;
        return go.GetComponent<Button>();
    }

    internal static Text CreateText(string name, Transform parent, string content, int fontSize, Vector2 anchor, Vector2 size)
    {
        var go = new GameObject(name, typeof(RectTransform), typeof(Text), typeof(Outline));
        var rect = (RectTransform)go.transform;
        rect.SetParent(parent, false);
        rect.anchorMin = rect.anchorMax = anchor;
        rect.sizeDelta = size;
        rect.anchoredPosition = Vector2.zero;

        var text = go.GetComponent<Text>();
        text.text = content;
        text.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
        text.fontSize = fontSize;
        text.fontStyle = FontStyle.Bold;
        text.alignment = TextAnchor.MiddleCenter;
        text.color = Color.white;
        text.raycastTarget = false;

        var outline = go.GetComponent<Outline>();
        outline.effectColor = new Color(0.1f, 0.1f, 0.15f, 1f);
        outline.effectDistance = new Vector2(4f, -4f);
        return text;
    }

    internal static void Stretch(RectTransform rect)
    {
        rect.anchorMin = Vector2.zero;
        rect.anchorMax = Vector2.one;
        rect.offsetMin = Vector2.zero;
        rect.offsetMax = Vector2.zero;
    }
}

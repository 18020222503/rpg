using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.UI;

// 重建 Boot 场景的启动界面：背景、标题、下载进度条，以及下载失败时的重试按钮
public static class BootUIBuilder
{
    const string ScenePath = "Assets/Scenes/Boot.unity";
    const string ViewName = "BootView";

    // 配色取自地图：地砖的深蓝灰，火把的橙金
    static readonly Color BackgroundColor = new Color(0.09f, 0.11f, 0.15f, 1f);
    static readonly Color Gold = new Color(1f, 0.72f, 0.25f, 1f);
    static readonly Color FrameColor = new Color(0.55f, 0.42f, 0.18f, 1f);
    static readonly Color TrackColor = new Color(0.04f, 0.05f, 0.07f, 1f);

    [MenuItem("Tools/UI/RebuildBootUI")]
    public static void Rebuild()
    {
        if (!EditorSceneManager.SaveCurrentModifiedScenesIfUserWantsTo()) return;

        var scene = EditorSceneManager.OpenScene(ScenePath, OpenSceneMode.Single);

        var boot = Object.FindFirstObjectByType<GameBoot>();
        var canvas = boot != null ? boot.GetComponentInParent<Canvas>() : null;
        if (boot == null || canvas == null)
        {
            Debug.LogError("[UI] Boot 场景里找不到挂在 Canvas 上的 GameBoot");
            return;
        }

        SetupScaler(canvas);
        RemoveOldView(canvas.transform);
        DisableLegacyChildren(canvas.transform);
        var view = CreateView(canvas.transform);
        SetupCamera();

        var so = new SerializedObject(boot);
        var prop = so.FindProperty("view");
        if (prop == null)
        {
            Debug.LogError("[UI] GameBoot 没有 view 字段，请等脚本编译完成后再执行");
            return;
        }

        prop.objectReferenceValue = view;
        so.ApplyModifiedPropertiesWithoutUndo();

        EditorSceneManager.MarkSceneDirty(scene);
        EditorSceneManager.SaveScene(scene, ScenePath);
        Debug.Log("[UI] Boot 界面已生成");
    }

    static void SetupScaler(Canvas canvas)
    {
        var scaler = canvas.GetComponent<CanvasScaler>();
        if (scaler == null) scaler = canvas.gameObject.AddComponent<CanvasScaler>();

        // 按屏幕尺寸缩放，参考 1920x1080，和 Entry 的界面一致
        scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
        scaler.referenceResolution = new Vector2(1920f, 1080f);
        scaler.screenMatchMode = CanvasScaler.ScreenMatchMode.MatchWidthOrHeight;
        scaler.matchWidthOrHeight = 0.5f;
    }

    static void RemoveOldView(Transform canvas)
    {
        var old = canvas.Find(ViewName);
        if (old != null) Object.DestroyImmediate(old.gameObject);
    }

    // 旧的滚动条和图片只停用，不删除，需要时勾回来即可
    static void DisableLegacyChildren(Transform canvas)
    {
        foreach (Transform child in canvas)
        {
            if (!child.gameObject.activeSelf) continue;
            child.gameObject.SetActive(false);
            Debug.Log($"[UI] 旧的 {child.name} 已停用（没有删除）");
        }
    }

    static void SetupCamera()
    {
        var cam = Camera.main != null ? Camera.main : Object.FindFirstObjectByType<Camera>();
        if (cam == null) return;

        cam.clearFlags = CameraClearFlags.SolidColor;
        cam.backgroundColor = BackgroundColor;
    }

    static BootProgressView CreateView(Transform parent)
    {
        var go = new GameObject(ViewName, typeof(RectTransform), typeof(BootProgressView));
        var rect = (RectTransform)go.transform;
        rect.SetParent(parent, false);
        EntryUIBuilder.Stretch(rect);
        var view = go.GetComponent<BootProgressView>();

        var bg = new GameObject("Background", typeof(RectTransform), typeof(Image));
        var bgRect = (RectTransform)bg.transform;
        bgRect.SetParent(rect, false);
        EntryUIBuilder.Stretch(bgRect);
        var bgImage = bg.GetComponent<Image>();
        bgImage.color = BackgroundColor;
        bgImage.raycastTarget = false;

        EntryUIBuilder.CreateText("Title", rect, "EXTRACTION", 120, new Vector2(0.5f, 0.62f), new Vector2(1400f, 200f));
        var subtitle = EntryUIBuilder.CreateText("Subtitle", rect, "LOOT.  FIGHT.  ESCAPE.", 38, new Vector2(0.5f, 0.53f), new Vector2(1000f, 70f));
        subtitle.color = Gold;

        view.bar = CreateBar(rect, new Vector2(0.5f, 0.22f), new Vector2(1100f, 44f));
        view.percentText = EntryUIBuilder.CreateText("Percent", rect, "0%", 30, new Vector2(0.5f, 0.22f), new Vector2(200f, 44f));

        view.statusText = EntryUIBuilder.CreateText("Status", rect, "", 34, new Vector2(0.5f, 0.15f), new Vector2(1400f, 60f));
        view.statusText.color = new Color(0.8f, 0.85f, 0.9f, 1f);
        view.detailText = EntryUIBuilder.CreateText("Detail", rect, "", 26, new Vector2(0.5f, 0.11f), new Vector2(1400f, 50f));
        view.detailText.color = new Color(0.55f, 0.62f, 0.7f, 1f);

        // 下载失败时才显示：错误信息和重试按钮
        var errorGo = new GameObject("Error", typeof(RectTransform));
        var errorRect = (RectTransform)errorGo.transform;
        errorRect.SetParent(rect, false);
        EntryUIBuilder.Stretch(errorRect);
        view.errorRoot = errorGo;
        view.errorText = EntryUIBuilder.CreateText("ErrorText", errorRect, "", 34, new Vector2(0.5f, 0.40f), new Vector2(1500f, 60f));
        view.errorText.color = new Color(1f, 0.45f, 0.4f, 1f);
        view.retryButton = EntryUIBuilder.CreateButton("RetryButton", errorRect, "RETRY", new Vector2(0.5f, 0.31f), new Vector2(320f, 90f));
        errorGo.SetActive(false);

        return view;
    }

    // 金色外框 + 深色轨道 + 橙金填充。用 Slider 实现，值 0~1 对应下载进度
    static Slider CreateBar(Transform parent, Vector2 anchor, Vector2 size)
    {
        var sprite = AssetDatabase.GetBuiltinExtraResource<Sprite>("UI/Skin/UISprite.psd");

        var frameGo = new GameObject("BarFrame", typeof(RectTransform), typeof(Image));
        var frameRect = (RectTransform)frameGo.transform;
        frameRect.SetParent(parent, false);
        frameRect.anchorMin = frameRect.anchorMax = anchor;
        frameRect.sizeDelta = size + new Vector2(16f, 16f);
        frameRect.anchoredPosition = Vector2.zero;
        var frame = frameGo.GetComponent<Image>();
        frame.sprite = sprite;
        frame.type = Image.Type.Sliced;
        frame.color = FrameColor;
        frame.raycastTarget = false;

        var resources = new DefaultControls.Resources { standard = sprite, background = sprite, knob = sprite };
        var sliderGo = DefaultControls.CreateSlider(resources);
        sliderGo.name = "ProgressBar";
        var sliderRect = (RectTransform)sliderGo.transform;
        sliderRect.SetParent(frameRect, false);
        sliderRect.anchorMin = Vector2.zero;
        sliderRect.anchorMax = Vector2.one;
        sliderRect.offsetMin = new Vector2(8f, 8f);
        sliderRect.offsetMax = new Vector2(-8f, -8f);

        var slider = sliderGo.GetComponent<Slider>();
        var background = (RectTransform)sliderRect.Find("Background");
        var fillArea = (RectTransform)sliderRect.Find("Fill Area");
        var fill = (RectTransform)fillArea.Find("Fill");

        // 只用来显示进度，不需要滑块手柄，也不让玩家拖动
        slider.handleRect = null;
        Object.DestroyImmediate(sliderRect.Find("Handle Slide Area").gameObject);
        slider.interactable = false;
        slider.transition = Selectable.Transition.None;
        slider.minValue = 0f;
        slider.maxValue = 1f;
        slider.wholeNumbers = false;

        background.anchorMin = Vector2.zero;
        background.anchorMax = Vector2.one;
        background.offsetMin = Vector2.zero;
        background.offsetMax = Vector2.zero;
        background.GetComponent<Image>().color = TrackColor;

        fillArea.anchorMin = Vector2.zero;
        fillArea.anchorMax = Vector2.one;
        fillArea.offsetMin = new Vector2(4f, 4f);
        fillArea.offsetMax = new Vector2(-4f, -4f);

        // Slider 运行时会接管填充条的锚点，这里先摆成宽度为 0 的初始状态
        fill.anchorMin = Vector2.zero;
        fill.anchorMax = new Vector2(0f, 1f);
        fill.offsetMin = Vector2.zero;
        fill.offsetMax = Vector2.zero;
        fill.GetComponent<Image>().color = Gold;

        slider.value = 0f;
        return slider;
    }
}

using System;
using System.Collections.Generic;
using UnityEngine;

// 挂在 UI 根 Canvas 上。启动时建好 HUD / Popup / Top 三个层，
// 并把 Canvas 下所有 UIPanel 登记进来（统一隐藏，需要时用 Open<T>() 打开）
public class UIManager : MonoBehaviour
{
    public static UIManager Instance { get; private set; }

    readonly Dictionary<Type, UIPanel> panels = new Dictionary<Type, UIPanel>();
    readonly Dictionary<UILayer, RectTransform> layers = new Dictionary<UILayer, RectTransform>();

    void Awake()
    {
        if (Instance != null && Instance != this)
        {
            Destroy(gameObject);
            return;
        }

        Instance = this;
        CreateLayers();

        foreach (var panel in GetComponentsInChildren<UIPanel>(true))
        {
            Register(panel);
        }
    }

    void OnDestroy()
    {
        if (Instance == this) Instance = null;
    }

    public T Open<T>(object data = null) where T : UIPanel
    {
        var panel = Get<T>();
        if (panel == null)
        {
            Debug.LogError($"[UI] 没有登记 {typeof(T).Name}，请确认它在 UIRoot 下");
            return null;
        }

        panel.transform.SetAsLastSibling();
        panel.Open(data);
        return panel;
    }

    public void Close<T>(float fadeTime = 0f) where T : UIPanel
    {
        var panel = Get<T>();
        if (panel != null) panel.Close(fadeTime);
    }

    public T Get<T>() where T : UIPanel
    {
        return panels.TryGetValue(typeof(T), out var panel) ? (T)panel : null;
    }

    public void CloseAll(UILayer layer, float fadeTime = 0f)
    {
        foreach (var panel in panels.Values)
        {
            if (panel.layer == layer) panel.Close(fadeTime);
        }
    }

    void CreateLayers()
    {
        foreach (UILayer layer in Enum.GetValues(typeof(UILayer)))
        {
            var go = new GameObject($"Layer_{layer}", typeof(RectTransform));
            var rect = (RectTransform)go.transform;
            rect.SetParent(transform, false);
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
            layers[layer] = rect;
        }
    }

    void Register(UIPanel panel)
    {
        var type = panel.GetType();
        if (panels.ContainsKey(type))
        {
            Debug.LogWarning($"[UI] {type.Name} 重复，忽略 {panel.name}");
            return;
        }

        panels[type] = panel;
        panel.transform.SetParent(layers[panel.layer], false);
        panel.gameObject.SetActive(false);
    }
}

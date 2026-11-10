using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEngine;

// 资源加载耗时测试窗口：对比 LoadFromFile（打开 bundle）和 LoadAsset（取出资源）。
// 需要在 Play 模式下使用，bundle 要先用 Tools/CreateABTag + Tools/BuildAB 打好。
public class LoadProfilerWindow : EditorWindow
{
    const string AssetNameKey = "LoadProfiler.AssetName";
    const string RepeatKey = "LoadProfiler.Repeat";

    static readonly Color BundleColor = new Color(0.30f, 0.60f, 0.95f);
    static readonly Color AssetColor = new Color(0.95f, 0.60f, 0.25f);
    static readonly Color AgainColor = new Color(0.45f, 0.80f, 0.45f);

    string assetName;
    int repeat;
    Vector2 scroll;
    readonly List<ResourceManager.LoadTestResult> results = new List<ResourceManager.LoadTestResult>();

    [MenuItem("Tools/LoadProfiler", priority = 4)]
    public static void Open()
    {
        GetWindow<LoadProfilerWindow>("加载耗时测试");
    }

    void OnEnable()
    {
        assetName = EditorPrefs.GetString(AssetNameKey, "Prefab/map/Dungeon.prefab");
        repeat = EditorPrefs.GetInt(RepeatKey, 5);
    }

    void OnGUI()
    {
        assetName = EditorGUILayout.TextField("资源(相对GameResource)", assetName);
        repeat = Mathf.Clamp(EditorGUILayout.IntField("重复次数", repeat), 1, 100);

        using (new EditorGUILayout.HorizontalScope())
        {
            using (new EditorGUI.DisabledScope(!Application.isPlaying))
            {
                if (GUILayout.Button("运行测试")) Run();
            }
            if (GUILayout.Button("清空结果")) results.Clear();
        }

        if (!Application.isPlaying)
        {
            EditorGUILayout.HelpBox("请进入 Play 模式后再运行测试。", MessageType.Info);
        }

        if (results.Count == 0) return;

        DrawSummary();
        DrawTable();
    }

    void Run()
    {
        EditorPrefs.SetString(AssetNameKey, assetName);
        EditorPrefs.SetInt(RepeatKey, repeat);

        var rm = ResourceManager.Instance;
        if (!rm.IsInitialized) rm.Init();

        results.Clear();
        for (int i = 0; i < repeat; i++)
        {
            if (!rm.RunLoadTest(assetName, out var r)) break;
            results.Add(r);
        }
        Repaint();
    }

    void DrawSummary()
    {
        EditorGUILayout.Space();
        double maxMs = results.Max(r => System.Math.Max(r.loadBundleMs, System.Math.Max(r.loadAssetMs, r.loadAssetAgainMs)));

        EditorGUILayout.LabelField($"平均值（共 {results.Count} 次，第 1 次磁盘未缓存，通常最慢）", EditorStyles.boldLabel);
        DrawBar("LoadFromFile", results.Average(r => r.loadBundleMs), maxMs, BundleColor, results.Average(r => r.loadBundleKB));
        DrawBar("LoadAsset 首次", results.Average(r => r.loadAssetMs), maxMs, AssetColor, results.Average(r => r.loadAssetKB));
        DrawBar("LoadAsset 再次", results.Average(r => r.loadAssetAgainMs), maxMs, AgainColor, results.Average(r => r.loadAssetAgainKB));

        var assets = results[0].assetNames;
        if (assets != null)
        {
            EditorGUILayout.LabelField($"bundle 内资源 {assets.Length} 个：{string.Join(", ", assets)}", EditorStyles.wordWrappedMiniLabel);
        }
    }

    static void DrawBar(string label, double ms, double maxMs, Color color, float kb)
    {
        Rect row = EditorGUILayout.GetControlRect();
        const float labelWidth = 110f;
        const float textWidth = 170f;

        EditorGUI.LabelField(new Rect(row.x, row.y, labelWidth, row.height), label);

        float barMax = row.width - labelWidth - textWidth;
        float barWidth = maxMs > 0 ? Mathf.Max(1f, (float)(ms / maxMs) * barMax) : 1f;
        EditorGUI.DrawRect(new Rect(row.x + labelWidth, row.y + 2, barWidth, row.height - 4), color);

        EditorGUI.LabelField(new Rect(row.x + labelWidth + barMax + 4, row.y, textWidth, row.height),
            $"{ms:F2} ms  {kb:F1} KB");
    }

    void DrawTable()
    {
        EditorGUILayout.Space();
        EditorGUILayout.LabelField("明细", EditorStyles.boldLabel);

        using (new EditorGUILayout.HorizontalScope(EditorStyles.toolbar))
        {
            Cell("#", 30);
            Cell("LoadFromFile(ms)", 120);
            Cell("LoadAsset首次(ms)", 130);
            Cell("LoadAsset再次(ms)", 130);
            Cell("内存(KB)", 80);
        }

        scroll = EditorGUILayout.BeginScrollView(scroll);
        for (int i = 0; i < results.Count; i++)
        {
            var r = results[i];
            using (new EditorGUILayout.HorizontalScope())
            {
                Cell((i + 1).ToString(), 30);
                Cell(r.loadBundleMs.ToString("F2"), 120);
                Cell(r.loadAssetMs.ToString("F2"), 130);
                Cell(r.loadAssetAgainMs.ToString("F2"), 130);
                Cell((r.loadBundleKB + r.loadAssetKB + r.loadAssetAgainKB).ToString("F1"), 80);
            }
        }
        EditorGUILayout.EndScrollView();
    }

    static void Cell(string text, float width)
    {
        GUILayout.Label(text, GUILayout.Width(width));
    }
}

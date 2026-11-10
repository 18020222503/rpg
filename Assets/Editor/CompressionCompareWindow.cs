using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using UnityEditor;
using UnityEngine;
using Debug = UnityEngine.Debug;

// 压缩方式对比窗口：把当前打了标签的资源分别用 LZMA / LZ4 / 不压缩各打一份，
// 并排对比体积、加载耗时和内存，帮助直观理解三者的区别。
// 先执行 Tools/CreateABTag，再在非 Play 模式下使用。
public class CompressionCompareWindow : EditorWindow
{
    const string OutputRoot = "AssetBundleCompare";
    const int ChunkBlockCount = 32;

    [Serializable]
    class ModeResult
    {
        public string name;
        public Color color;
        public int bundleCount;
        public long sizeBytes;
        public double buildMs;
        public double loadBundleMs;   // 所有 bundle 的 LoadFromFile 耗时之和（取多轮平均）
        public double loadAssetMs;    // 每个 bundle 取第一个资源的 LoadAsset 耗时之和
        public float memoryKB;        // LoadFromFile 之后增加的内存之和
    }

    struct Mode
    {
        public string name;
        public BuildAssetBundleOptions options;
        public Color color;
    }

    static readonly Mode[] Modes =
    {
        new Mode { name = "LZMA",   options = BuildAssetBundleOptions.None,                       color = new Color(0.90f, 0.35f, 0.35f) },
        new Mode { name = "LZ4",    options = BuildAssetBundleOptions.ChunkBasedCompression,      color = new Color(0.30f, 0.60f, 0.95f) },
        new Mode { name = "不压缩", options = BuildAssetBundleOptions.UncompressedAssetBundle,    color = new Color(0.45f, 0.80f, 0.45f) },
    };

    [SerializeField] List<ModeResult> results = new List<ModeResult>();
    [SerializeField] int repeat = 10;
    Vector2 scroll;

    [MenuItem("Tools/CompressionCompare", priority = 5)]
    public static void Open()
    {
        GetWindow<CompressionCompareWindow>("压缩方式对比");
    }

    void OnGUI()
    {
        repeat = Mathf.Clamp(EditorGUILayout.IntField("测量轮数", repeat), 1, 100);

        using (new EditorGUI.DisabledScope(Application.isPlaying))
        {
            if (GUILayout.Button("打包并测试（LZMA / LZ4 / 不压缩）", GUILayout.Height(28))) Run();
        }
        if (Application.isPlaying)
        {
            EditorGUILayout.HelpBox("请退出 Play 模式再测试，否则和 ResourceManager 已加载的同名 bundle 冲突。", MessageType.Info);
        }

        scroll = EditorGUILayout.BeginScrollView(scroll);
        DrawSchematic();
        if (results.Count > 0)
        {
            DrawCharts();
            DrawConclusion();
        }
        EditorGUILayout.EndScrollView();
    }

    #region 打包与测量

    void Run()
    {
        results.Clear();
        string projectRoot = Path.GetDirectoryName(Application.dataPath);
        var target = EditorUserBuildSettings.activeBuildTarget;

        try
        {
            for (int i = 0; i < Modes.Length; i++)
            {
                var mode = Modes[i];
                EditorUtility.DisplayProgressBar("压缩方式对比", $"打包 {mode.name}", (float)i / Modes.Length);

                string dir = Path.Combine(projectRoot, OutputRoot, mode.name);
                if (Directory.Exists(dir)) Directory.Delete(dir, true);
                Directory.CreateDirectory(dir);

                var sw = Stopwatch.StartNew();
                var manifest = BuildPipeline.BuildAssetBundles(dir, mode.options | BuildAssetBundleOptions.ForceRebuildAssetBundle, target);
                sw.Stop();
                if (manifest == null)
                {
                    Debug.LogError($"[Compare] {mode.name} 打包失败，请先执行 Tools/CreateABTag");
                    return;
                }

                string[] names = manifest.GetAllAssetBundles();
                var result = new ModeResult
                {
                    name = mode.name,
                    color = mode.color,
                    bundleCount = names.Length,
                    buildMs = sw.Elapsed.TotalMilliseconds,
                };
                foreach (var n in names) result.sizeBytes += new FileInfo(Path.Combine(dir, n)).Length;

                EditorUtility.DisplayProgressBar("压缩方式对比", $"测量 {mode.name}", (i + 0.5f) / Modes.Length);
                Measure(dir, names, result);
                results.Add(result);
            }
        }
        finally
        {
            EditorUtility.ClearProgressBar();
        }
        Repaint();
    }

    void Measure(string dir, string[] names, ModeResult result)
    {
        // 先空跑一轮预热系统文件缓存，保证三种方式的比较条件一致
        MeasureOnce(dir, names, out _, out _, out _);

        double bundleMs = 0, assetMs = 0;
        float memKB = 0;
        for (int i = 0; i < repeat; i++)
        {
            MeasureOnce(dir, names, out var b, out var a, out var m);
            bundleMs += b;
            assetMs += a;
            memKB += m;
        }
        result.loadBundleMs = bundleMs / repeat;
        result.loadAssetMs = assetMs / repeat;
        result.memoryKB = memKB / repeat;
    }

    static void MeasureOnce(string dir, string[] names, out double bundleMs, out double assetMs, out float memKB)
    {
        bundleMs = 0;
        assetMs = 0;
        memKB = 0;
        var sw = new Stopwatch();
        foreach (var name in names)
        {
            long mem0 = UnityEngine.Profiling.Profiler.GetTotalAllocatedMemoryLong();
            sw.Restart();
            var bundle = AssetBundle.LoadFromFile(Path.Combine(dir, name));
            sw.Stop();
            if (bundle == null) continue;
            bundleMs += sw.Elapsed.TotalMilliseconds;
            memKB += (UnityEngine.Profiling.Profiler.GetTotalAllocatedMemoryLong() - mem0) / 1024f;

            var assets = bundle.GetAllAssetNames();
            if (assets.Length > 0)
            {
                sw.Restart();
                bundle.LoadAsset(assets[0]);
                sw.Stop();
                assetMs += sw.Elapsed.TotalMilliseconds;
            }
            bundle.Unload(true);
        }
    }

    #endregion

    #region 绘制

    // 示意图：加载其中一个资源时，各方式需要解压多少数据
    void DrawSchematic()
    {
        EditorGUILayout.Space();
        EditorGUILayout.LabelField("原理示意：只想取 1 个资源时，需要解压多少数据", EditorStyles.boldLabel);

        DrawBlocks("LZMA", Modes[0].color, ChunkBlockCount, "整个包是一条压缩流，必须从头到尾全部解压，才能取出任何资源");
        DrawBlocks("LZ4", Modes[1].color, 2, "文件切成小块分别压缩，只解压资源所在的块");
        DrawBlocks("不压缩", Modes[2].color, 0, "文件原样存放，直接从磁盘读取资源所在位置");
        EditorGUILayout.LabelField("方块 = 文件数据；有颜色 = 需要解压；灰色 = 不需要。块数仅为示意。", EditorStyles.miniLabel);
    }

    static void DrawBlocks(string label, Color color, int needDecompress, string desc)
    {
        Rect row = EditorGUILayout.GetControlRect(false, 18);
        const float labelWidth = 60f;
        EditorGUI.LabelField(new Rect(row.x, row.y, labelWidth, row.height), label);

        float areaWidth = Mathf.Min(row.width - labelWidth, 400f);
        float blockWidth = areaWidth / ChunkBlockCount;
        for (int i = 0; i < ChunkBlockCount; i++)
        {
            // LZ4 只高亮中间两块，模拟“资源在文件中间”
            bool need = needDecompress >= ChunkBlockCount ||
                        (needDecompress > 0 && i >= ChunkBlockCount / 2 && i < ChunkBlockCount / 2 + needDecompress);
            var rect = new Rect(row.x + labelWidth + i * blockWidth, row.y + 1, blockWidth - 1, row.height - 2);
            EditorGUI.DrawRect(rect, need ? color : new Color(0.3f, 0.3f, 0.3f));
        }
        EditorGUILayout.LabelField(desc, EditorStyles.miniLabel);
    }

    void DrawCharts()
    {
        EditorGUILayout.Space();
        EditorGUILayout.LabelField($"实测结果（{results[0].bundleCount} 个 bundle，{repeat} 轮平均）", EditorStyles.boldLabel);

        DrawChart("文件总大小", r => r.sizeBytes / 1024.0, "{0:F1} KB");
        DrawChart("LoadFromFile 耗时（打开全部 bundle）", r => r.loadBundleMs, "{0:F2} ms");
        DrawChart("LoadAsset 耗时（每包取 1 个资源）", r => r.loadAssetMs, "{0:F2} ms");
        DrawChart("LoadFromFile 后增加的内存", r => r.memoryKB, "{0:F1} KB");
        DrawChart("打包耗时", r => r.buildMs, "{0:F0} ms");
    }

    void DrawChart(string title, Func<ModeResult, double> getter, string format)
    {
        EditorGUILayout.Space(4);
        EditorGUILayout.LabelField(title, EditorStyles.miniBoldLabel);

        double max = 0;
        foreach (var r in results) max = Math.Max(max, getter(r));

        foreach (var r in results)
        {
            Rect row = EditorGUILayout.GetControlRect(false, 18);
            const float labelWidth = 60f;
            const float textWidth = 100f;
            EditorGUI.LabelField(new Rect(row.x, row.y, labelWidth, row.height), r.name);

            double v = getter(r);
            float barMax = Mathf.Max(10f, row.width - labelWidth - textWidth);
            float w = max > 0 ? Mathf.Max(1f, (float)(v / max) * barMax) : 1f;
            EditorGUI.DrawRect(new Rect(row.x + labelWidth, row.y + 2, w, row.height - 4), r.color);
            EditorGUI.LabelField(new Rect(row.x + labelWidth + w + 4, row.y, textWidth, row.height), string.Format(format, v));
        }
    }

    void DrawConclusion()
    {
        var lzma = results.Find(r => r.name == "LZMA");
        var lz4 = results.Find(r => r.name == "LZ4");
        var raw = results.Find(r => r.name == "不压缩");
        if (lzma == null || lz4 == null || raw == null) return;

        EditorGUILayout.Space();
        string text =
            $"体积：LZMA 是不压缩的 {Percent(lzma.sizeBytes, raw.sizeBytes)}，LZ4 是 {Percent(lz4.sizeBytes, raw.sizeBytes)}。\n" +
            $"LoadFromFile：LZMA 耗时是 LZ4 的 {Ratio(lzma.loadBundleMs, lz4.loadBundleMs)}。\n" +
            $"内存：LZMA 比 LZ4 多占 {(lzma.memoryKB - lz4.memoryKB):F1} KB。\n" +
            "资源很小时，差距可能被计时误差淹没。体积差异大的资源（贴图、场景）更明显。";
        EditorGUILayout.HelpBox(text, MessageType.None);
    }

    static string Percent(double a, double b) => b > 0 ? $"{a / b * 100:F0}%" : "-";
    static string Ratio(double a, double b) => b > 0 ? $"{a / b:F1} 倍" : "-";

    #endregion
}

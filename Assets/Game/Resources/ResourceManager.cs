using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif

// 资源加载入口。编辑器下由 UseBundle 决定直读工程资源还是走 bundle，真机固定走 bundle。
// assetName 相对 Assets/GameResource 并带后缀，如 "Prefab/test/test1.prefab"
public class ResourceManager
{
    // 编辑器下设为 false 时直接读工程里的资源，不用先打 bundle；真机上不起作用
    public bool UseBundle { get; set; } = true;

    const string AssetRoot = "Assets/GameResource/";

    const string ManifestBundleName = "AssetBundles";
    private static ResourceManager instance;
    public static ResourceManager Instance => instance ??= new ResourceManager();
    
    
    AssetBundleManifest manifest;
    readonly Dictionary<string, AssetBundle> bundles = new Dictionary<string, AssetBundle>();


    // bundle 所在目录，就是 Boot 下载 bundle 的缓存目录（BootConfig.CacheDir），由 GameEntry 传进来。
    // 热更程序集引用不到 Boot 的代码，所以这里的默认值单独写一份，只给 LoadProfiler 这类直接调用的工具用
    public string BundleRoot { get; set; } = DefaultBundleRoot;

    static string DefaultBundleRoot
    {
        get
        {
#if UNITY_EDITOR
            return Path.Combine(Path.GetDirectoryName(Application.dataPath), "Library", "HotUpdateCache");
#else
            return Application.persistentDataPath;
#endif
        }
    }

    public void Init()
    {
#if UNITY_EDITOR
      if (!UseBundle) return;
#endif
      var manifestPath = Path.Combine(BundleRoot, ManifestBundleName);
      var mainfestAb =  AssetBundle.LoadFromFile(manifestPath);
      if (mainfestAb== null)
      {
          Debug.LogError($"[Resource] 加载总清单失败：{manifestPath}");
          return;
      }
      manifest = mainfestAb.LoadAsset<AssetBundleManifest>("AssetBundleManifest");

      var bundlesName = manifest.GetAllAssetBundles();
      foreach (var item in bundlesName)
      {    
          Debug.Log(item);
      }
      mainfestAb.Unload(false);
    }

    public T LoadAsset<T>(string assetName) where T : UnityEngine.Object
    {
        // string assetPath = AssetRoot + assetName;
        Debug.unityLogger.Log(assetName);
#if UNITY_EDITOR
        if (!UseBundle) return AssetDatabase.LoadAssetAtPath<T>(AssetRoot + assetName);
#endif
        if (manifest == null)
        {
            return null;
        }
    
        var bundleName = GetBundleName(assetName);
        foreach (var item in manifest.GetAllDependencies(bundleName))
        {
            LoadBundle(item);
            Debug.Log("depence:"+item);
        }

        var bundle = LoadBundle(bundleName);
        if (bundle == null) return null;
        // bundle 内的资源名是完整工程路径
        return bundle.LoadAsset<T>(AssetRoot + assetName);
    }
    
    AssetBundle LoadBundle(string bundleName)
    {
        if (bundles.TryGetValue(bundleName, out var bundle)) return bundle;

        bundle = AssetBundle.LoadFromFile(Path.Combine(BundleRoot, bundleName));
        if (bundle == null)
        {
            Debug.LogError($"[Resource] 加载 bundle 失败：{bundleName}");
            return null;
        }
        bundles[bundleName] = bundle;
        return bundle;
    }
    
    // 与 CreateABTag 保持一致：bundle 名 = 资源所在文件夹，如 "Prefab/map/Dungeon.prefab" -> "gameresource/prefab/map.ab"
    static string GetBundleName(string assetName)
    {
        string dir = Path.GetDirectoryName(assetName).Replace("\\", "/");
        return ("gameresource/" + dir).ToLower() + ".ab";
    }
    
    IEnumerator LoadBundleFileAsync(string bundleName)
    {  
        var request = AssetBundle.LoadFromFileAsync(Path.Combine(BundleRoot, bundleName));
        yield return request;
        if (request.assetBundle == null)
        {
            Debug.LogError($"[Resource] 加载 bundle 失败：{bundleName}");
            yield break;
        } 
    }


    #region 测试代码

    // 对比 LoadFromFile（只打开 bundle）和 LoadAsset（从 bundle 里取出具体资源）的耗时与内存。
    // 调用前先执行 Init()，例如在 EntryFlow.LoadScene 里：
    //   ResourceManager.Instance.Init();
    //   ResourceManager.Instance.TestLoadFromFileVsLoadAsset("Prefab/map/Dungeon.prefab");
    public void TestLoadFromFileVsLoadAsset(string assetName)
    {
        if (!RunLoadTest(assetName, out var r)) return;
        Debug.Log($"[Test] 1.LoadFromFile  耗时 {r.loadBundleMs:F2} ms，内存 +{r.loadBundleKB:F1} KB");
        Debug.Log($"[Test]    bundle 内资源：{string.Join(", ", r.assetNames)}");
        Debug.Log($"[Test] 2.LoadAsset(首次) 耗时 {r.loadAssetMs:F2} ms，内存 +{r.loadAssetKB:F1} KB");
        Debug.Log($"[Test] 3.LoadAsset(再次) 耗时 {r.loadAssetAgainMs:F2} ms，内存 +{r.loadAssetAgainKB:F1} KB，是同一对象：{r.sameInstance}");
    }

    public bool IsInitialized => manifest != null;

    public struct LoadTestResult
    {
        public double loadBundleMs, loadAssetMs, loadAssetAgainMs;
        public float loadBundleKB, loadAssetKB, loadAssetAgainKB;
        public bool sameInstance;
        public string[] assetNames;
    }

    // 测一次完整流程：LoadFromFile -> LoadAsset -> 再次 LoadAsset，最后 Unload(true) 还原现场，可重复调用
    public bool RunLoadTest(string assetName, out LoadTestResult result)
    {
        result = default;
        if (manifest == null)
        {
            Debug.LogError("[Test] 请先调用 Init()");
            return false;
        }

        string bundleName = GetBundleName(assetName);

        // 依赖包走缓存加载，不计入测试
        foreach (var dep in manifest.GetAllDependencies(bundleName))
        {
            LoadBundle(dep);
        }

        // 同一个 bundle 不能加载两次，缓存里已有就先卸掉，保证从零开始测
        if (bundles.TryGetValue(bundleName, out var cached))
        {
            cached.Unload(true);
            bundles.Remove(bundleName);
        }

        var sw = new System.Diagnostics.Stopwatch();   //创建计时器
        long mem0 = UnityEngine.Profiling.Profiler.GetTotalAllocatedMemoryLong();

        // 1. LoadFromFile：只打开 bundle，读文件头和资源目录，不创建任何资源对象
        sw.Restart();
        var bundle = AssetBundle.LoadFromFile(Path.Combine(BundleRoot, bundleName));
        sw.Stop();
        if (bundle == null)
        {
            Debug.LogError($"[Test] LoadFromFile 失败：{bundleName}");
            return false;
        }
        long mem1 = UnityEngine.Profiling.Profiler.GetTotalAllocatedMemoryLong();
        result.loadBundleMs = sw.Elapsed.TotalMilliseconds;
        result.loadBundleKB = (mem1 - mem0) / 1024f;
        result.assetNames = bundle.GetAllAssetNames();

        // 2. 第一次 LoadAsset：从 bundle 读出数据并反序列化成 Object
        string fullPath = AssetRoot + assetName;
        sw.Restart();
        var asset = bundle.LoadAsset<UnityEngine.Object>(fullPath);
        sw.Stop();
        long mem2 = UnityEngine.Profiling.Profiler.GetTotalAllocatedMemoryLong();
        result.loadAssetMs = sw.Elapsed.TotalMilliseconds;
        result.loadAssetKB = (mem2 - mem1) / 1024f;
        if (asset == null) Debug.LogError($"[Test] LoadAsset 返回 null：{fullPath}");

        // 3. 第二次 LoadAsset：资源已在内存，直接返回同一个对象
        sw.Restart();
        var asset2 = bundle.LoadAsset<UnityEngine.Object>(fullPath);
        sw.Stop();
        long mem3 = UnityEngine.Profiling.Profiler.GetTotalAllocatedMemoryLong();
        result.loadAssetAgainMs = sw.Elapsed.TotalMilliseconds;
        result.loadAssetAgainKB = (mem3 - mem2) / 1024f;
        result.sameInstance = ReferenceEquals(asset, asset2);

        // 4. Unload(true) 连已加载的资源一起销毁，下一轮才是从零开始
        bundle.Unload(true);
        return true;
    }

    #endregion

}

using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif

// 资源加载入口。编辑器下由 isAB 决定直读工程资源还是走 bundle，真机固定走 bundle。
// assetName 相对 Assets/GameResource 并带后缀，如 "Prefab/test/test1.prefab"
public class ResourceManager
{
    const string AssetRoot = "Assets/GameResource/";
    // BuildAB 的输出目录名，Unity 会生成同名的主 bundle，里面是 AssetBundleManifest
    const string ManifestBundleName = "AssetBundles";

    private static ResourceManager instance;
    public static ResourceManager Instance => instance ??= new ResourceManager();

    // 编辑器下是否走 bundle，真机忽略这个开关
    public bool isAB;

    AssetBundleManifest manifest;
    readonly Dictionary<string, AssetBundle> bundles = new Dictionary<string, AssetBundle>();
    readonly Dictionary<string, AssetBundleCreateRequest> loading = new Dictionary<string, AssetBundleCreateRequest>();

    public bool UseBundle
    {
        get
        {
#if UNITY_EDITOR
            return isAB;
#else
            return true;
#endif
        }
    }

    // 编辑器直接读 BuildAB 的输出，真机读热更下载目录
    static string BundleRoot
    {
        get
        {
#if UNITY_EDITOR
            return Path.Combine(Application.dataPath, "AssetBundles");
#else
            return Application.persistentDataPath;
#endif
        }
    }

    // 走 bundle 时加载主 manifest，后面靠它查依赖。Load 时也会自动调用
    public void Init()
    {
        if (!UseBundle || manifest != null) return;

        var path = Path.Combine(BundleRoot, ManifestBundleName);
        var bundle = AssetBundle.LoadFromFile(path);
        if (bundle == null)
        {
            Debug.LogError($"[Resource] 加载主 manifest 失败：{path}");
            return;
        }
        manifest = bundle.LoadAsset<AssetBundleManifest>("AssetBundleManifest");
        bundle.Unload(false);
    }

    public T Load<T>(string assetName) where T : UnityEngine.Object
    {
        string assetPath = AssetRoot + assetName;
#if UNITY_EDITOR
        if (!UseBundle)
        {
            var editorAsset = AssetDatabase.LoadAssetAtPath<T>(assetPath);
            if (editorAsset == null) Debug.LogError($"[Resource] 找不到 {assetPath}");
            return editorAsset;
        }
#endif
        Init();
        if (manifest == null) return null;

        string bundleName = GetBundleName(assetName);
        foreach (var dep in manifest.GetAllDependencies(bundleName))
        {
            LoadBundleFile(dep);
        }
        var bundle = LoadBundleFile(bundleName);
        if (bundle == null) return null;

        var asset = bundle.LoadAsset<T>(assetPath);
        if (asset == null) Debug.LogError($"[Resource] {bundleName} 里找不到 {assetPath}");
        return asset;
    }

    // 由调用方用 StartCoroutine 驱动，加载完成后回调，失败时回调 null
    public IEnumerator LoadAsync<T>(string assetName, Action<T> onLoaded) where T : UnityEngine.Object
    {
        string assetPath = AssetRoot + assetName;
#if UNITY_EDITOR
        if (!UseBundle)
        {
            onLoaded?.Invoke(Load<T>(assetName));
            yield break;
        }
#endif
        Init();
        if (manifest == null)
        {
            onLoaded?.Invoke(null);
            yield break;
        }

        string bundleName = GetBundleName(assetName);
        foreach (var dep in manifest.GetAllDependencies(bundleName))
        {
            yield return LoadBundleFileAsync(dep);
        }
        yield return LoadBundleFileAsync(bundleName);

        if (!bundles.TryGetValue(bundleName, out var bundle))
        {
            onLoaded?.Invoke(null);
            yield break;
        }

        var request = bundle.LoadAssetAsync<T>(assetPath);
        yield return request;
        var asset = request.asset as T;
        if (asset == null) Debug.LogError($"[Resource] {bundleName} 里找不到 {assetPath}");
        onLoaded?.Invoke(asset);
    }

    // 和 BuildAssetBundleTool.GenerateBundleNameFromPath 的规则一致：去 Assets/、去后缀、转小写
    static string GetBundleName(string assetName)
    {
        return ("gameresource/" + Path.ChangeExtension(assetName, null)).ToLower();
    }

    AssetBundle LoadBundleFile(string bundleName)
    {
        if (bundles.TryGetValue(bundleName, out var bundle)) return bundle;

        // 异步加载还没完成时，访问 assetBundle 会让它立刻同步完成
        if (loading.TryGetValue(bundleName, out var request))
        {
            loading.Remove(bundleName);
            bundle = request.assetBundle;
        }
        else
        {
            bundle = AssetBundle.LoadFromFile(Path.Combine(BundleRoot, bundleName));
        }

        if (bundle == null)
        {
            Debug.LogError($"[Resource] 加载 bundle 失败：{bundleName}");
            return null;
        }
        bundles[bundleName] = bundle;
        return bundle;
    }

    IEnumerator LoadBundleFileAsync(string bundleName)
    {
        if (bundles.ContainsKey(bundleName)) yield break;

        // 同一个 bundle 正在加载时等同一个请求，避免重复加载报错
        if (!loading.TryGetValue(bundleName, out var request))
        {
            request = AssetBundle.LoadFromFileAsync(Path.Combine(BundleRoot, bundleName));
            loading[bundleName] = request;
        }
        yield return request;
        loading.Remove(bundleName);

        if (request.assetBundle == null)
        {
            Debug.LogError($"[Resource] 加载 bundle 失败：{bundleName}");
            yield break;
        }
        bundles[bundleName] = request.assetBundle;
    }
}

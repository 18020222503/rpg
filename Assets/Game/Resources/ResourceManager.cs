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
    // const string AssetRoot = "Assets/GameResource/";
    
    const string ManifestBundleName = "AssetBundles";
    private static ResourceManager instance;
    public static ResourceManager Instance => instance ??= new ResourceManager();
    
    
    AssetBundleManifest manifest;
    readonly Dictionary<string, AssetBundle> bundles = new Dictionary<string, AssetBundle>();


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

    public void Init()
    {
      var mainfestAb =  AssetBundle.LoadFromFile(Path.Combine(BundleRoot, ManifestBundleName));
      if (mainfestAb== null)
      { 
          Debug.LogError("loadmainfestAB fail");
          return;
      }
      manifest = mainfestAb.LoadAsset<AssetBundleManifest>("AssetBundleManifest");

      var bundlesName = manifest.GetAllAssetBundles();
      foreach (var item in bundlesName)
      {    
          Debug.Log(item);
      }
    }

    public T LoadAsset<T>(string assetName) where T : UnityEngine.Object
    {
        // string assetPath = AssetRoot + assetName;
        Debug.logger.Log(assetName);
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
        return bundle.LoadAsset<T>(assetName);
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
    
    static string GetBundleName(string assetName)
    {
        return ("gameresource/prefab/map/" + Path.ChangeExtension(assetName, null)).ToLower();
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

}

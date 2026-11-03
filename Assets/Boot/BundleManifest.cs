using System;
using System.Collections.Generic;
using UnityEngine;

// 热更 bundle 清单：打包工具生成，随 bundle 一起发布到 CDN，客户端按 hash 判断哪些 bundle 需要重新下载
[Serializable]
public class BundleManifest
{
    public const string FileName = "bundles.json";

    public List<BundleInfo> bundles = new List<BundleInfo>();

    public BundleInfo Find(string name)
    {
        return bundles.Find(b => b.name == name);
    }

    public static BundleManifest FromJson(string json)
    {
        return JsonUtility.FromJson<BundleManifest>(json);
    }
}

[Serializable]
public class BundleInfo
{
    public string name;
    public string hash;
    public long size;
}

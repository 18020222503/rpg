using HybridCLR;
using System;
using System.IO;
using System.Linq;
using System.Net;
using UnityEditor;
using UnityEditor.Timeline.Actions;
using UnityEngine;

public static class BuildAssetBundleTool
{
    const string OutputDirName = "AssetBundle";

    const string DllAssetDir = "Assets/HotUpdateDlls";
    const string DllAssetPath = DllAssetDir + "/Game.dll.bytes";
    const string EntryScenePath = "Assets/Scenes/Entry.unity";

    static string GetOutputDir(BuildTarget target)
    {
        string projectRoot = Path.GetDirectoryName(Application.dataPath);
        return Path.Combine(projectRoot, OutputDirName, target.ToString());
    }

    #region 打AB
    [MenuItem("Tools/CreateABTag", priority = 3)]
    public static void CreateABTag()
    {
        //清除所有旧标签，forceRemove=true 会把仍在使用的名字也从资源上摘掉
        foreach (var name in AssetDatabase.GetAllAssetBundleNames())
        {
            AssetDatabase.RemoveAssetBundleName(name, true);
        }
        //创建AB标签
        string assetPath = "Assets/GameResource";
        if (Directory.Exists(assetPath))
        {       
            string[] files = Directory.GetFiles(assetPath,"*", SearchOption.AllDirectories);
            foreach (var file in files)
            {
                if (file.EndsWith(".meta")||file.EndsWith(".cs"))
                {
                    continue;
                }
                string path = file.Replace("\\", "/");
                AssetImporter importer = AssetImporter.GetAtPath(path);
                if (importer != null)
                {
                    string bundleName = GenerateBundleNameFromPath(path);
                    Debug.Log($"file:{path} -> bundle:{bundleName}");
                    importer.assetBundleName = bundleName;
                }
            }
        }
        AssetDatabase.RemoveUnusedAssetBundleNames();
        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
    }

    // 按所在文件夹命名：Assets/GameResource/prefab/map/a.prefab -> gameresource/prefab/map.ab
    // 同一文件夹下的文件共用一个标签（Unity 会把 AB 名统一转成小写）。
    // 带后缀是因为一个文件夹本身有资源、子文件夹也有资源时，不带后缀的 bundle 文件和子文件夹同名，打包会失败
    private static string GenerateBundleNameFromPath(string path)
    {
        string dir = Path.GetDirectoryName(path).Replace("\\", "/");
        if (dir.StartsWith("Assets/"))
            dir = dir.Substring("Assets/".Length);
        return dir.ToLower() + ".ab";
    }

    [MenuItem("Tools/BuildAB", priority = 2)]
    public static void BuildBundles()
    {
        // 标签不带 .ab 说明还是改名前打的，文件夹和 bundle 会重名，先重新打标签
        var oldNames = AssetDatabase.GetAllAssetBundleNames().Where(n => !n.EndsWith(".ab")).ToArray();
        if (oldNames.Length > 0)
        {
            Debug.LogError($"[AssetBundle] 有 {oldNames.Length} 个旧标签（如 {oldNames[0]}），请先执行 Tools/CreateABTag");
            return;
        }

        string assetBundleDirectory = "Assets/AssetBundles";
        if(!Directory.Exists(assetBundleDirectory))
        {
            Directory.CreateDirectory(assetBundleDirectory);
        }
        DeleteStaleBundles(assetBundleDirectory);
        BuildPipeline.BuildAssetBundles(assetBundleDirectory, 
            BuildAssetBundleOptions.None, 
            BuildTarget.StandaloneWindows);
    }

    // 删掉输出目录里已经没有对应标签的旧 bundle。BuildAssetBundles 不会自己清，
    // 旧文件留着会占住新 bundle 要用的文件夹名（比如改名前的 gameresource/fx/fx_hero）
    static void DeleteStaleBundles(string outDir)
    {
        var current = new System.Collections.Generic.HashSet<string>(AssetDatabase.GetAllAssetBundleNames());
        // 总清单 bundle 的名字和输出目录同名
        current.Add(Path.GetFileName(outDir));

        foreach (var file in Directory.GetFiles(outDir, "*", SearchOption.AllDirectories))
        {
            if (file.EndsWith(".meta") || file.EndsWith(".manifest")) continue;
            string name = file.Substring(outDir.Length + 1).Replace("\\", "/");
            if (current.Contains(name)) continue;

            Debug.Log($"[AssetBundle] 删除旧 bundle：{name}");
            foreach (var path in new[] { file, file + ".meta", file + ".manifest", file + ".manifest.meta" })
            {
                if (File.Exists(path)) File.Delete(path);
            }
        }
        AssetDatabase.Refresh();
    }

    #endregion


    #region 上传资源至CDN

    [MenuItem("Tools/Hotdate/PublishToCDN", priority = 3)]
    public static void PublishToCdn()
    {
        BuildTarget target = EditorUserBuildSettings.activeBuildTarget;
        string outDir = GetOutputDir(target);
        string manifestPath = Path.Combine(outDir, BundleManifest.FileName);
        if (!File.Exists(manifestPath))
        {
            Debug.LogError($"[AssetBundle] 找不到 {manifestPath}，请先执行 Tools/Hotdate/BuildHotUpdateBundle");
            return;
        }

        string host = EditorPrefs.GetString(FtpSettingsWindow.HostKey);
        string user = EditorPrefs.GetString(FtpSettingsWindow.UserKey);
        string password = EditorPrefs.GetString(FtpSettingsWindow.PasswordKey);
        string remoteDir = EditorPrefs.GetString(FtpSettingsWindow.RemoteDirKey, FtpSettingsWindow.DefaultRemoteDir);
        if (string.IsNullOrEmpty(host) || string.IsNullOrEmpty(user))
        {
            Debug.LogError("[AssetBundle] 还没配置FTP，请在 Tools/Hotdate/FtpSettings 里填写并保存");
            FtpSettingsWindow.Open();
            return;
        }

        var manifest = BundleManifest.FromJson(File.ReadAllText(manifestPath));
        try
        {
            // 清单最后传：客户端读到新清单时，它指向的 bundle 一定已经在 CDN 上
            foreach (var info in manifest.bundles)
            {
                string path = Path.Combine(outDir, info.name);
                if (!File.Exists(path))
                {
                    Debug.LogError($"[AssetBundle] 清单里的 {info.name} 不存在，请重新打包");
                    return;
                }
                Upload(path, host, remoteDir, user, password);
            }
            Upload(manifestPath, host, remoteDir, user, password);
        }
        catch (WebException e)
        {
            Debug.LogError($"[AssetBundle] 上传失败：{e.Message}");
        }
    }

    static void Upload(string srcPath, string host, string remoteDir, string user, string password)
    {
        var uri = new Uri($"ftp://{host}/{remoteDir}/{Path.GetFileName(srcPath)}");
        var req = (FtpWebRequest)WebRequest.Create(uri);
        req.Method = WebRequestMethods.Ftp.UploadFile;
        req.Credentials = new NetworkCredential(user, password);
        req.UseBinary = true;
        req.UsePassive = true;

        byte[] data = File.ReadAllBytes(srcPath);
        req.ContentLength = data.Length;
        using (Stream stream = req.GetRequestStream())
        {
            stream.Write(data, 0, data.Length);
        }

        using (var resp = (FtpWebResponse)req.GetResponse())
        {
            Debug.Log($"[AssetBundle] 已上传到 {uri}，{resp.StatusDescription}");
        }
    }

    #endregion

}

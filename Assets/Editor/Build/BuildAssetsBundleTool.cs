using HybridCLR;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Security.Cryptography;
using UnityEditor;
using UnityEditor.Timeline.Actions;
using UnityEngine;

public static class BuildAssetBundleTool
{
    // 输出到 {项目根目录}/AssetBundle/{当前平台}，放在 Assets 外面，Unity 不会去导入。
    // 编辑器下载流程（BootConfig.BaseUrl）和上传 CDN 都读这个目录
    const string OutputDirName = "AssetBundle";
    // 运行时加载的总清单 bundle 名，和 ResourceManager.ManifestBundleName 一致
    const string ManifestBundleName = "AssetBundles";

    // Tools/Hotdate/GenerateHotUpdateDll 把 Game.dll 拷到这里
    const string DllAssetDir = "Assets/GameResource/Dll";
    const string DllAssetPath = DllAssetDir + "/Game.dll.bytes";
    const string EntryScenePath = "Assets/Scenes/Entry.unity";

    public static string GetOutputDir(BuildTarget target)
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

        BuildTarget target = EditorUserBuildSettings.activeBuildTarget;
        string outDir = GetOutputDir(target);
        Directory.CreateDirectory(outDir);
        DeleteStaleBundles(outDir, target);

        // 默认是增量打包：内容没变的 bundle 直接跳过，Console 里只打印这次重新打的那几个
        var startTime = DateTime.Now;
        var manifest = BuildPipeline.BuildAssetBundles(outDir, BuildAssetBundleOptions.None, target);
        // 打包失败时不抛异常，只返回 null
        if (manifest == null)
        {
            Debug.LogError("[AssetBundle] 打包失败，详见上面的 Console 日志");
            return;
        }

        // 总清单 bundle 的文件名跟着输出目录叫平台名，运行时 ResourceManager 不知道平台，按固定名字复制一份
        File.Copy(Path.Combine(outDir, target.ToString()), Path.Combine(outDir, ManifestBundleName), true);
        WriteBundleList(outDir, manifest);

        var names = manifest.GetAllAssetBundles();
        var rebuilt = names.Where(n => File.GetLastWriteTime(Path.Combine(outDir, n)) >= startTime).ToArray();
        Debug.Log($"[AssetBundle] 打包完成，输出到 {outDir}，共 {names.Length} 个 bundle，本次重新打 {rebuilt.Length} 个，其余内容没变已跳过：" +
                  (rebuilt.Length > 0 ? string.Join(", ", rebuilt) : "无"));
    }

    // 生成 bundles.json：客户端拿它和本地那份对比 hash，不一样的才下载。
    // hash 用文件 MD5，文件内容变了一定会变，以后也能拿它校验下载是否完整
    static void WriteBundleList(string outDir, AssetBundleManifest manifest)
    {
        var list = new BundleManifest();
        foreach (var name in manifest.GetAllAssetBundles().Append(ManifestBundleName))
        {
            string path = Path.Combine(outDir, name);
            list.bundles.Add(new BundleInfo
            {
                name = name,
                hash = ComputeMd5(path),
                size = new FileInfo(path).Length,
            });
        }
        File.WriteAllText(Path.Combine(outDir, BundleManifest.FileName), JsonUtility.ToJson(list, true));
    }

    static string ComputeMd5(string path)
    {
        using (var md5 = MD5.Create())
        using (var stream = File.OpenRead(path))
        {
            return BitConverter.ToString(md5.ComputeHash(stream)).Replace("-", "").ToLower();
        }
    }

    // 删掉输出目录里已经没有对应标签的旧 bundle。BuildAssetBundles 不会自己清，
    // 旧文件留着会占住新 bundle 要用的文件夹名（比如改名前的 gameresource/fx/fx_hero）
    static void DeleteStaleBundles(string outDir, BuildTarget target)
    {
        var current = new HashSet<string>(AssetDatabase.GetAllAssetBundleNames())
        {
            target.ToString(),          // Unity 生成的总清单 bundle，和输出目录同名
            ManifestBundleName,         // 上面复制出来的固定名字的总清单
            BundleManifest.FileName,
        };

        foreach (var file in Directory.GetFiles(outDir, "*", SearchOption.AllDirectories))
        {
            if (file.EndsWith(".manifest")) continue;
            string name = file.Substring(outDir.Length + 1).Replace("\\", "/");
            if (current.Contains(name)) continue;

            Debug.Log($"[AssetBundle] 删除旧 bundle：{name}");
            File.Delete(file);
            if (File.Exists(file + ".manifest")) File.Delete(file + ".manifest");
        }
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
            Debug.LogError($"[AssetBundle] 找不到 {manifestPath}，请先执行 Tools/BuildAB");
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
        var createdDirs = new HashSet<string>();
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
                Upload(path, info.name, createdDirs, host, remoteDir, user, password);
            }
            Upload(manifestPath, BundleManifest.FileName, createdDirs, host, remoteDir, user, password);
        }
        catch (WebException e)
        {
            Debug.LogError($"[AssetBundle] 上传失败：{e.Message}");
        }
    }

    // remoteName 是相对 remoteDir 的路径，bundle 名带子目录（如 gameresource/dll.ab），客户端按同样的路径下载
    static void Upload(string srcPath, string remoteName, HashSet<string> createdDirs, string host, string remoteDir, string user, string password)
    {
        EnsureRemoteDirs(remoteName, createdDirs, host, remoteDir, user, password);

        var uri = new Uri($"ftp://{host}/{remoteDir}/{remoteName}");
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

    // FTP 上传不会自动建目录，逐级创建 remoteName 所在的目录。目录已存在时服务器返回 550，忽略
    static void EnsureRemoteDirs(string remoteName, HashSet<string> createdDirs, string host, string remoteDir, string user, string password)
    {
        var parts = remoteName.Split('/');
        string dir = "";
        for (int i = 0; i < parts.Length - 1; i++)
        {
            dir = dir.Length == 0 ? parts[i] : $"{dir}/{parts[i]}";
            if (!createdDirs.Add(dir)) continue;

            var req = (FtpWebRequest)WebRequest.Create(new Uri($"ftp://{host}/{remoteDir}/{dir}"));
            req.Method = WebRequestMethods.Ftp.MakeDirectory;
            req.Credentials = new NetworkCredential(user, password);
            req.UsePassive = true;
            try
            {
                using (req.GetResponse()) { }
            }
            catch (WebException e) when (e.Response is FtpWebResponse r && r.StatusCode == FtpStatusCode.ActionNotTakenFileUnavailable)
            {
            }
        }
    }

    #endregion

}

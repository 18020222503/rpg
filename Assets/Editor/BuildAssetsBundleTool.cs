using HybridCLR;
using System;
using System.IO;
using System.Linq;
using System.Net;
using UnityEditor;
using UnityEngine;

public static class BuildAssetBundleTool
{
    //bundle输出目录名，位于项目根目录（Assets 的上一层）
    const string OutputDirName = "AssetBundle";

    //bundle 只能打包 Assets 内的资源，所以把 Game.dll 以 .bytes 形式暂存到这个目录
    const string DllAssetDir = "Assets/HotUpdateDlls";
    const string DllAssetPath = DllAssetDir + "/Game.dll.bytes";
    const string EntryScenePath = "Assets/Scenes/Entry.unity";

    static string GetOutputDir(BuildTarget target)
    {
        string projectRoot = Path.GetDirectoryName(Application.dataPath);
        return Path.Combine(projectRoot, OutputDirName, target.ToString());
    }

    //把 Game.dll 和 Entry 场景打成 bundle，输出到 AssetBundle/{平台}，并生成 bundles.json 清单
    [MenuItem("Tools/Hotdate/BuildHotUpdateBundle", priority = 2)]
    public static void BuildBundles()
    {
        BuildTarget target = EditorUserBuildSettings.activeBuildTarget;
        string projectRoot = Path.GetDirectoryName(Application.dataPath);
        string outDir = GetOutputDir(target);
        Directory.CreateDirectory(outDir);

        string srcPath = Path.Combine(SettingsUtil.GetHotUpdateDllsOutputDirByTarget(target), "Game.dll");
        if (!File.Exists(srcPath))
        {
            Debug.LogError($"[AssetBundle] 找不到 {srcPath}，请先执行 Tools/Hotdate/GenerateHotUpdateDll");
            return;
        }
 
        Directory.CreateDirectory(Path.Combine(projectRoot, DllAssetDir));
        File.Copy(srcPath, Path.Combine(projectRoot, DllAssetPath), true);
        AssetDatabase.ImportAsset(DllAssetPath);

        // 场景引用的材质、模型等没有单独列出的资源，会被隐式打进 entry.ab。
        // 目前只有一个场景 bundle，不会重复；以后再加 bundle 时需要把公共资源拆出来
        var builds = new[]
        {
            new AssetBundleBuild
            {
                assetBundleName = ProcedureLoadAssembly.DllBundleName,
                assetNames = new[] { DllAssetPath },
            },
            new AssetBundleBuild
            {
                assetBundleName = GameBoot.EntryBundleName,
                assetNames = new[] { EntryScenePath },
            },
        };

        var abManifest = BuildPipeline.BuildAssetBundles(outDir, builds,
            BuildAssetBundleOptions.ChunkBasedCompression, target);
        if (abManifest == null)
        {
            Debug.LogError("[AssetBundle] 打包失败，详见上面的 Console 日志");
            return;
        }

        var manifest = new BundleManifest();
        foreach (var build in builds)
        {
            var name = build.assetBundleName;
            manifest.bundles.Add(new BundleInfo
            {
                name = name,
                hash = abManifest.GetAssetBundleHash(name).ToString(),
                size = new FileInfo(Path.Combine(outDir, name)).Length,
            });
        }
        File.WriteAllText(Path.Combine(outDir, BundleManifest.FileName), JsonUtility.ToJson(manifest, true));

        Debug.Log($"[AssetBundle] 已输出到 {outDir}：{string.Join(", ", manifest.bundles.Select(b => b.name))}");
    }

    //通过 FTP 把 bundle 和清单上传到宝塔站点目录，之后可通过 http://{BootConfig.CDN}/{文件名} 下载
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
}

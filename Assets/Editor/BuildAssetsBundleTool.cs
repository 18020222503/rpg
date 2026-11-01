using HybridCLR;
using System;
using System.IO;
using System.Net;
using UnityEditor;
using UnityEngine;

public static class BuildAssetBundleTool
{
    //bundle输出目录名，位于项目根目录（Assets 的上一层）
    const string OutputDirName = "AssetBundle";
    [MenuItem("Tools/Build Entry Scene AB")]
    public static void BuildEntryScene()
    {

        
        string outDir = Application.streamingAssetsPath;
        Directory.CreateDirectory(outDir);

        var builds = new[]
        {
            new AssetBundleBuild
            {
                assetBundleName = "entry.ab",
                assetNames = new[] { "Assets/Scenes/Entry.unity" },
            }
        };

        BuildPipeline.BuildAssetBundles(outDir, builds,
            BuildAssetBundleOptions.ChunkBasedCompression,
            EditorUserBuildSettings.activeBuildTarget);

        Debug.Log($"[AssetBundle] 已输出到 {outDir}");
    }

    public static void BuildAssetBundles()
    {
        
    }

    //bundle 只能打包 Assets 内的资源，所以把 Game.dll 以 .bytes 形式暂存到这个目录
    const string DllAssetDir = "Assets/HotUpdateDlls";

    //把 HybridCLRData 里编译好的 Game.dll 打成 bundle，输出到 AssetBundle/{平台}/game.dll.ab
    [MenuItem("Tools/Hotdate/BuildHotUpdateBundle", priority = 2)]
    public static void BuildDllAssetBundles()
    {
        BuildTarget target = EditorUserBuildSettings.activeBuildTarget;
        string projectRoot = Path.GetDirectoryName(Application.dataPath);
        string outDir = Path.Combine(projectRoot, OutputDirName, target.ToString());
        Directory.CreateDirectory(outDir);

        string srcPath = Path.Combine(SettingsUtil.GetHotUpdateDllsOutputDirByTarget(target), "Game.dll");
        if (!File.Exists(srcPath))
        {
            Debug.LogError($"[AssetBundle] 找不到 {srcPath}，请先执行 Tools/Hotdate/GenerateHotUpdateDll");
            return; 
        }

        string assetPath = $"{DllAssetDir}/Game.dll.bytes";
        Directory.CreateDirectory(Path.Combine(projectRoot, DllAssetDir));
        File.Copy(srcPath, Path.Combine(projectRoot, assetPath), true);
        AssetDatabase.ImportAsset(assetPath);

        var builds = new[]
        {
            new AssetBundleBuild
            {
                assetBundleName = "game.dll.ab",
                assetNames = new[] { assetPath },
            }
        };

        BuildPipeline.BuildAssetBundles(outDir, builds,
            BuildAssetBundleOptions.ChunkBasedCompression,
            EditorUserBuildSettings.activeBuildTarget);

        Debug.Log($"[AssetBundle] 已输出到 {Path.Combine(outDir, "game.dll.ab")}");
    }

    //通过 FTP 把 game.dll.ab 上传到宝塔站点目录，之后可通过 http://{BootConfig.CDN}/game.dll.ab 下载
    [MenuItem("Tools/Hotdate/PublishToCDN", priority = 3)]
    public static void PublishToCdn()
    {
        BuildTarget target = EditorUserBuildSettings.activeBuildTarget;
        string projectRoot = Path.GetDirectoryName(Application.dataPath);
        string srcPath = Path.Combine(projectRoot, OutputDirName, target.ToString(), "game.dll.ab");
        if (!File.Exists(srcPath))
        {
            Debug.LogError($"[AssetBundle] 找不到 {srcPath}，请先执行 Tools/Hotdate/BuildHotUpdateBundle");
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

        var uri = new Uri($"ftp://{host}/{remoteDir}/game.dll.ab");
        try
        {
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
        catch (WebException e)
        {
            Debug.LogError($"[AssetBundle] 上传失败：{uri}，{e.Message}");
        }
    }
}
using System.IO;
using System.Linq;
using UnityEngine;
using UnityEditor;
using UnityEditor.Build.Reporting;


public  static class Build
{
    const string PCOutputDirName = "Build/PC";

    //打 Windows 64 位包，输出到 {项目根目录}/Build/PC/{productName}.exe。
    //CICD 调用：Unity.exe -batchmode -quit -projectPath <path> -executeMethod Build.BuildPC
    //失败时以退出码 1 结束进程，让流水线能识别
    [MenuItem("Tools/Build/BuildPC", priority = 1)]
    public static void BuildPC()
    {
        string[] scenes = EditorBuildSettings.scenes
            .Where(s => s.enabled)
            .Select(s => s.path)
            .ToArray();
        if (scenes.Length == 0)
        {
            Fail("[Build] Build Settings 里没有启用的场景");
            return;
        }

        string projectRoot = Path.GetDirectoryName(Application.dataPath);
        string outDir = Path.Combine(projectRoot, PCOutputDirName);
        Directory.CreateDirectory(outDir);

        var options = new BuildPlayerOptions
        {
            scenes = scenes,
            locationPathName = Path.Combine(outDir, PlayerSettings.productName + ".exe"),
            target = BuildTarget.StandaloneWindows64,
            targetGroup = BuildTargetGroup.Standalone,
            options = BuildOptions.None,
        };

        BuildSummary summary = BuildPipeline.BuildPlayer(options).summary;
        if (summary.result != BuildResult.Succeeded)
        {
            Fail($"[Build] PC 打包失败：{summary.result}，错误数 {summary.totalErrors}，详见上面的日志");
            return;
        }

        Debug.Log($"[Build] PC 打包完成：{options.locationPathName}，{summary.totalSize / 1024 / 1024} MB，用时 {summary.totalTime}");
    }

    static void Fail(string message)
    {
        Debug.LogError(message);
        if (Application.isBatchMode)
        {
            EditorApplication.Exit(1);
        }
    }

}

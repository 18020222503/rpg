using System.IO;
using UnityEditor;
using UnityEngine;

public static class BuildAssetBundleTool
{
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

        AssetDatabase.Refresh();
    }
}
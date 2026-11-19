using HybridCLR;
using HybridCLR.Commands;
using System.IO;
using UnityEngine;
using UnityEditor;
using UnityEditor.Build;
public class HybridCLRTool 
{  
    
    //生成热更dll
    [MenuItem("Tools/Hotdate/GenerateHotUpdateDll",priority = 1)]
    public static void GenerateHotUpdateDll()
    {
        
        var installer = new HybridCLR.Installer.InstallerController();
        if (!installer.HasInstalledHybridCLR())
        {
            throw new BuildFailedException($"You have not initialized HybridCLR, please install it via menu 'HybridCLR/Installer'");
        }
        BuildTarget target = EditorUserBuildSettings.activeBuildTarget;
        
        //编译代码，将热更代码编程成dll文件
        CompileDllCommand.CompileDll(target, EditorUserBuildSettings.development);    
        
        Il2CppDefGeneratorCommand.GenerateIl2CppDef();
   
        
        //生成link.xml ，里面写的都是热更程序集引用了哪些非热更程序集。避免裁剪过程种被剪掉
        LinkGeneratorCommand.GenerateLinkXml(target);


        MethodBridgeGeneratorCommand.GenerateEmptyMethodBridgeAndReversePInvokeWrapper(target);
        
        //生成裁剪过后的AOT 程序集
        StripAOTDllCommand.GenerateStripedAOTDlls(target);

        MethodBridgeGeneratorCommand.GenerateMethodBridgeAndReversePInvokeWrapper(target);
        AOTReferenceGeneratorCommand.GenerateAOTGenericReference(target);
        
        //生成的game.dll跟Asset目录同级叫HybridCLRData，拷贝Game.dll到Assets/GameResource/Dll 目录下，同时修改名字为Game.dll.bytes
        CopyHotUpdateDll(target);
    }

    const string DllAssetDir = "Assets/GameResource/Dll";

    //Unity 不认 .dll 当普通资源，改成 .bytes 后会导入成 TextAsset，才能打进 bundle
    static void CopyHotUpdateDll(BuildTarget target)
    {
        string srcPath = $"{SettingsUtil.GetHotUpdateDllsOutputDirByTarget(target)}/Game.dll";
        if (!File.Exists(srcPath))
        {
            throw new BuildFailedException($"找不到 {srcPath}，热更 dll 编译失败");
        }

        Directory.CreateDirectory(DllAssetDir);
        string dstPath = $"{DllAssetDir}/Game.dll.bytes";
        File.Copy(srcPath, dstPath, true);
        AssetDatabase.ImportAsset(dstPath);
        Debug.Log($"[HybridCLR] 已拷贝 {srcPath} -> {dstPath}");
    }
}

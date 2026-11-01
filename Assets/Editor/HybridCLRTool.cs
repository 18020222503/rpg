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
    }
}

using System.IO;
using UnityEditor;
using UnityEngine;

//编辑器启动模式开关：关闭时直读工程资源，打开时从 AssetBundle/{平台} 走完整下载流程
public static class BootModeMenu
{
    const string ToggleMenu = "Tools/Hotdate/EditorUseLocalBundle";

    [MenuItem(ToggleMenu, priority = 50)]
    static void ToggleUseLocalBundle()
    {
        bool value = !EditorPrefs.GetBool(BootConfig.EditorUseLocalBundleKey, false);
        EditorPrefs.SetBool(BootConfig.EditorUseLocalBundleKey, value);
        Debug.Log(value ? "[Boot] 编辑器使用本地 bundle，下载源：" + BootConfig.BaseUrl : "[Boot] 编辑器直读工程资源");
    }

    [MenuItem(ToggleMenu, true)]
    static bool ToggleUseLocalBundleValidate()
    {
        Menu.SetChecked(ToggleMenu, EditorPrefs.GetBool(BootConfig.EditorUseLocalBundleKey, false));
        return true;
    }

    //删除编辑器的下载缓存，用来测试首次下载
    [MenuItem("Tools/Hotdate/ClearEditorCache", priority = 51)]
    static void ClearEditorCache()
    {
        string dir = BootConfig.CacheDir;
        if (Directory.Exists(dir)) Directory.Delete(dir, true);
        Debug.Log($"[Boot] 已清空 {dir}");
    }
}

using HybridCLR;
using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Threading.Tasks;
using UnityEngine;
using UnityEngine.Networking;

public class ProcedureLoadAssembly
{
    private static ProcedureLoadAssembly _instance;
    public Action onComplete;
    public static ProcedureLoadAssembly Instance
    {
        get
        {
            if (_instance == null)
            {
                _instance =  new ProcedureLoadAssembly();
                return _instance;
            }
            return _instance;
        }
    }


    //热更dll所在的bundle名，和打包工具 BuildHotUpdateBundle 里的一致
    public const string DllBundleName = "game.dll.ab";
    //dll在bundle里的资源路径，打包前它被拷到 Assets/HotUpdateDlls 下
    const string DllAssetPath = "Assets/HotUpdateDlls/Game.dll.bytes";

    public Assembly HotUpdateAss { get; private set; }

    public void Load(Action onComplete)
    {
        if (HotUpdateAss != null) return;

#if !UNITY_EDITOR
        var bundlePath = Path.Combine(Application.persistentDataPath, DllBundleName);
        var bundle = AssetBundle.LoadFromFile(bundlePath);
        if (bundle == null)
        {
            Debug.LogError($"加载热更bundle失败：{bundlePath}");
            return;
        }

        var dllAsset = bundle.LoadAsset<TextAsset>(DllAssetPath);
        if (dllAsset == null)
        {
            Debug.LogError($"bundle里找不到 {DllAssetPath}");
            bundle.Unload(true);
            return;
        }

        HotUpdateAss = Assembly.Load(dllAsset.bytes);
        //dll已经加载进内存，bundle可以卸载
        bundle.Unload(true);
#else
        HotUpdateAss = System.AppDomain.CurrentDomain.GetAssemblies().First(a => a.GetName().Name == "Game");
#endif
        if (onComplete!=null)
        {
            onComplete.Invoke();
        }
    }
}
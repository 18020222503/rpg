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

public class LoadDll
{
    private static LoadDll _instance;

    public static LoadDll Instance
    {
        get
        {
            if (_instance == null)
            {
                _instance =  new LoadDll();
                return _instance;
            }
            return _instance;
        }
    }


    public Assembly HotUpdateAss { get; private set; }

    public void Load()
    {
        if (HotUpdateAss != null) return;

        // Editor环境下，HotUpdate.dll.bytes已经被自动加载，不需要加载，重复加载反而会出问题。
#if !UNITY_EDITOR
        HotUpdateAss = Assembly.Load(File.ReadAllBytes($"{Application.streamingAssetsPath}/Game.dll.bytes"));
#else
        // Editor下无需加载，直接查找获得HotUpdate程序集
        HotUpdateAss = System.AppDomain.CurrentDomain.GetAssemblies().First(a => a.GetName().Name == "Game");
#endif
        
        Type type = HotUpdateAss.GetType("Hello");
        type.GetMethod("Run").Invoke(null, null);
    }
}
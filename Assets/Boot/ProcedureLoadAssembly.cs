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


    public Assembly HotUpdateAss { get; private set; }

    public void Load(Action onComplete)
    {
        if (HotUpdateAss != null) return;

#if !UNITY_EDITOR
        HotUpdateAss = Assembly.Load(File.ReadAllBytes($"{Application.streamingAssetsPath}/Game.dll.bytes"));
#else
        HotUpdateAss = System.AppDomain.CurrentDomain.GetAssemblies().First(a => a.GetName().Name == "Game");
#endif
        if (onComplete!=null)
        {
            onComplete.Invoke();
        }
    }
}
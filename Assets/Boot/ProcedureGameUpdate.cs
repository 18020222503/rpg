using System;
using System.IO;
using Microsoft.VisualBasic;
using UnityEngine;
using UnityEngine.Networking;

public class ProcedureGameUpdate
{
    private static ProcedureGameUpdate _instance;
    public Action onComplete;
    public static ProcedureGameUpdate Instance
    {
        get
        {
            if (_instance == null)
            {
                _instance =  new ProcedureGameUpdate();
                return _instance;
            }
            return _instance;
        }
    }
    
    public void start()
    {   
        
        Check();
    }

    private void Check()
    {  
        //1.检查版本，下载最新的dll/资源到presistenDataPath ,下载json文件 判断是否需要更新
        bool needUpdate = true;
        if (needUpdate)
        {
            Download();
        }
    }

    private bool DownLoadJson()
    {
        return true;
    }

    private void Download()
    {
        var cdnAddress = BootConfig.CDN;
        var url = $"http://{cdnAddress}/{ProcedureLoadAssembly.DllBundleName}";
        var req = UnityWebRequest.Get(url);
        req.SendWebRequest().completed += _ =>
        {
            using (req)
            {
                if (req.result != UnityWebRequest.Result.Success)
                {
                    Debug.LogError($"下载热更bundle失败：{url}，{req.error}");
                    return;
                }

                //原样保存 bundle 文件，加载时用 AssetBundle.LoadFromFile 读取
                var savePath = Path.Combine(Application.persistentDataPath, ProcedureLoadAssembly.DllBundleName);
                File.WriteAllBytes(savePath, req.downloadHandler.data);
                Debug.Log($"热更bundle下载完成：{savePath}");
                onComplete?.Invoke();
            }
        };
    }
}

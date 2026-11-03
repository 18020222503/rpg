using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using UnityEngine.Networking;

public class ProcedureGameUpdate
{
    private static ProcedureGameUpdate _instance;
    public static ProcedureGameUpdate Instance => _instance ??= new ProcedureGameUpdate();

    // 下载进度：0~1 的比例、已下载字节数、总字节数（所有需要更新的 bundle 加起来）
    public Action<float, long, long> onProgress;
    public Action<string> onFailed;
    public Action onComplete;

    // 由调用方用 StartCoroutine 驱动，这个类本身不是 MonoBehaviour
    public IEnumerator Run()
    {
        // 1.下载远端清单
        string json = null;
        string error = null;
        yield return DownloadText(BundleManifest.FileName, (text, err) => { json = text; error = err; });
        if (error != null)
        {
            Fail(error);
            yield break;
        }

        var remote = BundleManifest.FromJson(json);
        if (remote == null || remote.bundles == null)
        {
            Fail($"{BundleManifest.FileName} 格式不对");
            yield break;
        }

        // 2.和本地清单对比，找出需要下载的 bundle
        var local = LoadLocalManifest();
        var pending = new List<BundleInfo>();
        long total = 0;
        foreach (var info in remote.bundles)
        {
            var old = local.Find(info.name);
            var upToDate = old != null && old.hash == info.hash && File.Exists(GetLocalPath(info.name));
            if (upToDate) continue;
            pending.Add(info);
            total += info.size;
        }

        // 3.逐个下载，每下完一个就更新本地清单，中途失败重试时已下好的不会重复下载
        long finished = 0;
        foreach (var info in pending)
        {
            var baseBytes = finished;
            yield return Download(info, downloaded =>
            {
                var sum = baseBytes + downloaded;
                onProgress?.Invoke(total > 0 ? Mathf.Clamp01((float)sum / total) : 1f, sum, total);
            }, err => error = err);

            if (error != null)
            {
                Fail(error);
                yield break;
            }

            finished += info.size;
            local.bundles.RemoveAll(b => b.name == info.name);
            local.bundles.Add(info);
            SaveLocalManifest(local);
        }

        onProgress?.Invoke(1f, total, total);
        Debug.Log($"热更完成，下载了 {pending.Count} 个 bundle");
        onComplete?.Invoke();
    }

    public static string GetLocalPath(string bundleName)
    {
        return Path.Combine(Application.persistentDataPath, bundleName);
    }

    private static string GetUrl(string name) => $"http://{BootConfig.CDN}/{name}";

    private void Fail(string error)
    {
        Debug.LogError($"热更失败：{error}");
        onFailed?.Invoke(error);
    }

    private IEnumerator DownloadText(string name, Action<string, string> done)
    {
        var url = GetUrl(name);
        using (var req = UnityWebRequest.Get(url))
        {
            yield return req.SendWebRequest();
            if (req.result != UnityWebRequest.Result.Success)
                done(null, $"{req.error} ({url})");
            else
                done(req.downloadHandler.text, null);
        }
    }

    private IEnumerator Download(BundleInfo info, Action<long> onBytes, Action<string> onError)
    {
        var url = GetUrl(info.name);
        var savePath = GetLocalPath(info.name);
        // 先下载到临时文件，完整下完再替换，中途失败不会破坏上一次下好的 bundle
        var tempPath = savePath + ".tmp";
        if (File.Exists(tempPath)) File.Delete(tempPath);

        using (var req = UnityWebRequest.Get(url))
        {
            req.downloadHandler = new DownloadHandlerFile(tempPath) { removeFileOnAbort = true };
            var op = req.SendWebRequest();
            while (!op.isDone)
            {
                onBytes((long)req.downloadedBytes);
                yield return null;
            }

            if (req.result != UnityWebRequest.Result.Success)
            {
                if (File.Exists(tempPath)) File.Delete(tempPath);
                onError($"{req.error} ({url})");
                yield break;
            }
        }

        if (File.Exists(savePath)) File.Delete(savePath);
        File.Move(tempPath, savePath);
        onBytes(info.size);
        Debug.Log($"bundle 下载完成：{savePath}");
        onError(null);
    }

    private static BundleManifest LoadLocalManifest()
    {
        var path = GetLocalPath(BundleManifest.FileName);
        if (!File.Exists(path)) return new BundleManifest();
        try
        {
            return BundleManifest.FromJson(File.ReadAllText(path)) ?? new BundleManifest();
        }
        catch (Exception e)
        {
            Debug.LogWarning($"本地清单读取失败，当作没有：{e.Message}");
            return new BundleManifest();
        }
    }

    private static void SaveLocalManifest(BundleManifest manifest)
    {
        File.WriteAllText(GetLocalPath(BundleManifest.FileName), JsonUtility.ToJson(manifest));
    }
}

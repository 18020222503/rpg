#if UNITY_EDITOR
using UnityEditor.SceneManagement;
#endif
using System.Collections;
using UnityEngine;
using UnityEngine.SceneManagement;

public class GameBoot : MonoBehaviour
{
    //场景所在的bundle名和场景路径，和打包工具 BuildAssetBundleTool 里的一致
    public const string EntryBundleName = "entry.ab";
    const string EntryScenePath = "Assets/Scenes/Entry.unity";
   
    public BootProgressView view;

    // 下载完、程序集加载完，等进度条走满后再切场景
    bool readyToSwitch;
    bool switching;

    void Start()
    {
        var update = ProcedureGameUpdate.Instance;
        update.onProgress = OnDownloadProgress;
        update.onFailed = OnDownloadFailed;
        update.onComplete = OnDownloadComplete;
        StartDownload();
    }

    void Update()
    {
        if (!readyToSwitch || switching || !view.IsFull) return;

        switching = true;
        SwitchScene();
    }

    void StartDownload()
    {
        view.ResetProgress();
        view.SetStatus("Downloading update...");
        view.SetDetail("");
        StartCoroutine(ProcedureGameUpdate.Instance.Run());
    }

    void OnDownloadProgress(float progress, long downloaded, long total)
    {
        view.SetProgress(progress);
        view.SetDetail(total > 0 ? $"{FormatSize(downloaded)} / {FormatSize(total)}" : FormatSize(downloaded));
    }

    void OnDownloadFailed(string error)
    {
        view.SetStatus("Download failed");
        view.SetDetail("");
        view.ShowError(error, StartDownload);
    }

    void OnDownloadComplete()
    {
        view.SetProgress(1f);
        view.SetStatus("Loading...");

        //2.加载 AOT 补充元数据（mscorlib、System、System.Core 的 .dll.bytes）

        //3.Assembly.Load(Game.dll.bytes)

        //4.反射调用热更入口
        ProcedureLoadAssembly.Instance.Load(() => readyToSwitch = true);
    }

    public void SwitchScene()
    {
        if (BootConfig.UseBundle)
        {
            StartCoroutine(LoadEntryFromAB());
            return;
        }
#if UNITY_EDITOR
        EditorSceneManager.LoadSceneAsyncInPlayMode(
            EntryScenePath,
            new LoadSceneParameters(LoadSceneMode.Single));
#endif
    }

    // 场景 bundle 已经由 ProcedureGameUpdate 下载到 BootConfig.CacheDir。
    // 必须在 Game.dll 加载之后再加载场景，否则场景里的热更脚本会丢失
    IEnumerator LoadEntryFromAB()
    {
        var path = ProcedureGameUpdate.GetLocalPath(EntryBundleName);
        var request = AssetBundle.LoadFromFileAsync(path);
        yield return request;
        if (request.assetBundle == null)
        {
            switching = false;
            view.SetStatus("Load failed");
            view.ShowError($"加载场景 bundle 失败：{path}", StartDownload);
            yield break;
        }

        // 场景 bundle 在场景存活期间不能 Unload(true)，这里不卸载
        yield return SceneManager.LoadSceneAsync(EntryScenePath, LoadSceneMode.Single);
    }

    static string FormatSize(long bytes)
    {
        if (bytes < 1024) return $"{bytes} B";
        if (bytes < 1024 * 1024) return $"{bytes / 1024f:0.0} KB";
        return $"{bytes / (1024f * 1024f):0.00} MB";
    }
}

using UnityEngine;
using UnityEngine.EventSystems;

public class GameBoot : MonoBehaviour
{
    // 热更入口，在 Game.dll 里。AOT 代码不能直接引用热更程序集，只能反射调用
    const string EntryType = "GameEntry";
    const string EntryMethod = "Start";

    public BootProgressView view;
    [Tooltip("编辑器下是否走 bundle（下载 + 从 bundle 加载）；真机固定走 bundle")]
    public bool  useAssetBundle;

    bool UseBundle => !Application.isEditor || useAssetBundle;

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
        EnterHotUpdate();
    }

    void StartDownload()
    {
        view.ResetProgress();
        view.SetStatus("Downloading update...");
        view.SetDetail("");
        StartCoroutine(ProcedureGameUpdate.Instance.Run(UseBundle));
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

        ProcedureLoadAssembly.Instance.Load(() => readyToSwitch = true);
    }

    void EnterHotUpdate()
    {
        var method = ProcedureLoadAssembly.Instance.HotUpdateAss.GetType(EntryType)?.GetMethod(EntryMethod);
        if (method == null)
        {
            view.SetStatus($"Game.dll 里找不到 {EntryType}.{EntryMethod}");
            return;
        }

        // Boot 场景里的相机、灯光、进度界面只在启动阶段用，交给热更层前关掉。
        // EventSystem 留着，后面的界面共用。入口会在这个场景根下新建 GameFlow，所以要先关再调入口
        foreach (var go in gameObject.scene.GetRootGameObjects())
        {
            if (go.GetComponent<EventSystem>() == null) go.SetActive(false);
        }

        method.Invoke(null, new object[] { UseBundle, BootConfig.CacheDir });
    }

    static string FormatSize(long bytes)
    {
        if (bytes < 1024) return $"{bytes} B";
        if (bytes < 1024 * 1024) return $"{bytes / 1024f:0.0} KB";
        return $"{bytes / (1024f * 1024f):0.00} MB";
    }
}

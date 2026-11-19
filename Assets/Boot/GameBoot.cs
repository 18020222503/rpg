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

    // StageTimer 的阶段编号
    int updateStage = -1;
    int waitStage = -1;

    void Start()
    {
        // 编辑器里这个时间包含编辑器自己的启动和进 Play 模式，没有参考意义，只在打出的包里记
        if (!Application.isEditor)
            StageTimer.Add("引擎启动 + 加载 Boot 场景", 0, Time.realtimeSinceStartupAsDouble);

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
        StageTimer.End(waitStage);
        EnterHotUpdate();
    }

    void StartDownload()
    {
        view.ResetProgress();
        view.SetStatus("Downloading update...");
        view.SetDetail("");
        updateStage = StageTimer.Begin(UseBundle ? "热更检查和下载" : "热更检查和下载（编辑器直读，跳过）");
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
        StageTimer.End(updateStage, "失败");
    }

    void OnDownloadComplete() 
    {
        view.SetStatus("Loading...");
        StageTimer.End(updateStage);

        var loadStage = StageTimer.Begin("加载 Game.dll");
        ProcedureLoadAssembly.Instance.Load(() => readyToSwitch = true);
        view.SetProgress(1f);
        StageTimer.End(loadStage, readyToSwitch ? null : "失败");

        // 进度条是平滑过渡的，下载很快时要等它追上来，这段是纯等待
        if (readyToSwitch) waitStage = StageTimer.Begin("等进度条走满");
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

        var entryStage = StageTimer.Begin("调用热更入口 GameEntry.Start");
        method.Invoke(null, new object[] { UseBundle, BootConfig.CacheDir });
        StageTimer.End(entryStage);
    }

    static string FormatSize(long bytes)
    {
        if (bytes < 1024) return $"{bytes} B";
        if (bytes < 1024 * 1024) return $"{bytes / 1024f:0.0} KB";
        return $"{bytes / (1024f * 1024f):0.00} MB";
    }
}

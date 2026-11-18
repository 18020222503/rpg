using UnityEngine;
using UnityEngine.SceneManagement;

public class GameBoot : MonoBehaviour
{
    // 启动完成后进入的第一个场景，已加入 Build Settings
    const string LoginSceneName = "Ported_Login";

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
        SceneManager.LoadSceneAsync(LoginSceneName, LoadSceneMode.Single);
    }

    static string FormatSize(long bytes)
    {
        if (bytes < 1024) return $"{bytes} B";
        if (bytes < 1024 * 1024) return $"{bytes / 1024f:0.0} KB";
        return $"{bytes / (1024f * 1024f):0.00} MB";
    }
}

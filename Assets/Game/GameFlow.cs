using System.Collections;
using Ported;
using UnityEngine;

// 只有 Boot 一个场景，登录和游戏都是 prefab。切换时销毁当前的，再从资源里加载下一个
public class GameFlow : MonoBehaviour
{
    // 由 Tools/Ported/Export Prefabs 生成
    const string LoginPrefab = "Prefab/login/Login.prefab";
    const string GamePrefab = "Prefab/game/Game.prefab";

    GameObject current;
    bool unloading;
    // 第一次切换是启动流程的最后一步，打印的表从进程启动开始；之后每次切换单独一张表
    bool firstSwitch = true;

    void Awake()
    {
        PortedSession.EnterGame = () => Switch(GamePrefab);
        PortedSession.BackToLogin = () => Switch(LoginPrefab);
    }

    void Start()
    {
        Switch(LoginPrefab);
    }

    void OnDestroy()
    {
        PortedSession.EnterGame = null;
        PortedSession.BackToLogin = null;
    }

    void Switch(string assetName)
    {
        var name = System.IO.Path.GetFileNameWithoutExtension(assetName);
        var switchStage = StageTimer.Begin($"切换到 {name}");

        if (current != null)
        {
            // Destroy 要到帧末才生效，先关掉，免得新旧两份的相机、灯光同时在
            var destroyStage = StageTimer.Begin($"关闭 {current.name}");
            current.SetActive(false);
            Destroy(current);
            current = null;
            StageTimer.End(destroyStage);
            StartCoroutine(UnloadUnused());
        }

        var loadStage = StageTimer.Begin($"加载 {assetName}");
        var prefab = ResourceManager.Instance.LoadAsset<GameObject>(assetName);
        StageTimer.End(loadStage, prefab == null ? "失败" : null);
        if (prefab == null)
        {
            StageTimer.End(switchStage, "失败");
            StageTimer.Report($"切换到 {name} 失败");
            Debug.LogError($"[GameFlow] 加载失败：{assetName}。先执行 Tools/Ported/Export Prefabs；走 bundle 时还要重新执行 Tools/CreateABTag 和 Tools/BuildAB");
            return;
        }

        var instStage = StageTimer.Begin("Instantiate");
        current = Instantiate(prefab);
        current.name = prefab.name;
        StageTimer.End(instStage);

        StartCoroutine(ReportAfterFirstFrame(name, switchStage));
    }

    // 界面里的组件在下一帧才跑 Start（登录界面在 Start 里搭 UI），再加上渲染，这一帧画完才算真正进入界面
    IEnumerator ReportAfterFirstFrame(string name, int switchStage)
    {
        var frameStage = StageTimer.Begin("首帧（各组件 Start + 渲染）");
        yield return null;
        yield return new WaitForEndOfFrame();
        StageTimer.End(frameStage);
        StageTimer.End(switchStage);

        while (unloading) yield return null;

        StageTimer.Report(firstSwitch ? $"启动到进入 {name}" : $"切换到 {name}");
        firstSwitch = false;
    }

    // 释放上一个 prefab 用到、现在没人引用的贴图和模型。等一帧，让 Destroy 先生效
    IEnumerator UnloadUnused()
    {
        unloading = true;
        yield return null;
        var stage = StageTimer.Begin("Resources.UnloadUnusedAssets");
        yield return Resources.UnloadUnusedAssets();
        StageTimer.End(stage);
        unloading = false;
    }
}

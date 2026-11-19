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
        if (current != null)
        {
            // Destroy 要到帧末才生效，先关掉，免得新旧两份的相机、灯光同时在
            current.SetActive(false);
            Destroy(current);
            current = null;
            StartCoroutine(UnloadUnused());
        }

        var prefab = ResourceManager.Instance.LoadAsset<GameObject>(assetName);
        if (prefab == null)
        {
            Debug.LogError($"[GameFlow] 加载失败：{assetName}。先执行 Tools/Ported/Export Prefabs；走 bundle 时还要重新执行 Tools/CreateABTag 和 Tools/BuildAB");
            return;
        }

        current = Instantiate(prefab);
        current.name = prefab.name;
    }

    // 释放上一个 prefab 用到、现在没人引用的贴图和模型。等一帧，让 Destroy 先生效
    IEnumerator UnloadUnused()
    {
        yield return null;
        yield return Resources.UnloadUnusedAssets();
    }
}

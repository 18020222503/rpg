using UnityEngine;

// 热更入口。Boot 场景下载完资源、加载完 Game.dll 后反射调用 Start，之后的流程都在热更层
public static class GameEntry
{
    // useBundle：编辑器下是否走 bundle，由 Boot 场景上 GameBoot 的勾选决定；真机固定走 bundle
    // bundleRoot：Boot 下载 bundle 存放的目录（BootConfig.CacheDir）
    public static void Start(bool useBundle, string bundleRoot)
    {
        ResourceManager.Instance.UseBundle = useBundle;
        ResourceManager.Instance.BundleRoot = bundleRoot;
        var stage = StageTimer.Begin(useBundle ? "ResourceManager.Init（加载总清单）" : "ResourceManager.Init（编辑器直读，跳过）");
        ResourceManager.Instance.Init();
        StageTimer.End(stage);
        new GameObject("GameFlow").AddComponent<GameFlow>();
    }
}

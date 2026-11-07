using System.Collections;
using UnityEngine;

// Entry 场景从菜单进入玩法的过渡：开始界面淡出，镜头从总览位置飞向玩家，然后开放玩家操作
public class EntryFlow : MonoBehaviour
{
    public PlayerController player;
    public TopDownCamera followCamera;
    public float fadeTime = 0.6f;

    bool started;

    void Awake()
    {
        // 菜单阶段镜头停在总览位置，玩家不能操作
        if (player != null) player.enabled = false;
        if (followCamera != null) followCamera.enabled = false;
    }

    void Start()
    {
        if (UIManager.Instance == null)
        {
            Debug.LogError("[Entry] 场景里没有 UIManager，请执行 Tools/UI/BuildEntryUI");
            return;
        }

        var panel = UIManager.Instance.Open<UIStartPanel>();
        if (panel != null) panel.onStart += StartGameplay;
        if (panel != null) panel.onStart1 += LoadScene;
    }

    public void StartGameplay()
    {
        if (started) return;
        started = true;
        StartCoroutine(Transition());
    }

    public void LoadScene()
    {
        var sceneName = "dungeon";
        ResourceManager.Instance.Init(); 
         var prefab =  ResourceManager.Instance.LoadAsset<GameObject>(sceneName);
         Instantiate(prefab);
    }

    IEnumerator Transition()
    {
        // 镜头开始跟随玩家，TopDownCamera 会从当前位置平滑移过去
        followCamera.enabled = true;
        UIManager.Instance.Close<UIStartPanel>(fadeTime);

        yield return new WaitForSecondsRealtime(fadeTime);
        player.enabled = true;
    }
}

using System.Collections;
using UnityEngine;
using UnityEngine.UI;

// Entry 场景从菜单进入玩法的过渡：菜单淡出，镜头从总览位置飞向玩家，然后开放玩家操作
public class EntryFlow : MonoBehaviour
{
    public Button startButton;
    public CanvasGroup menuGroup;
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
        if (startButton != null) startButton.onClick.AddListener(StartGameplay);
    }

    public void StartGameplay()
    {
        if (started) return;
        started = true;
        StartCoroutine(Transition());
    }

    IEnumerator Transition()
    {
        menuGroup.interactable = false;
        menuGroup.blocksRaycasts = false;

        // 镜头开始跟随玩家，TopDownCamera 会从当前位置平滑移过去
        followCamera.enabled = true;

        var t = 0f;
        while (t < fadeTime)
        {
            t += Time.deltaTime;
            menuGroup.alpha = 1f - Mathf.Clamp01(t / fadeTime);
            yield return null;
        }

        menuGroup.gameObject.SetActive(false);
        player.enabled = true;
    }
}

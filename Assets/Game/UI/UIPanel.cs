using System.Collections;
using UnityEngine;

public enum UILayer
{
    HUD,    // 常驻界面：血条、小地图
    Popup,  // 菜单、背包等可开关的界面
    Top,    // 提示、加载遮罩等永远在最上面的界面
}

// 所有界面的基类。打开和关闭统一走 UIManager，子类只重写 OnOpen / OnClose
[RequireComponent(typeof(CanvasGroup))]
public abstract class UIPanel : MonoBehaviour
{
    public UILayer layer = UILayer.Popup;

    public bool IsOpen { get; private set; }

    CanvasGroup group;
    Coroutine fading;

    public CanvasGroup Group => group != null ? group : (group = GetComponent<CanvasGroup>());

    public void Open(object data = null)
    {
        StopFade();
        Group.alpha = 1f;
        Group.interactable = true;
        Group.blocksRaycasts = true;
        gameObject.SetActive(true);
        IsOpen = true;
        OnOpen(data);
    }

    // fadeTime > 0 时先淡出再隐藏。OnClose 在调用时立即触发，不等淡出结束
    public void Close(float fadeTime = 0f)
    {
        if (!IsOpen) return;
        IsOpen = false;
        OnClose();

        if (fadeTime > 0f && gameObject.activeInHierarchy)
        {
            fading = StartCoroutine(FadeOut(fadeTime));
        }
        else
        {
            gameObject.SetActive(false);
        }
    }

    protected virtual void OnOpen(object data) { }
    protected virtual void OnClose() { }

    IEnumerator FadeOut(float time)
    {
        Group.interactable = false;
        Group.blocksRaycasts = false;

        var from = Group.alpha;
        var t = 0f;
        while (t < time)
        {
            t += Time.unscaledDeltaTime;
            Group.alpha = Mathf.Lerp(from, 0f, t / time);
            yield return null;
        }

        fading = null;
        gameObject.SetActive(false);
    }

    void StopFade()
    {
        if (fading == null) return;
        StopCoroutine(fading);
        fading = null;
    }
}

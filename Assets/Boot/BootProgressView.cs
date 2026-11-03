using System;
using UnityEngine;
using UnityEngine.UI;

// Boot 场景的进度界面。只负责显示：进度条、百分比、状态文字、下载失败时的重试按钮
public class BootProgressView : MonoBehaviour
{
    public Slider bar;
    public Text percentText;
    public Text statusText;
    public Text detailText;
    public GameObject errorRoot;
    public Text errorText;
    public Button retryButton;

    // 进度条每秒最多前进多少（1 = 整条）。只是让画面不跳变，目标值始终是真实的下载进度
    public float fillSpeed = 2f;

    float target;
    float shown;
    Action onRetry;

    // 显示出来的进度条已经走满
    public bool IsFull => shown >= 0.999f;

    void Awake()
    {
        if (retryButton != null) retryButton.onClick.AddListener(() => onRetry?.Invoke());
        ResetProgress();
        HideError();
    }

    void Update()
    {
        shown = Mathf.MoveTowards(shown, target, fillSpeed * Time.unscaledDeltaTime);
        if (bar != null) bar.value = shown;
        if (percentText != null) percentText.text = $"{Mathf.RoundToInt(shown * 100f)}%";
    }

    public void ResetProgress()
    {
        target = 0f;
        shown = 0f;
        HideError();
    }

    public void SetProgress(float progress)
    {
        target = Mathf.Clamp01(progress);
    }

    public void SetStatus(string text)
    {
        if (statusText != null) statusText.text = text;
    }

    public void SetDetail(string text)
    {
        if (detailText != null) detailText.text = text;
    }

    public void ShowError(string message, Action retry)
    {
        onRetry = retry;
        if (errorText != null) errorText.text = message;
        if (errorRoot != null) errorRoot.SetActive(true);
    }

    public void HideError()
    {
        if (errorRoot != null) errorRoot.SetActive(false);
    }
}

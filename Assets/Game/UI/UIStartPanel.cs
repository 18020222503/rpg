using System;
using UnityEngine;
using UnityEngine.UI;

// 开始界面：标题加一个开始按钮。点击后只发出 onStart 事件，进入玩法由 EntryFlow 决定
public class UIStartPanel : UIPanel
{
    public Button startButton;
    public Button startButton1;
    public event Action onStart;

    public event Action onStart1;
    void Awake()
    {
        if (startButton != null) startButton.onClick.AddListener(() => onStart?.Invoke());
        
        if (startButton1 != null) startButton1.onClick.AddListener(() => onStart1?.Invoke());
    }
}

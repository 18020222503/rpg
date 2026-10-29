using UnityEngine;
using UnityEngine.UI;

public class UIMainview : MonoBehaviour
{  
    
    public Button testBtn;
    public Text testText;
    void Start()
    {
        if (testBtn!=null)
        {
            testBtn.onClick.AddListener(OnTestbtnClicked);
        }
    }
    
    
    void OnTestbtnClicked()
    {
        testText.text = "Hello World";
    }
    
    
}

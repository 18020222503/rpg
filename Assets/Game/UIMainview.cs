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
        Test t = new Test();
        testText.text = t.GetTestMsg();
    }
    
    
}

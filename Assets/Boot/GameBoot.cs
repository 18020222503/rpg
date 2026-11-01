#if UNITY_EDITOR
using UnityEditor.SceneManagement;
#endif
using System.Collections;
using UnityEngine;
using UnityEngine.Networking;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

public class GameBoot : MonoBehaviour
{

    public Scrollbar scrollbar;
    public float duration = 0.5f; 
    bool running;
    float t;
    void Start()
    {  
        //下载是异步的，下载完成后再加载程序集
        ProcedureGameUpdate.Instance.onComplete = () =>
        {
            //2.加载 AOT 补充元数据（mscorlib、System、System.Core 的 .dll.bytes）

            //3.Assembly.Load(Game.dll.bytes)

            //4.反射调用热更入口
            ProcedureLoadAssembly.Instance.Load(TestScrollbar);
        };
        ProcedureGameUpdate.Instance.start();

    }
    
    void Update()
    {
        if (!running) return;

        t += Time.deltaTime;
        scrollbar.size = Mathf.Clamp01(t / duration);

        if (t >= duration)
        {
            running = false;
            SwitchScene();
        }
    }

    public void TestScrollbar()
    {
        t = 0f;
        scrollbar.size = 0f;
        running = true;
    }
    
    public void SwitchScene()
    {
#if UNITY_EDITOR
        EditorSceneManager.LoadSceneAsyncInPlayMode(
            "Assets/Scenes/Entry.unity",
            new LoadSceneParameters(LoadSceneMode.Single));
#else
    StartCoroutine(LoadEntryFromAB());
#endif
    }
    
    
    IEnumerator LoadEntryFromAB()
    {
        var req = UnityWebRequestAssetBundle.GetAssetBundle(
            $"{Application.streamingAssetsPath}/entry.ab");
        yield return req.SendWebRequest();
        var bundle = DownloadHandlerAssetBundle.GetContent(req); // 先别 Unload
        yield return SceneManager.LoadSceneAsync("Entry", LoadSceneMode.Single);
    }


}

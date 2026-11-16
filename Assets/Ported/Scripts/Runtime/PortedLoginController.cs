using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.InputSystem.UI;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

namespace Ported
{
    // 挂在登录场景里，负责把原 LoginPanel 预制体接到新流程上：
    // 点“进入游戏”后出现角色选择，选好后载入游戏场景。原项目的网络登录、服务器列表和协议弹窗都没有搬。
    public class PortedLoginController : MonoBehaviour
    {
        public GameObject loginPanel;
        public string[] heroNames;

        GameObject selectPanel;

        void Start()
        {
            EnsureEventSystem();
            if (loginPanel == null)
            {
                Debug.LogError("[Ported] loginPanel 未指定");
                return;
            }

            // 这些节点在原预制体里依赖 Lua 控制，直接隐藏
            foreach (var n in new[] { "ServerNode", "AgreementNode", "NodeRightTop", "HealthTips_Txt", "Account_Input" })
            {
                var t = FindDeep(loginPanel.transform, n);
                if (t != null) t.gameObject.SetActive(false);
            }

            var btn = FindDeep(loginPanel.transform, "EnterLogin_Btn");
            if (btn == null)
            {
                Debug.LogError("[Ported] LoginPanel 里没找到 EnterLogin_Btn");
                return;
            }

            var button = btn.GetComponent<Button>();
            if (button == null) button = btn.gameObject.AddComponent<Button>();
            button.onClick.AddListener(ShowSelect);
        }

        void ShowSelect()
        {
            if (selectPanel != null) return;

            var canvas = loginPanel.GetComponentInParent<Canvas>();
            selectPanel = new GameObject("HeroSelect", typeof(RectTransform), typeof(Image));
            selectPanel.transform.SetParent(canvas.transform, false);
            var rt = (RectTransform)selectPanel.transform;
            rt.anchorMin = Vector2.zero;
            rt.anchorMax = Vector2.one;
            rt.offsetMin = rt.offsetMax = Vector2.zero;
            selectPanel.GetComponent<Image>().color = new Color(0f, 0f, 0f, 0.7f);

            MakeLabel(selectPanel.transform, "选择角色 / Select Hero", new Vector2(0f, 220f), 40);

            for (var i = 0; i < heroNames.Length; i++)
            {
                var index = i;
                var pos = new Vector2(-600f + i * 300f, 0f);
                MakeButton(selectPanel.transform, heroNames[i], pos, () =>
                {
                    PortedSession.HeroIndex = index;
                    SceneManager.LoadScene(PortedSession.GameScene);
                });
            }
        }

        static void EnsureEventSystem()
        {
            if (FindFirstObjectByType<EventSystem>() != null) return;
            new GameObject("EventSystem", typeof(EventSystem), typeof(InputSystemUIInputModule));
        }

        static Transform FindDeep(Transform root, string name)
        {
            foreach (var t in root.GetComponentsInChildren<Transform>(true))
                if (t.name == name) return t;
            return null;
        }

        static Font DefaultFont => Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");

        static Text MakeLabel(Transform parent, string text, Vector2 pos, int size)
        {
            var go = new GameObject("Label", typeof(RectTransform), typeof(Text));
            go.transform.SetParent(parent, false);
            var rt = (RectTransform)go.transform;
            rt.anchoredPosition = pos;
            rt.sizeDelta = new Vector2(900f, 80f);
            var t = go.GetComponent<Text>();
            t.text = text;
            t.font = DefaultFont;
            t.fontSize = size;
            t.alignment = TextAnchor.MiddleCenter;
            t.color = Color.white;
            return t;
        }

        static void MakeButton(Transform parent, string text, Vector2 pos, UnityEngine.Events.UnityAction onClick)
        {
            var go = new GameObject(text, typeof(RectTransform), typeof(Image), typeof(Button));
            go.transform.SetParent(parent, false);
            var rt = (RectTransform)go.transform;
            rt.anchoredPosition = pos;
            rt.sizeDelta = new Vector2(260f, 120f);
            go.GetComponent<Image>().color = new Color(0.2f, 0.25f, 0.4f, 0.95f);
            go.GetComponent<Button>().onClick.AddListener(onClick);
            var label = MakeLabel(go.transform, text, Vector2.zero, 26);
            ((RectTransform)label.transform).sizeDelta = new Vector2(250f, 110f);
        }
    }
}

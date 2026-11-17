using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.InputSystem;
using UnityEngine.InputSystem.UI;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

namespace Ported
{
    // 登录界面。原项目的 LoginPanel 预制体里大部分图片、文字由 Lua 在运行时填，搬过来以后一片空白，
    // 这里改用 qq13 的原图（背景、Logo、按钮、底板）在代码里搭：
    //   首页：背景 + Logo + “进入游戏”
    //   角色选择：左边角色列表，中间是选中角色的 3D 模型（可拖动旋转），右边角色信息和“开始游戏”
    // 分三层：背景画布放在相机远处 → 角色模型在它前面 → 按钮、列表在最上层
    public class PortedLoginController : MonoBehaviour
    {
        [Header("qq13 原图")]
        public Sprite background;
        public Sprite logo;
        public Sprite button;          // btn_A01，九宫格按钮
        public Sprite plate;           // plate_dl_ksdb，半透明底板
        public Font font;              // NotoSansSC

        [Header("角色")]
        public string[] heroNames;
        public string[] heroTitles;
        public GameObject[] heroPrefabs;

        [Header("展示")]
        [Tooltip("看角色的相机；为空时用 Camera.main")]
        public Camera sceneCamera;
        [Tooltip("模型朝向。模型正面朝 +Z，相机在 -Z，180 是正对相机")]
        public float modelYaw = 165f;
        public float dragSpeed = 0.4f;

        static readonly string[] IdleStates = { "idle", "idle_f" };
        // 选中时播一次展示动作（各角色的 Animator 里名字不同，取第一个存在的）
        static readonly string[] ShowStates = { "idle_show01", "idle_show_up01", "idle_show02", "idle_show_up02", "idle_show04" };

        static readonly Color EntryIdle = new Color(0.05f, 0.09f, 0.16f, 0.78f);
        static readonly Color EntrySelected = new Color(0.18f, 0.38f, 0.66f, 0.95f);
        static readonly Color Gold = new Color(1f, 0.86f, 0.55f);
        static readonly Color SubBlue = new Color(0.75f, 0.85f, 1f);

        int selected;
        bool loading;
        bool uiBuilt;
        CanvasGroup homeGroup, selectGroup;
        Image bgDim;
        Image[] entries;
        Image[] entryBars;
        Text[] entryNames;
        Text infoName, infoTitle, statusText, pressHint;

        Transform stage;
        readonly Dictionary<int, GameObject> models = new Dictionary<int, GameObject>();
        GameObject currentModel;
        Animator currentAnimator;
        int showHash;
        float showStart;
        float yaw;
        bool dragging;

        void Start()
        {
            EnsureEventSystem();
            selected = Mathf.Clamp(PortedSession.HeroIndex, 0, Mathf.Max(0, (heroNames?.Length ?? 1) - 1));
            BuildUI();
        }

        void Update()
        {
            if (loading) return;
            var kb = Keyboard.current;
            var mouse = Mouse.current;

            if (homeGroup != null && homeGroup.interactable)
            {
                if (kb != null && kb.anyKey.wasPressedThisFrame) ShowSelect();
                if (pressHint != null) pressHint.color = new Color(1f, 1f, 1f, 0.55f + 0.45f * Mathf.Sin(Time.unscaledTime * 3f));
                return;
            }

            UpdateShowAnimation();
            UpdateDrag(mouse);

            if (kb == null || heroNames == null || heroNames.Length == 0) return;
            var n = heroNames.Length;
            if (kb.leftArrowKey.wasPressedThisFrame || kb.upArrowKey.wasPressedThisFrame || kb.aKey.wasPressedThisFrame || kb.wKey.wasPressedThisFrame)
                Select((selected - 1 + n) % n);
            if (kb.rightArrowKey.wasPressedThisFrame || kb.downArrowKey.wasPressedThisFrame || kb.dKey.wasPressedThisFrame || kb.sKey.wasPressedThisFrame)
                Select((selected + 1) % n);
            if (kb.enterKey.wasPressedThisFrame || kb.spaceKey.wasPressedThisFrame) StartGame();
            if (kb.escapeKey.wasPressedThisFrame) ShowHome();
        }

        // ---------- 搭界面（编辑器截图也会调用） ----------

        public void BuildUI()
        {
            if (uiBuilt) return;
            uiBuilt = true;
            if (font == null) font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            var cam = sceneCamera != null ? sceneCamera : Camera.main;

            // 背景层：放到相机前 30 米，角色模型站在它前面
            var bgGo = new GameObject("LoginBgCanvas", typeof(Canvas), typeof(CanvasScaler));
            bgGo.transform.SetParent(transform, false);
            var bgCanvas = bgGo.GetComponent<Canvas>();
            if (cam != null)
            {
                bgCanvas.renderMode = RenderMode.ScreenSpaceCamera;
                bgCanvas.worldCamera = cam;
                bgCanvas.planeDistance = 30f;
            }
            else
            {
                bgCanvas.renderMode = RenderMode.ScreenSpaceOverlay;
                bgCanvas.sortingOrder = -10;
            }
            SetupScaler(bgGo.GetComponent<CanvasScaler>());

            var bg = NewImage(bgGo.transform, "Background", background, Color.white);
            Stretch(bg.rectTransform);
            if (background != null)
            {
                var fitter = bg.gameObject.AddComponent<AspectRatioFitter>();
                fitter.aspectMode = AspectRatioFitter.AspectMode.EnvelopeParent;
                fitter.aspectRatio = background.rect.width / background.rect.height;
            }
            // 角色选择页把背景压暗一点，突出模型
            bgDim = NewImage(bgGo.transform, "Dim", null, new Color(0f, 0f, 0f, 0f));
            Stretch(bgDim.rectTransform);
            var shade = NewImage(bgGo.transform, "BottomShade", GradientSprite(), Color.white);
            Anchor(shade.rectTransform, new Vector2(0, 0), new Vector2(1, 0.5f), Vector2.zero, Vector2.zero);

            // 模型层
            stage = new GameObject("ModelStage").transform;
            stage.SetParent(transform, false);
            var foot = new GameObject("FootShadow").AddComponent<SpriteRenderer>();
            foot.transform.SetParent(stage, false);
            foot.transform.localPosition = new Vector3(0f, 0.01f, 0f);
            foot.transform.localRotation = Quaternion.Euler(90f, 0f, 0f);
            foot.transform.localScale = new Vector3(2.2f, 2.2f, 1f);
            foot.sprite = RadialSprite();
            foot.color = new Color(0f, 0f, 0f, 0.55f);
            stage.gameObject.SetActive(false);

            // 界面层
            var canvasGo = new GameObject("LoginCanvas", typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
            canvasGo.transform.SetParent(transform, false);
            canvasGo.GetComponent<Canvas>().renderMode = RenderMode.ScreenSpaceOverlay;
            SetupScaler(canvasGo.GetComponent<CanvasScaler>());

            homeGroup = BuildHome(canvasGo.transform);
            selectGroup = BuildSelect(canvasGo.transform);
            SetGroup(selectGroup, false);
        }

        CanvasGroup BuildHome(Transform root)
        {
            var go = NewRect(root, "Home");
            Stretch((RectTransform)go.transform);
            var group = go.AddComponent<CanvasGroup>();

            if (logo != null)
            {
                var img = NewImage(go.transform, "Logo", logo, Color.white);
                img.preserveAspect = true;
                Anchor(img.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0, 170), new Vector2(760, 405));
            }

            pressHint = NewText(go.transform, "PressHint", "点击按钮或按任意键开始", 36, Color.white);
            Anchor(pressHint.rectTransform, new Vector2(0.5f, 0), new Vector2(0.5f, 0), new Vector2(0, 230), new Vector2(900, 60));
            AddOutline(pressHint);

            var start = NewButton(go.transform, "Start_Btn", "进入游戏", 40, ShowSelect);
            Anchor((RectTransform)start.transform, new Vector2(0.5f, 0), new Vector2(0.5f, 0), new Vector2(0, 130), new Vector2(460, 96));

            var tip = NewText(go.transform, "Version", "qq13 资源移植 · 离线模式", 22, new Color(1f, 1f, 1f, 0.6f));
            tip.alignment = TextAnchor.LowerRight;
            tip.rectTransform.pivot = new Vector2(1, 0);
            Anchor(tip.rectTransform, new Vector2(1, 0), new Vector2(1, 0), new Vector2(-30, 24), new Vector2(600, 40));
            return group;
        }

        CanvasGroup BuildSelect(Transform root)
        {
            var go = NewRect(root, "HeroSelect");
            Stretch((RectTransform)go.transform);
            var group = go.AddComponent<CanvasGroup>();

            var title = NewText(go.transform, "Title", "选择角色", 58, Gold);
            Anchor(title.rectTransform, new Vector2(0.5f, 1), new Vector2(0.5f, 1), new Vector2(0, -72), new Vector2(800, 90));
            AddOutline(title);

            var back = NewButton(go.transform, "Back_Btn", "返回", 32, ShowHome);
            Anchor((RectTransform)back.transform, new Vector2(0, 1), new Vector2(0, 1), new Vector2(170, -72), new Vector2(240, 76));

            // 左边：角色列表
            var count = heroNames != null ? heroNames.Length : 0;
            entries = new Image[count];
            entryBars = new Image[count];
            entryNames = new Text[count];
            const float entryW = 400f, entryH = 108f, step = 124f;
            for (var i = 0; i < count; i++)
            {
                var index = i;
                var y = (count - 1) * step * 0.5f - i * step + 20f;

                var entry = NewImage(go.transform, "Hero_" + i, null, EntryIdle);
                entry.raycastTarget = true;     // 没有这一项按钮收不到点击
                Anchor(entry.rectTransform, new Vector2(0, 0.5f), new Vector2(0, 0.5f), new Vector2(70 + entryW * 0.5f, y), new Vector2(entryW, entryH));
                var btn = entry.gameObject.AddComponent<Button>();
                btn.targetGraphic = entry;
                btn.transition = Selectable.Transition.None;
                btn.onClick.AddListener(() => Select(index));
                entries[i] = entry;

                var bar = NewImage(entry.transform, "Bar", null, Gold);
                Anchor(bar.rectTransform, new Vector2(0, 0), new Vector2(0, 1), new Vector2(4, 0), new Vector2(8, 0));
                entryBars[i] = bar;

                var num = NewText(entry.transform, "Index", (i + 1).ToString("00"), 44, new Color(1f, 1f, 1f, 0.18f));
                num.alignment = TextAnchor.MiddleRight;
                Anchor(num.rectTransform, new Vector2(0, 0), new Vector2(1, 1), new Vector2(-22, 0), new Vector2(0, 0));
                num.rectTransform.offsetMin = new Vector2(0, 0);
                num.rectTransform.offsetMax = new Vector2(-22, 0);

                var nameText = NewText(entry.transform, "Name", heroNames[i], 38, Color.white);
                nameText.alignment = TextAnchor.MiddleLeft;
                Anchor(nameText.rectTransform, new Vector2(0, 0.5f), new Vector2(0, 0.5f), new Vector2(36 + 150, 14), new Vector2(300, 50));
                AddOutline(nameText);
                entryNames[i] = nameText;

                var sub = heroTitles != null && i < heroTitles.Length ? heroTitles[i] : "";
                var subText = NewText(entry.transform, "Title", sub, 22, SubBlue);
                subText.alignment = TextAnchor.MiddleLeft;
                Anchor(subText.rectTransform, new Vector2(0, 0.5f), new Vector2(0, 0.5f), new Vector2(36 + 150, -28), new Vector2(300, 34));
            }

            // 右边：角色信息
            var panel = NewImage(go.transform, "InfoPanel", null, new Color(0f, 0f, 0f, 0.45f));
            Anchor(panel.rectTransform, new Vector2(1, 0.5f), new Vector2(1, 0.5f), new Vector2(-340, 90), new Vector2(540, 400));
            var edge = panel.gameObject.AddComponent<Outline>();
            edge.effectColor = new Color(Gold.r, Gold.g, Gold.b, 0.35f);
            edge.effectDistance = new Vector2(2f, -2f);

            infoName = NewText(panel.transform, "Name", "", 64, Gold);
            Anchor(infoName.rectTransform, new Vector2(0.5f, 1), new Vector2(0.5f, 1), new Vector2(0, -62), new Vector2(500, 80));
            AddOutline(infoName);

            infoTitle = NewText(panel.transform, "Title", "", 28, SubBlue);
            Anchor(infoTitle.rectTransform, new Vector2(0.5f, 1), new Vector2(0.5f, 1), new Vector2(0, -122), new Vector2(500, 40));

            var line = NewImage(panel.transform, "Line", null, new Color(Gold.r, Gold.g, Gold.b, 0.4f));
            Anchor(line.rectTransform, new Vector2(0.5f, 1), new Vector2(0.5f, 1), new Vector2(0, -158), new Vector2(440, 2));

            var keys = NewText(panel.transform, "Controls",
                "WASD 移动    右键拖动 转镜头\nJ 普攻连招    U 重击\nK / 1 技能一    L / 2 技能二\nI / 3 大招", 26, new Color(1f, 1f, 1f, 0.85f));
            keys.lineSpacing = 1.3f;
            Anchor(keys.rectTransform, new Vector2(0.5f, 1), new Vector2(0.5f, 1), new Vector2(0, -260), new Vector2(500, 180));

            statusText = NewText(go.transform, "Status", "", 30, Color.white);
            Anchor(statusText.rectTransform, new Vector2(1, 0), new Vector2(1, 0), new Vector2(-340, 236), new Vector2(540, 50));
            AddOutline(statusText);

            var play = NewButton(go.transform, "Play_Btn", "开始游戏", 40, StartGame);
            Anchor((RectTransform)play.transform, new Vector2(1, 0), new Vector2(1, 0), new Vector2(-340, 150), new Vector2(480, 100));

            var help = NewText(go.transform, "Help", "↑↓ / ←→ 切换角色    拖动鼠标 旋转角色    Enter 开始    Esc 返回", 24, new Color(1f, 1f, 1f, 0.7f));
            Anchor(help.rectTransform, new Vector2(0.5f, 0), new Vector2(0.5f, 0), new Vector2(0, 40), new Vector2(1400, 40));
            AddOutline(help);
            return group;
        }

        // ---------- 交互 ----------

        public void ShowSelect()
        {
            if (loading) return;
            SetGroup(homeGroup, false);
            SetGroup(selectGroup, true);
            if (bgDim != null) bgDim.color = new Color(0f, 0f, 0f, 0.25f);
            if (stage != null) stage.gameObject.SetActive(true);
            Select(selected);
        }

        void ShowHome()
        {
            if (loading) return;
            SetGroup(selectGroup, false);
            SetGroup(homeGroup, true);
            if (bgDim != null) bgDim.color = new Color(0f, 0f, 0f, 0f);
            if (stage != null) stage.gameObject.SetActive(false);
        }

        public void Select(int index)
        {
            if (heroNames == null || heroNames.Length == 0) return;
            selected = Mathf.Clamp(index, 0, heroNames.Length - 1);
            for (var i = 0; i < entries.Length; i++)
            {
                var on = i == selected;
                entries[i].color = on ? EntrySelected : EntryIdle;
                entryBars[i].enabled = on;
                entryNames[i].color = on ? Gold : Color.white;
            }
            if (infoName != null) infoName.text = heroNames[selected];
            if (infoTitle != null) infoTitle.text = heroTitles != null && selected < heroTitles.Length ? heroTitles[selected] : "";
            ShowModel(selected);
        }

        void StartGame()
        {
            if (loading || heroNames == null || heroNames.Length == 0) return;
            loading = true;
            PortedSession.HeroIndex = selected;
            if (statusText != null) statusText.text = "正在进入……";
            StartCoroutine(LoadGame());
        }

        IEnumerator LoadGame()
        {
            yield return null; // 先让“正在进入”显示出来
            SceneManager.LoadScene(PortedSession.GameScene);
        }

        // ---------- 角色模型 ----------

        void ShowModel(int index)
        {
            if (stage == null) return;
            foreach (var kv in models)
                if (kv.Value != null) kv.Value.SetActive(kv.Key == index);

            currentModel = GetModel(index);
            currentAnimator = null;
            showHash = 0;
            if (currentModel == null) return;

            currentModel.SetActive(true);
            yaw = modelYaw;
            currentModel.transform.localRotation = Quaternion.Euler(0f, yaw, 0f);

            currentAnimator = FindBodyAnimator(currentModel);
            if (currentAnimator == null) return;
            currentAnimator.applyRootMotion = false;
            currentAnimator.cullingMode = AnimatorCullingMode.AlwaysAnimate;

            var show = FirstState(currentAnimator, ShowStates);
            var idle = FirstState(currentAnimator, IdleStates);
            if (show != 0)
            {
                currentAnimator.Play(show, 0, 0f);
                showHash = show;
                showStart = Time.unscaledTime;
            }
            else if (idle != 0)
            {
                currentAnimator.Play(idle, 0, 0f);
            }

            // 编辑器截图时动画不会自己走，手动采样一帧姿势
            if (!Application.isPlaying)
            {
                currentAnimator.Update(0f);
                currentAnimator.Update(0.6f);
            }
        }

        GameObject GetModel(int index)
        {
            if (models.TryGetValue(index, out var cached) && cached != null) return cached;
            if (heroPrefabs == null || index >= heroPrefabs.Length || heroPrefabs[index] == null) return null;

            // 在未激活的节点下生成，先关掉角色控制再激活：展示用不需要移动、重力和技能
            var holder = new GameObject("Hero_" + index);
            holder.SetActive(false);
            holder.transform.SetParent(stage, false);
            var go = Instantiate(heroPrefabs[index], holder.transform);
            go.transform.localPosition = Vector3.zero;
            go.transform.localRotation = Quaternion.identity;
            foreach (var hc in go.GetComponentsInChildren<HeroController>(true)) hc.enabled = false;
            foreach (var cc in go.GetComponentsInChildren<CharacterController>(true)) cc.enabled = false;
            holder.SetActive(true);
            models[index] = holder;
            return holder;
        }

        // 播完展示动作后回到待机
        void UpdateShowAnimation()
        {
            if (currentAnimator == null || showHash == 0) return;
            if (Time.unscaledTime - showStart < 0.2f) return;   // Play 要等下一帧才生效
            var st = currentAnimator.GetCurrentAnimatorStateInfo(0);
            if (currentAnimator.IsInTransition(0)) return;
            if (st.shortNameHash == showHash && st.normalizedTime < 0.95f) return;
            var idle = FirstState(currentAnimator, IdleStates);
            if (idle != 0 && st.shortNameHash != idle) currentAnimator.CrossFadeInFixedTime(idle, 0.25f);
            showHash = 0;
        }

        // 在空白处按住鼠标左键拖动，旋转模型
        void UpdateDrag(Mouse mouse)
        {
            if (mouse == null || currentModel == null) return;
            if (mouse.leftButton.wasPressedThisFrame)
                dragging = EventSystem.current == null || !EventSystem.current.IsPointerOverGameObject();
            if (!mouse.leftButton.isPressed) dragging = false;
            if (!dragging) return;
            yaw -= mouse.delta.ReadValue().x * dragSpeed;
            currentModel.transform.localRotation = Quaternion.Euler(0f, yaw, 0f);
        }

        // 和 HeroController 一样：身上可能还有表情 Animator，选带待机和攻击状态的那个
        static Animator FindBodyAnimator(GameObject root)
        {
            Animator fallback = null;
            foreach (var a in root.GetComponentsInChildren<Animator>(true))
            {
                if (a.runtimeAnimatorController == null) continue;
                if (!Application.isPlaying) a.Rebind();   // 编辑器截图时 Animator 还没初始化
                if (FirstState(a, IdleStates) == 0) continue;
                if (a.HasState(0, Animator.StringToHash("atk01"))) return a;
                if (fallback == null) fallback = a;
            }
            return fallback;
        }

        static int FirstState(Animator a, string[] names)
        {
            foreach (var n in names)
            {
                var h = Animator.StringToHash(n);
                if (a.HasState(0, h)) return h;
            }
            return 0;
        }

        // ---------- 工具 ----------

        // 竖向渐变：底部黑 0.75 → 顶部全透明
        static Sprite gradient;
        static Sprite GradientSprite()
        {
            if (gradient != null) return gradient;
            const int h = 64;
            var tex = new Texture2D(1, h, TextureFormat.RGBA32, false) { wrapMode = TextureWrapMode.Clamp, filterMode = FilterMode.Bilinear };
            for (var y = 0; y < h; y++)
            {
                var t = y / (h - 1f);
                tex.SetPixel(0, y, new Color(0f, 0f, 0f, 0.75f * (1f - t * t)));
            }
            tex.Apply();
            gradient = Sprite.Create(tex, new Rect(0, 0, 1, h), new Vector2(0.5f, 0.5f));
            return gradient;
        }

        // 圆形渐变，用作脚下的影子
        static Sprite radial;
        static Sprite RadialSprite()
        {
            if (radial != null) return radial;
            const int s = 64;
            var tex = new Texture2D(s, s, TextureFormat.RGBA32, false) { wrapMode = TextureWrapMode.Clamp, filterMode = FilterMode.Bilinear };
            for (var y = 0; y < s; y++)
                for (var x = 0; x < s; x++)
                {
                    var dx = (x + 0.5f) / s * 2f - 1f;
                    var dy = (y + 0.5f) / s * 2f - 1f;
                    var d = Mathf.Clamp01(Mathf.Sqrt(dx * dx + dy * dy));
                    tex.SetPixel(x, y, new Color(1f, 1f, 1f, (1f - d) * (1f - d)));
                }
            tex.Apply();
            radial = Sprite.Create(tex, new Rect(0, 0, s, s), new Vector2(0.5f, 0.5f), s);
            return radial;
        }

        static void SetupScaler(CanvasScaler scaler)
        {
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1920f, 1080f);
            scaler.matchWidthOrHeight = 0.5f;
        }

        static void SetGroup(CanvasGroup g, bool on)
        {
            if (g == null) return;
            g.alpha = on ? 1f : 0f;
            g.interactable = on;
            g.blocksRaycasts = on;
        }

        static void EnsureEventSystem()
        {
            if (FindFirstObjectByType<EventSystem>() != null) return;
            new GameObject("EventSystem", typeof(EventSystem), typeof(InputSystemUIInputModule));
        }

        static GameObject NewRect(Transform parent, string name)
        {
            var go = new GameObject(name, typeof(RectTransform));
            go.transform.SetParent(parent, false);
            return go;
        }

        static Image NewImage(Transform parent, string name, Sprite sprite, Color color)
        {
            var go = NewRect(parent, name);
            var img = go.AddComponent<Image>();
            img.sprite = sprite;
            img.color = color;
            img.raycastTarget = false;
            return img;
        }

        Text NewText(Transform parent, string name, string text, int size, Color color)
        {
            var go = NewRect(parent, name);
            var t = go.AddComponent<Text>();
            t.text = text;
            t.font = font;
            t.fontSize = size;
            t.color = color;
            t.alignment = TextAnchor.MiddleCenter;
            t.horizontalOverflow = HorizontalWrapMode.Overflow;
            t.verticalOverflow = VerticalWrapMode.Overflow;
            t.raycastTarget = false;
            return t;
        }

        GameObject NewButton(Transform parent, string name, string label, int fontSize, UnityEngine.Events.UnityAction onClick)
        {
            var img = NewImage(parent, name, button, Color.white);
            img.type = button != null && button.border != Vector4.zero ? Image.Type.Sliced : Image.Type.Simple;
            img.raycastTarget = true;
            if (button == null) img.color = new Color(0.16f, 0.36f, 0.62f, 0.95f);

            var btn = img.gameObject.AddComponent<Button>();
            btn.targetGraphic = img;
            var colors = btn.colors;
            colors.highlightedColor = new Color(1.15f, 1.15f, 1.15f);
            colors.pressedColor = new Color(0.75f, 0.75f, 0.75f);
            btn.colors = colors;
            btn.onClick.AddListener(onClick);

            var text = NewText(img.transform, "Label", label, fontSize, Color.white);
            Stretch(text.rectTransform);
            AddOutline(text);
            return img.gameObject;
        }

        static void AddOutline(Text t)
        {
            var o = t.gameObject.AddComponent<Outline>();
            o.effectColor = new Color(0f, 0f, 0f, 0.6f);
            o.effectDistance = new Vector2(2f, -2f);
        }

        static void Stretch(RectTransform rt)
        {
            rt.anchorMin = Vector2.zero;
            rt.anchorMax = Vector2.one;
            rt.offsetMin = Vector2.zero;
            rt.offsetMax = Vector2.zero;
        }

        static void Anchor(RectTransform rt, Vector2 min, Vector2 max, Vector2 pos, Vector2 size)
        {
            rt.anchorMin = min;
            rt.anchorMax = max;
            rt.anchoredPosition = pos;
            rt.sizeDelta = size;
        }
    }
}

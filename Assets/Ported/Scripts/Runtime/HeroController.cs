using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;

namespace Ported
{
    // 角色控制：WASD 移动（相对相机），Shift 加速跑，左 Ctrl 闪避，空格跳跃，J 连招，U 重击，K/L 技能，I 大招。
    // 技能按原项目的动作配置（HeroActionSet）执行：特效挂点和出现时间、伤害框、子弹、位移、动画变速。
    // 移植来的 Animator Controller 没有参数，状态切换靠 CrossFade 直接按状态名播放。
    [RequireComponent(typeof(CharacterController))]
    public class HeroController : MonoBehaviour
    {
        public HeroActionSet actions;
        public float moveSpeed = 5.5f;
        public float turnSpeed = 14f;
        public float baseDamage = 10f;

        [Tooltip("按顺序取第一个存在的状态")]
        public string[] idleStates = { "idle", "idle_f" };
        public string[] runStates = { "run_R", "run_f", "run", "walk" };
        // 移动分三档：run（默认）、dash（按住 Shift）、rush（按住 Shift 持续移动 rushDelay 秒后）。
        // 某一档的动画找不到时，退回低一档
        [Tooltip("dash 动画，按顺序取第一个存在的状态")]
        public string[] dashStates = { "dash_R", "dash_f", "dash_L", "dash" };
        [Tooltip("dash 的速度倍率")]
        public float dashMultiplier = 1.35f;
        [Tooltip("rush 动画，按顺序取第一个存在的状态")]
        public string[] rushStates = { "rush_R", "rush_f", "rush_L", "rush" };
        [Tooltip("rush 的速度倍率")]
        public float rushMultiplier = 1.8f;
        [Tooltip("按住 Shift 持续移动多少秒后从 dash 升到 rush")]
        public float rushDelay = 1.5f;
        public string[] jumpStartStates = { "jump_start", "jump_start_f" };
        public string[] jumpLoopStates = { "jump_loop", "jump_loop_f" };
        public string[] jumpEndStates = { "jump_end", "jump_end_f" };

        [Tooltip("起跳初速度（米/秒），重力 -20 时约跳 1.6 米")]
        public float jumpSpeed = 8f;
        [Tooltip("落地后播放落地动画的时间，期间开始移动会直接打断")]
        public float landTime = 0.2f;

        [Tooltip("闪避位移距离（米）")]
        public float dodgeDistance = 4f;
        [Tooltip("闪避持续时间（秒），期间不能放技能和起跳")]
        public float dodgeDuration = 0.25f;
        [Tooltip("闪避结束后到下次能闪避的间隔（秒）")]
        public float dodgeCooldown = 0.8f;

        public Transform cameraTransform;
        public bool inputEnabled = true;

        public Key comboKey = Key.J;
        public Key heavyKey = Key.U;
        public Key skill1Key = Key.K;
        public Key skill2Key = Key.L;
        public Key ultimateKey = Key.I;
        public Key jumpKey = Key.Space;
        public Key sprintKey = Key.LeftShift;
        public Key dodgeKey = Key.LeftCtrl;

        const float Gravity = -20f;

        CharacterController controller;
        Animator animator;
        float verticalSpeed;
        int currentLoop;
        bool jumping;
        float landTimer;
        bool currentRepeats = true;
        float sprintTime;
        float dodgeTimer;
        float dodgeCooldownTimer;
        Vector3 dodgeDir;

        // 当前动作
        ActionData current;
        float actionTime;
        bool comboQueued;
        readonly List<SpawnedFx> liveFx = new List<SpawnedFx>();
        readonly List<ActiveMove> moves = new List<ActiveMove>();
        readonly Dictionary<HitEvent, Dictionary<Damageable, HitRecord>> hitLog = new Dictionary<HitEvent, Dictionary<Damageable, HitRecord>>();
        readonly HashSet<object> fired = new HashSet<object>();
        readonly Dictionary<string, Transform> socketCache = new Dictionary<string, Transform>();

        struct SpawnedFx { public GameObject go; public FxEvent ev; }
        class ActiveMove { public MoveEvent ev; public float elapsed; }
        class HitRecord { public int count; public float last; }

        public bool IsCasting => current != null;
        public string LastSkill { get; private set; } = "";

        void Awake()
        {
            controller = GetComponent<CharacterController>();
            animator = FindBodyAnimator();
            PortedBlobShadow.Register(gameObject);
            if (animator != null)
            {
                animator.applyRootMotion = false;
                animator.cullingMode = AnimatorCullingMode.AlwaysAnimate;
            }
        }

        void OnDestroy()
        {
            PortedBlobShadow.Unregister(gameObject);
        }

        void Start()
        {
            // 技能数据丢了的话按键会全部无效，这里直接报出来
            if (actions == null) Debug.LogError($"[Ported] {name} 没有技能数据（HeroController.actions 为空），重新执行 Tools/Ported/Build All");
            PlayLoop(idleStates);
        }

        void Update()
        {
            var kb = inputEnabled ? Keyboard.current : null;
            var moveInput = kb != null ? ReadMove(kb) : Vector2.zero;

            if (dodgeCooldownTimer > 0f) dodgeCooldownTimer -= Time.deltaTime;
            var dodging = dodgeTimer > 0f;

            // 空中和闪避期间不能放技能，落地、闪避结束后才行
            if (kb != null && !jumping && !dodging && actions != null && animator != null) HandleSkillInput(kb, moveInput);
            if (kb != null && !jumping && !dodging && current == null && controller.isGrounded)
            {
                if (kb[dodgeKey].wasPressedThisFrame && dodgeCooldownTimer <= 0f) StartDodge(moveInput);
                else if (kb[jumpKey].wasPressedThisFrame) StartJump();
            }
            if (current != null) TickAction(Time.deltaTime);
            var sprint = kb != null && (kb[sprintKey].isPressed || kb.rightShiftKey.isPressed);
            HandleMove(moveInput, sprint);
        }

        // ---------- 输入 ----------

        static Vector2 ReadMove(Keyboard kb)
        {
            var input = Vector2.zero;
            if (kb.wKey.isPressed || kb.upArrowKey.isPressed) input.y += 1f;
            if (kb.sKey.isPressed || kb.downArrowKey.isPressed) input.y -= 1f;
            if (kb.dKey.isPressed || kb.rightArrowKey.isPressed) input.x += 1f;
            if (kb.aKey.isPressed || kb.leftArrowKey.isPressed) input.x -= 1f;
            return Vector2.ClampMagnitude(input, 1f);
        }

        void HandleSkillInput(Keyboard kb, Vector2 moveInput)
        {
            var canBreak = current == null || actionTime >= current.breakTime;

            if (kb[comboKey].wasPressedThisFrame)
            {
                if (current != null && IsCombo(current) && current.nextId != 0 && actionTime <= current.comboEnd)
                {
                    // 连招窗口之前按下先记着，到窗口开始时接下一段
                    comboQueued = true;
                }
                else if (canBreak)
                {
                    StartAction(actions.combo.Length > 0 ? actions.combo[0] : null, moveInput);
                    return;
                }
            }

            if (canBreak)
            {
                // 数字键 1/2/3 也可以放技能1/技能2/大招
                if (kb[heavyKey].wasPressedThisFrame) StartAction(actions.heavy, moveInput);
                else if (kb[skill1Key].wasPressedThisFrame || kb.digit1Key.wasPressedThisFrame) StartAction(actions.skill1, moveInput);
                else if (kb[skill2Key].wasPressedThisFrame || kb.digit2Key.wasPressedThisFrame) StartAction(actions.skill2, moveInput);
                else if (kb[ultimateKey].wasPressedThisFrame || kb.digit3Key.wasPressedThisFrame) StartAction(actions.ultimate, moveInput);
                else if (current != null && moveInput.sqrMagnitude > 0.01f) EndAction();
            }
        }

        bool IsCombo(ActionData a)
        {
            foreach (var c in actions.combo)
                if (c == a) return true;
            return false;
        }

        // ---------- 移动 ----------

        Vector3 CameraRelative(Vector2 input)
        {
            var forward = Vector3.forward;
            var right = Vector3.right;
            if (cameraTransform != null)
            {
                forward = Vector3.ProjectOnPlane(cameraTransform.forward, Vector3.up).normalized;
                right = Vector3.ProjectOnPlane(cameraTransform.right, Vector3.up).normalized;
            }
            return forward * input.y + right * input.x;
        }

        void HandleMove(Vector2 input, bool sprint)
        {
            var dodging = dodgeTimer > 0f;
            var move = Vector3.zero;
            if (dodging)
            {
                // 闪避期间沿起冲方向匀速前进，不受方向键影响
                move = dodgeDir;
                dodgeTimer -= Time.deltaTime;
                if (dodgeTimer <= 0f) dodgeCooldownTimer = dodgeCooldown;
            }
            else if (current == null && input.sqrMagnitude > 0.01f)
            {
                move = CameraRelative(input);
                if (move.sqrMagnitude > 0.001f)
                    transform.rotation = Quaternion.Slerp(transform.rotation, Quaternion.LookRotation(move), turnSpeed * Time.deltaTime);
            }

            if (jumping)
            {
                verticalSpeed += Gravity * Time.deltaTime;
                // 起跳那一帧还贴着地面，等开始下落后再检测落地
                if (verticalSpeed <= 0f && controller.isGrounded) Land();
            }
            else
            {
                verticalSpeed = controller.isGrounded ? -1f : verticalSpeed + Gravity * Time.deltaTime;
            }
            // 档位：闪避期间固定 rush；其余按 Shift 按住并移动的时长决定。松开 Shift 或停下就回到 run
            var moving = move.sqrMagnitude > 0.01f;
            if (!dodging) sprintTime = sprint && moving ? sprintTime + Time.deltaTime : 0f;
            var rushing = dodging || sprintTime >= rushDelay;
            var dashing = !rushing && sprintTime > 0f;

            var speed = dodging ? dodgeDistance / Mathf.Max(0.05f, dodgeDuration)
                : rushing ? moveSpeed * rushMultiplier
                : dashing ? moveSpeed * dashMultiplier
                : moveSpeed;
            var velocity = move * speed;
            velocity.y = verticalSpeed;
            controller.Move(velocity * Time.deltaTime);

            if (current != null) return;
            if (landTimer > 0f && move.sqrMagnitude > 0.01f) landTimer = 0f;

            if (jumping)
            {
                if (verticalSpeed > 0f) PlayLoop(jumpStartStates, false);
                else PlayLoop(jumpLoopStates);
            }
            else if (landTimer > 0f) { landTimer -= Time.deltaTime; PlayLoop(jumpEndStates, false); }
            else if (moving)
            {
                // 没有对应档位的动画就退回低一档
                var played = rushing && PlayLoop(rushStates);
                if (!played && (rushing || dashing)) played = PlayLoop(dashStates);
                if (!played) PlayLoop(runStates);
            }
            else PlayLoop(idleStates);

            RepeatLoopIfFinished();
        }

        // 没有专门的翻滚动画，闪避用加速跑动画加一段短距离位移
        void StartDodge(Vector2 moveInput)
        {
            var dir = moveInput.sqrMagnitude > 0.01f ? CameraRelative(moveInput) : transform.forward;
            dir = Vector3.ProjectOnPlane(dir, Vector3.up);
            if (dir.sqrMagnitude < 0.001f) dir = transform.forward;
            dodgeDir = dir.normalized;
            transform.rotation = Quaternion.LookRotation(dodgeDir);
            dodgeTimer = dodgeDuration;
            landTimer = 0f;
        }

        void StartJump()
        {
            jumping = true;
            landTimer = 0f;
            verticalSpeed = jumpSpeed;
        }

        void Land()
        {
            jumping = false;
            verticalSpeed = -1f;
            landTimer = landTime;
        }

        // ---------- 动作 ----------

        void StartAction(ActionData a, Vector2 moveInput)
        {
            if (a == null || !a.IsValid) return;
            if (!Has(a.clip))
            {
                Debug.LogWarning($"[Ported] {name} 没有动画状态 {a.clip}");
                return;
            }

            if (current != null) EndAction();

            // 释放时朝向摇杆方向，和原项目 IsFaceTo 一致
            if (moveInput.sqrMagnitude > 0.01f)
            {
                var dir = CameraRelative(moveInput);
                if (dir.sqrMagnitude > 0.001f) transform.rotation = Quaternion.LookRotation(dir);
            }

            current = a;
            actionTime = 0f;
            landTimer = 0f;
            comboQueued = false;
            fired.Clear();
            hitLog.Clear();
            moves.Clear();
            currentLoop = 0;
            LastSkill = a.clip;
            animator.speed = 1f;
            animator.CrossFadeInFixedTime(Animator.StringToHash(a.clip), 0.05f, 0, 0f);
            TickAction(0f);
        }

        void TickAction(float dt)
        {
            var a = current;
            var speed = SpeedAt(a, actionTime);
            animator.speed = speed;
            var prev = actionTime;
            actionTime += dt * speed;
            var t = actionTime;

            foreach (var fx in a.fx)
                if (t >= fx.start && fired.Add(fx)) SpawnFx(fx);

            foreach (var b in a.bullets)
                if (t >= b.start && fired.Add(b)) PortedBullet.Fire(actions, b.emitter, transform, transform);

            foreach (var m in a.moves)
                if (t >= m.start && fired.Add(m)) moves.Add(new ActiveMove { ev = m });
            ApplyMoves(dt * speed);

            foreach (var h in a.hits)
                // 伤害框只要和这一帧的时间段有交集就判定，避免很短的框被跳过
                if (h.end >= prev && h.start <= t) CheckHit(h);

            if (comboQueued && a.nextId != 0 && t >= a.comboStart)
            {
                var next = actions.FindCombo(a.nextId);
                if (next != null)
                {
                    StartAction(next, Vector2.zero);
                    return;
                }
            }

            if (t >= a.duration) EndAction();
        }

        static float SpeedAt(ActionData a, float t)
        {
            foreach (var s in a.speeds)
                if (t >= s.start && t < s.end) return Mathf.Max(0.05f, s.speed);
            return 1f;
        }

        void ApplyMoves(float dt)
        {
            for (var i = moves.Count - 1; i >= 0; i--)
            {
                var m = moves[i];
                var step = Mathf.Min(dt, m.ev.time - m.elapsed);
                if (step > 0f) controller.Move(transform.TransformDirection(m.ev.dir) * (step / Mathf.Max(0.001f, m.ev.time)));
                m.elapsed += dt;
                if (m.elapsed >= m.ev.time) moves.RemoveAt(i);
            }
        }

        void EndAction()
        {
            if (current == null) return;
            foreach (var s in liveFx) PortedFx.Stop(this, s.go, s.ev.disappear, s.ev.softDel);
            liveFx.Clear();
            moves.Clear();
            current = null;
            comboQueued = false;
            animator.speed = 1f;
            currentLoop = 0;
            PlayLoop(idleStates);
        }

        // ---------- 特效 ----------

        void SpawnFx(FxEvent ev)
        {
            var go = PortedFx.SpawnEvent(ev, GetSocket(ev.socket));
            if (go == null) return;
            Destroy(go, Mathf.Max(0.1f, ev.end - ev.start));
            liveFx.Add(new SpawnedFx { go = go, ev = ev });
        }

        Transform GetSocket(string socket)
        {
            if (string.IsNullOrEmpty(socket)) return transform;
            if (socketCache.TryGetValue(socket, out var cached) && cached != null) return cached;
            var result = PortedFx.ResolveSocket(transform, actions, socket);
            socketCache[socket] = result;
            return result;
        }

        // ---------- 伤害 ----------

        void CheckHit(HitEvent h)
        {
            var center = transform.TransformPoint(h.pos);
            var rot = transform.rotation * Quaternion.Euler(h.rot);
            Collider[] cols;
            if (h.shape == 3)
            {
                var half = Mathf.Max(0f, h.height * 0.5f - h.radius);
                var up = rot * Vector3.up;
                cols = Physics.OverlapCapsule(center - up * half, center + up * half, h.radius, ~0, QueryTriggerInteraction.Ignore);
            }
            else
            {
                cols = Physics.OverlapBox(center, h.size * 0.5f, rot, ~0, QueryTriggerInteraction.Ignore);
            }

            if (!hitLog.TryGetValue(h, out var log)) hitLog[h] = log = new Dictionary<Damageable, HitRecord>();

            foreach (var c in cols)
            {
                var target = c.GetComponentInParent<Damageable>();
                if (target == null || target.transform.IsChildOf(transform)) continue;

                if (!log.TryGetValue(target, out var rec)) log[target] = rec = new HitRecord { last = -999f };
                if (rec.count >= Mathf.Max(1, h.maxHits)) continue;
                if (actionTime - rec.last < h.interval) continue;
                rec.count++;
                rec.last = actionTime;

                target.TakeDamage(baseDamage * Mathf.Max(0.1f, h.damageMul), transform.position);
                if (h.hitFxPrefab != null)
                {
                    var p = target.transform.position + Vector3.up;
                    var fx = PortedFx.Spawn(h.hitFxPrefab, p, Quaternion.LookRotation(transform.position - target.transform.position + Vector3.up * 0.01f));
                    fx.transform.localScale = Vector3.one * h.hitFxScale;
                    Destroy(fx, 2f);
                }
            }
        }

        // ---------- 动画 ----------

        // repeat=false 用于起跳和落地这类只播一次的动画
        // 返回 true 表示候选里有可用的状态（不论是否刚切换过来）
        bool PlayLoop(string[] candidates, bool repeat = true)
        {
            if (animator == null || candidates == null) return false;
            foreach (var c in candidates)
            {
                if (!Has(c)) continue;
                var hash = Animator.StringToHash(c);
                currentRepeats = repeat;
                if (hash == currentLoop) return true;
                currentLoop = hash;
                animator.CrossFadeInFixedTime(hash, 0.12f);
                return true;
            }
            return false;
        }

        // 移植来的跑步、跳跃动画片段没有开 loopTime，播完一遍会停在最后一帧，角色看起来就是在滑动。
        // 这里在循环状态播完后重新衔接一遍
        void RepeatLoopIfFinished()
        {
            if (animator == null || !currentRepeats || currentLoop == 0 || animator.IsInTransition(0)) return;
            var info = animator.GetCurrentAnimatorStateInfo(0);
            if (info.shortNameHash != currentLoop || info.loop || info.normalizedTime < 1f) return;
            animator.CrossFadeInFixedTime(currentLoop, 0.1f, 0, 0f);
        }

        // 角色身上除了身体的 Animator，还有脸部表情（emo_*.controller）等 Animator，要选带待机和攻击状态的那个
        Animator FindBodyAnimator()
        {
            Animator fallback = null;
            foreach (var a in GetComponentsInChildren<Animator>(true))
            {
                if (a.runtimeAnimatorController == null) continue;
                var hasIdle = false;
                foreach (var s in idleStates) hasIdle |= a.HasState(0, Animator.StringToHash(s));
                if (!hasIdle) continue;
                if (a.HasState(0, Animator.StringToHash("atk01"))) return a;
                if (fallback == null) fallback = a;
            }
            if (fallback == null) Debug.LogWarning($"[Ported] {name} 没找到带 idle 状态的 Animator");
            return fallback;
        }

        bool Has(string state)
        {
            return animator != null && !string.IsNullOrEmpty(state) && animator.HasState(0, Animator.StringToHash(state));
        }

        void OnDrawGizmosSelected()
        {
            if (current == null) return;
            Gizmos.color = Color.red;
            foreach (var h in current.hits)
            {
                if (actionTime < h.start || actionTime > h.end) continue;
                Gizmos.matrix = Matrix4x4.TRS(transform.TransformPoint(h.pos), transform.rotation * Quaternion.Euler(h.rot), Vector3.one);
                if (h.shape == 3) Gizmos.DrawWireSphere(Vector3.zero, h.radius);
                else Gizmos.DrawWireCube(Vector3.zero, h.size);
            }
            Gizmos.matrix = Matrix4x4.identity;
        }
    }
}

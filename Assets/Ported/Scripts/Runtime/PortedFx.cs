using System.Collections;
using UnityEngine;

namespace Ported
{
    // 特效实例的生成和回收，对应原项目 VFXManager / EffectDefine 里用到的几条规则
    public static class PortedFx
    {
        static readonly int AlphaMulId = Shader.PropertyToID("_AlphaMultiplyer");

        public static GameObject Spawn(GameObject prefab, Vector3 position, Quaternion rotation, Transform parent = null)
        {
            if (prefab == null) return null;
            var go = Object.Instantiate(prefab, position, rotation, parent);
            ApplyHighQuality(go.transform);
            return go;
        }

        // 原项目的 FxQualitySetting：特效根下 root/h、root/m、root/l 是三档质量，只保留高档
        public static void ApplyHighQuality(Transform fx)
        {
            var root = FindDeep(fx, "root");
            if (root == null) return;

            Transform high = null;
            foreach (Transform c in root)
                if (c.name.ToLowerInvariant() == "h") high = c;
            if (high == null) return;

            foreach (Transform c in root)
            {
                var n = c.name.ToLowerInvariant();
                if (n == "h") c.gameObject.SetActive(true);
                else if (n == "m" || n == "l") c.gameObject.SetActive(false);
            }
        }

        public static void SetSpeed(GameObject fx, float speed)
        {
            if (fx == null || Mathf.Approximately(speed, 1f)) return;
            foreach (var ps in fx.GetComponentsInChildren<ParticleSystem>(true))
            {
                var main = ps.main;
                main.simulationSpeed *= speed;
            }
            foreach (var a in fx.GetComponentsInChildren<Animator>(true)) a.speed *= speed;
        }

        // 动作切换时停掉特效：立即删除，或者在 softDel 秒内把透明度降到 0 再删
        public static void Stop(MonoBehaviour host, GameObject fx, int disappear, float softDel)
        {
            if (fx == null) return;
            if (disappear == 2) return;
            if (disappear == 1 || softDel <= 0.01f || !host.isActiveAndEnabled)
            {
                Object.Destroy(fx);
                return;
            }
            host.StartCoroutine(FadeOut(fx, softDel));
        }

        static IEnumerator FadeOut(GameObject fx, float time)
        {
            foreach (var ps in fx.GetComponentsInChildren<ParticleSystem>(true))
                ps.Stop(false, ParticleSystemStopBehavior.StopEmitting);

            var renderers = fx.GetComponentsInChildren<Renderer>(true);
            var block = new MaterialPropertyBlock();
            var t = 0f;
            while (t < time && fx != null)
            {
                t += Time.deltaTime;
                var a = 1f - t / time;
                foreach (var r in renderers)
                {
                    if (r == null) continue;
                    r.GetPropertyBlock(block);
                    block.SetFloat(AlphaMulId, a);
                    r.SetPropertyBlock(block);
                }
                yield return null;
            }
            if (fx != null) Object.Destroy(fx);
        }

        // 原项目的挂点：先查角色配置里的 SocketDic（挂点名 -> 骨骼名 + 偏移），再按名字直接找节点，都没有就用角色根节点
        public static Transform ResolveSocket(Transform root, HeroActionSet set, string socket)
        {
            if (string.IsNullOrEmpty(socket)) return root;

            SocketData data = null;
            if (set != null)
                foreach (var s in set.sockets)
                    if (s.name == socket) data = s;

            if (data != null)
            {
                var bone = string.IsNullOrEmpty(data.bone) ? root : FindDeep(root, data.bone);
                if (bone != null)
                {
                    if (data.pos == Vector3.zero && data.rot == Vector3.zero) return bone;
                    var nodeName = "socket_" + socket;
                    var node = bone.Find(nodeName);
                    if (node == null)
                    {
                        node = new GameObject(nodeName).transform;
                        node.SetParent(bone, false);
                        node.localPosition = data.pos;
                        node.localEulerAngles = data.rot;
                    }
                    return node;
                }
            }

            var direct = FindDeep(root, socket);
            if (direct != null) return direct;
            Debug.LogWarning($"[Ported] {root.name} 找不到挂点 {socket}，用角色根节点");
            return root;
        }

        // 按配置把特效摆到挂点上；不跟随的特效摆好后脱离父节点，缩放保持配置值
        public static GameObject SpawnEvent(FxEvent ev, Transform socket)
        {
            if (ev.prefab == null) return null;
            var go = Spawn(ev.prefab, socket.position, socket.rotation, socket);
            var tr = go.transform;
            tr.localPosition = ev.pos;
            tr.localEulerAngles = ev.rot;
            tr.localScale = ev.scale;
            if (!ev.follow)
            {
                tr.SetParent(null, true);
                tr.localScale = ev.scale;
            }
            SetSpeed(go, ev.speed);
            return go;
        }

        public static Transform FindDeep(Transform root, string name)
        {
            if (root == null || string.IsNullOrEmpty(name)) return null;
            foreach (var t in root.GetComponentsInChildren<Transform>(true))
                if (t.name == name) return t;
            return null;
        }
    }
}

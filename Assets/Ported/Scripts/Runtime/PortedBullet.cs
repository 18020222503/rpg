using System.Collections.Generic;
using UnityEngine;

namespace Ported
{
    // 原项目子弹（Emitter 配置）的简化版：直线飞行，带加速度和速度上下限，
    // 命中/时间到/销毁时按配置再发射子发射器。抛物线、追踪、地面检测都没有做。
    public class PortedBullet : MonoBehaviour
    {
        const float HitRadius = 0.6f;
        const float Damage = 10f;

        HeroActionSet set;
        EmitterData data;
        Transform owner;
        float speed;
        float age;
        int depth;
        bool done;
        readonly HashSet<Damageable> hitTargets = new HashSet<Damageable>();

        public static void Fire(HeroActionSet set, int emitterId, Transform origin, Transform owner, int depth = 0)
        {
            if (set == null || depth > 4) return;
            var data = set.FindEmitter(emitterId);
            if (data == null) return;

            var mouths = Mathf.Max(1, data.mouths);
            for (var i = 0; i < mouths; i++)
            {
                // 多个发射口时在 range 角度内均匀散开
                var spread = mouths > 1 ? Mathf.Lerp(-data.range * 0.5f, data.range * 0.5f, i / (float)(mouths - 1)) : 0f;
                var rot = origin.rotation * Quaternion.Euler(data.rot) * Quaternion.Euler(0f, spread, 0f);
                var pos = origin.TransformPoint(data.pos);

                var go = new GameObject("Bullet_" + data.id);
                go.transform.SetPositionAndRotation(pos, rot);
                var b = go.AddComponent<PortedBullet>();
                b.set = set;
                b.data = data;
                b.owner = owner;
                b.speed = data.speed;
                b.depth = depth;

                if (data.assetPrefab != null)
                {
                    var fx = PortedFx.Spawn(data.assetPrefab, pos, rot, go.transform);
                    fx.transform.localPosition = data.assetPos;
                    fx.transform.localRotation = Quaternion.Euler(data.assetRot);
                    fx.transform.localScale = Vector3.one * data.assetScale;
                }
            }
        }

        void Update()
        {
            if (done) return;
            var dt = Time.deltaTime;
            age += dt;

            speed = Mathf.Clamp(speed + data.accel * dt, Mathf.Min(data.minSpeed, data.speed), Mathf.Max(data.maxSpeed, data.speed));
            transform.position += transform.forward * speed * dt;

            foreach (var c in Physics.OverlapSphere(transform.position, HitRadius, ~0, QueryTriggerInteraction.Ignore))
            {
                var target = c.GetComponentInParent<Damageable>();
                if (target == null || hitTargets.Contains(target)) continue;
                if (owner != null && target.transform.IsChildOf(owner)) continue;

                hitTargets.Add(target);
                target.TakeDamage(Damage, transform.position);
                if (data.hurtFxPrefab != null)
                {
                    var fx = PortedFx.Spawn(data.hurtFxPrefab, target.transform.position + Vector3.up, Quaternion.LookRotation(-transform.forward));
                    fx.transform.localScale = Vector3.one * data.hurtFxScale;
                    Destroy(fx, 2f);
                }
                Trigger(2);
                if (!data.penetrate) { Finish(); return; }
            }

            if (age >= Mathf.Max(0.02f, data.life))
            {
                Trigger(1);
                Finish();
            }
        }

        void Finish()
        {
            if (done) return;
            done = true;
            Trigger(6);
            // 子弹特效里常有拖尾，留一会儿再删
            foreach (var ps in GetComponentsInChildren<ParticleSystem>()) ps.Stop(true, ParticleSystemStopBehavior.StopEmitting);
            Destroy(gameObject, 0.5f);
        }

        void Trigger(int trigger)
        {
            if (data.children == null) return;
            foreach (var c in data.children)
            {
                if (c.trigger != trigger) continue;
                Fire(set, c.emitter, transform, owner, depth + 1);
            }
        }
    }
}

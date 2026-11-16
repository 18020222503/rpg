using System.Collections;
using UnityEngine;

namespace Ported
{
    // 受击目标：扣血、闪白、被推开一点，血量归零后恢复，方便反复练技能
    public class Damageable : MonoBehaviour
    {
        public float maxHp = 200f;
        public float hp = 200f;

        static readonly int BaseColorId = Shader.PropertyToID("_BaseColor");

        Renderer[] renderers;
        MaterialPropertyBlock block;
        Coroutine flash;

        void Awake()
        {
            hp = maxHp;
            renderers = GetComponentsInChildren<Renderer>();
            block = new MaterialPropertyBlock();
        }

        public void TakeDamage(float amount, Vector3 from)
        {
            hp -= amount;
            Debug.Log($"[Ported] {name} 受到 {amount} 点伤害，剩余 {Mathf.Max(hp, 0f)}/{maxHp}");

            var push = transform.position - from;
            push.y = 0f;
            if (push.sqrMagnitude > 0.001f) transform.position += push.normalized * 0.3f;

            if (flash != null) StopCoroutine(flash);
            flash = StartCoroutine(Flash());

            if (hp <= 0f) hp = maxHp;
        }

        IEnumerator Flash()
        {
            Paint(Color.white);
            yield return new WaitForSeconds(0.08f);
            Paint(null);
            flash = null;
        }

        void Paint(Color? color)
        {
            foreach (var r in renderers)
            {
                if (r == null) continue;
                if (color.HasValue)
                {
                    r.GetPropertyBlock(block);
                    block.SetColor(BaseColorId, color.Value);
                    r.SetPropertyBlock(block);
                }
                else
                {
                    r.SetPropertyBlock(null);
                }
            }
        }
    }
}

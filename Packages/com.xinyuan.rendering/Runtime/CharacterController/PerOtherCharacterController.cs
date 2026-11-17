using System.Collections.Generic;
using UnityEngine;

namespace XYRendering.Runtime
{
    // qq13 PerOtherCharacterController（怪物用）的精简移植：
    // 保留原序列化字段，只做 alphaValue 为 0 时隐藏。
    // 原来的描边距离剔除、屏占比 LOD、Slime 质量分级都依赖自研 LOD/状态系统，没有移植。
    [ExecuteAlways]
    [DisallowMultipleComponent]
    public class PerOtherCharacterController : MonoBehaviour
    {
        public Material outlineBloomMat;
        public bool perCharTransparentState = false;
        [Range(0f, 1f)] public float alphaValue = 1;
        [Range(0, 1)] public float perCharFogeffect = 0;
        public bool perCharacterShadowCasterOff = false;

        readonly List<Renderer> _renderers = new List<Renderer>();

        void OnEnable()
        {
            RefreshRenderers();
        }

        public void RefreshRenderers()
        {
            PerCharacterRenderController.CollectCharacterRenderers(transform, _renderers);
        }

        void LateUpdate()
        {
            bool visible = alphaValue > 0;
            foreach (var r in _renderers)
                if (r != null) r.enabled = visible;
        }
    }
}

using System;
using System.Collections.Generic;
using UnityEngine;

namespace XYRendering.Runtime
{
    // qq13 PerCharacterRenderController 的精简移植：
    // 保留原序列化字段（prefab 数据不丢），只做 ToonCharacter 需要的逐角色参数传递。
    // 去掉了 LOD、阴影 GO、XYBrain 状态机、AllInOneRendererFeature 注册等依赖。
    [ExecuteAlways]
    [DisallowMultipleComponent]
    public class PerCharacterRenderController : MonoBehaviour
    {
        public enum TransformDirection { X, Y, Z, negX, negY, negZ }

        [Serializable]
        public class PerCharSetup
        {
            [Tooltip("头部骨骼，空时按 Bip001 Head 查找")] public Transform headBoneTransform;
            public TransformDirection faceTransForwardDirection = TransformDirection.Y;
            public TransformDirection faceTransUpDirection = TransformDirection.negX;
            [Tooltip("角色高度，0 时按 Renderer 包围盒计算")] public float characterHeright = 0;
            public bool showfaceTransForwardDirectionGizmo = true;
            public float characterBoundRadius = 1;
            public Vector3 characterBoundOffset;
            public bool showBoundingSphereGizmo = false;
            public bool showBoundingSphereGizmoTest;
        }

        [Serializable]
        public class PerCharBlush
        {
            public bool NeedUpdateBlendShape = false;
            public GameObject BlendShapeObject;
            public string[] BlushNameR;
            public Color BlushRColor;
            public string[] BlushNameG;
            public Color BlushGColor;
            public string[] BlushNameB;
            public Color BlushBColor;
            public Vector4 BlushParams;
        }

        // ===== 原 PerCharacterInterface / PerCharacterRootController 的字段 =====
        public Material outlineBloomMat;
        public bool perCharTransparentState = false;
        [Range(0f, 1f)] public float alphaValue = 1;
        [Range(0, 1)] public float perCharFogeffect = 0;
        public bool perCharacterShadowCasterOff = false;
        public bool useEmission = false;
        [ColorUsage(true, true)] public Color emissionColor = Color.white;
        public bool useFresnelRamp = false;
        public Vector4 fresnelRampParams = new Vector4(0, 0, -2, 0);
        [HideInInspector] public bool manualUpdateSpaceInfo = false;

        // ===== 原 PerCharacterRenderController 的字段 =====
        public PerCharSetup perCharSetup = new PerCharSetup();
        public PerCharBlush perCharBlush = new PerCharBlush();
        public bool cameraLightOn = false;
        public Quaternion targetAngels;
        [Range(0, 1)] public float perCharLightIntensity = 1;
        [Range(0, 1)] public float perspectiveRemovalAmount = 0;
        public float perspectiveRemovalRadius = 1;
        public bool enableTransparent = false;
        [Range(0f, 1f)] public float transparentAlpha = 0.5f;

        const string CharacterShaderPrefix = "XinYuan/Character/";
        const string DefaultHeadBoneName = "Bip001 Head";

        static readonly int _PerspectiveRemovalAmount = Shader.PropertyToID("_PerspectiveRemovalAmount");
        static readonly int _PerspectiveRemovalRadius = Shader.PropertyToID("_PerspectiveRemovalRadius");
        static readonly int _HeadBonePositionWS = Shader.PropertyToID("_HeadBonePositionWS");
        static readonly int _FaceForwardDirection = Shader.PropertyToID("_FaceForwardDirection");
        static readonly int _FaceUpDirection = Shader.PropertyToID("_FaceUpDirection");
        static readonly int _CharacterHeight = Shader.PropertyToID("_CharacterHeight");
        static readonly int _BlushParams = Shader.PropertyToID("_BlushParams");
        static readonly int _BlushRColor = Shader.PropertyToID("_BlushRColor");
        static readonly int _BlushGColor = Shader.PropertyToID("_BlushGColor");
        static readonly int _BlushBColor = Shader.PropertyToID("_BlushBColor");
        static readonly int _UseCameraLight = Shader.PropertyToID("_UseCameraLight");
        static readonly int _EmissionColor = Shader.PropertyToID("_EmissionColor");
        static readonly int _FresnelRampParams = Shader.PropertyToID("_FresnelRampParams");

        readonly List<Renderer> _renderers = new List<Renderer>();
        MaterialPropertyBlock _block;

        void OnEnable()
        {
            RefreshRenderers();
        }

        // 换装、挂武器后调用，重新收集使用角色 shader 的 Renderer
        public void RefreshRenderers()
        {
            CollectCharacterRenderers(transform, _renderers);

            if (perCharSetup.headBoneTransform == null)
                perCharSetup.headBoneTransform = FindChildRecursive(transform, DefaultHeadBoneName) ?? transform;

            if (perCharSetup.characterHeright == 0)
            {
                foreach (var r in _renderers)
                    perCharSetup.characterHeright = Mathf.Max(perCharSetup.characterHeright, r.bounds.size.y);
            }
        }

        void LateUpdate()
        {
            if (_renderers.Count == 0 || perCharSetup.headBoneTransform == null) return;

            UpdateBlendShape();

            _block ??= new MaterialPropertyBlock();
            var head = perCharSetup.headBoneTransform;
            foreach (var r in _renderers)
            {
                if (r == null) continue;
                r.enabled = alphaValue > 0;
                r.GetPropertyBlock(_block);
                _block.SetFloat(_PerspectiveRemovalAmount, perspectiveRemovalAmount);
                _block.SetFloat(_PerspectiveRemovalRadius, Mathf.Max(0.01f, perspectiveRemovalRadius));
                _block.SetVector(_HeadBonePositionWS, head.position);
                _block.SetVector(_FaceForwardDirection, GetDirectionWS(head, perCharSetup.faceTransForwardDirection));
                _block.SetVector(_FaceUpDirection, GetDirectionWS(head, perCharSetup.faceTransUpDirection));
                _block.SetFloat(_CharacterHeight, perCharSetup.characterHeright);
                _block.SetVector(_BlushParams, perCharBlush.BlushParams);
                _block.SetColor(_BlushRColor, perCharBlush.BlushRColor);
                _block.SetColor(_BlushGColor, perCharBlush.BlushGColor);
                _block.SetColor(_BlushBColor, perCharBlush.BlushBColor);
                // 跟随相机的补光没有移植
                _block.SetFloat(_UseCameraLight, 0);
                if (useEmission) _block.SetColor(_EmissionColor, emissionColor);
                if (useFresnelRamp) _block.SetVector(_FresnelRampParams, fresnelRampParams);
                r.SetPropertyBlock(_block);
            }
        }

        // 腮红：对应 BlendShape 权重为 100 时打开对应通道
        void UpdateBlendShape()
        {
            if (!perCharBlush.NeedUpdateBlendShape || perCharBlush.BlendShapeObject == null) return;
            var smr = perCharBlush.BlendShapeObject.GetComponent<SkinnedMeshRenderer>();
            if (smr == null || smr.sharedMesh == null) return;

            bool r = false, g = false, b = false;
            var mesh = smr.sharedMesh;
            for (int i = 0; i < mesh.blendShapeCount; i++)
            {
                if (Mathf.Abs(smr.GetBlendShapeWeight(i) - 100f) >= 0.001f) continue;
                var shapeName = mesh.GetBlendShapeName(i);
                r |= Contains(perCharBlush.BlushNameR, shapeName);
                g |= Contains(perCharBlush.BlushNameG, shapeName);
                b |= Contains(perCharBlush.BlushNameB, shapeName);
            }
            perCharBlush.BlushParams = r ? new Vector4(1, 0, 0, 0)
                : g ? new Vector4(0, 1, 0, 0)
                : b ? new Vector4(0, 0, 1, 0)
                : Vector4.zero;
        }

        // 收集子节点里使用 XinYuan/Character/* shader 的 Renderer
        internal static void CollectCharacterRenderers(Transform root, List<Renderer> result)
        {
            result.Clear();
            foreach (var r in root.GetComponentsInChildren<Renderer>(true))
            {
                foreach (var m in r.sharedMaterials)
                {
                    if (m != null && m.shader != null && m.shader.name.StartsWith(CharacterShaderPrefix))
                    {
                        result.Add(r);
                        break;
                    }
                }
            }
        }

        static bool Contains(string[] names, string value)
        {
            return names != null && Array.IndexOf(names, value) >= 0;
        }

        static Vector3 GetDirectionWS(Transform bone, TransformDirection direction)
        {
            switch (direction)
            {
                case TransformDirection.X: return bone.right;
                case TransformDirection.Y: return bone.up;
                case TransformDirection.Z: return bone.forward;
                case TransformDirection.negX: return -bone.right;
                case TransformDirection.negY: return -bone.up;
                default: return -bone.forward;
            }
        }

        static Transform FindChildRecursive(Transform parent, string childName)
        {
            var child = parent.Find(childName);
            if (child != null) return child;
            for (int i = 0; i < parent.childCount; i++)
            {
                var found = FindChildRecursive(parent.GetChild(i), childName);
                if (found != null) return found;
            }
            return null;
        }

#if UNITY_EDITOR
        void OnDrawGizmosSelected()
        {
            if (perCharSetup.showBoundingSphereGizmo)
            {
                Gizmos.color = new Color(1, 0, 0, 0.5f);
                Gizmos.DrawSphere(transform.position + perCharSetup.characterBoundOffset, perCharSetup.characterBoundRadius);
            }
            if (perCharSetup.showfaceTransForwardDirectionGizmo && perCharSetup.headBoneTransform)
            {
                Gizmos.color = Color.blue;
                var head = perCharSetup.headBoneTransform;
                Gizmos.DrawRay(head.position, GetDirectionWS(head, perCharSetup.faceTransForwardDirection) * 0.5f);
            }
        }
#endif
    }
}

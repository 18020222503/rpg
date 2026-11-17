using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;

namespace Ported
{
    // qq13 的角色脚下阴影（原 com.xinyuan.rendering 的 DrawShadowRTFeature + 场景 shader 里的“虚投影”）。
    // 流程和原项目一致：
    //   1. 把相机转成俯视，按所有角色的范围算一个正交投影，把脚下阴影面片（ShadowGenerator pass）画进一张 256×256 的灰底图
    //   2. 地面按世界坐标投到这张图上采样，shadow = 1 - saturate(mask * 2 - 1)，再乘到颜色上
    // 原项目第 2 步写在每个场景 shader 里；这里的场景材质已换成 URP Lit，改成在画完不透明物体后，用深度图还原世界坐标统一处理。
    // 角色自身不压暗（原项目的角色 shader 不采样这张图），所以先画一张角色遮罩排除掉。
    [ExecuteAlways]
    [RequireComponent(typeof(Camera))]
    public class PortedBlobShadow : MonoBehaviour
    {
        [Tooltip("阴影图分辨率（原项目默认 256）")]
        public int resolution = 256;
        [Tooltip("超过这个距离的角色不画阴影（原项目 shadowVisibleSize）")]
        public float visibleDistance = 40f;
        [Tooltip("Hidden/Ported/BlobShadowApply；为空时按名字查找（打包后必须指定）")]
        public Shader applyShader;

        // 角色在 Awake/OnDestroy 时登记自己的渲染器
        public static readonly List<Renderer> CharacterRenderers = new List<Renderer>();
        public static readonly List<Renderer> BlobRenderers = new List<Renderer>();

        const string BlobShaderName = "Ported/ShadowGenerator";

        Camera cam;
        BlobShadowPass pass;
        Material material;

        public static void Register(GameObject character)
        {
            foreach (var r in character.GetComponentsInChildren<Renderer>(true))
            {
                if (r is ParticleSystemRenderer || r is TrailRenderer || r is LineRenderer) continue;
                var mat = r.sharedMaterial;
                if (mat != null && mat.shader != null && mat.shader.name == BlobShaderName)
                {
                    if (!BlobRenderers.Contains(r)) BlobRenderers.Add(r);
                }
                else if (!CharacterRenderers.Contains(r))
                {
                    CharacterRenderers.Add(r);
                }
            }
        }

        public static void Unregister(GameObject character)
        {
            foreach (var r in character.GetComponentsInChildren<Renderer>(true))
            {
                CharacterRenderers.Remove(r);
                BlobRenderers.Remove(r);
            }
        }

        void OnEnable()
        {
            cam = GetComponent<Camera>();
            RenderPipelineManager.beginCameraRendering += OnBeginCamera;
        }

        void OnDisable()
        {
            RenderPipelineManager.beginCameraRendering -= OnBeginCamera;
            CoreUtils.Destroy(material);
            material = null;
            pass = null;
        }

        bool EnsurePass()
        {
            if (pass != null) return true;
            if (applyShader == null) applyShader = Shader.Find("Hidden/Ported/BlobShadowApply");
            if (applyShader == null)
            {
                Debug.LogError("[Ported] 找不到 Hidden/Ported/BlobShadowApply shader");
                enabled = false;
                return false;
            }
            material = CoreUtils.CreateEngineMaterial(applyShader);
            pass = new BlobShadowPass(material);
            return true;
        }

        void OnBeginCamera(ScriptableRenderContext context, Camera c)
        {
            if (c != cam || !EnsurePass()) return;
            var data = c.GetUniversalAdditionalCameraData();
            if (data == null || data.scriptableRenderer == null) return;
            if (!pass.Setup(c, resolution, visibleDistance)) return;
            data.scriptableRenderer.EnqueuePass(pass);
        }

        class BlobShadowPass : ScriptableRenderPass
        {
            static readonly ShaderTagId GeneratorTag = new ShaderTagId("ShadowGenerator");
            static readonly int ShadowMaskId = Shader.PropertyToID("_PortedShadowMask");
            static readonly int CharMaskId = Shader.PropertyToID("_PortedCharMask");
            static readonly int SceneDepthId = Shader.PropertyToID("_PortedSceneDepth");
            static readonly int WorldToClipId = Shader.PropertyToID("_PortedWorldToClip");
            static readonly int ShadowVPId = Shader.PropertyToID("_PortedShadowVP");
            static readonly int MaxHeightId = Shader.PropertyToID("_PortedShadowMaxHeight");
            static readonly int BlitScaleBiasId = Shader.PropertyToID("_BlitScaleBias");
            const int PassCharMask = 0, PassApply = 1;

            readonly Material material;
            readonly Plane[] planes = new Plane[6];
            Matrix4x4 shadowView, shadowProj, worldToClip;
            float maxHeight;
            int resolution;

            class ShadowData
            {
                public RendererListHandle list;
                public Matrix4x4 shadowVP;
            }

            class MaskData
            {
                public Material material;
                public List<Renderer> renderers = new List<Renderer>();
            }

            class ApplyData
            {
                public Material material;
                public TextureHandle depth, charMask, shadowMask;
                public Matrix4x4 worldToClip;
                public float maxHeight;
            }

            public BlobShadowPass(Material material)
            {
                this.material = material;
                // 原项目在场景 shader 里乘，透明特效不受影响：放在不透明物体之后、透明物体之前
                renderPassEvent = RenderPassEvent.BeforeRenderingTransparents;
                requiresIntermediateTexture = true;
                ConfigureInput(ScriptableRenderPassInput.Depth);
            }

            // 原 DrawShadowRTFeature.renderRT：相机只保留偏航，转成俯视，再按角色包围球收紧正交范围
            public bool Setup(Camera camera, int res, float visibleDistance)
            {
                resolution = Mathf.Clamp(res, 64, 2048);
                var rotateAngle = 90f - camera.transform.eulerAngles.x;
                shadowView = Matrix4x4.Rotate(Quaternion.Euler(rotateAngle, 0f, 0f)) * camera.worldToCameraMatrix;
                var toVS = Matrix4x4.Scale(new Vector3(1, 1, -1)) * shadowView;

                GeometryUtility.CalculateFrustumPlanes(camera, planes);
                float minX = float.PositiveInfinity, maxX = float.NegativeInfinity;
                float minY = float.PositiveInfinity, maxY = float.NegativeInfinity;
                float minZ = float.PositiveInfinity, maxZ = float.NegativeInfinity;
                var count = 0;
                maxHeight = float.NegativeInfinity;
                for (var i = BlobRenderers.Count - 1; i >= 0; i--)
                {
                    var r = BlobRenderers[i];
                    if (r == null) { BlobRenderers.RemoveAt(i); continue; }
                    if (!r.enabled || !r.gameObject.activeInHierarchy) continue;
                    var b = r.bounds;
                    var radius = Mathf.Max(b.extents.magnitude, 0.5f);
                    var c = toVS.MultiplyPoint(b.center);
                    if (c.y + radius > visibleDistance) continue;
                    if (!GeometryUtility.TestPlanesAABB(planes, new Bounds(b.center, Vector3.one * radius))) continue;
                    minX = Mathf.Min(minX, c.x - radius); maxX = Mathf.Max(maxX, c.x + radius);
                    minY = Mathf.Min(minY, c.y - radius); maxY = Mathf.Max(maxY, c.y + radius);
                    minZ = Mathf.Min(minZ, c.z - radius); maxZ = Mathf.Max(maxZ, c.z + radius);
                    // 脚下面片在脚底高度：只压暗它上方一点以内的像素，角色身体、木桩等不受影响
                    maxHeight = Mathf.Max(maxHeight, b.center.y + 0.6f);
                    count++;
                }
                if (count == 0) return false;

                shadowProj = Matrix4x4.Ortho(minX, maxX, minY, maxY, minZ, maxZ);
                worldToClip = GL.GetGPUProjectionMatrix(shadowProj, true) * shadowView;
                return true;
            }

            public override void RecordRenderGraph(RenderGraph rg, ContextContainer frameData)
            {
                var resources = frameData.Get<UniversalResourceData>();
                var cameraData = frameData.Get<UniversalCameraData>();
                var renderingData = frameData.Get<UniversalRenderingData>();
                var lightData = frameData.Get<UniversalLightData>();
                if (resources.isActiveTargetBackBuffer || !resources.cameraDepthTexture.IsValid()) return;

                // 1. 阴影图：灰底，脚下面片按 SrcAlpha 混合画白色
                var shadowTex = rg.CreateTexture(new TextureDesc(resolution, resolution)
                {
                    colorFormat = GraphicsFormat.R8_UNorm,
                    filterMode = FilterMode.Bilinear,
                    wrapMode = TextureWrapMode.Clamp,
                    clearBuffer = true,
                    clearColor = Color.gray,
                    name = "_PortedShadowMask",
                });

                using (var builder = rg.AddRasterRenderPass<ShadowData>("Ported Blob Shadow RT", out var d))
                {
                    var draw = RenderingUtils.CreateDrawingSettings(GeneratorTag, renderingData, cameraData, lightData, SortingCriteria.CommonTransparent);
                    d.list = rg.CreateRendererList(new RendererListParams(renderingData.cullResults, draw, new FilteringSettings(RenderQueueRange.transparent)));
                    d.shadowVP = worldToClip;
                    builder.UseRendererList(d.list);
                    builder.SetRenderAttachment(shadowTex, 0, AccessFlags.Write);
                    builder.AllowGlobalStateModification(true);
                    builder.SetRenderFunc((ShadowData data, RasterGraphContext ctx) =>
                    {
                        // 只设阴影专用矩阵，不动相机矩阵（之前改了再恢复，恢复时翻转不对，把之后的透明特效都画到了画面外）
                        ctx.cmd.SetGlobalMatrix(ShadowVPId, data.shadowVP);
                        ctx.cmd.DrawRendererList(data.list);
                    });
                }

                // 2. 角色遮罩：和场景深度比较，只标记看得见的角色像素
                var maskDesc = rg.GetTextureDesc(resources.cameraColor);
                maskDesc.colorFormat = GraphicsFormat.R8_UNorm;
                maskDesc.depthBufferBits = 0;
                maskDesc.msaaSamples = MSAASamples.None;
                maskDesc.clearBuffer = true;
                maskDesc.clearColor = Color.black;
                maskDesc.name = "_PortedCharMask";
                var charMask = rg.CreateTexture(maskDesc);

                using (var builder = rg.AddRasterRenderPass<MaskData>("Ported Blob Shadow CharMask", out var d))
                {
                    d.material = material;
                    // 渲染图会复用 PassData，先清掉上一帧的列表
                    d.renderers.Clear();
                    for (var i = CharacterRenderers.Count - 1; i >= 0; i--)
                    {
                        var r = CharacterRenderers[i];
                        if (r == null) { CharacterRenderers.RemoveAt(i); continue; }
                        // 不看 isVisible：角色刚生成的第一帧还没被判定为可见，排除不掉会被整个压黑
                        if (r.enabled && r.gameObject.activeInHierarchy) d.renderers.Add(r);
                    }
                    builder.SetRenderAttachment(charMask, 0, AccessFlags.Write);
                    builder.SetRenderAttachmentDepth(resources.activeDepthTexture, AccessFlags.Read);
                    builder.SetRenderFunc((MaskData data, RasterGraphContext ctx) =>
                    {
                        foreach (var r in data.renderers)
                        {
                            // 录制和执行之间角色可能已被销毁（换场景、编辑器截图）
                            if (r == null) continue;
                            var subCount = r is SkinnedMeshRenderer smr && smr.sharedMesh != null ? smr.sharedMesh.subMeshCount
                                : (r.TryGetComponent<MeshFilter>(out var mf) && mf.sharedMesh != null ? mf.sharedMesh.subMeshCount : 1);
                            for (var s = 0; s < subCount; s++)
                                ctx.cmd.DrawRenderer(r, data.material, s, PassCharMask);
                        }
                    });
                }

                // 3. 叠到画面上（乘法混合）
                using (var builder = rg.AddRasterRenderPass<ApplyData>("Ported Blob Shadow Apply", out var d))
                {
                    d.material = material;
                    d.depth = resources.cameraDepthTexture;
                    d.charMask = charMask;
                    d.shadowMask = shadowTex;
                    d.worldToClip = worldToClip;
                    d.maxHeight = maxHeight;
                    builder.UseTexture(d.depth, AccessFlags.Read);
                    builder.UseTexture(d.charMask, AccessFlags.Read);
                    builder.UseTexture(d.shadowMask, AccessFlags.Read);
                    builder.SetRenderAttachment(resources.activeColorTexture, 0, AccessFlags.ReadWrite);
                    builder.AllowGlobalStateModification(true);
                    builder.SetRenderFunc((ApplyData data, RasterGraphContext ctx) =>
                    {
                        ctx.cmd.SetGlobalTexture(SceneDepthId, data.depth);
                        ctx.cmd.SetGlobalTexture(CharMaskId, data.charMask);
                        ctx.cmd.SetGlobalTexture(ShadowMaskId, data.shadowMask);
                        ctx.cmd.SetGlobalMatrix(WorldToClipId, data.worldToClip);
                        ctx.cmd.SetGlobalFloat(MaxHeightId, data.maxHeight);
                        ctx.cmd.SetGlobalVector(BlitScaleBiasId, new Vector4(1f, 1f, 0f, 0f));
                        ctx.cmd.DrawProcedural(Matrix4x4.identity, data.material, PassApply, MeshTopology.Triangles, 3, 1);
                    });
                }
            }
        }
    }
}

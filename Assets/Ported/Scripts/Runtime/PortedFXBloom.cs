using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;

namespace Ported
{
    // qq13 的特效 Bloom。原项目的特效 shader 在第二个渲染目标里输出 “颜色 × _BloomTint × _BloomOn”，
    // 后处理只对这张图做 Bloom，所以只有特效发光。这里的做法相同：
    //   1. 特效 shader 的 PortedFXBloom pass 单独画到一张 Bloom 图上（用场景深度遮挡）
    //   2. 半分辨率高斯金字塔模糊
    //   3. 叠回画面
    // 参数默认值取自 qq13 的 Config/Settings/BloomProfile.asset 和场景 Volume 里的 SceneFXBloom。
    // 挂在相机上即可，不需要改 URP Renderer 资源。
    [ExecuteAlways]
    [RequireComponent(typeof(Camera))]
    public class PortedFXBloom : MonoBehaviour
    {
        [Tooltip("Bloom 强度（BloomProfile.intensity）")]
        public float intensity = 1.3f;
        [Tooltip("扩散（BloomProfile.scatter），越大光晕越大")]
        [Range(0f, 1f)] public float scatter = 0.671f;
        public Color tint = Color.white;
        [Tooltip("特效发光强度（SceneFXBloom.globalFXBloomIntensity），乘在每个材质的 _BloomTint 上")]
        public float fxBloomIntensity = 0.7f;
        public float clamp = 65472f;

        [Tooltip("Hidden/Ported/FXBloom；为空时按名字查找（打包后必须指定）")]
        public Shader shader;

        static readonly int GlobalFXBloomOnId = Shader.PropertyToID("_GlobalFXBloomOn");
        static readonly int GlobalFXBloomIntensityId = Shader.PropertyToID("_GlobalFXBloomIntensity");

        Camera cam;
        FXBloomPass pass;
        Material material;

        void OnEnable()
        {
            cam = GetComponent<Camera>();
            RenderPipelineManager.beginCameraRendering += OnBeginCamera;
        }

        // 第一次渲染时再建材质，这样 AddComponent 之后再设置 shader 也来得及
        bool EnsurePass()
        {
            if (pass != null) return true;
            if (shader == null) shader = Shader.Find("Hidden/Ported/FXBloom");
            if (shader == null)
            {
                Debug.LogError("[Ported] 找不到 Hidden/Ported/FXBloom shader");
                enabled = false;
                return false;
            }
            material = CoreUtils.CreateEngineMaterial(shader);
            pass = new FXBloomPass(material);
            return true;
        }

        void OnDisable()
        {
            RenderPipelineManager.beginCameraRendering -= OnBeginCamera;
            Shader.SetGlobalFloat(GlobalFXBloomOnId, 0f);
            CoreUtils.Destroy(material);
            material = null;
            pass = null;
        }

        void OnBeginCamera(ScriptableRenderContext context, Camera c)
        {
            if (c != cam || !EnsurePass()) return;
            var data = c.GetUniversalAdditionalCameraData();
            if (data == null || data.scriptableRenderer == null) return;

            Shader.SetGlobalFloat(GlobalFXBloomOnId, 1f);
            Shader.SetGlobalFloat(GlobalFXBloomIntensityId, fxBloomIntensity);
            pass.Configure(intensity, scatter, tint, clamp);
            data.scriptableRenderer.EnqueuePass(pass);
        }

        class FXBloomPass : ScriptableRenderPass
        {
            const int MaxPyramid = 16;
            static readonly ShaderTagId BloomTag = new ShaderTagId("PortedFXBloom");
            static readonly int BlitTextureId = Shader.PropertyToID("_BlitTexture");
            static readonly int BlitTexelSizeId = Shader.PropertyToID("_BlitTexture_TexelSize");
            static readonly int BlitScaleBiasId = Shader.PropertyToID("_BlitScaleBias");
            static readonly int LowMipId = Shader.PropertyToID("_LowMip");
            static readonly int LowMipTexelSizeId = Shader.PropertyToID("_LowMip_TexelSize");
            static readonly int BloomTexId = Shader.PropertyToID("_PortedBloomTex");
            static readonly int BloomTexelSizeId = Shader.PropertyToID("_PortedBloomTex_TexelSize");
            static readonly int ParamsId = Shader.PropertyToID("_PortedBloomParams");
            static readonly int TintId = Shader.PropertyToID("_PortedBloomTint");

            const int PassPrefilter = 0, PassBlurH = 1, PassBlurV = 2, PassUpsample = 3, PassComposite = 4;

            readonly Material material;
            // 每个 Blit 一个属性块，跨帧复用，避免每帧分配
            readonly System.Collections.Generic.List<MaterialPropertyBlock> propPool = new System.Collections.Generic.List<MaterialPropertyBlock>();
            int propIndex;
            Vector4 bloomParams;
            Color bloomTint;

            class DrawData { public RendererListHandle list; }

            class BlitData
            {
                public Material material;
                public int pass;
                public TextureHandle source;
                public TextureHandle low;
                public TextureHandle bloom;
                public Vector2Int sourceSize;
                public Vector2Int lowSize;
                public Vector2Int bloomSize;
                public Vector4 bloomParams;
                public Color tint;
                public MaterialPropertyBlock props;
            }

            public FXBloomPass(Material material)
            {
                this.material = material;
                renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
                requiresIntermediateTexture = true;
            }

            public void Configure(float intensity, float scatter, Color tint, float clamp)
            {
                bloomParams = new Vector4(Mathf.Lerp(0.05f, 0.95f, scatter), clamp, intensity, 0f);
                bloomTint = tint;
            }

            public override void RecordRenderGraph(RenderGraph rg, ContextContainer frameData)
            {
                var resources = frameData.Get<UniversalResourceData>();
                var cameraData = frameData.Get<UniversalCameraData>();
                var renderingData = frameData.Get<UniversalRenderingData>();
                var lightData = frameData.Get<UniversalLightData>();
                if (resources.isActiveTargetBackBuffer) return;
                propIndex = 0;

                var camDesc = cameraData.cameraTargetDescriptor;
                var hdr = SystemInfo.IsFormatSupported(GraphicsFormat.B10G11R11_UFloatPack32, GraphicsFormatUsage.Render)
                    ? GraphicsFormat.B10G11R11_UFloatPack32
                    : GraphicsFormat.R16G16B16A16_SFloat;

                // 1. 特效 Bloom 图：和相机同尺寸、同 MSAA，深度用场景深度（只读），被墙挡住的特效不发光
                var fxDesc = camDesc;
                fxDesc.depthBufferBits = 0;
                fxDesc.depthStencilFormat = GraphicsFormat.None;
                fxDesc.graphicsFormat = GraphicsFormat.R16G16B16A16_SFloat;
                var fxTex = UniversalRenderer.CreateRenderGraphTexture(rg, fxDesc, "_PortedFXBloomSource", true, FilterMode.Bilinear);

                using (var builder = rg.AddRasterRenderPass<DrawData>("Ported FX Bloom Draw", out var d))
                {
                    var draw = RenderingUtils.CreateDrawingSettings(BloomTag, renderingData, cameraData, lightData, SortingCriteria.CommonTransparent);
                    var filter = new FilteringSettings(RenderQueueRange.transparent);
                    d.list = rg.CreateRendererList(new RendererListParams(renderingData.cullResults, draw, filter));
                    builder.UseRendererList(d.list);
                    builder.SetRenderAttachment(fxTex, 0, AccessFlags.Write);
                    builder.SetRenderAttachmentDepth(resources.activeDepthTexture, AccessFlags.Read);
                    builder.SetRenderFunc((DrawData data, RasterGraphContext ctx) => ctx.cmd.DrawRendererList(data.list));
                }

                // 2. 金字塔：从半分辨率开始
                var tw = Mathf.Max(1, camDesc.width >> 1);
                var th = Mathf.Max(1, camDesc.height >> 1);
                var iterations = Mathf.FloorToInt(Mathf.Log(Mathf.Max(tw, th), 2f) - 1);
                var mipCount = Mathf.Clamp(iterations, 1, MaxPyramid);

                var down = new TextureHandle[mipCount];
                var up = new TextureHandle[mipCount];
                var sizes = new Vector2Int[mipCount];
                for (var i = 0; i < mipCount; i++)
                {
                    sizes[i] = new Vector2Int(tw, th);
                    down[i] = CreateMip(rg, tw, th, hdr, "_PortedBloomDown" + i);
                    up[i] = CreateMip(rg, tw, th, hdr, "_PortedBloomUp" + i);
                    tw = Mathf.Max(1, tw >> 1);
                    th = Mathf.Max(1, th >> 1);
                }

                var full = new Vector2Int(camDesc.width, camDesc.height);
                Blit(rg, "Ported FX Bloom Prefilter", fxTex, full, down[0], PassPrefilter);
                for (var i = 1; i < mipCount; i++)
                {
                    // 横向模糊同时 2 倍降采样，结果暂存在 up[i]，再纵向模糊到 down[i]
                    Blit(rg, "Ported FX Bloom BlurH", down[i - 1], sizes[i - 1], up[i], PassBlurH);
                    Blit(rg, "Ported FX Bloom BlurV", up[i], sizes[i], down[i], PassBlurV);
                }

                // 3. 上采样
                var last = down[mipCount - 1];
                var lastSize = sizes[mipCount - 1];
                for (var i = mipCount - 2; i >= 0; i--)
                {
                    Blit(rg, "Ported FX Bloom Upsample", down[i], sizes[i], up[i], PassUpsample, last, lastSize);
                    last = up[i];
                    lastSize = sizes[i];
                }

                // 4. 合成：画面不能边读边写，写到新图后替换成相机颜色
                var colorDesc = rg.GetTextureDesc(resources.cameraColor);
                colorDesc.name = "_PortedFXBloomComposite";
                colorDesc.clearBuffer = false;
                var result = rg.CreateTexture(colorDesc);
                Blit(rg, "Ported FX Bloom Composite", resources.cameraColor, full, result, PassComposite, default, default, last, lastSize);
                resources.cameraColor = result;
            }

            static TextureHandle CreateMip(RenderGraph rg, int w, int h, GraphicsFormat format, string name)
            {
                var desc = new TextureDesc(w, h)
                {
                    colorFormat = format,
                    filterMode = FilterMode.Bilinear,
                    wrapMode = TextureWrapMode.Clamp,
                    name = name,
                };
                return rg.CreateTexture(desc);
            }

            void Blit(RenderGraph rg, string name, TextureHandle src, Vector2Int srcSize, TextureHandle dst, int shaderPass,
                TextureHandle low = default, Vector2Int lowSize = default, TextureHandle bloom = default, Vector2Int bloomSize = default)
            {
                using (var builder = rg.AddRasterRenderPass<BlitData>(name, out var d))
                {
                    d.material = material;
                    d.pass = shaderPass;
                    d.source = src;
                    d.sourceSize = srcSize;
                    d.low = low;
                    d.lowSize = lowSize;
                    d.bloom = bloom;
                    d.bloomSize = bloomSize;
                    d.bloomParams = bloomParams;
                    d.tint = bloomTint;
                    if (propIndex == propPool.Count) propPool.Add(new MaterialPropertyBlock());
                    d.props = propPool[propIndex++];

                    builder.UseTexture(src, AccessFlags.Read);
                    if (low.IsValid()) builder.UseTexture(low, AccessFlags.Read);
                    if (bloom.IsValid()) builder.UseTexture(bloom, AccessFlags.Read);
                    builder.SetRenderAttachment(dst, 0, AccessFlags.Write);

                    builder.SetRenderFunc((BlitData data, RasterGraphContext ctx) =>
                    {
                        var p = data.props;
                        p.Clear();
                        p.SetTexture(BlitTextureId, (RTHandle)data.source);
                        p.SetVector(BlitTexelSizeId, TexelSize(data.sourceSize));
                        p.SetVector(BlitScaleBiasId, new Vector4(1f, 1f, 0f, 0f));
                        p.SetVector(ParamsId, data.bloomParams);
                        p.SetColor(TintId, data.tint);
                        if (data.low.IsValid())
                        {
                            p.SetTexture(LowMipId, (RTHandle)data.low);
                            p.SetVector(LowMipTexelSizeId, TexelSize(data.lowSize));
                        }
                        if (data.bloom.IsValid())
                        {
                            p.SetTexture(BloomTexId, (RTHandle)data.bloom);
                            p.SetVector(BloomTexelSizeId, TexelSize(data.bloomSize));
                        }
                        ctx.cmd.DrawProcedural(Matrix4x4.identity, data.material, data.pass, MeshTopology.Triangles, 3, 1, p);
                    });
                }
            }

            static Vector4 TexelSize(Vector2Int s) => new Vector4(1f / s.x, 1f / s.y, s.x, s.y);
        }
    }
}

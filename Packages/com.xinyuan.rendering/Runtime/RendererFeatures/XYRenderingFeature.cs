using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;

namespace XYRendering.Runtime
{
    // 代替 qq13 自研管线里的 AllInOneRendererFeature / ToonOutlinePass / 特效 Pass：
    // 1. 设置 ToonCharacter 等 shader 依赖的全局参数（原来由 BaseCharacterController、ToonOutlinePass 设置）
    // 2. 按 LightMode 绘制 URP 不认识的自定义 Pass（描边 NiloToonOutline、特效 TransparentFX 等）
    // 挂在 Assets/Settings 下的 PC_Renderer / Mobile_Renderer 上
    public class XYRenderingFeature : ScriptableRendererFeature
    {
        public enum Queue { Opaque, Transparent }

        [Serializable]
        public class LightModeDraw
        {
            public string lightMode = "NiloToonOutline";
            public Queue queue = Queue.Opaque;
            public RenderPassEvent passEvent = RenderPassEvent.AfterRenderingSkybox;
            public LayerMask layerMask = -1;
        }

        [Serializable]
        public class CharacterSettings
        {
            // 默认值来自 qq13 BaseCharacterController 的 g_* 静态字段
            public float bloomThreshold = 0.01f;
            public float bloomIntensity = 0.1f;
            [Range(0, 1)] public float fogEffect = 0;
            [Range(0, 1)] public float probeOcclusionEffect = 0.5f;
            [Range(0, 1)] public float mainLightColorEffect = 0.5f;
            [Range(0, 1)] public float indirectLightColorEffect = 0f;
            public Color baseColorTint = Color.white;
            public Color lightTint = Color.white;
            public float lightMultiply = 1;
            public Color shadowTint = Color.white;
            public float shadowMultiply = 1;
            public Color additionalLightMultiplier = Color.white;
            public Color additionalLightMaxContribution = Color.white;
            // 描边宽度随距离/FOV 修正：(距离min, 距离max, FOVmin, FOVmax)，来自 ToonOutlinePass.Settings
            public Vector4 outlineWidthFix = new Vector4(0.5f, 12f, 1f, 40f);
        }

        public CharacterSettings character = new CharacterSettings();

        public List<LightModeDraw> draws = new List<LightModeDraw>
        {
            new LightModeDraw { lightMode = "NiloToonOutline", queue = Queue.Opaque, passEvent = RenderPassEvent.AfterRenderingSkybox },
            new LightModeDraw { lightMode = "TransparentFX", queue = Queue.Transparent, passEvent = RenderPassEvent.AfterRenderingTransparents },
        };

        static readonly int _GlobalCharacterBaseColorTint = Shader.PropertyToID("_GlobalCharacterBaseColorTint");
        static readonly int _GlobalCharacterParams = Shader.PropertyToID("_GlobalCharacterParams");
        static readonly int _GlobalCharacterLightParams1 = Shader.PropertyToID("_GlobalCharacterLightParams1");
        static readonly int _GlobalCharacterLightParams2 = Shader.PropertyToID("_GlobalCharacterLightParams2");
        static readonly int _GlobalAdditionalLightMultiplier = Shader.PropertyToID("_GlobalAdditionalLightMultiplier");
        static readonly int _GlobalAdditionalLightMaxContribution = Shader.PropertyToID("_GlobalAdditionalLightMaxContribution");
        static readonly int _GlobalToonOutlineWidthFix = Shader.PropertyToID("_GlobalToonOutlineWidthFix");
        static readonly int _GlobalAspectFix = Shader.PropertyToID("_GlobalAspectFix");
        static readonly int _GlobalFOVorOrthoSizeFix = Shader.PropertyToID("_GlobalFOVorOrthoSizeFix");
        static readonly int _GlobalMainLightDirVS = Shader.PropertyToID("_GlobalMainLightDirVS");

        List<LightModePass> _passes;

        public override void Create()
        {
            _passes = new List<LightModePass>();
            foreach (var d in draws)
                if (!string.IsNullOrEmpty(d.lightMode))
                    _passes.Add(new LightModePass(d));
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            var camera = renderingData.cameraData.camera;
            SetGlobals(camera);
            if (renderingData.cameraData.cameraType == CameraType.Preview) return;
            foreach (var p in _passes)
                renderer.EnqueuePass(p);
        }

        // 每个相机渲染前设置；相机依次渲染，所以逐相机的参数也能用全局变量
        void SetGlobals(Camera camera)
        {
            var c = character;
            Shader.SetGlobalVector(_GlobalCharacterParams,
                new Vector4(c.bloomThreshold, c.bloomIntensity, c.fogEffect, c.probeOcclusionEffect));
            Shader.SetGlobalColor(_GlobalCharacterBaseColorTint, c.baseColorTint);
            var light = c.lightTint * c.lightMultiply;
            light.a = c.mainLightColorEffect;
            Shader.SetGlobalColor(_GlobalCharacterLightParams1, light);
            var shadow = c.shadowTint * c.shadowMultiply;
            shadow.a = c.indirectLightColorEffect;
            Shader.SetGlobalColor(_GlobalCharacterLightParams2, shadow);
            Shader.SetGlobalColor(_GlobalAdditionalLightMultiplier, c.additionalLightMultiplier);
            Shader.SetGlobalColor(_GlobalAdditionalLightMaxContribution, c.additionalLightMaxContribution);
            Shader.SetGlobalVector(_GlobalToonOutlineWidthFix, c.outlineWidthFix);

            Shader.SetGlobalVector(_GlobalAspectFix, new Vector2((float)camera.pixelHeight / Mathf.Max(1, camera.pixelWidth), 1));
            Shader.SetGlobalFloat(_GlobalFOVorOrthoSizeFix,
                1.0f / (camera.orthographic ? camera.orthographicSize * 100 : camera.fieldOfView));
            var sun = RenderSettings.sun;
            if (sun != null)
                Shader.SetGlobalVector(_GlobalMainLightDirVS, -camera.worldToCameraMatrix.MultiplyVector(sun.transform.forward));
        }

        class LightModePass : ScriptableRenderPass
        {
            class PassData
            {
                public RendererListHandle list;
            }

            readonly ShaderTagId _tag;
            readonly Queue _queue;
            FilteringSettings _filtering;

            public LightModePass(LightModeDraw draw)
            {
                _tag = new ShaderTagId(draw.lightMode);
                _queue = draw.queue;
                renderPassEvent = draw.passEvent;
                var range = draw.queue == Queue.Opaque ? RenderQueueRange.opaque : RenderQueueRange.transparent;
                _filtering = new FilteringSettings(range, draw.layerMask);
                profilingSampler = new ProfilingSampler("XY " + draw.lightMode);
            }

            public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
            {
                var cameraData = frameData.Get<UniversalCameraData>();
                var renderingData = frameData.Get<UniversalRenderingData>();
                var lightData = frameData.Get<UniversalLightData>();
                var resourceData = frameData.Get<UniversalResourceData>();

                using (var builder = renderGraph.AddRasterRenderPass<PassData>(profilingSampler.name, out var passData, profilingSampler))
                {
                    var sorting = _queue == Queue.Transparent ? SortingCriteria.CommonTransparent : cameraData.defaultOpaqueSortFlags;
                    var drawing = RenderingUtils.CreateDrawingSettings(_tag, renderingData, cameraData, lightData, sorting);
                    var param = new RendererListParams(renderingData.cullResults, drawing, _filtering);
                    passData.list = renderGraph.CreateRendererList(param);
                    builder.UseRendererList(passData.list);

                    builder.SetRenderAttachment(resourceData.activeColorTexture, 0, AccessFlags.Write);
                    if (resourceData.activeDepthTexture.IsValid())
                        builder.SetRenderAttachmentDepth(resourceData.activeDepthTexture, AccessFlags.Write);
                    if (resourceData.mainShadowsTexture.IsValid())
                        builder.UseTexture(resourceData.mainShadowsTexture, AccessFlags.Read);
                    if (resourceData.additionalShadowsTexture.IsValid())
                        builder.UseTexture(resourceData.additionalShadowsTexture, AccessFlags.Read);
                    builder.AllowGlobalStateModification(true);

                    builder.SetRenderFunc((PassData data, RasterGraphContext ctx) => ctx.cmd.DrawRendererList(data.list));
                }
            }
        }
    }
}

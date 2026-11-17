#ifndef XY_LIT_META_PASS_INCLUDED
#define XY_LIT_META_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UniversalMetaPass.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/XYPipeline/ColorSpacePipelineVer.hlsl"

void MetaInitializeXYStandardLitSurfaceData(float2 uv, out XYSurfaceData outSurfaceData)
{

    // 工作流改为 gamma with linear, 光照计算仍然在线性空间计算
    // Albedo贴图输出在Gamma空间, Shader中采样的时候做一次Gamma2.2的矫正 (使得贴图在Shader中变为线性空间)
    // 最终输出的时候在转换到sRGB空间
    half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
    // Gamma correction
    albedoAlpha = SCENE_FAST_SRGB_TO_LINEAR(albedoAlpha);
        
    // outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;
    outSurfaceData.albedo = albedoAlpha.rgb * SCENE_FAST_SRGB_TO_LINEAR(_BaseColor.rgb);
    outSurfaceData.alpha = Alpha(albedoAlpha.a, _BaseColor, _Cutoff);

    half4 rmaoFactor = SCENE_FAST_SRGB_TO_LINEAR(SampleRMAO(uv));
    outSurfaceData.metallic = rmaoFactor.g * _Metallic;
    outSurfaceData.smoothness = RoughnessToPerceptualSmoothness(PerceptualRoughnessToRoughness(rmaoFactor.r * _Rounghness));
    outSurfaceData.occlusion = rmaoFactor.b * (1-_OcclusionStrength);
    #if defined(_FLOWMAP_NORMAL) || defined(_FLOWMAP_BOTH) // 开启流动法线时，需要两次采样Normal进行混合，在外部完成采样，这里直接返回Zero Vector
    outSurfaceData.normalTS = half3(0.0h, 0.0h, 1.0h);
    #else
    outSurfaceData.normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
    #endif
    outSurfaceData.emission = SampleEmission(uv, _EmissionColor.rgb, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap));
}

half4 UniversalFragmentMetaLit(Varyings input) : SV_Target
{
    XYSurfaceData surfaceData = (XYSurfaceData)0;
    MetaInitializeXYStandardLitSurfaceData(input.uv, surfaceData);
    BRDFData brdfData;
    InitializeBRDFData(surfaceData.albedo, surfaceData.metallic, half3(1.0h, 1.0h, 1.0h), surfaceData.smoothness, surfaceData.alpha, brdfData);

    MetaInput metaInput;
    metaInput.Albedo = brdfData.diffuse + brdfData.specular * brdfData.roughness * 0.5;
    metaInput.Emission = surfaceData.emission;
    return UniversalFragmentMeta(input, metaInput);
}
#endif

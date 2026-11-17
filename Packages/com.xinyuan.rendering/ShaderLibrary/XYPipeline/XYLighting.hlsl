#ifndef XY_PIPELINE_LIGHTING_INCLUDED
#define XY_PIPELINE_LIGHTING_INCLUDED

// xinyuan 管线 Lighting.hlsl 里的 XYFragmentPBR / XYFragmentBlinnPhong，按 URP 17 的 API 重写。
// 原实现去掉了清漆、SSAO、光照层；这里保持一致。DEBUG_DISPLAY 的调试分支没有移植。

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/XYPipeline/XYTypes.hlsl"

InputData XYToURPInputData(XYInputData xy)
{
    InputData d = (InputData)0;
    d.positionWS = xy.positionWS;
    d.positionCS = xy.positionCS;
    d.normalWS = xy.normalWS;
    d.viewDirectionWS = xy.viewDirectionWS;
    d.shadowCoord = xy.shadowCoord;
    d.fogCoord = xy.fogCoord;
    d.vertexLighting = xy.vertexLighting;
    d.bakedGI = xy.bakedGI;
    d.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(xy.positionCS);
    d.shadowMask = xy.shadowMask;
    d.tangentToWorld = xy.tangentToWorld;
    return d;
}

SurfaceData XYToURPSurfaceData(XYSurfaceData xy)
{
    SurfaceData s = (SurfaceData)0;
    s.albedo = xy.albedo;
    s.metallic = xy.metallic;
    s.smoothness = xy.smoothness;
    s.normalTS = xy.normalTS;
    s.emission = xy.emission;
    s.occlusion = xy.occlusion;
    s.alpha = xy.alpha;
    return s;
}

// 实时阴影和 shadowmask 都在阴影里的区域额外压暗 AO（原 fork 的“阴影内有阴影”）
half XYShadowAreaOcclusion(XYInputData xy, half4 shadowMask, half occlusion)
{
    half realtimeShadow = MainLightRealtimeShadow(xy.shadowCoord);
    // 按阴影强度还原出原始阴影值
    realtimeShadow = (realtimeShadow - 1) / max(GetMainLightShadowParams().x, HALF_MIN) + 1;
    half overlap = (1 - shadowMask.r) * step(realtimeShadow, 0.5);
    return lerp(occlusion, occlusion * (1 - _RealTimeShadowAreaOcclusion), overlap);
}

half3 CalculateBlinnPhong(Light light, XYInputData inputData, XYSurfaceData surfaceData)
{
    half3 attenuatedLightColor = light.color * (light.distanceAttenuation * light.shadowAttenuation);
    half3 lightColor = LightingLambert(attenuatedLightColor, light.direction, inputData.normalWS);
    lightColor *= surfaceData.albedo;

    #if !defined(DISABLE_LIT_SPECULAR) && (defined(_SPECGLOSSMAP) || defined(_SPECULAR_COLOR))
    half smoothness = exp2(10 * surfaceData.smoothness + 1);
    lightColor += LightingSpecular(attenuatedLightColor, light.direction, inputData.normalWS, inputData.viewDirectionWS, half4(0, 0, 0, 1), smoothness);
    #endif

    return lightColor;
}

half4 XYFragmentPBR(XYInputData xyInput, XYSurfaceData xySurface, inout bool debugOverride)
{
    #if defined(_SPECULARHIGHLIGHTS_OFF)
    bool specularHighlightsOff = true;
    #else
    bool specularHighlightsOff = false;
    #endif
    debugOverride = false;

    BRDFData brdfData;
    InitializeBRDFData(xySurface.albedo, xySurface.metallic, half3(0, 0, 0), xySurface.smoothness, xySurface.alpha, brdfData);

    // LIGHT_LOOP_BEGIN 在 Forward+ 下引用名为 inputData 的 InputData
    InputData inputData = XYToURPInputData(xyInput);
    half4 shadowMask = CalculateShadowMask(inputData);
    xySurface.occlusion = XYShadowAreaOcclusion(xyInput, shadowMask, xySurface.occlusion);

    AmbientOcclusionFactor aoFactor;
    aoFactor.directAmbientOcclusion = 1;
    aoFactor.indirectAmbientOcclusion = xySurface.occlusion;

    Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, shadowMask);
    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI);

    SurfaceData surfaceData = XYToURPSurfaceData(xySurface);
    LightingData lightingData = CreateLightingData(inputData, surfaceData);
    lightingData.giColor = GlobalIllumination(brdfData, inputData.bakedGI, xySurface.occlusion, inputData.positionWS,
                                              inputData.normalWS, inputData.viewDirectionWS);
    lightingData.mainLightColor = LightingPhysicallyBased(brdfData, mainLight, inputData.normalWS,
                                                          inputData.viewDirectionWS, specularHighlightsOff);

    #if defined(_ADDITIONAL_LIGHTS)
    uint pixelLightCount = GetAdditionalLightsCount();

    #if USE_CLUSTER_LIGHT_LOOP
    [loop] for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
    {
        CLUSTER_LIGHT_LOOP_SUBTRACTIVE_LIGHT_CHECK
        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);
        lightingData.additionalLightsColor += LightingPhysicallyBased(brdfData, light, inputData.normalWS,
                                                                      inputData.viewDirectionWS, specularHighlightsOff);
    }
    #endif

    LIGHT_LOOP_BEGIN(pixelLightCount)
        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);
        lightingData.additionalLightsColor += LightingPhysicallyBased(brdfData, light, inputData.normalWS,
                                                                      inputData.viewDirectionWS, specularHighlightsOff);
    LIGHT_LOOP_END
    #endif

    #if defined(_ADDITIONAL_LIGHTS_VERTEX)
    lightingData.vertexLightingColor += inputData.vertexLighting * brdfData.diffuse;
    #endif

    return half4(lightingData.mainLightColor + lightingData.emissionColor + lightingData.giColor
                 + lightingData.additionalLightsColor + lightingData.vertexLightingColor, xySurface.alpha);
}

half4 XYFragmentPBR(XYInputData xyInput, XYSurfaceData xySurface)
{
    bool debugOverride = false;
    return XYFragmentPBR(xyInput, xySurface, debugOverride);
}

half4 XYFragmentBlinnPhong(XYInputData xyInput, XYSurfaceData xySurface, out bool debugOverride)
{
    debugOverride = false;

    InputData inputData = XYToURPInputData(xyInput);
    half4 shadowMask = CalculateShadowMask(inputData);
    xySurface.occlusion = XYShadowAreaOcclusion(xyInput, shadowMask, xySurface.occlusion);

    AmbientOcclusionFactor aoFactor;
    aoFactor.directAmbientOcclusion = 1;
    aoFactor.indirectAmbientOcclusion = xySurface.occlusion;

    Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, shadowMask);
    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, aoFactor);
    inputData.bakedGI *= xySurface.albedo;

    SurfaceData surfaceData = XYToURPSurfaceData(xySurface);
    LightingData lightingData = CreateLightingData(inputData, surfaceData);
    lightingData.mainLightColor += CalculateBlinnPhong(mainLight, xyInput, xySurface);

    #if defined(_ADDITIONAL_LIGHTS)
    uint pixelLightCount = GetAdditionalLightsCount();

    #if USE_CLUSTER_LIGHT_LOOP
    [loop] for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
    {
        CLUSTER_LIGHT_LOOP_SUBTRACTIVE_LIGHT_CHECK
        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);
        lightingData.additionalLightsColor += CalculateBlinnPhong(light, xyInput, xySurface);
    }
    #endif

    LIGHT_LOOP_BEGIN(pixelLightCount)
        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);
        lightingData.additionalLightsColor += CalculateBlinnPhong(light, xyInput, xySurface);
    LIGHT_LOOP_END
    #endif

    #if defined(_ADDITIONAL_LIGHTS_VERTEX)
    lightingData.vertexLightingColor += inputData.vertexLighting;
    #endif

    return half4(lightingData.mainLightColor + lightingData.emissionColor + lightingData.giColor
                 + lightingData.additionalLightsColor + lightingData.vertexLightingColor, xySurface.alpha);
}

#endif

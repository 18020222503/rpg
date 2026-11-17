#ifndef XINYUAN_SCENE_COMMOM_INCLUDED
#define XINYUAN_SCENE_COMMOM_INCLUDED
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/ColorSpace.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/ColorAdjustment.hlsl"

half4 _SceneCommonParams1;
half4 _SceneCommonParams2;
half4 _SceneCommonParams3;
half4 _SceneCommonParams4;

half _DarkON; // 昼夜状态标识



#define _NegativeBrightScene _SceneCommonParams1.x
#define _NegativeStrengthScene _SceneCommonParams1.y
#define _LumThreshholdScene _SceneCommonParams1.z

// 场景烘焙阴影图强度控制
#define _SceneShadowMapIntensity _SceneCommonParams1.w

half4 _SceneAttenuationParams; // xyz postionWS, w radius, while radius = -1
half3 _NegativeTintScene;
half3 _PlayerPos;
half4 _PlayerPosCenter;


// Attenuation
#define _PlayerPosOffset _SceneCommonParams2.x
#define _GlobalTintAttenuation _SceneCommonParams2.y
// #define _ColorChangeProgress _SceneCommonParams2.w
// half _GlobalTintAttenuation;

//场景Bloom
#define _SceneBloomThreshold _SceneCommonParams3.x
#define _SceneBloomIntensity _SceneCommonParams3.y

// Camera block dither handle
#define _SceneDitherRadiusSqrtRcp _SceneCommonParams3.z
#define _InnerScreenPercentage _SceneCommonParams3.w

// Scene Lut
// (1f / lutWidth, 1f / lutHeight, lutHeight - 1f, postExposureLinear)
half4 _Scene_Lut_Params;
half _Apply_SceneLut;

TEXTURE2D(_ScenesLut);          

// 让Bloom强度可以在R8B8G8A8的格式下超过1，注意和bloom中的还原乘算对应
#define SCENE_BLOOM_MUL(a) a *= 0.1



half GetBloomPrefilter(half3 color, half Threshold)
{
    // Unity 内置的亮度算法是取颜色的最大分量...
    half brightness = max(color.r, max(color.g, color.b));
    // half brightness = dot(color, half3(0.2126729, 0.7151522, 0.0721750));
    half ThresholdKnee = Threshold * 0.5;// unity内置的软阈值写死为阈值的一半
    half softness = clamp(brightness - Threshold + ThresholdKnee, 0.0, 2.0 * ThresholdKnee);
    softness = (softness * softness) / (4.0 * ThresholdKnee + 1e-4);
    half multiplier = max(brightness - Threshold, softness) / max(brightness, 1e-4);
    return multiplier;
}

// 简单的球形遮挡处理，越靠近圆心, 半透程度越强
half GetDitherOpacityByDistance(half distance, half radius, half innerRadiusPercentage = 0.5)
{
    half radiusNorm = saturate(distance / (radius + 0.001));
    half ditherOpacity = step(innerRadiusPercentage, radiusNorm) * smoothstep(0.5, 1, radiusNorm);
    return ditherOpacity;
}

// void DoSceneColorChange(inout half3 outColor, half colorChangeProgress = 0)
// {
//     half3 multiColor = outColor.rgb * _SceneFilterColor;
//     outColor.rgb = lerp(outColor.rgb, multiColor, colorChangeProgress);
// }

half3 ApplyLut2DOpt(TEXTURE2D_PARAM(tex, samplerTex), half3 uvw, half3 scaleOffset)
{
    // Strip format where `height = sqrt(width)`
    
    uvw *= scaleOffset.z;
    
    half shift = floor(uvw.z);
    
    uvw.xy =  uvw.xy * scaleOffset.xy + scaleOffset.xy * 0.5h;
    uvw.x +=  shift * scaleOffset.y;
    uvw.xyz = lerp(
        SAMPLE_TEXTURE2D_LOD(tex, samplerTex, uvw.xy, 0.0h).rgb,
        SAMPLE_TEXTURE2D_LOD(tex, samplerTex, uvw.xy + half2(scaleOffset.y, 0.0h), 0.0h).rgb,
        uvw.z - shift
    );
    return uvw;
}

// Copy From Common.hlsl
half3 ApplyColorGrading(half3 input, half postExposure, TEXTURE2D_PARAM(lutTex, lutSampler), half3 lutParams)
{
    // Artist request to fine tune exposure in post without affecting bloom, dof etc
    input *= postExposure;

    // ss中一直没有用到HDR Grading， 出于减少变体的考虑，直接屏蔽HDR Grading相关代码
    // #if _HDR_GRADING
    // {
    //     float3 inputLutSpace = saturate(LinearToLogC(input)); // LUT space is in LogC
    //     input = ApplyLut2D(TEXTURE2D_ARGS(lutTex, lutSampler), inputLutSpace, lutParams);

        // Scene only Lut not use user Lut
        // UNITY_BRANCH
        // if (userLutContrib > 0.0)
        // {
        //     input = saturate(input);
        //     input.rgb = LinearToSRGB(input.rgb); // In LDR do the lookup in sRGB for the user LUT
        //     half3 outLut = ApplyLut2D(TEXTURE2D_ARGS(userLutTex, userLutSampler), input, userLutParams);
        //     input = lerp(input, outLut, userLutContrib);
        //     input.rgb = SRGBToLinear(input.rgb);
        // }
    // }

    // LDR Grading:
    //   - Apply tonemapping (result is clamped)
    //   - (optional) Apply user LUT
    //   - Apply internal linear LUT
    // #else
    {
        // input = ApplyTonemap(input);
        // TODO : 暂时不使用Tonemapping
        input = saturate(input);

    // UNITY_BRANCH
    // if (userLutContrib > 0.0)
    // {
    //     input.rgb = LinearToSRGB(input.rgb); // In LDR do the lookup in sRGB for the user LUT
    //     half3 outLut = ApplyLut2D(TEXTURE2D_ARGS(userLutTex, userLutSampler), input, userLutParams);
    //     input = lerp(input, outLut, userLutContrib);
    //     input.rgb = SRGBToLinear(input.rgb);
    // }
        input = ApplyLut2DOpt(TEXTURE2D_ARGS(lutTex, lutSampler), input, lutParams);
        
    }
    // #endif
    return input;
}

// 圆柱遮罩
//https://stackoverflow.com/questions/47932955/how-to-check-if-a-3d-point-is-inside-a-cylinder
half GetDitherOpacityWithCylinder(half3 p, half3 p1, half3 p2, half rSqrtRcp, half offset = 0)
{
    half3 cameraToPosVec = normalize(p2 - p1);
    p2 += cameraToPosVec * offset;
    half3 p1_p_vec = p - p1;
    half3 p2_q_vec = p - p2;
    half3 p2_p1_vec = p2 - p1;

    half isBetweenTwoPlanes = dot(p1_p_vec, p2_p1_vec) >= 0 ? 1.0h : 0.0h;
    isBetweenTwoPlanes *= (dot(p2_q_vec, p2_p1_vec) <= 0 ? 1.0h : 0.0h);
    half3 crossVec = cross(p1_p_vec, p2_p1_vec);
    // 用点积的比值代替长度, 避免开方操作
    half isInsideCylinderSurface = (dot(crossVec, crossVec) / dot(p2_p1_vec, p2_p1_vec)) * rSqrtRcp;
    // rsqrtinv 为0时认为关闭虚化
    isInsideCylinderSurface = rSqrtRcp == 0 ? 1 : isInsideCylinderSurface;
    return lerp(1, saturate(isInsideCylinderSurface), isBetweenTwoPlanes);
}

#if defined(_DITHER_LOCAL_ON)
#define DO_DITHER(positionWS, positionCS, ditherType) half ditherFactor = 1;\
ditherFactor = GetDitherOpacityWithCylinder(positionWS, _WorldSpaceCameraPos, _PlayerPosCenter, _SceneDitherRadiusSqrtRcp, _PlayerPosOffset);\
DoDitherFadeoutClip(positionCS, lerp(ditherFactor, _DitherOpacity, ditherType));
#else
#define DO_DITHER(positionWS, positionCS, ditherType)
#endif


#endif
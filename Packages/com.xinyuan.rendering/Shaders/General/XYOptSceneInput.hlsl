#ifndef XY_OPT_LIT_INPUT_INCLUDED
#define XY_OPT_LIT_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/XYPipeline/XYTypes.hlsl"
// #include "Packages/com.xinyuan.render-pipelines.core/ShaderLibrary/ParallaxMapping.hlsl"
// #include  "Packages/com.xinyuan.render-pipelines/ShaderLibrary/Core.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Scene/ScenesCommon.hlsl"
// #include "Packages/com.xinyuan.render-pipelines.core/ShaderLibrary/Color.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/ColorSpace.hlsl"

#if defined(_DETAIL_MULX2) || defined(_DETAIL_SCALED)
#define _DETAIL
#endif

// NOTE: Do not ifdef the properties here as SRP batcher can not handle different layouts.
CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
// float4 _DetailAlbedoMap_ST;
//---- 2022 - 08 - 05
//---- Add By 志成
//------------- 添加顶点动画属性 ---------
half4 _NoiseMap_ST;
half4 _Anchor;
half4 _MinMaxStrength;
half4 _MinMaxStrengthB;
half4 _WindDirection;
half4 _WindDirectionB;
half4 _UVSpeed;
half4 _BaseColor;
half4 _EmissionColor;
half4 _FlowOffsetSpeed;
half4 _VertexOffsetParam;

half _Switcher; //---- Add By 志成  添加顶点动画信息
//-----------------EndAdd --------------
half _Cutoff;
half _Metallic;
half _Rounghness;
half _BumpScale;
// half _Parallax;
half _OcclusionStrength;
// half _ClearCoatMask;
// half _ClearCoatSmoothness;
// half _DetailAlbedoMapScale;
// half _DetailNormalMapScale;
half _Surface;

half _UVMove;
half _DitherType;
//deprecated
// half _Smoothness;
// half4 _SpecColor;
half _SceneBloomOn;
half _VertexAniUseVertexCol;


half _DitherOpacity;
half _EmissionOnly;
CBUFFER_END

#define _FlowVector             _FlowOffsetSpeed.xy
#define _FlowSpeed              _FlowOffsetSpeed.z
// #define _VextexOffsetSpeed      _VertexOffsetParam.xy 
// #define _VertexOffsetIntensity  _VertexOffsetParam.z 

// NOTE: Do not ifdef the properties for dots instancing, but ifdef the actual usage.
// Otherwise you might break CPU-side as property constant-buffer offsets change per variant.
// NOTE: Dots instancing is orthogonal to the constant buffer above.
// #ifdef UNITY_DOTS_INSTANCING_ENABLED
// UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
//     UNITY_DOTS_INSTANCED_PROP(float4, _BaseColor)
//     UNITY_DOTS_INSTANCED_PROP(float4, _EmissionColor)
//     UNITY_DOTS_INSTANCED_PROP(float , _Cutoff)
//     
//     UNITY_DOTS_INSTANCED_PROP(float , _Metallic)
//     UNITY_DOTS_INSTANCED_PROP(float, _Rounghness)
//     UNITY_DOTS_INSTANCED_PROP(float , _BumpScale)
//     UNITY_DOTS_INSTANCED_PROP(float , _Parallax)
//     UNITY_DOTS_INSTANCED_PROP(float , _OcclusionStrength)
//     UNITY_DOTS_INSTANCED_PROP(float , _ClearCoatMask)
//     UNITY_DOTS_INSTANCED_PROP(float , _ClearCoatSmoothness)
//     UNITY_DOTS_INSTANCED_PROP(float , _DetailAlbedoMapScale)
//     UNITY_DOTS_INSTANCED_PROP(float , _DetailNormalMapScale)
//     UNITY_DOTS_INSTANCED_PROP(float , _Surface)
//     UNITY_DOTS_INSTANCED_PROP(half4 , _UVSpeed)
//     UNITY_DOTS_INSTANCED_PROP(half  , _UVMove)
//
// // deprecated
//     UNITY_DOTS_INSTANCED_PROP(float4, _SpecColor)
//     UNITY_DOTS_INSTANCED_PROP(float , _Smoothness)
// UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)
//
// #define _BaseColor              UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float4 , Metadata__BaseColor)
// #define _EmissionColor          UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float4 , Metadata__EmissionColor)
// #define _Cutoff                 UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata__Cutoff)
// #define _Metallic               UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata__Metallic)
// #define _Rounghness             UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata__Rounghness)
// #define _BumpScale              UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata__BumpScale)
// #define _Parallax               UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata__Parallax)
// #define _OcclusionStrength      UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata__OcclusionStrength)
// #define _ClearCoatMask          UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata__ClearCoatMask)
// #define _ClearCoatSmoothness    UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata__ClearCoatSmoothness)
// #define _DetailAlbedoMapScale   UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata__DetailAlbedoMapScale)
// #define _DetailNormalMapScale   UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata__DetailNormalMapScale)
// #define _Surface                UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata__Surface)
// #define _UVSpeed                UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(half4  , Metadata__UVSpeed)
// #define _UVMove                 UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(half   , Metadata__UVMove)
//
// // deprecated
// #define _SpecColor              UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float4 , Metadata__SpecColor)
// #define _Smoothness             UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata__Smoothness)
// #endif


//---- Add By 志成
//----------------------- 添加顶点动画属性 --------------------

#define  MinStrength _MinMaxStrength.x
#define  MaxStrength _MinMaxStrength.y
#define  MinSpeed _MinMaxStrength.z
#define  MaxSpeed _MinMaxStrength.w

#define MinStrengthB _MinMaxStrengthB.x
#define MaxStrengthB _MinMaxStrengthB.y
#define MinSpeedB _MinMaxStrengthB.z
#define STRENGTHBPROGRESS _MinMaxStrengthB.w

// #define  SPEED lerp(MinSpeed,MaxSpeed,_Switcher)
#define  SPEED MinSpeed
#define  SPEEDB MinSpeedB
#define  STRENGTH lerp(MinStrength,MaxStrength,_Switcher)
#define  STRENGTHB lerp(MinStrengthB,MaxStrengthB, STRENGTHBPROGRESS)

//----------------------------------------------------------

//---- Add By 海婷
//----------------------- 添加虚椭圆属性 --------------------
#if defined( _SHADOWTEX_ON)
  TEXTURE2D(_ShadowMask);   //
  float4x4 _WorldToClip;
  half _IsGlobalShadow;
#endif
//----------------------------------------------------------
TEXTURE2D(_RMAOMap);            SAMPLER(sampler_RMAOMap);
// TEXTURE2D(_ParallaxMap);        SAMPLER(sampler_ParallaxMap);
// TEXTURE2D(_DetailMask);         SAMPLER(sampler_DetailMask);
// TEXTURE2D(_DetailAlbedoMap);    SAMPLER(sampler_DetailAlbedoMap);
// TEXTURE2D(_DetailNormalMap);    SAMPLER(sampler_DetailNormalMap);
// TEXTURE2D(_ClearCoatMap);       SAMPLER(sampler_ClearCoatMap);
TEXTURE2D(_FlowMap);            SAMPLER(sampler_FlowMap);
// TEXTURE2D(_VertexOffsetMap);    SAMPLER(sampler_VertexOffsetMap);

TEXTURE2D(_NoiseMap);           SAMPLER(sampler_NoiseMap);
TEXTURE2D(_AnimWeightMap);      SAMPLER(sampler_AnimWeightMap);


//deprecated
// TEXTURE2D(_OcclusionMap);       SAMPLER(sampler_OcclusionMap);
// TEXTURE2D(_MetallicGlossMap);   SAMPLER(sampler_MetallicGlossMap);
// TEXTURE2D(_SpecGlossMap);       SAMPLER(sampler_SpecGlossMap);




half4 SampleRMAO(float2 uv) 
{
    return SAMPLE_TEXTURE2D(_RMAOMap, sampler_RMAOMap, uv);
}


// #ifdef _SPECULAR_SETUP
//     #define SAMPLE_METALLICSPECULAR(uv) SAMPLE_TEXTURE2D(_SpecGlossMap, sampler_SpecGlossMap, uv)
// #else
//     #define SAMPLE_METALLICSPECULAR(uv) SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, uv)
// #endif

// half4 SampleMetallicSpecGloss(float2 uv, half albedoAlpha)
// {
//     half4 specGloss;
//
// #ifdef _METALLICSPECGLOSSMAP
//     specGloss = SAMPLE_METALLICSPECULAR(uv);
//     #ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
//         specGloss.a = albedoAlpha * _Smoothness;
//     #else
//         specGloss.a *= _Smoothness;
//     #endif
// #else // _METALLICSPECGLOSSMAP
//     #if _SPECULAR_SETUP
//         specGloss.rgb = _SpecColor.rgb;
//     #else
//         specGloss.rgb = _Metallic.rrr;
//     #endif
//
//     #ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
//         specGloss.a = albedoAlpha * _Smoothness;
//     #else
//         specGloss.a = 1;
//     #endif
// #endif
//
//     return specGloss;
// }

// half SampleOcclusion(float2 uv)
// {
// #ifdef _OCCLUSIONMAP
// // TODO: Controls things like these by exposing SHADER_QUALITY levels (low, medium, high)
// #if defined(SHADER_API_GLES)
//     return SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv).g;
// #else
//     half occ = SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv).g;
//     return LerpWhiteTo(occ, _OcclusionStrength);
// #endif
// #else
//     return 1.0;
// #endif
// }


// Returns clear coat parameters
// .x/.r == mask
// .y/.g == smoothness
// half2 SampleClearCoat(float2 uv)
// {
// #if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
//     half2 clearCoatMaskSmoothness = half2(_ClearCoatMask, _ClearCoatSmoothness);
//
// #if defined(_CLEARCOATMAP)
//     clearCoatMaskSmoothness *= SAMPLE_TEXTURE2D(_ClearCoatMap, sampler_ClearCoatMap, uv).rg;
// #endif
//
//     return clearCoatMaskSmoothness;
// #else
//     return half2(0.0, 1.0);
// #endif  // _CLEARCOAT
// }

// void ApplyPerPixelDisplacement(half3 viewDirTS, inout float2 uv)
// {
// #if defined(_PARALLAXMAP)
//     uv += ParallaxMapping(TEXTURE2D_ARGS(_ParallaxMap, sampler_ParallaxMap), viewDirTS, _Parallax, uv);
// #endif
// }

// Used for scaling detail albedo. Main features:
// - Depending if detailAlbedo brightens or darkens, scale magnifies effect.
// - No effect is applied if detailAlbedo is 0.5.
// half3 ScaleDetailAlbedo(half3 detailAlbedo, half scale)
// {
//     // detailAlbedo = detailAlbedo * 2.0h - 1.0h;
//     // detailAlbedo *= _DetailAlbedoMapScale;
//     // detailAlbedo = detailAlbedo * 0.5h + 0.5h;
//     // return detailAlbedo * 2.0f;
//
//     // A bit more optimized
//     return 2.0h * detailAlbedo * scale - scale + 1.0h;
// }

// half3 ApplyDetailAlbedo(float2 detailUv, half3 albedo, half detailMask)
// {
// #if defined(_DETAIL)
//     half3 detailAlbedo = SAMPLE_TEXTURE2D(_DetailAlbedoMap, sampler_DetailAlbedoMap, detailUv).rgb;
//
//     // In order to have same performance as builtin, we do scaling only if scale is not 1.0 (Scaled version has 6 additional instructions)
// #if defined(_DETAIL_SCALED)
//     detailAlbedo = ScaleDetailAlbedo(detailAlbedo, _DetailAlbedoMapScale);
// #else
//     detailAlbedo = 2.0h * detailAlbedo;
// #endif
//
//     return albedo * LerpWhiteTo(detailAlbedo, detailMask);
// #else
//     return albedo;
// #endif
// }

// half3 ApplyDetailNormal(float2 detailUv, half3 normalTS, half detailMask)
// {
// #if defined(_DETAIL)
// #if BUMP_SCALE_NOT_SUPPORTED
//     half3 detailNormalTS = UnpackNormal(SAMPLE_TEXTURE2D(_DetailNormalMap, sampler_DetailNormalMap, detailUv));
// #else
//     half3 detailNormalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_DetailNormalMap, sampler_DetailNormalMap, detailUv), _DetailNormalMapScale);
// #endif
//
//     // With UNITY_NO_DXT5nm unpacked vector is not normalized for BlendNormalRNM
//     // For visual consistancy we going to do in all cases
//     detailNormalTS = normalize(detailNormalTS);
//
//     return lerp(normalTS, BlendNormalRNM(normalTS, detailNormalTS), detailMask); // todo: detailMask should lerp the angle of the quaternion rotation, not the normals
// #else
//     return normalTS;
// #endif
// }

/*
inline void InitializeStandardLitSurfaceData(float2 uv, out SurfaceData outSurfaceData)
{
    half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
    outSurfaceData.alpha = Alpha(albedoAlpha.a, _BaseColor, _Cutoff);

    half4 specGloss = SampleMetallicSpecGloss(uv, albedoAlpha.a);
    outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb * _GlobalTintAttenuation;

#if _SPECULAR_SETUP
    outSurfaceData.metallic = 1.0h;
    outSurfaceData.specular = specGloss.rgb;
#else
    outSurfaceData.metallic = specGloss.r;
    outSurfaceData.specular = half3(0.0h, 0.0h, 0.0h);
#endif

    outSurfaceData.smoothness = specGloss.a;
    outSurfaceData.normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
    outSurfaceData.occlusion = SampleOcclusion(uv);
    outSurfaceData.emission = SampleEmission(uv, _EmissionColor.rgb, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap));

#if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
    half2 clearCoat = SampleClearCoat(uv);
    outSurfaceData.clearCoatMask       = clearCoat.r;
    outSurfaceData.clearCoatSmoothness = clearCoat.g;
#else
    outSurfaceData.clearCoatMask       = 0.0h;
    outSurfaceData.clearCoatSmoothness = 0.0h;
#endif

#if defined(_DETAIL)
    half detailMask = SAMPLE_TEXTURE2D(_DetailMask, sampler_DetailMask, uv).a;
    float2 detailUv = uv * _DetailAlbedoMap_ST.xy + _DetailAlbedoMap_ST.zw;
    outSurfaceData.albedo = ApplyDetailAlbedo(detailUv, outSurfaceData.albedo, detailMask);
    outSurfaceData.normalTS = ApplyDetailNormal(detailUv, outSurfaceData.normalTS, detailMask);

#endif
}
*/

// inline void InitializeStandardLitSurfaceData(float2 uv, out SurfaceData outSurfaceData)
// {
//
//     // 工作流改为 gamma with linear, 光照计算仍然在线性空间计算
//     // Albedo贴图输出在Gamma空间, Shader中采样的时候做一次Gamma2.2的矫正 (使得贴图在Shader中变为线性空间)
//     // 最终输出的时候在转换到sRGB空间
//     half4 albedoAlpha = SampleAlbedoAlpha(uv + (_Time.yy * _UVSpeed.xy) * step(0.5, _UVMove), TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
//     // Gamma correction
//
//     albedoAlpha = SCENE_FAST_SRGB_TO_LINEAR(albedoAlpha);
//         
//     // outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;
//     outSurfaceData.albedo = albedoAlpha.rgb * SCENE_FAST_SRGB_TO_LINEAR(_BaseColor.rgb);
//     outSurfaceData.alpha = Alpha(albedoAlpha.a, _BaseColor, _Cutoff);
//
//     half4 rmaoFactor = SCENE_FAST_SRGB_TO_LINEAR(SampleRMAO(uv));
//     outSurfaceData.metallic = rmaoFactor.g * _Metallic;
//     outSurfaceData.smoothness = RoughnessToPerceptualSmoothness(PerceptualRoughnessToRoughness(rmaoFactor.r * _Rounghness));
//     outSurfaceData.occlusion = rmaoFactor.b * (1-_OcclusionStrength);
//     #if defined(_FLOWMAP_NORMAL) || defined(_FLOWMAP_BOTH) // 开启流动法线时，需要两次采样Normal进行混合，在外部完成采样，这里直接返回Zero Vector
//     outSurfaceData.normalTS = half3(0.0h, 0.0h, 1.0h);
//     #else
//     outSurfaceData.normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
//     #endif
//     outSurfaceData.emission = SampleEmission(uv + (_UVSpeed.xy * _Time.yy) * step(0.5, _UVMove), _EmissionColor.rgb, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap));
//
//     // #if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
//     // half2 clearCoat = SampleClearCoat(uv);
//     // outSurfaceData.clearCoatMask       = clearCoat.r;
//     // outSurfaceData.clearCoatSmoothness = clearCoat.g;
//     // #else
//     outSurfaceData.clearCoatMask       = 0.0h;
//     outSurfaceData.clearCoatSmoothness = 0.0h;
//     // #endif
//
//     // #if defined(_DETAIL)
//     // half detailMask = SAMPLE_TEXTURE2D(_DetailMask, sampler_DetailMask, uv).a;
//     // float2 detailUv = uv * _DetailAlbedoMap_ST.xy + _DetailAlbedoMap_ST.zw;
//     // outSurfaceData.albedo = ApplyDetailAlbedo(detailUv, outSurfaceData.albedo, detailMask);
//     // outSurfaceData.normalTS = ApplyDetailNormal(detailUv, outSurfaceData.normalTS, detailMask);
//     //
//     // #endif
//
//     // deprecated
//     outSurfaceData.specular = half3(0.0h, 0.0h, 0.0h);
// }

void InitializeXYStandardLitSurfaceData(float2 uv, out XYSurfaceData outSurfaceData)
{

    // 工作流改为 gamma with linear, 光照计算仍然在线性空间计算
    // Albedo贴图输出在Gamma空间, Shader中采样的时候做一次Gamma2.2的矫正 (使得贴图在Shader中变为线性空间)
    // 最终输出的时候在转换到sRGB空间
    half4 albedoAlpha = SampleAlbedoAlpha(uv + (_Time.yy * _UVSpeed.xy) * step(0.5, _UVMove), TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
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
    outSurfaceData.emission = SampleEmission(uv + (_UVSpeed.xy * _Time.yy) * step(0.5, _UVMove), _EmissionColor.rgb, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap));
}

// vertex ani

struct VertexAnimData
{
    float3 vertexPos; 
    float2 baseMapUv;
    float2 uv;
    half4 vertexColor;
};

#if defined(_VERTEXANIM_ON)  || defined (_VERTEXANIM_ANCHOR_ON)
#define INIT_VERTEX_ANIM_DATA VertexAnimData vd = (VertexAnimData)0;\
vd.vertexPos = input.positionOS;\
vd.uv = input.texcoord;\
vd.baseMapUv = output.uv;\
vd.vertexColor = input.color;
#define DOVERTEXANIM  input.positionOS.xyz = DoVertexAnim(vd, _VertexAniUseVertexCol);
#else
#define INIT_VERTEX_ANIM_DATA
#define DOVERTEXANIM 
#endif

float3 DoVertexAnim(VertexAnimData animData, half useVertexCol = 0.0h)
{
    // TODO  看他们用顶点色还是tex half tempStrength =  SAMPLE_TEXTURE2D_LOD();
    // TODO 确定权重方式后，去掉另外一种
    float tempStrength = SAMPLE_TEXTURE2D_LOD(_AnimWeightMap,sampler_AnimWeightMap,animData.baseMapUv,0).r;
    tempStrength = lerp(tempStrength, animData.vertexColor.r, useVertexCol);
    float2 uv = TRANSFORM_TEX(animData.baseMapUv,_NoiseMap);
    float2 uvB = uv; 
    uv.x -= (_Time.y * SPEED) % 1;
    uvB -= (_Time.y * SPEEDB) % 1;
    float offsetA =  SAMPLE_TEXTURE2D_LOD(_NoiseMap,sampler_NoiseMap,uv,0).r - 0.5;
    float offsetB =  SAMPLE_TEXTURE2D_LOD(_NoiseMap,sampler_NoiseMap,uvB,0).g - 0.5;
    half3 direction = normalize(_WindDirection.xyz) * STRENGTH * tempStrength * offsetA;
    half3 directionB = normalize(_WindDirectionB.xyz) * STRENGTHB * tempStrength * offsetB;
    float3 targetPoin = animData.vertexPos.xyz + direction + directionB;
		
    #if defined (_VERTEXANIM_ANCHOR_ON)
    float lenght = distance(_Anchor.xyz,animData.vertexPos.xyz);
    half3 dir = normalize(targetPoin-_Anchor.xyz);
    return lerp(targetPoin,dir*lenght+_Anchor.xyz,saturate(lenght/4));
    #else
    return targetPoin;
    #endif
}
#endif // UNIVERSAL_INPUT_SURFACE_PBR_INCLUDED

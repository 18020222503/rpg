// SPDX-License-Identifier: (Not available for this version, you are only allowed to use this software if you have express permission from the copyright holder and agreed to the latest NiloToonURP EULA)
// Copyright (c) 2020 Kuroneko ShaderLab

// For more information, visit -> https://github.com/ColinLeung-NiloCat/UnityURPToonLitShaderExample

// #pragma once is a safeguard best practice in almost every .hlsl, 
// doing this can make sure your .hlsl's user can include this .hlsl anywhere anytime without producing any multi include conflict
#ifndef __ToonCharacter_Shared_Input__
#define __ToonCharacter_Shared_Input__
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// samplers / CBUFFER(material local Uniforms) 
// you should put all per material uniforms of all passes inside this single UnityPerMaterial CBUFFER! 
// else SRP batching is not possible!
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// per material textures
// *all samplers don't need to put inside CBUFFER
TEXTURE2D(_MainTex);         
TEXTURE2D(_DecalTex);       
TEXTURE2D(_RMAOMap);       



#if _NORMALMAP
TEXTURE2D(_BumpMap);         SAMPLER(sampler_BumpMap);
#endif
#if _FLOWMAP_ON
TEXTURE2D(_FlowMap);         SAMPLER(sampler_FlowMap);
TEXTURE2D(_VertFlowTex);         SAMPLER(sampler_VertFlowTex);
#endif

#if _RAMP_LIGHTING
    TEXTURE2D(_RampLightingTex);         SAMPLER(linear_clamp_sampler);
#endif

#ifdef _ISFACE
    sampler2D _FaceAoMap;
    sampler2D _BlushMap;
#endif

#if _DISSOLVE
    TEXTURE2D(_DissCustomTex);      SAMPLER(sampler_DissCustomTex);
#endif

// NiloToon's global textures
TEXTURE2D(_TOONAverageShadowMapRT);
TEXTURE2D(_TOONCharSelfShadowMapRT);    SAMPLER_CMP(sampler_TOONCharSelfShadowMapRT);

// URP's global textures
// TEXTURE2D(_CameraDepthTexture);
// float4 _CameraDepthTexture_TexelSize;
TEXTURE2D(_ToonHairDepthTexture);
//sampler2D _ToonHairDepthTexture;
float4 _ToonHairDepthTexture_TexelSize;

// Material shader variables are not defined in SRP or URP shader library.
// This means _MainColor, _MainTex, _MainTex_ST, and all variables in the Properties section of a shader
// must be defined by the shader itself. If you define all those properties in CBUFFER named
// UnityPerMaterial, SRP can cache the material properties between frames and reduce significantly the cost
// of each drawcall.
// In this case, although URP's LitInput.hlsl contains the CBUFFER for some of the material
// properties defined in .shader file. As one can see this is not part of the ShaderLibrary, it specific to the
// URP Lit shader.
// So we are not going to use LitInput.hlsl, we will implement everything by ourself.
//#include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"

// put all your uniforms(usually things inside .shader file's properties{}) inside this CBUFFER, in order to make SRP batcher compatible
// see -> https://blogs.unity3d.com/2019/02/28/srp-batcher-speed-up-your-rendering/

// IMPORTANT NOTE: Do not #ifdef #endif the properties inside CBUFFER as SRP batcher can NOT handle different CBUFFER layouts.
CBUFFER_START(UnityPerMaterial)

    // base color
    half4   _MainColor;

    // alpha test
    half    _Cutoff;
    half    _DetailMapUV;
    half    _DecalTexAlpha;
    half    _showVertColorChannel;

    // face area
    half    _FaceAoOffset;
    half3   _FaceForwardDirection;
    half3   _FaceUpDirection;

    // lighting style
    half3   _HeadBonePosOffset;
    half    _UseSphereNormal;
    half    _ShowSphereNormal;
    half    _CelShadowIntensity;
    half    _CelShadeMidPoint;
    half    _CelShadeSoftnessx;
    // occlusion
    half    _OcclusionStrength;

    // ramp lighting texture
    //half    _RampLightingTexSampleUvY;
    //half    _RampStrength;
    //half    _useVertColorSamplingUvY;

    //CustomHSVShadowColor
    half    _ShowLightColorMask;
    half    _lightColorThreshold;
    half    _LowSaturationThreshold;

    half4   _LowSaturationFallbackColor;
    half4   _CelShadowOcclusionColorSV;

    half    _SelfShadowAreaHueOffset_light;
    half    _SelfShadowAreaSaturationBoost_light;
    half    _SelfShadowAreaValueMul_light;
    half4   _SelfShadowTintColor_light;
    half4   _CelShadowOcclusionColorV;

    half    _SelfShadowAreaHueOffset_dark;
    half    _SelfShadowAreaSaturationBoost_dark;
    half    _SelfShadowAreaValueMul_dark;
    half4   _SelfShadowTintColor_dark;
    half4   _CelShadowOcclusionColorD;

    half    _CelShadowReflectIntensity;
    half    _CelShadowReflectIntensityLightMulty;
    half    _CelShadowReflectWidthx;
    half    _CelShadowReflectSmooth;
    half4   _CelShadowReflectColor;

    // depth texture rim light and shadow
    //half    LOADING_DEPTH_ON;
    //half    _useNoVRimLight;
    //half    _FresnelPoint;
    //half    _FresnelSoft;
    
    half   _DepthTexRimLightAndShadowWidthMultiplier;
    //
    // half    _DepthTexRimLightUsage;
    // half3   _DepthTexRimLightTintColor;
    // half   _DepthTexRimFadeoutRange;
    // half   _DepthTexRimThresholdOffset;

    //Fix：暂时关闭刘海深度阴影
    //half    _FaceDepthTexShadowWidthMultiplier;
    // half    _DepthTexShadowUsage;
    half   _DepthTexShadowThresholdOffset;
    //half   _DepthTexShadowFadeoutRange;
    half3   _DepthTexShadowTintColor;
    // half    _UseDepthShadowTintColorToAO;

    // specular
    half    _UseGGXDirectSpecular;
    half    _GGXDirectSpecularSmoothnessMultiplier;
    half    _SpecularFadeDistance;

    half    _SpecularIntensity;
    half    _MultiplyBaseColorToSpecularColor;
    half3   _SpecularColor;
    half    _SpecularAreaRemapUsage;
    half    _SpecularAreaRemapMidPoint;
    half    _SpecularAreaRemapRange;

    // emission
    half    _UseEmission;
    half3   _EmissionColor;

    // average shadow mapping
    float   _AverageShadowMapRTSampleIndex;

    // outline
    half    _RenderOutline;
    half    _OutlineUseBakedSmoothNormal;
    half    _OutlinePixelWidth;
    half    _useVertColorR;
    half3   _OutlineTintColor;
    half3   _OutlineEmissionCol;
    half   _OutlineReplace;

    // per char center
    // half _CharacterHeight;
    // half _CharacterWidth;
    // half _CharacterLength;
    // half _CharacterMax;

    //VAT
    half    _VAT_ON;
    half    _sinoffset;
    half    _sinpinlv;
    half    _speedsin;
    //half    _usesin;

    half    _offsetX;
    half    _offsetY;
    half    _offsetZ;

    float4  _PovitPosWS;
    half4   _PovitPosOffset;
    half3   _PovitPosWSForward;
    half3   _PovitPosWSUp;

    // perspective removal
    half   _PerspectiveRemovalAmount;
    half   _PerspectiveRemovalRadius;
    half3  _HeadBonePositionWS;
    
    // //dissolve
    half _DISSOLVE_ON;
    half    _DissNoiseScale1;
    half    _DissNoiseScale2;
    half    _DissSpeed1;
    half    _DissSpeed2;
    //half    _DissNoiseMul;
    //clip
    half    _DissDirect;
    half    _DissDirectInvert;
    half    _DissDirProgress;
    half    _DissClipWidth;
    //half    _DissClipPow;
    half    _DissClipRemapMin;
    half    _DissClipRemapMax;
    //half    _ShowDissClipMask;
    //anim
    half    _DissAnimDelay;
    half    _DissAnimPow;
    half    _DissAnimStren;
    half    _DissAnimNormalStren;
    //half    _ShowDissAnimMask;
    //edge
    half4   _DissDirEdgeColor;
    //half    _DissEdgeWidth;
    //half    _DissEdgePow;
    //half    _DissClipMul;

    //Dissolve
    half    _DissNoiseSelect;
    half    _DissNoiseUV;
    half    _DissNoiseScalex;
    half2   _DissSpeed;
    half    _DissProgress;
    half    _DissFirstStageEnd;
    half    _DissSecondStageStart;
    half    _DissEdgeWidthx;
    half    _DissEdgeSmooth;
    //half    _DissEdgeBloom;
    half    _DissEdgeBloomSten;
    half3   _DissEdgeColor;
    half4   _DissCustomTex_ST;

    // Energy Filed
    half    _EFSize;
    half    _EFEdgeThreshold;
    half    _EFEdgeSmooth;

    //flowMap
    half _BumpScale;
    half3 _FlowOffsetSpeed;
    half4 _ColorFlowOffsetSpeed;
    half4 _FlowVert;
    half _applyColorFlow;
    half4 _VertFlowTex_ST;
    half _showFlowVert;
    half _applyVertFlow;
    half _useVertColB;

    //DissolveOpt
    // half  _DISSOLVEE_ON;
    // half  _DissolveMappUV;
    // half  _DissolveMaskUV;
    // half4 _DissolveSpeed;
    // half  _DissolProgress;
    // half  _DissolDirect;
    // half  _DissolDirectInvert;
    // half4 _DissolClipParams;
    // half3 _DissolEdgeColor;
    // half  _DissolEdgeColorWidth;
    // half3  _DissolVertParams;
    // half4  _DissolveMapp_ST;

    //FresnelRim
    half  _FresnelRim_ON;
    half  _FresnelRimMainLightEffect;
    half4 _FresnelRimParams;
    half3 _FresnelRimColor;
    //特效用
    half  _FXFresnelRim_ON;
    half4 _FXFresnelRimParams;
    half3 _FXFresnelRimColor;

    half  _RenderType_PARAM;

    //相机灯光
    half3   _CameraLightPosWS;
    half3   _CameraLightPosVS;
    half    _UseCameraLight;

    //dither
    half    _DITHERFADEOUT_ON;
    half    _DitherFadeoutAmount;

    half   _FresnelRampInvert;
    half4   _FresnelRampParams;
    half4    _FresnelNoiseUV;
    
CBUFFER_END

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Global uniforms
// if an uniform is not a per material uniform, 
// it is fine to write it outside of CBUFFER_START(UnityPerMaterial)
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// a special uniform for applyShadowBiasFixToHClipPos() only
float3 _LightDirection;
half    _EnableHairShadow;
// global outline uniforms
float _GlobalShouldRenderOutline;
float _GlobalOutlineWidthMultiplier;


// //角色Bloom阈值调整
// half    _characterBloomIntensity;
// half    _characterBloomThreshold;
// //深度边缘光和自投影
// half    _SELF_SHADOW_ON;
// // 颜色调整调整
// half4   _GlobalCharacterBaseColorTint; //整体颜色Tint
// half4   _GlobalCharacterLightColor; //亮部颜色
// half4   _GlobalCharacterShadowColor; //暗部颜色
// //环境光影响
// half    _MainLightColorEffect; //主光颜色影响
// half    _IndirectLightColorEffect; //环境光颜色影响
// half    _GlobalCharFogEffect;
//亮部颜色
// half4   _GlobalCharacterLightColor;
half4   _GlobalCharacterBaseColorTint; //整体颜色Tint

//Color & Light Params
//use (R/G/B) no use(A)
half4 _GlobalCharacterParams;
//use (R/G/B/A)
half4 _GlobalCharacterLightParams1;
//use (R/G/B/A)
half4 _GlobalCharacterLightParams2;

#define _GlobalCharacterLightColor _GlobalCharacterLightParams1.rgb

//暗部颜色
// half4   _GlobalCharacterShadowColor; 
#define _GlobalCharacterShadowColor _GlobalCharacterLightParams2.rgb

//环境光影响
//主光颜色影响
// half    _MainLightColorEffect; 
#define _MainLightColorEffect _GlobalCharacterLightParams1.a
//环境光颜色影响
// half    _IndirectLightColorEffect; 
#define _IndirectLightColorEffect _GlobalCharacterLightParams2.a 

//Bloom
// half    _characterBloomThreshold;
#define _characterBloomThreshold _GlobalCharacterParams.r
// half    _characterBloomIntensity;
#define _characterBloomIntensity _GlobalCharacterParams.g
//fog
// half    _GlobalCharFogEffect;
#define _GlobalCharFogEffect _GlobalCharacterParams.b
#define _GlobalCharProbeOcclusionEffect _GlobalCharacterParams.a

// global shadow mapping uniforms
float _GlobalShouldReceiveShadowMapping;
half _GlobalReceiveShadowMappingAmount;
float _GlobalToonShaderNormalBiasMultiplier;
half3 _GlobalMainLightURPShadowAsDirectResultTintColor;

// self shadow mapping
float4x4 _TOONSelfShadowWorldToClip;
float4 _TOONSelfShadowParam;
float _TOONSelfShadowRange;
float _TOONSelfShadowDepthBias;

// global occlusion uniforms
half _GlobalOcclusionStrength;

// global lighting uniforms
// half _GlobalIndirectLightMultiplier;
// half3 _GlobalIndirectLightMinColor;

// global depth diff rim light and shadow uniforms
// float _GlobalDepthTexRimLightAndShadowWidthMultiplier;
// float _GlobalDepthTexRimLightDepthDiffThresholdOffset;

// global light uniforms
half3 _GlobalMainLightDirVS;

// global camera uniforms
float _CurrentCameraFOV;

// global camera fix
float2 _GlobalAspectFix;
float _GlobalFOVorOrthoSizeFix;

half3 _GlobalVolumeMulColor;
half4 _GlobalVolume;
// global volumeLerpColor;
half3 _GlobalRimLightMultiplier;
half3 _GlobalMainDirectionalLightMaxContribution;
half3 _GlobalAdditionalLightMaxContribution;
//half _GlobalSpecularIntensityMultiplier;
//half _GlobalSpecularMinIntensity;
half3 _GlobalMainDirectionalLightMultiplier;
half3 _GlobalAdditionalLightMultiplier;
half3 _GlobalVolumeBaseColorTintColor;
half4 _GlobalVolumeLerpColor;
// global debug
float _GlobalToonShadeDebugCase;

half4   _GlobalToonOutlineWidthFix;
#define _GlobalToonOutlineWidthFixDistMin _GlobalToonOutlineWidthFix.r
#define _GlobalToonOutlineWidthFixDistMax _GlobalToonOutlineWidthFix.g
#define _GlobalToonOutlineWidthFixFOVMin _GlobalToonOutlineWidthFix.b
#define _GlobalToonOutlineWidthFixFOVMax _GlobalToonOutlineWidthFix.a

half4 _BlushParams;
half4 _BlushRColor;
half4 _BlushGColor;
half4 _BlushBColor;


#endif
#ifndef FX_ICE_INPUT_INCLUDE
#define FX_ICE_INPUT_INCLUDE


#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/FX/FXCommonGlobalVar.hlsl"

TEXTURE2D(_BaseMap);            SAMPLER(sampler_BaseMap);
TEXTURE2D(_RampTex);            SAMPLER(sampler_RampTex);
TEXTURE2D(_NormalMap);          SAMPLER(sampler_NormalMap);
TEXTURE2D(_DitherMask);         SamplerState DitherMask_point_clamp_sampler;


//#ifdef _VOLUMETRIC_NOISE_UV_ON
TEXTURE2D(_VolNoiseTex);        SAMPLER(sampler_VolNoiseTex);
//#endif

//#ifdef _CLEARNESS_DISTORTION_ON
TEXTURE2D(_CameraTransparentTexture);  SAMPLER(sampler_CameraTransparentTexture);
//#endif

//#ifdef _DISSOLVE_ON
TEXTURE2D(_DissTex);            SAMPLER(sampler_DissTex);
//#endif


CBUFFER_START(UnityPerMaterial)
// Base Map
real4 _BaseMap_ST;
real _BaseWrapMode;
real _BaseUVMoveMode;
real _BaseUSpeed;
real _BaseVSpeed;
real _BaseRotAngle;

// Ramp Map
real4 _RampTex_ST;
real4 _RampColor1;
real4 _RampColor2;
real4 _RampValueCtrl;
real _InvertRampTex;

// Normal Map 
real4 _NormalMap_ST;
real _NormalScale;

// Volumetric Control
//#ifdef _VOLUMETRIC_NOISE_UV_ON
real4 _VolNoiseTex_ST;
real _VolUVOffsetNoiseON;
real _VolNoiseType;
real _VolNoiseScale;
real _VolNoiseAngle;
real _VolNoiseDensity;
real _InvertVolNoise;
real _VolUVNoiseStren;
//#endif
real _VolUVOffsetStren;

// Distortion
//#ifdef _CLEARNESS_DISTORTION_ON
half _ClearnessOn;
real _Clearness;
real _DistortionStren;
real _RampClearnessOn;
real _FresnelClearnessPow;
real _FresnelClearnessOn;
//#endif

// RimLight
//#ifdef _RIM_LIGHT_ON
half _FresnelOn;
real4 _FresnelColor;
real _FresnelPow;
//#endif

// Spec Light
//#ifdef _SPECULAR_LIGHT_ON
real4 _SpecLightDir;
real4 _SpecColor;
real _Shininess;
//#endif

// Dissovle
//#ifdef _DISSOLVE_ON
real4 _DissTex_ST;
real4 _DissEdgeColor;
real4 _DissParams;
real _DissNoiseType;
real _DissNoiseScale;
real _DissNoiseAngleOffset;
real _InvertDissNoise;
real _DissNoiseCellDensity;
real _DissEdgeWidth;
real _DissAmoutByCustomData1X;
//#endif

// Bloom
half _BloomOn;
half4 _BloomTint;

real _AlphaClip;
real _Cutoff;

real _FogOn;

CBUFFER_END
#if  DEBUG_DISPLAY
CBUFFER_START(PerDebugMaterial)
half _Blend;
CBUFFER_END
#endif
#endif
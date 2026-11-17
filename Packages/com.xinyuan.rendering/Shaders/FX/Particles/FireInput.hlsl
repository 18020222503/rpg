#ifndef FX_PARTICLE_FIRE_INPUT_INCLUDED
#define FX_PARTICLE_FIRE_INPUT_INCLUDED


#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/FX/FXCommonGlobalVar.hlsl"

TEXTURE2D(_FireTex);            //SAMPLER(sampler_FireTex);
TEXTURE2D(_NoiseTex);           //SAMPLER(sampler_NoiseTex);
TEXTURE2D(_Noise2Tex);          //SAMPLER(sampler_Noise2Tex);
TEXTURE2D(_NoiseMask);          //SAMPLER(sampler_NoiseMask);
TEXTURE2D(_DisplaceMap);        //SAMPLER(sampler_DisplaceMap);
TEXTURE2D(_DissMap);            //SAMPLER(sampler_DissMap);
TEXTURE2D(_AlphaMaskTex);       //(sampler_AlphaMaskTex);


CBUFFER_START(UnityPerMaterial)
float4 _FireTex_ST;
float4 _NoiseTex_ST;
float4 _Noise2Tex_ST;
float4 _NoiseMask_ST;
float4 _DisplaceMap_ST;
float4 _DissMap_ST;
float4 _AlphaMaskTex_ST;

// Base
half4 _InnerCol;
half4 _OuterCol;
half4 _MainCol;
half _FireTexUVMoveMode;
half _FireTexUVWrapMode;
half _FireTexUSpeed;
half _FireTexVSpeed;
half _FresnelScale;
half _FresnelPower;
half _RemapNewMin;
half _RemapNewMax;

// Noise
//half _NoiseType;
//half _NoiseScale;
half _NoiseStrenByCustomData;
half _NoiseTexUVWrapMode;
half _NoiseStren;
//half _NoiseAngle;
//half _NoiseDensity;
half _NoiseUSpeed;
half _NoiseVSpeed;
half _InvertNoise;

// Noise2
half _AlphaSimulateOn;
//half _Noise2Type;
//half _Noise2Scale;
half _Noise2StrenByCustomData;
half _Noise2TexUVWrapMode;
half _Noise2Stren;
//half _Noise2Angle;
//half _Noise2Density;
half _Noise2USpeed;
half _Noise2VSpeed;
half _InvertNoise2;

// distortion Mask
half _MaskType;
//half _NoiseMaskRot;
half _NoiseMaskPow;
half _InvertMask;

// Displacement
half _InvertDisplaceMap;
half _DisplaceUVWrapMode;
half _DisplaceUVMoveMode;
half _DisplaceUSpeed;
half _DisplaceVSpeed;
half _DisplaceStrenByCustomData;
half _DisplaceStren;

// Dissolve
half _DissovleOn;
half _InvertDissMap;
half _DissUVWrapMode;
half _DissUVMoveMode;
half _DissUSpeed;
half _DissVSpeed;
half _DissStren;
half _DissSmooth;
half _DissStrenByCustomData;
half _DissovleRandomOn;

// Alpha Mask
half _AlphaMaskOn;
//half _AlphaMaskRot;
half _AlphaMaskStren;
half _InvertAlphaMask;
half _AlphaMaskDistort;
half _AlphaMaskUVWrapMode;
// Gameplay Control
half _AlphaMultiplyer;

// Bloom
half _BloomOn;
half4 _BloomTint;

half _Cutoff;
half _TransparentZWrite;
half _FogOn;

half _DepthOffsetOn;
half _ZOffsetViewSpace;

half _FresnelMaskOn;
half _FresnelMaskMul;
half _FresnelMaskPow;
CBUFFER_END

#if  DEBUG_DISPLAY
CBUFFER_START(PerDebugMaterial)
half _Blend;
CBUFFER_END
#endif


#endif

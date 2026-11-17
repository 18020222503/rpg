#ifndef RANDOM_LIU_GUANG_INPUT_INCLUDED
#define RANDOM_LIU_GUANG_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/FX/FXCommonGlobalVar.hlsl"

TEXTURE2D(_BaseTex1);			SAMPLER(sampler_BaseTex1);
TEXTURE2D(_BaseTex2);			SAMPLER(sampler_BaseTex2);
TEXTURE2D(_NoiseTex);			//SAMPLER(sampler_NoiseTex);
TEXTURE2D(_DissolveTex);		//SAMPLER(sampler_DissolveTex);
TEXTURE2D(_MaskTex1);			//SAMPLER(sampler_MaskTex1);
TEXTURE2D(_MaskTex2);			//SAMPLER(sampler_MaskTex2);


CBUFFER_START(UnityPerMaterial)

half4 _Color1;
half4 _Color2;
half4 _BloomTint;
// 基础纹理1 
float4 _BaseTex1_ST;
float4 _BaseTexUVSpeed;
float4 _BaseTex12PM;
half   _BaseTex1UVMoveMode;
half   _BaseTex1UVWrapMode;

// 基础纹理2
float4 _BaseTex2_ST;
half   _BaseTex2UVMoveMode;
half   _BaseTex2UVWrapMode;

// 噪声贴图
float4 _NoiseTex_ST;
float4 _NoiseTexSpeed;
half   _NoiseTexUVMoveMode;
half   _NoiseTexUVWrapMode;

// 溶解贴图
float4 _DissolveTex_ST;
float4 _DissolveSpeed;
half   _DissolveUVMoveMode;
half   _DissolveUVWrapMode;

// 遮罩贴图1
float4 _MaskTex1_ST;
half _MaskTexOn;
half _MaskTex1UVWrapMode;
half   _Mask1UVMoveMode;
half   _Mask1UVWrapMode;

// 遮罩贴图2
float4 _MaskTex2_ST;
half   _Mask2UVMoveMode;
half   _Mask2UVWrapMode;

half   _Desature1;
half   _Desature2;

half _OpenRandomTex1UV;
half _OpenRandomTex2UV;
half _OpenRandomNoiseUV;
half _OpenRandomDissolveUV;

half _NoiseIntensity1;
half _NoiseIntensity2;

half _ColorLerp;

half  _OpenDissolve;
half _DissolveNoiseIntensity;
half  _Dissolve;
half _DissolveTexUVWrapMode;
half  _DissolveByCustomData;
half  _DissolveEdge;

half  _VertexAlphaOrderChange;
half _MaskTex2UVWrapMode;
half _OpenUDirMask;
half _OpenVDirMask;

half _Mask1NoiseIntensity;
half _Mask1AlphaMultiply;

half _AlphaMin;
half _AlphaEdge;

half _ZWrite;
half _DepthOffsetOn;
half _ZOffsetViewSpace;
half _BloomOn;
half _AlpahCaleOn;

half _TotalAlpha;
half _Cutoff;
CBUFFER_END

#if  DEBUG_DISPLAY
CBUFFER_START(PerDebugMaterial)
half _Blend;
CBUFFER_END
#endif

#endif
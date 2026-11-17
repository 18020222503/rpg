#ifndef FX_PARTICLE_EXPLOSION_INPUT_INCLUDED
#define FX_PARTICLE_EXPLOSION_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/FX/FXCommonGlobalVar.hlsl"


TEXTURE2D(_DisplaceMap);            SAMPLER(sampler_DisplaceMap);
TEXTURE2D(_DissMap);                SAMPLER(sampler_DissMap);



CBUFFER_START(UnityPerMaterial)

float4 _DisplaceMap_ST;
float4 _DissMap_ST;

half4 _HighTempCol;
half4 _MidTempCol;
half4 _LowTempCol;

half _MidTempRange;
half _LowTempRange;
half _MidTempEdgeSmooth;
half _LowTempEdgeSmooth;

half _InvertDisplaceMap;
half _DisplaceUVWrapMode;
half _DisplaceUVMoveMode;
half _DisplaceUSpeed;
half _DisplaceVSpeed;
half _DisplaceStren;

half _InvertDissMap;
half _DissUVWrapMode;
half _DissUVMoveMode;
half _DissUSpeed;
half _DissVSpeed;
half _DissStren;
half _DissSmooth;

// Gameplay Control
half _AlphaMultiplyer;

// Bloom
half _BloomOn;
half4 _BloomTint;

half _FogOn;

//#if defined(_LASEREND_ON)
half3 _HitPositionWS;
half3 _LaserDirWS;
//#endif

CBUFFER_END
#if  DEBUG_DISPLAY
CBUFFER_START(PerDebugMaterial)
half _Blend;
CBUFFER_END
#endif
#endif
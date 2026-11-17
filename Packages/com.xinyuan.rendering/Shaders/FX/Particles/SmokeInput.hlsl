#ifndef FX_PARTICLE_SMOKE_INPUT_INCLUDED
#define FX_PARTICLE_SMOKE_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/FX/FXCommonGlobalVar.hlsl"

TEXTURE2D(_BaseMap);					SAMPLER(sampler_BaseMap);

//#ifdef _BASE_DETAIL_MAP_ON
TEXTURE2D(_DetailMap);					SAMPLER(sampler_DetailMap);
//#endif

//#ifdef _MASK_ON
TEXTURE2D(_MaskMap);					SAMPLER(sampler_MaskMap); 
//#endif

//#ifdef _DISSOLVE_ON
TEXTURE2D(_DissolveMap);				SAMPLER(sampler_DissolveMap); 
//#endif

//#if defined(_DISTSTRENGTHMASK_ON)
TEXTURE2D(_DistStrengthControlMask);				SAMPLER(sampler_DistStrengthControlMask);
//#endif

TEXTURE2D(_DistMap);					SAMPLER(sampler_DistMap);
TEXTURE2D(_DetailDistMap);           SAMPLER(sampler_DetailDistMap);

//#if defined(_DEPTH_FADE_ON)
TEXTURE2D(_CameraDepthTexture);           SAMPLER(sampler_CameraDepthTexture);
//#endif

//#if defined(_SECONDARYDISTMAP_ON)
TEXTURE2D(_SecondaryDistMap);					SAMPLER(sampler_SecondaryDistMap);
//#endif

CBUFFER_START(UnityPerMaterial)
// Base Map
float4 _BaseMap_ST;
half4 _BaseColor;
half4 _HSV;
half _BaseColorByCutomData2;
half _AnimSheetOn;
half _BaseWrapMode;
half _BaseUVMoveMode;
half _BaseUSpeed;
half _BaseVSpeed;
half _Horizontal;
half _Vertical;
half _BaseRotAngle;
half _BaseRadialScale;
half _BaseLengthScale;
half _BaseMapDistortionStrength_A;
half _BaseMapDistortionStrength_B;
half _BaseMapDistStrenAByCustomData1;
half _BaseMapDistStrenBByCustomData1;
int _BaseMapDistStrenAChannel;
int _BaseMapDistStrenBChannel;

//#if defined(_DISTSTRENGTHMASK_ON)
half _DistStrengthMaskOn;
half _InvertDistMask;
half _DistMaskPower;
//#endif

half _DepthFadeOn;
half _DepthFadeRange;

// Custom Data channel chosen
half4 DistortionAChannel;
half4 DistortionBChannel;
half4 DistortionCChannel;
half4 DissolveProgressChannel;

// Detail Map
//#if defined(_BASE_DETAIL_MAP_ON)
float4 _DetailMap_ST;
half4 _DetailColor;
half _DetailWrapMode;
half _DetailUVMoveMode;
half _DetailUSpeed;
half _DetailVSpeed;
half _DetailRadialScale;
half _DetailLengthScale;
half _DetailRotAngle;
half _DetailStren;
//#endif

// Double Face
//#if defined(_DDUBLE_FACE_ON)
half4 _BackFaceColor;
half4 _BackFaceHSV;
//#endif

// Mask
//#if defined(_MASK_ON)
float4 _MaskMap_ST;
half _MaskOn;
half _MaskMapWrapMode;
half _MaskMapUVMoveMode;
half _MaskUSpeed;
half _MaskVSpeed;
half _MaskRotAngle;
half _MaskAddOn;
half _MaskAlphaStrength;
half _AlphaOn;
half _AlphaAddOn;
half _AlphaStrength;
half _MaskLengthScale;
half _MaskRadialScale;
//#endif

// Shape Distortion
float4 _DistMap_ST;
float4 _DetailDistMap_ST;
half _DistortionOn;
half _DistMapWrapMode;
half _DistMapUVMoveMode;
half _DistUSpeed;
half _DistVSpeed;
half _DistRotAngle;

half _DetailDistMapWrapMode;
half _DetailDistMapUVMoveMode;
half _DetailDistUSpeed;
half _DetailDistVSpeed;
half _DetailDistRotAngle;
half _DetailDistRadialScale;
half _DetailDistLengthScale;

half _DistStrenByCustomDataY;
half _DistStren;

half _DistRadialScale;
half _DistLengthScale;

// Dissolve
//#if defined(_DISSOLVE_ON)
float4 _DissolveMap_ST;
half4 _EdgeColor;
half _DissolveOn;
half _InvertDissolveMap;
half _DissolveMapWrapMode;
half _DissolveUVMoveMode;
half _DissolveUSpeed;
half _DissolveVSpped;
half _DissolveRadialScale;
half _DissolveLengthScale;
half _DissolveRotAngle;
half _DissolveByCustomData1;
int _DissolveCustomDataChannel;
half _Dissolve;
half _EdgeRange;
half _EdgeSmoothness;
half _EdgeColorMode;
half _FollowShapeDistortionOn;


half _DissolveDistortionStrength;
int _DissolveDistortionSource;

half _DissAChannelChosen;
half _DissBChannelChosen;
//#endif

    
// Near Camera Fade
//#if defined(_NEAR_CAMERA_FADE_ON)
half _NearFadeStar;
half _NearFadeRange;
//#endif

//#if defined(_SECONDARYDISTMAP_ON)
half4 _SecondaryDistMap_ST;
half _SecondaryDistMapWrapMode;
int _SecondaryDistMapDistortionSource;
half _SecondaryDistDistortionStrength;
//#endif

// Bloom
half _BloomOn;
half4 _BloomTint;

// Gameplay Control
half _AlphaMultiplyer;

half _FogOn;
half _Cutoff;
half _Cull;

//#if defined(_DEPTH_OFFSET_ON)
half _ZOffset;
//#endif
CBUFFER_END

#if  DEBUG_DISPLAY
CBUFFER_START(PerDebugMaterial)
half _Blend;
CBUFFER_END
#endif


#endif
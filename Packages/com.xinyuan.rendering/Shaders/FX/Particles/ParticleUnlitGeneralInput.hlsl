#ifndef PARTICLE_UNLIT_GENERAL_INPUT_INCLUDED
#define PARTICLE_UNLIT_GENERAL_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/FX/FXCommonGlobalVar.hlsl"

TEXTURE2D(_BaseMap);					//SAMPLER(sampler_BaseMap);

TEXTURE2D(_DetailMap);					//SAMPLER(sampler_DetailMap);

TEXTURE2D(_MaskMap);					//SAMPLER(sampler_MaskMap); 

TEXTURE2D(_DissolveMap);				//SAMPLER(sampler_DissolveMap); 

TEXTURE2D(_ShpDistMap);					//SAMPLER(sampler_ShpDistMap);
TEXTURE2D(_ShpDetailDistMap);           //SAMPLER(sampler_ShpDetailDistMap);

//TEXTURE2D(_AnimNoiseMap);				SAMPLER(sampler_AnimNoiseMap);

TEXTURE2D(_RfrDistMap);                 //SAMPLER(sampler_RfrDistMap);

TEXTURE2D(_VertexOffsetMaskMap);		//SAMPLER(sampler_VertexOffsetMaskMap);


// TEXTURE2D(_FlowNormalMap);			SAMPLER(sampler_FlowNormalMap);
// TEXTURE2D(_MatcapMap);			SAMPLER(sampler_MatcapMap);
// TEXTURE2D(_FlowMap);			SAMPLER(sampler_FlowMap);


TEXTURE2D(_ShpDistStrengthControlMask);			//SAMPLER(sampler_ShpDistStrengthControlMask);


TEXTURE2D(_CameraDepthTexture);			SAMPLER(sampler_CameraDepthTexture);
//TEXTURE2D(_CameraOpaqueTexture);        SAMPLER(sampler_CameraOpaqueTexture);

float _useOnGoogleSimulator;

CBUFFER_START(UnityPerMaterial)
// Base Map
float4 _BaseMap_ST;
half4 _BaseColor;
half4 _HSV;
half _BaseColorByCutomData2;
half _AnimSheetOn;
half _BaseWrapMode;
half _BaseUVMoveMode;
half _BaseScreenUV;
half _BaseUSpeed;
half _BaseVSpeed;
//half _Horizontal;
//half _Vertical;
half _BaseRotAngle;
half _BaseRadialScale;
half _BaseLengthScale;


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
//half _DetailRotAngle;
half _DetailStren;
//#endif

// Double Face
//#if defined(_DDUBLE_FACE_ON)
half4 _BackFaceColor;
//half4 _BackFaceHSV;
//#endif

// Mask
//#if defined(_MASK_ON)
float4 _MaskMap_ST;
half _MaskOn;
half _MaskMapChannel;
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
//#if defined(_DISTORTION_ON)
float4 _ShpDistMap_ST;
float4 _ShpDetailDistMap_ST;
half _ShpDistMapWrapMode;
half _ShpDistMapUVMoveMode;
half _ShpDistUSpeed;
half _ShpDistVSpeed;
//half _ShpDistRotAngle;

half _ShpDetailDistMapWrapMode;
half _ShpDetailDistMapUVMoveMode;
half _ShpDetailDistUSpeed;
half _ShpDetailDistVSpeed;
//half _ShpDetailDistRotAngle;
half _ShpDetailDistRadialScale;
half _ShpDetailDistLengthScale;
half _ShpDetailDistStrenOn;
half _ShpDetailDistStren;

half _ShpDistStrenByCustomDataY;
half _ShpDistStren;

half _ShpDistRadialScale;
half _ShpDistLengthScale;
half _DistStrengthMaskPower;
half _InvertDistMask;
half _ShpDistStrengthControlMaskChannel;
//#endif

// Refract Distortion
//#if defined(_REFRACT_DISTORTION_ON)
// float4 _RfrDistMap_ST;
// half _RfrDistOn;
// half _RfrDistMapWrapMode;
// half _RfrDistUVMoveMode;
// half _RfrDistUSpeed;
// half _RfrDistVSpeed;
// half _RfrDistRotAngle;
// half _RfrDistStren;
// half _RfrDistStrenByCustomData2X;
// half _RfrDistBlend;
// half _RfrDistBlendByCustomData2Y;
//#endif

// Dissolve
//#if defined(_DISSOLVE_ON)
float4 _DissolveMap_ST;
half _DissolveOn;
half _InvertDissolveMap;
half _DissolveMapWrapMode;
half _DissolveUVMoveMode;
half _DissolveUSpeed;
half _DissolveVSpped;
half _DissolveRadialScale;
half _DissolveLengthScale;
half _DissolveRotAngle;
half _DissolveByCustomDataX;
half _Dissolve;
half _EdgeRange;
half _EdgeSmoothness;
half _EdgeColorMode;
half4 _EdgeColor;
//#endif

// Fresnel
//#if defined(_FRESNEL_ON)
half4 _FresnelColor;
half _FresnelMode;
half _FresnelColorMode;
half _FresnelPow;
half _FresnelStrength;
half _InverFresnel;
//#endif

// Soft particle
//#if defined(_SOFTPARTICLES_ON)
//half _SoftParticleOn;
//half _SoftRange;
//#endif

// Depth Fade
//#if defined(_DEPTH_FADE_ON)
half _DepthFadeOn;
half _DepthFadeRange;
half _DepthFadePow;
half _DepthFadeMode;
//#endif

// Near Camera Fade
//#if defined(_NEAR_CAMERA_FADE_ON)
half _NearFadeStar;
half _NearFadeRange;
//#endif

// Vertex Animation
//#ifdef _VERTEXOFFSET_ON
half    _VertexOffsetMainTexOn;
half    _VertexOffsetMainTexColorOn;
half	_VertexMaskMapWrapMode;
//half	_VertexOffsetMaskRotAngle;
half	_VertexOffsetIntensity;
half4	_VertexOffsetMaskMap_ST;
half4	_VertexOffsetTexParams;
half    _VertexOffsetMaskUSpeed;
half    _VertexOffsetMaskVSpeed;
half    _VertexRandomByCutomData2w;
half    _VertexOffsetIntensityByCutomData2X;
half    _VertexOffsetMaskMapChannelMask;
//#endif

// Gameplay Control
half _AlphaMultiplyer;

// FlowMatcapUV
//#ifdef _FLOWMAP_ON 
// half4 _FlowSpeed;
// half4 _FlowTiling;
// half4 _FlowNormalMap_ST;
// half4 _FlowMap_ST;
// half4 _MatcapMap_ST;
// half4 _FlowOffsetSpeed;
// half _MatcapColorBlendMode;
// half _MatcapPower;
// half _FlowStrength;
// half _FlowNormalMapSampleMode;
//#endif
half _FogOn;
half _Cutoff;
half _Cull;
half _IgnoreNegativeEffect;

//#if defined(_LASEREND_ON)
// half3 _HitPositionWS;
// half3 _LaserDirWS;

//#endif

half4 _AlphaRemapping;

//#if defined(_DEPTH_OFFSET_ON)
half _ZOffsetViewSpace;

//#endif


// Bloom
half _BloomOn;
half4 _BloomTint;


half _DecalModeOn;
half3 _DecalRootRotation;


CBUFFER_END

#if  DEBUG_DISPLAY
CBUFFER_START(PerDebugMaterial)
half _Blend;
CBUFFER_END
#endif





#endif

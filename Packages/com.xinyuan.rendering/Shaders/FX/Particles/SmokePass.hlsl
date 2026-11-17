#ifndef FX_PARTICLE_SMOKE_PASS_INCLUDED
#define FX_PARTICLE_SMOKE_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
// #include "Packages/com.xinyuan.render-pipelines.core/ShaderLibrary/Color.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/Util.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/Math.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/Dissolve.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/UVHelper.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/FX/ParticlesInstancing.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/ColorAdjustment.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/ColorSpace.hlsl"

#include "Packages/com.xinyuan.rendering/ShaderLibrary/FX/FXDebug.hlsl"


#define TIME fmod(_Time.y, HALF_MAX)
#define CHANNEL_A_MASK 0x1
#define CHANNEL_B_MASK 0x2
#define CHANNEL_C_MASK 0x4
#define CHANNEL_D_MASK 0x8

#define BASE_DIST_SOURCE 0x1
#define DETAIL_DIST_SOURCE 0x2
#define SECONDARY_DIST_SOURCE 0x4

#define FOLDOUT 1
#define STATIC_BRANCH_START(flag) UNITY_BRANCH if (flag) {
#define STATIC_BRANCH_END }
#define KEY_WORD_START(kw) #if kw
#define KEY_WORD_END #endif

#if FOLDOUT
// _DISTORTION_ON (94.2%)
#ifdef _DISTORTION_BRANCH
	#define DISTORTION_START					STATIC_BRANCH_START(_DistortionOn)
	#define DISTORTION_END						STATIC_BRANCH_END
#else
	#define DISTORTION_START					KEY_WORD_START(_DISTORTION_ON)
	#define DISTORTION_END						KEY_WORD_END
#endif

// _FOLLOWSHAPEDISTORTION_ON (92.4%)
#ifdef _FOLLOWSHAPEDISTORTION_BRANCH
	#define FOLLOWSHAPEDISTORTION_START				STATIC_BRANCH_START(_FollowShapeDistortionOn)
	#define FOLLOWSHAPEDISTORTION_END				STATIC_BRANCH_END
#else
	#define FOLLOWSHAPEDISTORTION_START				KEY_WORD_START(_FOLLOWSHAPEDISTORTION_ON)
	#define FOLLOWSHAPEDISTORTION_END				KEY_WORD_END
#endif

//_DISTSTRENGTHMASK_ON (87.9%)
#ifdef _DISTSTRENGTHMASK_BRANCH
	#define DISTSTRENGTHMASK_START					STATIC_BRANCH_START(_DistStrengthMaskOn)
	#define DISTSTRENGTHMASK_END					STATIC_BRANCH_END
#else
	#define DISTSTRENGTHMASK_START					KEY_WORD_START(_DISTSTRENGTHMASK_ON)
	#define DISTSTRENGTHMASK_END					KEY_WORD_END
#endif


//_DEPTH_FADE_ON (84.8%)
#ifdef _DEPTH_FADE_BRANCH
	#define DEPTH_FADE_START						STATIC_BRANCH_START(_DepthFadeOn)
	#define DEPTH_FADE_END							STATIC_BRANCH_END
#else
	#define DEPTH_FADE_START						KEY_WORD_START(_DEPTH_FADE_ON)
	#define DEPTH_FADE_END							KEY_WORD_END
#endif

//_DISSOLVE_ON (58.2%)
#ifdef _DISSOLVE_BRANCH
	#define DISSOLVE_START							STATIC_BRANCH_START(_DissolveOn)
	#define DISSOLVE_END							STATIC_BRANCH_END
#else
	#define DISSOLVE_START							KEY_WORD_START(_DISSOLVE_ON)
	#define DISSOLVE_END							KEY_WORD_END
#endif

#endif // FOLDOUT

struct Attributes
{
    float3 positionOS				: POSITION;
    float3 normalOS					: NORMAL;
    float4 color					: COLOR;
    float4 texcoord					: TEXCOORD0;
    float4 customData				: TEXCOORD1;
    float4 customData2				: TEXCOORD2;

    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS		: SV_POSITION;
    half4 color				: COLOR;
    float4 uv				: TEXCOORD0;	
    half4 positionWS		: TEXCOORD2;
    half4 ScreenPosition	: TEXCOORD3;
    half4 customData		: TEXCOORD4;
    half4 customData2		: TEXCOORD5;
	
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct MRTOutput
{
	half4 fragColor		: SV_TARGET0;
	half4 bloomColor	: SV_TARGET1;
};

inline half GetCustomData(half4 customdata, int customDataChannelMask)
{
	return customdata.x * (customDataChannelMask & CHANNEL_A_MASK)
		+ customdata.y * ((customDataChannelMask & CHANNEL_B_MASK) >> 1)
		+ customdata.z * ((customDataChannelMask & CHANNEL_C_MASK) >> 2)
		+ customdata.w * ((customDataChannelMask & CHANNEL_D_MASK) >> 3);
}

Varyings vert (Attributes i)
{
	Varyings o = (Varyings)0;
	UNITY_SETUP_INSTANCE_ID(i);
    UNITY_TRANSFER_INSTANCE_ID(i, o);

	// Get Instancing vertex streams
	// vertex color
	o.color = GetParticleColor(i.color);

	// custom data
	o.customData = i.customData;
	o.customData2 = i.customData2;
	GetParticleCustomDatas(o.customData, o.customData2);

	o.uv.xy = i.texcoord.xy; 

	VertexPositionInputs vertexInput = GetVertexPositionInputs(i.positionOS.xyz);
	o.positionCS = vertexInput.positionCS;
	o.positionCS = vertexInput.positionCS;
	#if defined(_DEPTH_OFFSET_ON)
	float eps = 5.960464478e-8;
	float modifiedPositionVS_Z = -max(_ProjectionParams.y + eps, abs(o.positionCS.w) - _ZOffset);
	float modifiedPositionCS_Z = modifiedPositionVS_Z * UNITY_MATRIX_P[2].z + UNITY_MATRIX_P[2].w;
	o.positionCS.z = modifiedPositionCS_Z *  o.positionCS.w / -(modifiedPositionVS_Z);
	#endif
	o.positionWS.xyz = vertexInput.positionWS;
	o.positionWS.w = ComputeFogFactor(vertexInput.positionCS.z);
	o.ScreenPosition = ComputeScreenPos(vertexInput.positionCS);
	
	return o;
}

half4 ColorFrag(Varyings i, FRONT_FACE_TYPE frontFacing)
{
    UNITY_SETUP_INSTANCE_ID(i);


	// Base Map
	half2 baseMapUV = UVHelper_TexAdjust(i.uv.xy, _BaseMap_ST, _BaseRotAngle);
	baseMapUV = UVHelper_UVFlow(baseMapUV, _BaseUVMoveMode, half2(_BaseUSpeed, _BaseVSpeed), _BaseRadialScale, _BaseLengthScale, i.customData2.zw);
	baseMapUV = UVHelper_ApplyWrap(baseMapUV, _BaseWrapMode);

	//////////////////////////////////////////////////////////////////
	// Distortion
	/////////////////////////////////////////////////////////////////
#if FOLDOUT
	half2 baseDistortion = 0;
	half2 detailDistortion  = 0;
	half2 secondaryDistortion = 0;
DISTORTION_START
	half2 baseDistUV = UVHelper_TexAdjust(i.uv.xy, _DistMap_ST, _DistRotAngle);
	baseDistUV = UVHelper_UVFlow(baseDistUV, _DistMapUVMoveMode, half2(_DistUSpeed, _DistVSpeed), _DistRadialScale, _DistLengthScale);
	baseDistUV = UVHelper_ApplyWrap(baseDistUV, _DistMapWrapMode);

	baseDistortion = FX_FAST_SRGB_TO_LINEAR(SAMPLE_TEXTURE2D(_DistMap, sampler_DistMap, baseDistUV)) * 2 - 1; //颜色值为0.5 时表示无扭曲，和Flowmap类似

	half2 detailDistUV = UVHelper_TexAdjust(i.uv.xy, _DetailDistMap_ST, _DetailDistRotAngle);
	detailDistUV = UVHelper_UVFlow(detailDistUV, _DetailDistMapUVMoveMode,half2(_DetailDistUSpeed, _DetailDistVSpeed), _DetailDistRadialScale, _DetailDistLengthScale);
	detailDistUV = UVHelper_ApplyWrap(detailDistUV, _DistMapWrapMode);

	detailDistortion = FX_FAST_SRGB_TO_LINEAR(SAMPLE_TEXTURE2D(_DetailDistMap, sampler_DetailDistMap, detailDistUV)) * 2 - 1;

	// Secondary Distortion
#if defined(_SECONDARYDISTMAP_ON)
	half2 secondaryDistUV = UVHelper_TexAdjust(i.uv.xy, _SecondaryDistMap_ST, 0);
	secondaryDistUV += ((_SecondaryDistMapDistortionSource & BASE_DIST_SOURCE) * baseDistortion +  (_SecondaryDistMapDistortionSource & DETAIL_DIST_SOURCE)) * _SecondaryDistDistortionStrength;
	secondaryDistortion = FX_FAST_SRGB_TO_LINEAR(SAMPLE_TEXTURE2D(_SecondaryDistMap, sampler_SecondaryDistMap, secondaryDistUV)) * 2 - 1;
#endif
	
	half baseMapDistortionStrength_A = lerp(_BaseMapDistortionStrength_A, GetCustomData(i.customData, _BaseMapDistStrenAChannel), _BaseMapDistStrenAByCustomData1);
	half baseMapDistortionStrength_B = lerp(_BaseMapDistortionStrength_B, GetCustomData(i.customData, _BaseMapDistStrenBChannel), _BaseMapDistStrenBByCustomData1);
	baseDistortion = baseDistortion * baseMapDistortionStrength_A;

DISTSTRENGTHMASK_START
		half distStrength = FX_FAST_SRGB_TO_LINEAR(SAMPLE_TEXTURE2D(_DistStrengthControlMask, sampler_DistStrengthControlMask, i.uv.xy).r);
		distStrength = SafePow(distStrength, _DistMaskPower);
		distStrength = lerp(distStrength, 1-distStrength, _InvertDistMask);
		baseDistortion = lerp(0, baseDistortion, distStrength);
DISTSTRENGTHMASK_END
	
	baseMapUV += baseDistortion + detailDistortion * baseMapDistortionStrength_B;
DISTORTION_END
#endif // FOLDOUT
	
	half4 baseMapColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, baseMapUV);
	half4 color = baseMapColor * i.color;
	#if defined(_BASE_DETAIL_MAP_ON)
		// float2 baseDetailUV = UVHelper_TransformUV(i.uv.xy, _DetailMap_ST, float2(_DetailUSpeed, _DetailVSpeed), i.customData2.zw, _DetailRotAngle, _DetailUVMoveMode, _DetailWrapMode);
		float2 baseDetailUV = UVHelper_TexAdjust(i.uv.xy, _DetailMap_ST, _DetailRotAngle);
		baseDetailUV = UVHelper_UVFlow(baseDetailUV, _DetailUVMoveMode, half2(_DetailUSpeed, _DetailVSpeed), _DetailRadialScale, _DetailLengthScale, i.customData.zw);
		half4 detailMapColor = SAMPLE_TEXTURE2D(_DetailMap, sampler_DetailMap, baseDetailUV) * _DetailColor;
		color = lerp(color, color * detailMapColor, _DetailStren);
	#endif
	

	// TODO: opt it
	half4 tintColor = _BaseColor;


#if defined(_DDUBLE_FACE_ON)
	half4 backFaceColor = _BackFaceColor;
	tintColor = frontFacing ? tintColor : _BackFaceColor;
#endif
	
	color *= tintColor;
	
	color.rgb = DoHSV(color.rgb, _HSV);	
	
	//////////////////////////////////////////////////////////////////
	// Dissolve
	/////////////////////////////////////////////////////////////////
#if FOLDOUT
DISSOLVE_START
	// Get Dissolve Texture
	half2 dissUV = UVHelper_TexAdjust(i.uv.xy, _DissolveMap_ST, _DissolveRotAngle);
	dissUV = UVHelper_UVFlow(dissUV, _DissolveUVMoveMode, half2(_DissolveUSpeed, _DissolveVSpped), _DissolveRadialScale, _DissolveLengthScale, i.customData2.zw);

DISTORTION_START
FOLLOWSHAPEDISTORTION_START
		dissUV += ((_DissolveDistortionSource & CHANNEL_A_MASK) * baseDistortion
			+ (_DissolveDistortionSource & CHANNEL_B_MASK) * detailDistortion
			#if defined(_SECONDARYDISTMAP_ON)
			+ (_DissolveDistortionSource & SECONDARY_DIST_SOURCE) * secondaryDistortion
			#endif
			) * _DissolveDistortionStrength;
FOLLOWSHAPEDISTORTION_END
DISTORTION_END
	
	half4 dissolveTex = FX_FAST_SRGB_TO_LINEAR(SAMPLE_TEXTURE2D(_DissolveMap, sampler_DissolveMap, dissUV));

	half dissA = dissolveTex.r;

	half customProgress = GetCustomData(i.customData, _DissolveCustomDataChannel);
	half progress = lerp(_Dissolve, customProgress, _DissolveByCustomData1);
	
	progress += step(0.99h, progress) * 0.01h;
	
	dissA = lerp(dissA, 1 - dissA, _InvertDissolveMap > 0);
	
	half colEdgeRange = lerp(_EdgeRange * dissA, _EdgeRange, progress); 
	half inColEdge = step(dissA, progress + colEdgeRange) * step(0.01h, progress);
	half3 edgeColor = lerp(lerp(lerp(color.rgb, _EdgeColor.rgb, 1-PercentInRange(dissA, progress, progress+colEdgeRange)), _EdgeColor.rgb, int(_EdgeColorMode) == 1), color.rgb, int(_EdgeColorMode) == 0);
	color.rgb = lerp(color.rgb, edgeColor, inColEdge);
	
	color.a *= GetSoftDissolveValue(dissA, _EdgeRange, _EdgeSmoothness, progress);
DISSOLVE_END
#endif //FOLDOUT
	

DEPTH_FADE_START
	half rawDepth = SAMPLE_DEPTH_TEXTURE_LOD(_CameraDepthTexture, sampler_CameraDepthTexture, i.ScreenPosition.xy / i.ScreenPosition.w, 0);
	half sceneZ = LinearEyeDepth(rawDepth, _ZBufferParams);

	half selfZ = LinearEyeDepth(i.positionCS.z, _ZBufferParams);
	color.a *= saturate( abs(sceneZ - selfZ) / max(_DepthFadeRange, 0.001h));
DEPTH_FADE_END
	
#ifdef _NEAR_CAMERA_FADE_ON
	half viewDistance = distance(_WorldSpaceCameraPos.xyz, i.positionWS.xyz);
	half nearFadeStar = clamp(_NearFadeStar, 0, HALF_MAX);
	half nearFadeRange = clamp(_NearFadeRange, 0, HALF_MAX);
	color.a *= smoothstep(nearFadeStar, nearFadeStar+nearFadeRange, viewDistance);
#endif
	
	half a = color.a;	

// #ifdef _MASK_ON
// 	// Base Mask
// 	half2 maskPolarUV = UVHelper_TransformUVPolar(i.uv.zw, float2(_MaskUSpeed, _MaskVSpeed), _MaskMapUVMoveMode, _MaskRadialScale, _MaskLengthScale);
// 	half4 mask = FX_FAST_SRGB_TO_LINEAR(SAMPLE_TEXTURE2D(_MaskMap, sampler_MaskMap, lerp(i.uv2.zw, maskPolarUV, UVHelper_IsPolarUV(_MaskMapUVMoveMode))));
// 	//修改增加_MaskAddOn
// 	mask.r = lerp(mask.r, pow(clamp(mask.r, 0.0001, 1), _MaskAlphaStrength), _MaskAddOn);
// 	a = lerp(a, color.r * _BaseColor.a * i.color.a , _AlphaOn) * mask.r;
// 	a *= lerp(1.0, pow(clamp(a, 0.0001, 1), _AlphaStrength), _AlphaAddOn);
// 	a = saturate(a);
// #endif


#ifdef _ALPHATEST_ON
	clip(a - _Cutoff);
#endif
	
	color.rgb = lerp(color.rgb, MixFogColor(color.rgb, unity_FogColor.rgb,i.positionWS.w), _FogOn);
	color.a =  a * _AlphaMultiplyer;

	GreyNegativeWithTint(_NegativeBrightFX, _NegativeStrengthFX, color, _NegativeTintFX,_LumThreshholdFX);
	color = max(color, (0).xxxx);
	color.a = saturate(color.a);

	return OutputFXFinalColor(color);
}


half4 ForwardFrag(Varyings i, FRONT_FACE_TYPE frontFacing : FRONT_FACE_SEMANTIC) : SV_Target
{
	return ColorFrag(i, frontFacing);
}


half4 BloomFrag(Varyings i, FRONT_FACE_TYPE frontFacing : FRONT_FACE_SEMANTIC) : SV_Target
{
	half4 bloomMutiplyer = _GlobalFXBloomOn > 0 ? _BloomTint * _GlobalFXBloomIntensity : _BloomTint;
	half4 fragColor = ColorFrag(i, frontFacing);
	return half4(fragColor.rgb * bloomMutiplyer.rgb, fragColor.a);
}


MRTOutput MRTFrag(Varyings i, FRONT_FACE_TYPE frontFacing : FRONT_FACE_SEMANTIC)
{
	MRTOutput mrtOutput = (MRTOutput)0;
	half4 bloomMutiplyer = _GlobalFXBloomOn > 0 ? _BloomTint * _GlobalFXBloomIntensity : _BloomTint;
	mrtOutput.fragColor =  ColorFrag(i, frontFacing);
	mrtOutput.bloomColor = half4(mrtOutput.fragColor.rgb * bloomMutiplyer.rgb * _BloomOn, mrtOutput.fragColor.a);
	
	return mrtOutput;
}

#endif
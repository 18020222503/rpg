#ifndef PARTICLE_UNLIT_GENERAL_PASS_INCLUDED
#define PARTICLE_UNLIT_GENERAL_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/Math.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/UVHelper.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/FX/ParticlesInstancing.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/ColorAdjustment.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/ColorSpace.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/FX/FXDebug.hlsl"

#ifndef TIME_MACRO
#define TIME fmod(_Time.y, HALF_MAX)
#define TIME_MACRO 1
#endif



#define FOLDOUT 1
#define STATIC_BRANCH_START(flag) UNITY_BRANCH if (flag) {
#define STATIC_BRANCH_END }
#define KEY_WORD_START(kw) #if kw
#define KEY_WORD_END #endif


// Mask (46.5%)
#ifdef _MASK_ON_BRANCH
	#define MASK_START			STATIC_BRANCH_START(_MaskOn)
	#define MASK_END			STATIC_BRANCH_END
#else
	#define MASK_START			KEY_WORD_START(_MASK_ON)
	#define MASK_END			KEY_WORD_END
#endif


// Dissolve (38.6%)
#ifdef _DISSOLVE_ON_BRANCH
	#define DISSOLVE_START		STATIC_BRANCH_START(_DissolveOn)
	#define DISSOLVE_END		STATIC_BRANCH_END
#else
	#define DISSOLVE_START		KEY_WORD_START(_DISSOLVE_ON)
	#define DISSOLVE_END		KEY_WORD_END
#endif


// Depth Fade(28.1a%)
#ifdef _DEPTH_FADE_BRANCH
	#define DEPTH_FADE_START	STATIC_BRANCH_START(_DepthFadeOn)
	#define DEPTH_FADE_END		STATIC_BRANCH_END
#else
	#define DEPTH_FADE_START	KEY_WORD_START(_DEPTH_FADE_ON)
	#define DEPTH_FADE_END		KEY_WORD_END
#endif


// // Soft Particles(0.82%)
// #ifdef _SOFTPARTICLES_BRANCH
// 	#define SOFTPARTICLES_START		STATIC_BRANCH_START(_SoftParticleOn)
// 	#define SOFTPARTICLES_END		STATIC_BRANCH_END
// #else
// 	#define SOFTPARTICLES_START		KEY_WORD_START(_SOFTPARTICLES_ON)
// 	#define SOFTPARTICLES_END		KEY_WORD_END
// #endif

#if defined _GOOGLE_DEVICE

	#if defined(_VERTEXOFFSET_ON)&& defined(_FLIPBOOKBLENDING_ON)
		#undef  _FLIPBOOKBLENDING_ON
	#endif

	#if defined(_BASE_DETAIL_MAP_ON)&&defined(_FOLLOWSHAPEDISTORTION_ON)&&defined(_DISTORTION_ON)
		#undef _FOLLOWSHAPEDISTORTION_ON
	#endif

#endif





			
struct Attributes
{
	float3 positionOS				: POSITION;
	float3 normalOS					: NORMAL;
    float4 tangentOS				: TANGENT;
    float4 color					: COLOR;
	float4 texcoord					: TEXCOORD0;
	float4 customData				: TEXCOORD1;
	float4 customData2				: TEXCOORD2;
#if defined(_FLIPBOOKBLENDING_ON) || defined(_DECAL_ON) 
	float4 animSheetFrameAndBlend	: TEXCOORD3;
#endif

#ifdef _DECAL_ON 
	float4 size3D					: TEXCOORD4;
	float4 rotation3D				: TEXCOORD5;
#endif
	
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
	float4 positionCS		: SV_POSITION;
	half4 color				: COLOR;
	float4 uv				: TEXCOORD0;	
	//float4 uv2				: TEXCOORD1;	
	half4 positionWS		: TEXCOORD2;
	half4 ScreenPosition	: TEXCOORD3;
	half4 customData		: TEXCOORD4;
	half4 customData2		: TEXCOORD5;
#ifdef _FLIPBOOKBLENDING_ON
	float3 animSheetUVAndBlend : TEXCOORD6; 	
#endif

#if defined(_FRESNEL_ON) || defined(_FLOWMAP_ON)
	half4 normalWS			: TEXCOORD7;    // xyz: normal, w: viewDir.x
#endif
#ifdef _FRESNEL_ON
	half4 tangentWS			: TEXCOORD8;    // xyz: tangent, w: viewDir.y
	half4 bitangentWS		: TEXCOORD9;    // xyz: bitangent, w: viewDir.z
#endif

#ifdef _DECAL_ON
	float4 viewRayWS		: TEXCOORD10;
	float3 povitWS			: TEXCOORD11;
	half4 size3DAndYRotation: TEXCOORD12;
#endif

    UNITY_VERTEX_INPUT_INSTANCE_ID
};


struct MRTOutput
{
	half4 fragColor		: SV_TARGET0;
	half4 bloomColor	: SV_TARGET1;
};


// inline half PercentInRange(half c, half minValue, half maxValue)
// {
// 	c = (c - minValue)/(maxValue - minValue);
// 	c = saturate(c);
// 	return c;
// }


// half3 DoHSV(half3 rgb, half3 hsv)
// {
// 	half3 col = RgbToHsv(rgb);
// 	col.x = RotateHue(col.x + hsv.x * 0.1, 0, 1);
// 	col = HsvToRgb(col);
//
// 	col = Desaturate(col, clamp(hsv.y, 0, 10));
// 	
// 	col *= clamp(hsv.z, 0, 10);
//
// 	return col;
// }

half3x3 RotaionYFromAngle(half angle)
{
	half si = sin(angle);
	half co = cos(angle);
	return half3x3(half3(co, 0, si), half3(0, 1, 0), half3(-si, 0, co));
}

half3x3 InvertedRotaionYFromAngle(half angle)
{
	half si = sin(angle);
	half co = cos(angle);
	return half3x3(half3(co, 0, -si), half3(0, 1, 0), half3(si, 0, co));
}

half4 TextureChannelMaskToVector(int channel) // 0-R 1-G 2-B 3-A
{
	channel = pow(2, channel);
	return half4(channel & 1, (channel & 2) >> 1, (channel & 4) >> 2, (channel & 8) >> 3);
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

	// base uv |anim sheet uv | anim sheet blend
	float2 texcoord = i.texcoord.xy;

	float onGoogleDeviceAndFlipBookAndVertexOffsetOn = 0;
	#if defined(_FLIPBOOKBLENDING_ON) && defined(_VERTEXOFFSET_ON)
	onGoogleDeviceAndFlipBookAndVertexOffsetOn = _useOnGoogleSimulator==0?0:1;
	#endif

	UNITY_BRANCH
	if(onGoogleDeviceAndFlipBookAndVertexOffsetOn==0)
	{
		#if defined(_FLIPBOOKBLENDING_ON)
        #if defined(UNITY_PARTICLE_INSTANCING_ENABLED)
            GetParticleTexcoords(texcoord, o.animSheetUVAndBlend, i.texcoord.xyxy, 0.0);
        #else
            GetParticleTexcoords(texcoord, o.animSheetUVAndBlend, i.texcoord, i.animSheetFrameAndBlend.y);
        #endif
        #endif
	}
	




//   关闭掉Vert种的VertexOffset keyworld	
#ifdef _VERTEXOFFSET_ON
	half base = 1.h;
	half random = 0;
	UNITY_BRANCH
	if (_VertexOffsetMainTexOn > 0)
	{
		half2 uv_base = UVHelper_TransformUV_NotWarp(texcoord, _VertexOffsetTexParams, half2(_BaseUSpeed, _BaseVSpeed), o.customData.zw, _BaseRotAngle, _BaseUVMoveMode);
		base = SAMPLE_TEXTURE2D_WARP_LOD(_BaseMap,  uv_base, _BaseWrapMode).r;
	}
	UNITY_BRANCH
	if (_VertexRandomByCutomData2w > 0)
	{
		random = o.customData2.w ;
	}
	half2 uv_mask = UVHelper_TransformUV_NotWarp(texcoord, _VertexOffsetMaskMap_ST, half2(_VertexOffsetMaskUSpeed, _VertexOffsetMaskVSpeed), 0, 0, 1);
	half4 maskSample =  FX_FAST_SRGB_TO_LINEAR(SAMPLE_TEXTURE2D_WARP_LOD(_VertexOffsetMaskMap, uv_mask + random, _BaseWrapMode));
	half mask = dot(maskSample, TextureChannelMaskToVector(_VertexOffsetMaskMapChannelMask));

	half vertexOffsetIntensity = lerp(_VertexOffsetIntensity, o.customData2.x, _VertexOffsetIntensityByCutomData2X);
	half3 vertexOffset = ((base * 2.0) - 1.0) * mask * vertexOffsetIntensity * i.normalOS;
	i.positionOS.xyz += vertexOffset;
#endif

	

	VertexPositionInputs vertexInput = GetVertexPositionInputs(i.positionOS.xyz);
	o.positionCS = vertexInput.positionCS;
#if defined(_DEPTH_OFFSET_ON)
	// #if defined(UNITY_REVERSED_Z)
	float eps = 5.960464478e-8;
	float modifiedPositionVS_Z = -max(_ProjectionParams.y + eps, abs(o.positionCS.w) - _ZOffsetViewSpace);
	float modifiedPositionCS_Z = modifiedPositionVS_Z * UNITY_MATRIX_P[2].z + UNITY_MATRIX_P[2].w;
	o.positionCS.z = modifiedPositionCS_Z *  o.positionCS.w / -(modifiedPositionVS_Z);
	// #else
	// o.positionCS.z -= _ZOffsetViewSpace;
	// #endif
#endif
	
#ifdef _DECAL_ON
	// unity's camera space is right hand coord(negativeZ pointing into screen), we want positive z ray in fragment shader, so negate it
	half3 viewRay = -vertexInput.positionVS; 
	// "viewRay z division" must do in the fragment shader, not vertex shader! (due to rasteriazation varying interpolation's perspective correction)
	//viewRay /= viewRay.z;
	o.viewRayWS.w = vertexInput.positionVS.z;
	o.viewRayWS.xyz = mul(UNITY_MATRIX_I_V, half4(viewRay, 0));
	o.povitWS = float3(i.animSheetFrameAndBlend.zw, i.size3D.x);
	o.size3DAndYRotation.xyz = i.size3D.yzw;
	o.size3DAndYRotation.w = i.rotation3D.y + _DecalRootRotation.y;
#endif
	
	o.positionWS.xyz = vertexInput.positionWS;
	o.positionWS.w = ComputeFogFactor(vertexInput.positionCS.z);
	o.ScreenPosition = ComputeScreenPos(vertexInput.positionCS);
	//o.positionOS = i.positionOS.xyz;
	o.uv.zw = lerp(texcoord,(o.ScreenPosition.xy/o.ScreenPosition.w),_BaseScreenUV);
#if defined(_FRESNEL_ON) || defined(_FLOWMAP_ON)
	VertexNormalInputs normalInput = GetVertexNormalInputs(i.normalOS, i.tangentOS);
	half3 viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
	viewDirWS = SafeNormalize(viewDirWS);
	o.normalWS = half4(SafeNormalize(normalInput.normalWS), viewDirWS.x);
#endif
	
#if defined(_FRESNEL_ON)
	o.tangentWS = half4(SafeNormalize(normalInput.tangentWS), viewDirWS.y);
	o.bitangentWS = half4(SafeNormalize(normalInput.bitangentWS), viewDirWS.z);
#endif

	return o;
}


half4 ColorFrag (Varyings i, FRONT_FACE_TYPE frontFacing)
{
    UNITY_SETUP_INSTANCE_ID(i);
	// #if defined(_FLIPBOOKBLENDING_ON)
	// return half4(i.animSheetUVAndBlend.z,0,0,1);
	// #endif
	//return half4(i.uv.zw,1,1);
// #if defined(_LASEREND_ON)
// 	// half3 positionFromStartPoint = i.positionWS - _StartPositionWS;
// 	// half3 laserDir = _EndPositionWS - _StartPositionWS;
// 	// half laserMagnitudeSqr = laserDir.x * laserDir.x + laserDir.y * laserDir.y + laserDir.z *laserDir.z;
// 	// half FDotLaser = dot(positionFromStartPoint, laserDir);
// 	// half projectionC = FDotLaser / laserMagnitudeSqr; 
// 	// clip(1 - projectionC);
// 	half3 positionFromHitPoint = i.positionWS - _HitPositionWS;
// 	half HDotLaser = dot(positionFromHitPoint, _LaserDirWS);
// 	clip(-HDotLaser);
// #endif

	
	
	//////////////////////////////////////////////////////////////////////
	/// Sample Depth
	//////////////////////////////////////////////////////////////////////
	float sceneZ = 0;
	half requireSceneDepth = _DepthFadeOn + _DecalModeOn;
	UNITY_BRANCH
	if (requireSceneDepth > 0)
	{
		float rawZ = SAMPLE_DEPTH_TEXTURE_LOD(_CameraDepthTexture, sampler_CameraDepthTexture, i.ScreenPosition.xy / i.ScreenPosition.w, 0).r;
		sceneZ = LinearEyeDepth(rawZ, _ZBufferParams);
	}

	/////////////////////////////////////////////////////////////////////////
	// Main Texture
	//////////////////////////////////////////////////////////////////////////
#ifdef _DECAL_ON
	float3 decalProjPos = _WorldSpaceCameraPos + i.viewRayWS.xyz / i.viewRayWS.w * sceneZ;

	// particles system bake vertex to mesh in world space
	// use UNITY_I_MV matrix to transform view space position we actually get world position particle vertex
	// so we need to transform world to local manually here 
	decalProjPos -= i.povitWS;
	half3x3 M_Y_ROT = InvertedRotaionYFromAngle(i.size3DAndYRotation.w);
	decalProjPos = mul(M_Y_ROT, decalProjPos);
	decalProjPos /= i.size3DAndYRotation.xyz;
	
	clip( 0.5 - abs(decalProjPos)); // discard out of cube volume pixels
	decalProjPos += 0.5; // convert unity cube's [-0.5,0.5] vertex pos range to [0,1] uv
	i.uv.zw = decalProjPos.xz; // hard code project from y axis
#endif
	
	// DISSOLVE_START
	// float2 dissolveUV = UVHelper_TransformUV(i.uv.zw, _DissolveMap_ST, float2(_DissolveUSpeed, _DissolveVSpped), 0, _DissolveRotAngle, _DissolveUVMoveMode, _DissolveMapWrapMode);
	// DISSOLVE_END

	// MASK_START
	// i.uv2.zw = UVHelper_TransformUV(i.uv.zw, _MaskMap_ST, float2(_MaskUSpeed, _MaskVSpeed), 0, _MaskRotAngle, _MaskMapUVMoveMode, _MaskMapWrapMode);
	// MASK_END

#if FOLDOUT
	
#ifdef _DISTORTION_ON  // Shape distortion
	
	float2 distUV =  0 ;
	UNITY_BRANCH
	if (UVHelper_IsPolarUV(_ShpDistMapUVMoveMode)> 0)
	{
		distUV = UVHelper_TransformUVPolar(i.uv.zw, float2(_ShpDistUSpeed, _ShpDistVSpeed),  _ShpDistMapWrapMode, _ShpDistRadialScale, _ShpDistLengthScale);

	}else{
		distUV = UVHelper_TransformUV_NotWarp(i.uv.zw, _ShpDistMap_ST, float2(_ShpDistUSpeed, _ShpDistVSpeed), 0, 0, _ShpDistMapUVMoveMode ); 	
	}

	// distUV = SAMPLE_TEXTURE2D(_ShpDistMap, sampler_ShpDistMap, distUV).rg*2 - 1;
	distUV = FX_FAST_SRGB_TO_LINEAR(SAMPLE_TEXTURE2D_WARP(_ShpDistMap,distUV,_ShpDistMapWrapMode).rg) * 2 - 1;
	half disStrength = lerp(_ShpDistStren, clamp(i.customData.y, 0, 2), _ShpDistStrenByCustomDataY);
	half2 distUVWithoutDistMask = distUV * disStrength; 
#if defined(_DISTSTRENGTHMASK_ON)
		// half distStrenghMask = SAMPLE_TEXTURE2D(_ShpDistStrengthControlMask, sampler_ShpDistStrengthControlMask, i.uv.zw).r;
		half distStrenghMask = dot(FX_FAST_SRGB_TO_LINEAR(SAMPLE_TEXTURE2D_WARP(_ShpDistStrengthControlMask, i.uv.zw,_ShpDistMapWrapMode)),
			TextureChannelMaskToVector(_ShpDistStrengthControlMaskChannel));
		distStrenghMask = lerp(distStrenghMask, 1-distStrenghMask, _InvertDistMask);
		distStrenghMask = SafePow(distStrenghMask, _DistStrengthMaskPower);
		distUV *= lerp(0, disStrength, distStrenghMask);
#else
		distUV = distUVWithoutDistMask;
#endif
	
	float2 detailDistUV = UVHelper_TransformUV_NotWarp(i.uv.zw, _ShpDetailDistMap_ST, float2(_ShpDetailDistUSpeed, _ShpDetailDistVSpeed), 0,
		0, _ShpDetailDistMapUVMoveMode);
	UNITY_BRANCH
	if (UVHelper_IsPolarUV(_ShpDetailDistMapUVMoveMode) > 0)
	{
		detailDistUV = UVHelper_TransformUVPolar(i.uv.zw, float2(_ShpDistUSpeed, _ShpDistVSpeed), _ShpDetailDistMapWrapMode, _ShpDetailDistRadialScale, _ShpDetailDistLengthScale);
	}
	// detailDistUV = SAMPLE_TEXTURE2D(_ShpDetailDistMap, sampler_ShpDetailDistMap, lerp(detailDistUV ,detailDistUVPolar, UVHelper_IsPolarUV(_ShpDetailDistMapUVMoveMode))).rg*2 - 1;
	detailDistUV = FX_FAST_SRGB_TO_LINEAR(SAMPLE_TEXTURE2D_WARP(_ShpDetailDistMap,detailDistUV,_ShpDetailDistMapWrapMode).rg) * 2 - 1;
	half detailDistStren = lerp(disStrength, _ShpDetailDistStren, _ShpDetailDistStrenOn);
#if defined(_DISTSTRENGTHMASK_ON)
		detailDistUV *= detailDistStren * distStrenghMask;
#else
		detailDistUV *= detailDistStren;
#endif
	
	distUV *= detailDistUV;

#if defined(_FLIPBOOKBLENDING_ON)
	i.animSheetUVAndBlend.xy += distUV;
#endif

	i.uv.xy = distUV + i.uv.zw;
#else
    i.uv.xy = i.uv.zw;
#endif
	
	float2 baseMapUV;
	UNITY_BRANCH
    if (UVHelper_IsPolarUV(_BaseUVMoveMode)> 0)
    {
    	baseMapUV = UVHelper_TransformUVPolar(i.uv.xy, float2(_BaseUSpeed, _BaseVSpeed), _BaseWrapMode, _BaseRadialScale, _BaseLengthScale);
    }
	else
    {
	   baseMapUV =  UVHelper_TransformUV_NotWarp(i.uv.xy, _BaseMap_ST, float2(_BaseUSpeed, _BaseVSpeed), i.customData.zw, _BaseRotAngle, _BaseUVMoveMode );
    }
	half4 baseMapColor = SAMPLE_TEXTURE2D_WARP(_BaseMap,  baseMapUV,_BaseWrapMode);

#ifdef _VERTEXOFFSET_ON
	
	UNITY_BRANCH
	if (_VertexOffsetMainTexColorOn < 1)
	{
		baseMapColor = half4(1,1,1,1);
	}
#endif
	
#if defined(_FLIPBOOKBLENDING_ON) // Animation Sheet
    float2 nextSheetUV;
	UNITY_BRANCH
    if (UVHelper_IsPolarUV(_BaseUVMoveMode) > 0)
    {
	    nextSheetUV = UVHelper_TransformUVPolar(i.animSheetUVAndBlend.xy, float2(_BaseUSpeed, _BaseVSpeed),
	                                            _BaseWrapMode, _BaseRadialScale, _BaseLengthScale);
    }
    else
    {
	    nextSheetUV = UVHelper_TransformUV_NotWarp(i.animSheetUVAndBlend.xy, _BaseMap_ST,
	                                               float2(_BaseUSpeed, _BaseVSpeed), i.customData.zw, _BaseRotAngle,
	                                               _BaseUVMoveMode);
    }
	half4 nextSheetColor = SAMPLE_TEXTURE2D_WARP(_BaseMap,  nextSheetUV,_BaseWrapMode);
	baseMapColor = lerp(baseMapColor, nextSheetColor,  i.animSheetUVAndBlend.z);
#endif
	

#endif // FOLDOUT

	half4 color = baseMapColor * i.color;
	half4 tintColor = _BaseColorByCutomData2 ? i.customData2 : _BaseColor;
	
// #ifdef _REFRACT_DISTORTION_ON
//  	tintColor =	_RfrDistOn ? _BaseColor : tintColor;
// #endif

#if defined(_DDUBLE_FACE_ON)
	half4 backFaceColor = _BackFaceColor;
	tintColor =   frontFacing ? tintColor : backFaceColor; // Two side material
#endif

	color *= tintColor;
	
	/////////////////////////////////////////////////////////////////////////
	// Detail Texture
	//////////////////////////////////////////////////////////////////////////
#if defined(_BASE_DETAIL_MAP_ON)
	float2 baseDetailUV ;
	UNITY_BRANCH
	if ( UVHelper_IsPolarUV(_DetailUVMoveMode)> 0)
	{
		baseDetailUV = UVHelper_TransformUVPolar(i.uv.zw, float2(_DetailUSpeed, _DetailVSpeed), _DetailWrapMode, _DetailRadialScale, _DetailLengthScale);
	}else
	{
		baseDetailUV = UVHelper_TransformUV_NotWarp(i.uv.zw, _DetailMap_ST, float2(_DetailUSpeed, _DetailVSpeed),
		                                            i.customData2.zw, 0, _DetailUVMoveMode);
	}
	
	half4 detailMapColor = SAMPLE_TEXTURE2D_WARP(_DetailMap,baseDetailUV,_DetailWrapMode) * _DetailColor;
	color = lerp(color, color * detailMapColor, _DetailStren);
#endif
	

	color.rgb = DoHSV(color.rgb, _HSV);	
	
	/////////////////////////////////////////////////////////////////////////
	// Scene Distortion
	//////////////////////////////////////////////////////////////////////////
// #ifdef _REFRACT_DISTORTION_ON
// 	float2 refractUV = UVHelper_TransformUV(i.uv.zw, _RfrDistMap_ST, float2(_RfrDistUSpeed, _RfrDistVSpeed), i.customData2.zw, _RfrDistRotAngle, _RfrDistUVMoveMode, _RfrDistMapWrapMode);
// 	// half4 distorVec = SAMPLE_TEXTURE2D(_RfrDistMap, sampler_RfrDistMap, refractUV);
// 	half4 distorVec = FX_FAST_SRGB_TO_LINEAR(SAMPLE_TEXTURE2D(_RfrDistMap, sampler_RfrDistMap, refractUV));
// 	distorVec.rgb = distorVec.rgb * 2 - 1;
// 	distorVec.rg *= distorVec.a * color.a * lerp(_RfrDistStren,  saturate(i.customData2.x), _RfrDistStrenByCustomData2X) * 0.1;
// 	refractUV = i.ScreenPosition.xy / i.ScreenPosition.w + distorVec.rg;
// 	float3 refractColor = SAMPLE_TEXTURE2D_LOD(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, refractUV, 0).rgb;
// 	color.rgb = lerp(color.rgb, refractColor, saturate(lerp(_RfrDistBlend, i.customData2.y, _RfrDistBlendByCustomData2Y)));
// #endif

	/////////////////////////////////////////////////////////////////////////
	// Dissolve
	//////////////////////////////////////////////////////////////////////////
#if FOLDOUT
DISSOLVE_START
	half progress = lerp(_Dissolve, i.customData.x, _DissolveByCustomDataX);
	progress += step(0.99h, progress) * 0.01h;
	float2 dissUV;
	UNITY_BRANCH
	if (UVHelper_IsPolarUV(_DissolveUVMoveMode) > 0)
	{
		dissUV = UVHelper_TransformUVPolar(i.uv.zw, half2(_DissolveUSpeed, _DissolveVSpped), _DissolveMapWrapMode,
		                                   _DissolveRadialScale, _DissolveLengthScale);
	}
	else
	{
		dissUV = UVHelper_TransformUV_NotWarp(i.uv.zw, _DissolveMap_ST, float2(_DissolveUSpeed, _DissolveVSpped), 0,
		                                      _DissolveRotAngle, _DissolveUVMoveMode);
	}

	half USE_DISTORTION_ON_AND_FOLLOWSHAPEDISTORTION_ON = 0;
	half2 cacheDistUVWithoutDistMask = 0;
	half enableFollowShapeDistortionOnGoogle = 1;
	
	#if defined(_FOLLOWSHAPEDISTORTION_ON)& defined(_BASE_DETAIL_MAP_ON)
			enableFollowShapeDistortionOnGoogle = _useOnGoogleSimulator>0?0:1;
	#endif

	half diss =0;
	UNITY_BRANCH
	if(enableFollowShapeDistortionOnGoogle>0)
	{
		#if defined(_DISTORTION_ON) && defined(_FOLLOWSHAPEDISTORTION_ON)
				half diss = FX_FAST_SRGB_TO_LINEAR(SAMPLE_TEXTURE2D_WARP(_DissolveMap,(distUVWithoutDistMask + dissUV) * _DissolveMap_ST.xy + _DissolveMap_ST.zw,_DissolveMapWrapMode).r);
		#else
			diss = FX_FAST_SRGB_TO_LINEAR(SAMPLE_TEXTURE2D_WARP(_DissolveMap,dissUV,_DissolveMapWrapMode).r);
		#endif
		
	}else
	{
		
		diss = FX_FAST_SRGB_TO_LINEAR(SAMPLE_TEXTURE2D_WARP(_DissolveMap,dissUV,_DissolveMapWrapMode).r);
	}
	
	
	diss = lerp(diss, 1 - diss, _InvertDissolveMap > 0);

	half colEdgeRange = lerp(_EdgeRange * diss, _EdgeRange, progress); 
	half inColEdge = step(diss, progress + colEdgeRange) * step(0.01h, progress);
	half3 edgeColor = lerp(lerp(lerp(color.rgb, _EdgeColor.rgb, 1-PercentInRange(diss, progress, progress+colEdgeRange)), _EdgeColor.rgb, int(_EdgeColorMode) == 1), color.rgb, int(_EdgeColorMode) == 0);
	color.rgb = lerp(color.rgb, edgeColor, inColEdge);
	
	//clip(diss - progress);
	
	// half smEdgeRange = lerp(_EdgeSmoothness * diss, _EdgeSmoothness, progress); //溶解值太小的边会被瞬间虚化掉，目前只想到缩小EdgeRange的方法
	// half inSmEdge = step(diss, progress + smEdgeRange) * step(0.01h, progress);
	// color.a *= lerp(1, saturate(diss - progress) / max(smEdgeRange, 0.01h), inSmEdge);
	
	half dissolveTexR = 1 - diss;  //金富自创算法
	progress *= (1 + _EdgeRange);
	half hardnessFactor = 2.0 - (1 - _EdgeSmoothness);
	half dissolve02 = (progress - _EdgeRange) * hardnessFactor + dissolveTexR;
	dissolve02 = PercentInRange(2.0 - dissolve02, 1 - _EdgeSmoothness, 1.0);
	color.a *= dissolve02;
DISSOLVE_END
#endif //FOLDOUT
	
	/////////////////////////////////////////////////////////////////////////
	// Soft particles And Depth Fade
	//////////////////////////////////////////////////////////////////////////
#if FOLDOUT
	
// SOFTPARTICLES_START
// 	selfZ = i.ScreenPosition.z;
// 	color.a *= saturate( abs(sceneZ - selfZ) / clamp(_SoftRange, 0, HALF_MAX));
// SOFTPARTICLES_END
	
DEPTH_FADE_START
	float selfZ = LinearEyeDepth(i.positionCS.z, _ZBufferParams);
	float depthDiff = sceneZ - selfZ;
	if(_DepthFadeMode == 1) depthDiff = abs(depthDiff);
	color.a *= pow(saturate( depthDiff / max(_DepthFadeRange, 0.001h)), _DepthFadePow);
DEPTH_FADE_END
#endif //FOLDOUT

	/////////////////////////////////////////////////////////////////////////
	// Near Camera Fade
	//////////////////////////////////////////////////////////////////////////
#ifdef _NEAR_CAMERA_FADE_ON
	half viewDistance = distance(_WorldSpaceCameraPos.xyz, i.positionWS.xyz);
	half nearFadeStar = clamp(_NearFadeStar, 0, HALF_MAX);
	half nearFadeRange = clamp(_NearFadeRange, 0, HALF_MAX);
	color.a *= smoothstep(nearFadeStar, nearFadeStar+nearFadeRange, viewDistance);
#endif


	/////////////////////////////////////////////////////////////////////////
	// Fresnel Color
	//////////////////////////////////////////////////////////////////////////
#if defined(_FRESNEL_ON)
	half fresnel = 1.0;
	half3 viewDirWS = half3(i.normalWS.w, i.tangentWS.w, i.bitangentWS.w);
	half3 normalWS = i.normalWS.xyz;
	half NDotV = saturate(dot(normalWS, viewDirWS));
	fresnel = saturate(pow(1 - NDotV, _FresnelPow));
	half inv_fresnel = saturate(pow(NDotV, _FresnelPow));
	fresnel = lerp(fresnel, inv_fresnel, _InverFresnel);
	fresnel *= _FresnelStrength;
	//half4 fresnelColor = lerp(color, _FresnelColor, fresnel);
	half3 fresnel_col1 = color.rgb * _FresnelColor.rgb * fresnel;
	half3 fresnel_col2 = color.rgb + _FresnelColor.rgb * fresnel;
	half3 frenel_col = lerp(fresnel_col1, fresnel_col2, _FresnelColorMode);
	half fresnel_alpha = color.a * _FresnelColor.a * fresnel;

	color.rgb = lerp(color.rgb, frenel_col.rgb , _FresnelMode == 0 || _FresnelMode == 2);
	color.a = saturate(lerp(color.a, fresnel_alpha, _FresnelMode == 1 || _FresnelMode == 2));
#endif
	// half4 flowNormalTex = SAMPLE_TEXTURE2D(_FlowNormalTex, sampler_FlowNormalTex, i.uv.xy);

	/////////////////////////////////////////////////////////////////////////
	// Flow Map
	//////////////////////////////////////////////////////////////////////////
// #if defined(_FLOWMAP_ON)
// 	half3 orignalWS = TransformObjectToWorld(half3(0,0,0));
//
// 	// Matcap UV by Triplanar Sample
// 	half3 triPosistionWS = (i.positionWS - orignalWS) * _FlowTiling.xyz + TIME * _FlowSpeed; 
// 	float3 matcapUVByTriSample = TriplanarSampling(TEXTURE2D_ARGS(_FlowNormalMap, sampler_FlowNormalMap),triPosistionWS, i.normalWS, 5);
// 	matcapUVByTriSample = mul(unity_MatrixV, matcapUVByTriSample);
// 	
// 	// Matcap UV By Flowmap + normalMap
// 	// half2 flowMap = SAMPLE_TEXTURE2D(_FlowNormalMap, sampler_FlowMap, i.uv * _FlowNormalMap_ST.xy + _FlowNormalMap_ST.zw).rg - half2(0.5, 0) + 0.5;
// 	half2 flowMap = FX_FAST_SRGB_TO_LINEAR(SAMPLE_TEXTURE2D(_FlowNormalMap, sampler_FlowMap, i.uv * _FlowNormalMap_ST.xy + _FlowNormalMap_ST.zw).rg) - half2(0.5, 0) + 0.5;
// 	half flowSpeed = frac(TIME * _FlowOffsetSpeed.z);
// 	half2 flowStrength = (-_FlowOffsetSpeed.xy * 0.1);
// 	half2 flow0 = i.uv - (flowMap * flowStrength * flowSpeed);
// 	half2 flow1 = i.uv - (flowMap * flowStrength * frac(flowSpeed+0.5));
// 	// half4 normalMapUV0 = SAMPLE_TEXTURE2D(_FlowMap, sampler_FlowMap, flow0 * _FlowMap_ST.xy + _FlowMap_ST.zw);
// 	half4 normalMapUV0 = FX_FAST_SRGB_TO_LINEAR(SAMPLE_TEXTURE2D(_FlowMap, sampler_FlowMap, flow0 * _FlowMap_ST.xy + _FlowMap_ST.zw));
// 	// half4 normalMapUV1 = SAMPLE_TEXTURE2D(_FlowMap, sampler_FlowMap, flow1 * _FlowMap_ST.xy + _FlowMap_ST.zw);
// 	half4 normalMapUV1 = FX_FAST_SRGB_TO_LINEAR(SAMPLE_TEXTURE2D(_FlowMap, sampler_FlowMap, flow1 * _FlowMap_ST.xy + _FlowMap_ST.zw));
// 	half4 normalMapUV = lerp(normalMapUV0, normalMapUV1, abs(flowSpeed-0.5)/0.5);
// 	normalMapUV = mul(unity_MatrixV, normalMapUV);
//
// 	// half2 matcapUVByFlowNormal = SAMPLE_TEXTURE2D(_FlowNormalMap, sampler_FlowNormalMap, normalMapUV.xy * _FlowNormalMap_ST.xy + _FlowNormalMap_ST.zw);
// 	half2 matcapUVByFlowNormal =  FX_FAST_SRGB_TO_LINEAR(SAMPLE_TEXTURE2D(_FlowNormalMap, sampler_FlowNormalMap, normalMapUV.xy * _FlowNormalMap_ST.xy + _FlowNormalMap_ST.zw));
// 	float2 matcapUV = lerp(matcapUVByTriSample, matcapUVByFlowNormal, saturate(_FlowNormalMapSampleMode));
// 	half3 matcapColor = SAMPLE_TEXTURE2D(_MatcapMap, sampler_MatcapMap, matcapUV * _MatcapMap_ST.xy + _MatcapMap_ST.zw);
// 	matcapColor = SafePow(matcapColor, _MatcapPower);
// #endif
	
	 
	half a = color.a;	
	/////////////////////////////////////////////////////////////////////////
	// Mask Area
	//////////////////////////////////////////////////////////////////////////
MASK_START
	// Base Mask
	//half2 maskPolarUV = UVHelper_TransformUVPolar(i.uv.zw, float2(_MaskUSpeed, _MaskVSpeed), _MaskMapUVMoveMode, _MaskRadialScale, _MaskLengthScale);
	// half4 mask = SAMPLE_TEXTURE2D(_MaskMap, sampler_MaskMap, lerp(i.uv2.zw, maskPolarUV, UVHelper_IsPolarUV(_MaskMapUVMoveMode)));
    float2 maskScreenUV = UVHelper_TransformUV_NotWarp(i.uv.zw, _MaskMap_ST, float2(_MaskUSpeed, _MaskVSpeed), 0, _MaskRotAngle, _MaskMapUVMoveMode);
    half4 maskSample = FX_FAST_SRGB_TO_LINEAR(SAMPLE_TEXTURE2D_WARP(_MaskMap, maskScreenUV, _MaskMapWrapMode));
	//修改增加_MaskAddOn
    half alphaMask = dot(maskSample, TextureChannelMaskToVector(_MaskMapChannel));
    alphaMask = lerp(alphaMask, pow(clamp(alphaMask, 0.0001, 1), _MaskAlphaStrength), _MaskAddOn);
    a = lerp(a, color.r * _BaseColor.a * i.color.a, _AlphaOn) * alphaMask;
    a *= lerp(1.0, pow(clamp(a, 0.0001, 1), _AlphaStrength), _AlphaAddOn);
    a = saturate(a);
MASK_END

#ifdef _ALPHATEST_ON
	clip(a - _Cutoff);
#endif
	
	color.rgb = lerp(color.rgb, MixFogColor(color.rgb, unity_FogColor.rgb,i.positionWS.w), _FogOn);

	////////////////////////////////////////////////////
	/// Alpha Addition Control
	///////////////////////////////////////////////////
    a = lerp(a, smoothstep(_AlphaRemapping.x, _AlphaRemapping.y, a), _AlphaRemapping.w);
    a *= _AlphaMultiplyer;

	color.a = a; 
	
// #if defined(_FLOWMAP_ON)
// 	half3 matcapMulColor = matcapColor * color.rgb;
// 	half3 matcapAdditiveColor = matcapColor + color.rgb;
// 	color.rgb = lerp(matcapAdditiveColor, matcapMulColor, _MatcapColorBlendMode);
// #endif

	
	// Common Color Adjust Area
	// 根据是否受反相影响，重置反相强度
	// 不受反相影响，反相强度重置为0
    half localNegativeStrengthFX = min(_NegativeStrengthFX, 1 - _IgnoreNegativeEffect);
    GreyNegativeWithTint(_NegativeBrightFX, localNegativeStrengthFX, color, _NegativeTintFX, _LumThreshholdFX);
    color.rgb = max(color.rgb, (0).xxx);
    color.a = saturate(color.a);
	return OutputFXFinalColor(color);
}


half4 ForwardFrag (Varyings i, FRONT_FACE_TYPE frontFacing : FRONT_FACE_SEMANTIC) : SV_Target
{
	return ColorFrag(i, frontFacing);
}


half4 BloomFrag (Varyings i, FRONT_FACE_TYPE frontFacing : FRONT_FACE_SEMANTIC) : SV_Target
{
	half4 bloomMutiplyer = _GlobalFXBloomOn > 0 ? _BloomTint * _GlobalFXBloomIntensity : _BloomTint;
	half4 fragColor = ColorFrag(i, frontFacing);
	return half4(fragColor.rgb * bloomMutiplyer.rgb, fragColor.a);
}


half4 DepthOnlyFrag (Varyings i, FRONT_FACE_TYPE frontFacing : FRONT_FACE_SEMANTIC) : SV_Target
{
	half4 c = ColorFrag(i, frontFacing);

	clip(c.a - 0.01);

	return 0;
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
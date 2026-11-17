#ifndef FX_ICE_PASS_INCLUDED
#define FX_ICE_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/ProceduralNoiseHelper.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/UVHelper.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/Math.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/Dissolve.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/ColorAdjustment.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/FX/FXDebug.hlsl"

#define FOLDOUT 1
#define STATIC_BRANCH_START(flag) UNITY_BRANCH if (flag) {
#define STATIC_BRANCH_END }
#define KEY_WORD_START(kw) #if kw
#define KEY_WORD_END #endif

#if FOLDOUT
// _CLEARNESS_DISTORTION_ON (88%)
#ifdef _CLEARNESS_DISTORTION_ON_BRANCH
	#define CLEARNESS_DISTORTION_START			STATIC_BRANCH_START(_ClearnessOn)
	#define CLEARNESS_DISTORTION_END			STATIC_BRANCH_END
#else
	#define CLEARNESS_DISTORTION_START			KEY_WORD_START(_CLEARNESS_DISTORTION_ON)
	#define CLEARNESS_DISTORTION_END			KEY_WORD_END
#endif

// _RIM_LIGHT_ON (88%)
#ifdef _RIM_LIGHT_ON_BRANCH
	#define RIM_LIGHT_START						STATIC_BRANCH_START(_FresnelOn)
	#define RIM_LIGHT_END						STATIC_BRANCH_END
#else
	#define RIM_LIGHT_START						KEY_WORD_START(_RIM_LIGHT_ON)
	#define RIM_LIGHT_END						KEY_WORD_END
#endif


// _VOLUMETRIC_NOISE_UV_ON (45%)
#ifdef _VOLUMETRIC_NOISE_UV_BRANCH
	#define VOLUMETRIC_NOISE_UV_START			STATIC_BRANCH_START(_VolUVOffsetNoiseON)
	#define VOLUMETRIC_NOISE_UV_END				STATIC_BRANCH_END
#else
	#define VOLUMETRIC_NOISE_UV_START			KEY_WORD_START(_VOLUMETRIC_NOISE_UV_ON)
	#define VOLUMETRIC_NOISE_UV_END				KEY_WORD_END
#endif

#endif // FOLDOUT


struct Attributes
{
    float3 positionOS       : POSITION;
    float3 normalOS         : NORMAL;
    float4 tangentOS        : TANGENT;
    float4 baseUV           : TEXCOORD0;
    real4 customData        : TEXCOORD1;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};


struct Varyings
{
    float4 positionCS           : SV_POSITION;
    float4 positionSS           : TEXCOORD0;
    real4 normalWS              : TEXCOORD1; // W - ViewDir X
    real4 tangentWS             : TEXCOORD2; // W - ViewDir Y
    real4 bitangentWS           : TEXCOORD3; // W - ViewDir Z
    float4 baseUV               : TEXCOORD4;
    float4 rampAndNormalUV      : TEXCOORD5;
    float2 noiseUV              : TEXCOORD6;
	real4 customData			: TEXCOORD7;

    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct MRTOutput
{
	half4 fragColor		: SV_TARGET0;
	half4 bloomColor	: SV_TARGET1;
};


real Fresnel(real3 viewDir, real3 normal, real fresnelPow)
{
	return pow(1 - saturate(dot(viewDir, normal)), fresnelPow);
}


Varyings vert(Attributes attrs)
{
    Varyings vars = (Varyings)0;
    UNITY_SETUP_INSTANCE_ID(attrs);
    UNITY_TRANSFER_INSTANCE_ID(attrs, vars);
    
    VertexPositionInputs vertPositionInputs = GetVertexPositionInputs(attrs.positionOS);
    VertexNormalInputs vertNormalInputs = GetVertexNormalInputs(attrs.normalOS, attrs.tangentOS);
    
    real3 viewDirWS = normalize(GetWorldSpaceViewDir(vertPositionInputs.positionWS));

    vars.positionCS = vertPositionInputs.positionCS;
    vars.positionSS = vertPositionInputs.positionNDC;
    vars.normalWS.xyz = vertNormalInputs.normalWS;
    vars.tangentWS.xyz = vertNormalInputs.tangentWS;
    vars.bitangentWS.xyz = vertNormalInputs.bitangentWS;
    vars.tangentWS.w = viewDirWS.x;
    vars.bitangentWS.w = viewDirWS.y;
    vars.normalWS.w = viewDirWS.z;

    vars.baseUV.xy = UVHelper_TransformUV(attrs.baseUV.xy, _BaseMap_ST, real2(_BaseUSpeed, _BaseVSpeed),
                         attrs.customData.zw, _BaseRotAngle, _BaseUVMoveMode, _BaseWrapMode);
    vars.baseUV.zw = attrs.baseUV.xy;

    vars.rampAndNormalUV.xy = attrs.baseUV.xy * _RampTex_ST.xy + _RampTex_ST.zw;
    vars.rampAndNormalUV.zw = attrs.baseUV.xy * _NormalMap_ST.xy + _NormalMap_ST.zw;
    
VOLUMETRIC_NOISE_UV_START
    vars.noiseUV = attrs.baseUV.xy * _VolNoiseTex_ST.xy + _VolNoiseTex_ST.zw;
VOLUMETRIC_NOISE_UV_END

	vars.customData = attrs.customData;
    
    return  vars;
}


half4 ColorFrag(Varyings vars)
{
    UNITY_SETUP_INSTANCE_ID(vars);
    half4 finalCol = half4(0, 0, 0, 1);
    
    real3x3 TBN = real3x3(vars.tangentWS.xyz, vars.bitangentWS.xyz, vars.normalWS.xyz);
    real3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, vars.rampAndNormalUV.zw), _NormalScale);
    real3 normalWS = mul(normalTS, TBN);
	real3 viewDirWS = real3(vars.tangentWS.w, vars.bitangentWS.w, vars.normalWS.w);
    real3 viewLookTS = mul(TBN, normalize(GetViewForwardDir()));

    // Base Color
	////////////////////////////////////////////////////////////
	// Displacement Mapping
	///////////////////////////////////////////////////////////
    real3 reflectViewLookTS = normalize(reflect(viewLookTS, normalTS));
    real2 k_volUVOffset = abs(reflectViewLookTS.z);
#if FOLDOUT	
VOLUMETRIC_NOISE_UV_START
     real volUVNoise = _VolNoiseType > 0 ? ProceduralNoiseHelper_GenerateNoise(_VolNoiseType, vars.baseUV.zw, _VolNoiseScale,
                                            _VolNoiseAngle, _VolNoiseDensity)
                                         : SAMPLE_TEXTURE2D(_VolNoiseTex, sampler_VolNoiseTex, vars.noiseUV).r;
    volUVNoise = lerp(volUVNoise, 1-volUVNoise, _InvertVolNoise);
    k_volUVOffset = lerp(k_volUVOffset, k_volUVOffset * volUVNoise, _VolUVNoiseStren);
VOLUMETRIC_NOISE_UV_END
#endif // FOLDOUT
	
    k_volUVOffset *= _VolUVOffsetStren;
    float2 baseUV = vars.baseUV.xy + reflectViewLookTS.xy * k_volUVOffset * 0.1h;
    half3 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, baseUV).rgb;

	//////////////////////////////////////////////////////////
    // Ramp Color
	/////////////////////////////////////////////////////////
    real k_ramp = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, vars.rampAndNormalUV.xy).r;
    k_ramp = lerp(k_ramp, 1-k_ramp, _InvertRampTex > 0);
    k_ramp = saturate(pow(k_ramp * _RampValueCtrl.x + _RampValueCtrl.y, _RampValueCtrl.z));
    baseColor.rgb *= lerp(_RampColor1.rgb, _RampColor2.rgb, k_ramp);
    
    finalCol.rgb = baseColor;

	/////////////////////////////////////////////////////////////
    // scene distortion
	////////////////////////////////////////////////////////////
#if FOLDOUT 
CLEARNESS_DISTORTION_START
	float2 screenUV = vars.positionSS.xy / vars.positionSS.w;
	float2 distorUVOffset = normalTS.xy * _DistortionStren;

	float ditherMask = SAMPLE_TEXTURE2D(_DitherMask, DitherMask_point_clamp_sampler, screenUV + distorUVOffset);
	distorUVOffset *= ditherMask;

    real clearness = lerp(_Clearness, _Clearness * k_ramp, _RampClearnessOn);
	clearness = lerp(clearness, clearness * Fresnel(viewDirWS, normalWS, _FresnelClearnessPow), _FresnelClearnessOn);
	clearness = saturate(clearness);

    finalCol.rgb = lerp(finalCol.rgb, SAMPLE_TEXTURE2D(_CameraTransparentTexture, sampler_CameraTransparentTexture, screenUV + distorUVOffset).rgb, clearness);
CLEARNESS_DISTORTION_END
#endif //FOLDOUT

	/////////////////////////////////////////////////////////
	// Rim Light
	/////////////////////////////////////////////////////////
RIM_LIGHT_START
	real k_fresnel = Fresnel(viewDirWS, normalWS, _FresnelPow);
	finalCol.rgb += _FresnelColor * k_fresnel;
RIM_LIGHT_END

	////////////////////////////////////////////////////////////
	// Spec Light
	///////////////////////////////////////////////////////////
#if defined(_SPECULAR_LIGHT_ON)
	real3 H = normalize(normalize(-_SpecLightDir) + viewDirWS);
	real k_spec = pow(saturate(dot(H, normalWS)), _Shininess);
	finalCol.rgb += _SpecColor * k_spec;
#endif

	//////////////////////////////////////////////////////////
	//Dissolve
	//////////////////////////////////////////////////////////
#if defined(_DISSOLVE_ON)
	real dissVal = Dissolve_GetThreshold(_DissNoiseType,TEXTURE2D_ARGS(_DissTex, sampler_DissTex), vars.baseUV.zw,
					_DissNoiseScale, _DissNoiseAngleOffset, _DissNoiseCellDensity, _DissTex_ST);
	
	dissVal = lerp(dissVal, 1 - dissVal, _InvertDissNoise > 0);
	dissVal *= _DissParams.x;
	
	real dissAmout = lerp(_DissParams.w, vars.customData.x, _DissAmoutByCustomData1X > 0);
	real k_edge = Dissolve_HardClip(dissAmout, dissVal, _DissParams.yz, _DissEdgeWidth);
	finalCol.rgb += _DissEdgeColor * k_edge;
#endif

	GreyNegativeWithTint(_NegativeBrightFX, _NegativeStrengthFX, finalCol, _NegativeTintFX,_LumThreshholdFX);
	finalCol.a = saturate(finalCol.a);

	return OutputFXFinalColor(finalCol);
}


half4 ForwardFrag(Varyings vars) : SV_TARGET
{
	return ColorFrag(vars);
}


half4 BloomFrag(Varyings vars) : SV_TARGET
{
	half4 bloomMutiplyer = _GlobalFXBloomOn > 0 ? _BloomTint * _GlobalFXBloomIntensity : _BloomTint;
	half4 fragColor = ColorFrag(vars);
	return half4(fragColor.rgb * bloomMutiplyer.rgb, fragColor.a);
}


MRTOutput MRTFrag(Varyings i)
{
	MRTOutput mrtOutput = (MRTOutput)0;
	half4 bloomMutiplyer = _GlobalFXBloomOn > 0 ? _BloomTint * _GlobalFXBloomIntensity : _BloomTint;
	mrtOutput.fragColor =  ColorFrag(i);
	mrtOutput.bloomColor = half4(mrtOutput.fragColor.rgb * bloomMutiplyer.rgb * _BloomOn, mrtOutput.fragColor.a);
	
	return mrtOutput;
}


#endif 
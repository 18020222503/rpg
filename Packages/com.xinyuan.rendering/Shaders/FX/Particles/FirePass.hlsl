#ifndef FX_PARTICLE_FIRE_PASS_INCLUDED
#define FX_PARTICLE_FIRE_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/ProceduralNoiseHelper.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/UVHelper.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/Math.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/ColorAdjustment.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/ColorSpace.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/FX/FXDebug.hlsl"


#define STATIC_BRANCH_START(flag) UNITY_BRANCH if (flag) {
#define STATIC_BRANCH_END }
#define KEY_WORD_START(kw) #if kw
#define KEY_WORD_END #endif


// _DISSOVLE_ON (69.5%)
#ifdef _DISSOVLE_ON_BRANCH
    #define DISSOVLE_START			STATIC_BRANCH_START(_DissovleOn)
    #define DISSOVLE_END			STATIC_BRANCH_END
#else
    #define DISSOVLE_START			KEY_WORD_START(_DISSOVLE_ON)
    #define DISSOVLE_END			KEY_WORD_END
#endif


// _ALPHAMASK_ON (32%)
#ifdef _ALPHAMASK_ON_BRANCH
    #define ALPHAMASK_START			STATIC_BRANCH_START(_AlphaMaskOn)
    #define ALPHAMASK_END			STATIC_BRANCH_END
#else
    #define ALPHAMASK_START			KEY_WORD_START(_ALPHAMASK_ON)
    #define ALPHAMASK_END			KEY_WORD_END
#endif

struct Attributes
{
    float3 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float2 baseUV : TEXCOORD0;
    float4 customData : TEXCOORD1;
    float4 customData2 : TEXCOORD2;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
    float4 fireAndBaseUV : TEXCOORD0;
    float4 noiseAndMaskUV : TEXCOORD1;
    float4 dissUVAndFogFactor : TEXCOORD2;
    float4 customData : TEXCOORD3;
    float4 noise2UVAndRandomData : TEXCOORD4;
    float3 normalWS : TEXCOORD5;
    float3 positionWS : TEXCOORD6;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct MRTOutput
{
    half4 fragColor		: SV_TARGET0;
    half4 bloomColor	: SV_TARGET1;
};

real Fresnel(real3 viewDir, real3 normal, real fresnelScale, real fresnelPow)
{
    return fresnelScale * pow(1 - saturate(dot(viewDir, normal)), fresnelPow);
}

half4 SampleNoiseValue(Texture2D tex, half2 uv, half uvWarpMode,half invertNoise, half noiseStrenByCustomData, float customDataY, half noiseStren, half isLod)
{
    half4 noiseVal = isLod > 0 ? FX_FAST_SRGB_TO_LINEAR(SAMPLE_TEXTURE2D_WARP_LOD(tex, uv, uvWarpMode)) : FX_FAST_SRGB_TO_LINEAR(SAMPLE_TEXTURE2D_WARP(tex, uv,uvWarpMode));
    noiseVal = invertNoise > 0 ? half4(1, 1, 1, 1) - noiseVal : noiseVal;
    half noiseStren_ = noiseStrenByCustomData > 0 ? customDataY : noiseStren;
    noiseVal *= noiseStren_;
    return noiseVal;
}

Varyings vert(Attributes attrs)
{
    Varyings vars = (Varyings)0;
    UNITY_SETUP_INSTANCE_ID(attrs);
    UNITY_TRANSFER_INSTANCE_ID(attrs, vars);
    float2 baseUV = attrs.baseUV.xy;

    vars.noiseAndMaskUV.xy = UVHelper_TransformUV_NotWarp(baseUV, _NoiseTex_ST, float2(_NoiseUSpeed, _NoiseVSpeed), float2(0, 0), 0, 1);
    vars.noise2UVAndRandomData.xy = UVHelper_TransformUV_NotWarp(baseUV, _Noise2Tex_ST, float2(_Noise2USpeed, _Noise2VSpeed), float2(0, 0), 0, 1);
    // customData2的zw通道作为随机因子
    vars.noise2UVAndRandomData.zw = attrs.customData2.zw;
    half4 noiseVal = half4(1.0, 1.0, 1.0, 1.0);
#if defined(_ALPHA_SIMULATE_ON)
    half4 noise1Val = SampleNoiseValue(_NoiseTex,vars.noiseAndMaskUV.xy,_NoiseTexUVWrapMode,_InvertNoise,_NoiseStrenByCustomData,attrs.customData.y,_NoiseStren, 1);
    half4 noise2Val = SampleNoiseValue(_Noise2Tex,vars.noise2UVAndRandomData.xy,_Noise2TexUVWrapMode,_InvertNoise2,0,0,_Noise2Stren,1);
    noiseVal = noise1Val + noise2Val;
#endif

// Displacement 
#if defined(_DISPLACEMENT_ON)
    float2 displaceUV = UVHelper_TransformUV_NotWarp(baseUV, _DisplaceMap_ST,  float2(_DisplaceUSpeed, _DisplaceVSpeed), float2(0, 0), 0, _DisplaceUVMoveMode);
    half displaceAmout = FX_FAST_SRGB_TO_LINEAR(SAMPLE_TEXTURE2D_WARP_LOD(_DisplaceMap, displaceUV, _DisplaceUVWrapMode).r);
    displaceAmout = _InvertDisplaceMap > 0 ? 1-displaceAmout :  displaceAmout;
    displaceAmout *= _DisplaceStrenByCustomData > 0 ? attrs.customData2.x : _DisplaceStren;

    #if defined(_ALPHA_SIMULATE_ON)
        attrs.positionOS += attrs.normalOS * noiseVal.xyz * displaceAmout;
    #else
        attrs.positionOS += attrs.normalOS * displaceAmout; 
    #endif
#endif
    
    vars.positionCS = TransformObjectToHClip(attrs.positionOS);
    
    float eps = 5.960464478e-8;
    float modifiedPositionVS_Z = -max(_ProjectionParams.y + eps, abs(vars.positionCS.w) - _ZOffsetViewSpace);
    float modifiedPositionCS_Z = modifiedPositionVS_Z * UNITY_MATRIX_P[2].z + UNITY_MATRIX_P[2].w;
    vars.positionCS.z = lerp(vars.positionCS.z, modifiedPositionCS_Z *  vars.positionCS.w / -(modifiedPositionVS_Z), _DepthOffsetOn); 
        
    vars.fireAndBaseUV.xy = UVHelper_TransformUV_NotWarp(baseUV, _FireTex_ST, float2(_FireTexUSpeed, _FireTexVSpeed), attrs.customData.zw, 0, _FireTexUVMoveMode);
    vars.fireAndBaseUV.zw = baseUV;
    vars.noiseAndMaskUV.zw = UVHelper_TransformUV_NotWarp(baseUV, _NoiseMask_ST, float2(0,0), float2(0,0), 0, 0, float2(0.5, 0.5));
    vars.dissUVAndFogFactor.z = ComputeFogFactor(vars.positionCS.z);
    vars.customData = attrs.customData;
    vars.normalWS.xyz = TransformObjectToWorldNormal(attrs.normalOS);
    vars.positionWS.xyz = TransformObjectToWorld(attrs.positionOS);
DISSOVLE_START
    vars.dissUVAndFogFactor.xy = UVHelper_TransformUV_NotWarp(baseUV, _DissMap_ST,  float2(_DissUSpeed, _DissVSpeed), float2(0,0), 0, _DissUVMoveMode);
DISSOVLE_END

    return  vars;
}


half4 ColorFrag(Varyings vars)
{
    UNITY_SETUP_INSTANCE_ID(vars);

    // Noise
    half4 noiseVal = SampleNoiseValue(_NoiseTex,vars.noiseAndMaskUV.xy,_NoiseTexUVWrapMode,_InvertNoise,_NoiseStrenByCustomData,vars.customData.y,_NoiseStren, 0);

#if defined(TEXTURE_MASK_ON)
    half noiseMask = pow(FX_FAST_SRGB_TO_LINEAR(SAMPLE_TEXTURE2D_WARP(_NoiseMask, vars.noiseAndMaskUV.zw,_NoiseTexUVWrapMode).r), _NoiseMaskPow);
#else
    half noiseMask = pow(vars.noiseAndMaskUV.w, _NoiseMaskPow);
#endif
    noiseMask = _InvertMask > 0 ? 1 - noiseMask : noiseMask;   
    noiseVal *= noiseMask;
    
    // 第二张噪声贴图开启后与第一张噪声贴图相加 
    float2 noiseDir = float2(0, noiseVal.x);
    float2 alphaUV = UVHelper_TransformUV(vars.fireAndBaseUV.zw, _AlphaMaskTex_ST,  float2(0, 0), float2(0,0), 0, 0, 0);
    
    half FresnelMask = lerp(1, pow(vars.fireAndBaseUV.w * _FresnelMaskMul, _FresnelMaskPow), _FresnelMaskOn);
    
    // 透明度模拟火焰形态开关宏
#if defined(_ALPHA_SIMULATE_ON)
    half4 noise2Val = SampleNoiseValue(_Noise2Tex,vars.noise2UVAndRandomData.xy,_Noise2TexUVWrapMode,_InvertNoise2,_Noise2StrenByCustomData,vars.customData.y,_Noise2Stren, 0);
    noiseDir = noiseVal + noise2Val;

    noiseDir.x = XYRemap(noiseDir.x, 0, 1, _RemapNewMin, _RemapNewMax);
    noiseDir.y = XYRemap(noiseDir.y, 0, 1, _RemapNewMin, _RemapNewMax);

    half3 viewDir = normalize( _WorldSpaceCameraPos - vars.positionWS );
    half fresnelVal = Fresnel(viewDir, vars.normalWS, _FresnelScale, _FresnelPower) * FresnelMask;
    noiseDir = noiseDir * fresnelVal;
    half4 fireTex = SAMPLE_TEXTURE2D_WARP(_FireTex, noiseDir,_FireTexUVWrapMode);
    half3 col = fireTex.rgb * _MainCol;
    half alpha = 1.0;

    // AlphaMask处理 
    alphaUV += (noiseVal + noise2Val) * _AlphaMaskDistort;

#else
    half4 fireTex = SAMPLE_TEXTURE2D_WARP(_FireTex, vars.fireAndBaseUV.xy + noiseDir,_FireTexUVWrapMode);
    half3 col = _InnerCol.rgb * fireTex.g + _OuterCol.rgb * fireTex.r;
    half alpha = fireTex.b * _OuterCol.a;
#endif
    
ALPHAMASK_START
    half alphaMask = SAMPLE_TEXTURE2D_WARP(_AlphaMaskTex, alphaUV,_AlphaMaskUVWrapMode).r;
    alphaMask = _InvertAlphaMask > 0 ? 1-alphaMask : alphaMask;
    alphaMask *= _AlphaMaskStren;
    alpha *= alphaMask;
ALPHAMASK_END

#ifdef _ALPHATEST_ON
    clip(alpha - _Cutoff);
#endif

// Dissovle
DISSOVLE_START
    half progress = _DissStrenByCustomData > 0 ? saturate(vars.customData.x) : _DissStren;
    half2 dissUV = lerp(vars.dissUVAndFogFactor.xy, vars.dissUVAndFogFactor.xy + vars.noise2UVAndRandomData.zw, _DissovleRandomOn);
    half diss = FX_FAST_SRGB_TO_LINEAR(SAMPLE_TEXTURE2D_WARP(_DissMap, dissUV,_DissUVWrapMode).r);
    diss = _InvertDissMap > 0  ? 1-diss : diss;
    diss -= XYRemap(progress, half2(0,1), half2(-1,1));
    alpha *= smoothstep(0.5-_DissSmooth, 0.5, diss);
DISSOVLE_END

    col = _FogOn > 0 ? MixFog(col, vars.dissUVAndFogFactor.z) : col;
    alpha *= _AlphaMultiplyer;    

    GreyNegativeWithTint(_NegativeBrightFX, _NegativeStrengthFX, col, _NegativeTintFX,_LumThreshholdFX);
    alpha = saturate(alpha);

  //  col = FresnelMask;
    
    return OutputFXFinalColor(half4(col, alpha));
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
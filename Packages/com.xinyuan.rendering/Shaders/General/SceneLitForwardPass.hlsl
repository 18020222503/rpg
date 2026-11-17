#ifndef UNIVERSAL_STANDARD_FORWARD_LIT_PASS_INCLUDED
#define UNIVERSAL_STANDARD_FORWARD_LIT_PASS_INCLUDED

#include "Packages/com.xinyuan.rendering/ShaderLibrary/XYPipeline/XYLighting.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/XYPipeline/VertexDecode.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/ColorAdjustment.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/DitherFadeoutClipUtil.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Scene/FogLib.hlsl"

// GLES2 has limited amount of interpolators
#if defined(_PARALLAXMAP) && !defined(SHADER_API_GLES)
#define REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR
#endif

#if (defined(_NORMALMAP) || (defined(_PARALLAXMAP) && !defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR))) || defined(_DETAIL)
#define REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR
#endif

#if defined(_VERTEXANIM_ON) || defined(_VERTEXANIM_ANCHOR_ON)
#define _NEED_VERTEX_COLOR 1
#endif

#define TIME fmod(_Time.y, HALF_MAX)

struct Attributes
{
    float3 positionOS   : POSITION;
    half3  normalOS     : NORMAL;
    half4  tangentOS    : TANGENT;
    float2 texcoord      : TEXCOORD0;
    float2 lightmapUV    : TEXCOORD1;
#if defined(_FLOWMAP_NORMAL)
    float2 texcoord2    : TEXCOORD2;
#endif
    #if defined(_NEED_VERTEX_COLOR)
    half4 color         : COLOR;
    #endif
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float2 uv                       : TEXCOORD0;
    DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);

#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
    float3 positionWS               : TEXCOORD2;
#endif

    half3 normalWS                 : TEXCOORD3;
#if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR)
    float4 tangentWS                : TEXCOORD4;    // xyz: tangent, w: sign
#endif
    half3 viewDirWS                : TEXCOORD5;

    half4 fogFactorAndVertexLight   : TEXCOORD6; // x: fogFactor, yzw: vertex light

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    float4 shadowCoord              : TEXCOORD7;
#endif

#if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
    float3 viewDirTS                : TEXCOORD8;
#endif
    half4 screenPos                 : TEXCOORD9;
#if defined(_FLOWMAP_NORMAL)
    half2 flowNormalUV              : TEXCOORD10;
#endif
 
#if defined( _SHADOWTEX_ON)
    half4 selfshadow                : TEXCOORD11;
#endif
 
    float4 positionCS               : SV_POSITION;

    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};




// void InitializeSceneInputData(Varyings input, half3 normalTS, out InputData inputData)
// {
//     inputData = (InputData)0;
//
// #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
//     inputData.positionWS = input.positionWS;
// #endif
//
//     half3 viewDirWS = SafeNormalize(input.viewDirWS);
// #if defined(_NORMALMAP) || defined(_DETAIL)
//     half sgn = input.tangentWS.w;      // should be either +1 or -1 
//     half3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
//     inputData.normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz));
// #else
//     inputData.normalWS = input.normalWS;
// #endif
//
//     inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
//     inputData.viewDirectionWS = viewDirWS;
//
// #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
//     inputData.shadowCoord = input.shadowCoord;
// #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
//     inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
// #else
//     inputData.shadowCoord = float4(0, 0, 0, 0);
// #endif
//
//     inputData.fogCoord = input.fogFactorAndVertexLight.x;
//     inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
//     inputData.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, inputData.normalWS);
//     // inputData.bakedGI = FastSRGBToLinear(SAMPLE_GI(input.lightmapUV, input.vertexSH, inputData.normalWS)); 
//     inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
//     inputData.shadowMask = SAMPLE_SHADOWMASK(input.lightmapUV);
// }


void InitializeXYSceneInputData(Varyings input, half3 normalTS, out XYInputData inputData)
{
    inputData = (XYInputData)0;

    #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
    inputData.positionWS = input.positionWS;
    #endif

    half3 viewDirWS = SafeNormalize(input.viewDirWS);
    #if defined(_NORMALMAP) || defined(_DETAIL)
    half sgn = input.tangentWS.w;      // should be either +1 or -1 
    half3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
    inputData.normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz));
    #else
    inputData.normalWS = input.normalWS;
    #endif

    inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
    inputData.viewDirectionWS = viewDirWS;

    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    inputData.shadowCoord = input.shadowCoord;
    #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
    inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
    #else
    inputData.shadowCoord = float4(0, 0, 0, 0);
    #endif

    inputData.fogCoord = input.fogFactorAndVertexLight.x;
    inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
    inputData.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, inputData.normalWS);
    // inputData.bakedGI = FastSRGBToLinear(SAMPLE_GI(input.lightmapUV, input.vertexSH, inputData.normalWS)); 
    // inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
    inputData.shadowMask = SAMPLE_SHADOWMASK(input.lightmapUV);

}
///////////////////////////////////////////////////////////////////////////////
//                  Vertex and Fragment functions                            //
///////////////////////////////////////////////////////////////////////////////

// Used in Standard (Physically Based) shader
Varyings LitPassVertex(Attributes input)
{
    Varyings output = (Varyings)0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
    INIT_VERTEX_ANIM_DATA
    DOVERTEXANIM

    // #ifdef _VERTEXOFFSET_ON
    // half base = SAMPLE_TEXTURE2D_LOD(_VertexOffsetMap, sampler_VertexOffsetMap, (input.texcoord.xy + TIME * _VextexOffsetSpeed), 0.0h).r;
    // half3 vertexOffset = ((base * 2.0h) - 1.0h) * _VertexOffsetIntensity * input.normalOS;
    // input.positionOS.xyz += vertexOffset;
    // #endif


    half3 normalOS = input.normalOS; 
    half4 tangentOS = input.tangentOS; 
    #if _VERTEXCOMPRESSION_ON
         normalOS =  qTangentToNormal(input.tangentOS);
         tangentOS.xyz = qTangentToTangent(input.tangentOS);
    #endif  

    
    // normalWS and tangentWS already normalize.
    // this is required to avoid skewing the direction during interpolation
    // also required for per-vertex lighting and SH evaluation
    output.positionWS = TransformObjectToWorld(input.positionOS);
    output.positionCS = TransformWorldToHClip(output.positionWS);
    output.viewDirWS = GetWorldSpaceViewDir(output.positionWS);
    output.normalWS = TransformObjectToWorldNormal(normalOS);
    // already normalized from normal transform to WS.
    half4 tangentWS = real4(TransformObjectToWorldDir(tangentOS), 1.0h);
    
#if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR) || defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
    real sign = input.tangentOS.w * GetOddNegativeScale();
    tangentWS.w = sign;
#endif
#if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR)
    output.tangentWS = tangentWS;
#endif
    
#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    output.shadowCoord = TransformWorldToShadowCoord(output.positionWS);
#endif

    output.screenPos = ComputeScreenPos(output.positionCS);

#if defined( _SHADOWTEX_ON)
     half4 shadowuv =  mul(_WorldToClip ,half4(output.positionWS.xyz,1));
     output.selfshadow.xyz = shadowuv.xyz/shadowuv.w;
     output.selfshadow.xy = output.selfshadow.xy * 0.5 + 0.5 ;
#endif    
// #if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
//     half3 viewDirTS = GetViewDirectionTangentSpace(tangentWS, output.normalWS, viewDirWS);
//     output.viewDirTS = viewDirTS;
// #endif

    // Modify : 2022/10/19 不搞顶点灯先
    // half3 vertexLight = VertexLighting(output.positionWS, output.normalWS);
    half fogFactor = ComputeFogFactor(output.positionCS.z);
    output.fogFactorAndVertexLight = half4(fogFactor, 0.0h, 0.0h, 0.0h);
    OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

#if defined(_FLOWMAP_NORMAL)
    output.flowNormalUV = input.texcoord2;
#endif

    return output;
}

// Used in Standard (Physically Based) shader
half4 LitPassFragment(Varyings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    
    // ================================================
    // Tips: Diter 操作全部移动到DepthOnly 来计算 [by breen]
    DO_DITHER(input.positionWS, input.positionCS.xy, _DitherType);
    
    // ================================================ 

    
    XYSurfaceData xYsurfaceData = (XYSurfaceData)0;
    InitializeXYStandardLitSurfaceData(input.uv, xYsurfaceData);

    #if defined(_ALPHATEST_ON)
    clip(xYsurfaceData.alpha - _Cutoff);
    #endif

    #if defined(_FLOWMAP_NORMAL)
    half2 uv = input.flowNormalUV;
    half2 flowStrength = (_FlowVector * 0.1h);
    half2 flowMap = SAMPLE_TEXTURE2D(_FlowMap, sampler_FlowMap, uv);
    flowMap = flowMap - half2(0.5, 0) + 0.5h;
    half fracSpeed = frac(TIME * _FlowSpeed);
    half2 flowUV1 = uv - (flowMap * flowStrength * fracSpeed);
    half2 flowUV2 = uv - (flowMap * flowStrength * frac(fracSpeed + 0.5h));
    half4 normalMap = lerp(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, flowUV1),
        SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, flowUV2),
        (abs(fracSpeed - 0.5h) * 2.0h));
    xYsurfaceData.normalTS = UnpackNormalScale(normalMap, _BumpScale);
    #endif

    half radius = _SceneAttenuationParams.w;
    bool isCycleAtten = radius > -0.5h;
    half attenuation = _GlobalTintAttenuation;
    [branch] if (isCycleAtten)
    {
        half3 d = input.positionWS - _SceneAttenuationParams.xyz;
        half distance = dot(d, d);
        half attenuationMask = 1 - saturate(distance - radius * radius);
        attenuation = lerp(1, _GlobalTintAttenuation, attenuationMask);
    }
    // 当Radius为-1时 表示正常的场景压暗，不带球形遮罩
    // xYsurfaceData.albedo *= attenuation;

    // InputData inputData;
    // InitializeSceneInputData(input, surfaceData.normalTS, inputData);

    XYInputData xYInputData;
    InitializeXYSceneInputData(input, xYsurfaceData.normalTS, xYInputData);
    //增加对烘焙阴影图的强度控制
    xYInputData.shadowMask = lerp(_SceneShadowMapIntensity,1, xYInputData.shadowMask);
    // SETUP_DEBUG_TEXTURE_DATA(inputData, input.uv, _BaseMap);
    
    //------------cycle 2.9-----------------------
    
    bool debugOverride = false;
    half4 color = half4(xYsurfaceData.emission,1);
    half isNoEmission = color > 0 && _EmissionOnly >0 ? 0:1;
    
    [branch] if (isNoEmission)
    {
        #if defined(_BLINNPHONG)
         color = XYFragmentBlinnPhong(xYInputData, xYsurfaceData, debugOverride);
        #else
         color = XYFragmentPBR(xYInputData, xYsurfaceData, debugOverride);  // cycle 12
        #endif
    }
    
    //---------------cycle 16.17-----------------------

    // 添加虚投影   
    #if defined(_SHADOWTEX_ON)
        half4 ShadowMask = half4(1,1,1,1) ;
      #if defined(SHADOWS_SHADOWMASK) && defined(LIGHTMAP_ON)
        ShadowMask = SAMPLE_SHADOWMASK(input.lightmapUV);
      #elif !defined (LIGHTMAP_ON)
        ShadowMask = unity_ProbesOcclusion;
      #endif  
         #if UNITY_REVERSED_Z
         input.selfshadow.y = 1 - input.selfshadow.y ;
         #else
         input.selfshadow.y =  input.selfshadow.y;
         #endif     
         half4 shadowmask = SAMPLE_TEXTURE2D(_ShadowMask,sampler_LinearClamp,input.selfshadow.xy);              
         half shadow = saturate( 1- saturate(shadowmask * 2 - 1)  );  
         ShadowMask = lerp(ShadowMask , 0 , _IsGlobalShadow);
         half Shadowtex = saturate( shadow * (1 - ShadowMask.r) + ShadowMask.r ) ;
         color *= Shadowtex;                    
    #endif


    
    #if DEBUG_DISPLAY
    if (debugOverride)
        return color;
    #endif
    float height = input.positionWS.y - _FogPosition;
    MixFogWithHeightAndDistance(color.rgb, height, xYInputData.fogCoord);
    
    // color.a = OutputAlpha(color.a, _Surface);
    //TODO : 尝试把这个效果迁移到LUT中
    
    // GreyNegativeWithTint(_NegativeBrightScene, _NegativeStrengthScene, color, _NegativeTintScene, _LumThreshholdScene);

    
    // 场景单独Lut, _Apply_SceneLut在ColorGradingLut被赋值

    half3 lutColor = ApplyColorGrading(color.rgb, _Scene_Lut_Params.w, TEXTURE2D_ARGS(_ScenesLut, sampler_LinearClamp), _Scene_Lut_Params.xyz);
    
    color.rgb = lerp(color.rgb, lutColor, _Apply_SceneLut);
    
    color.rgb *= attenuation;
    
    half a = GetBloomPrefilter(color.rgb, _SceneBloomThreshold) * _SceneBloomIntensity;

    color.rgb = SCENE_FAST_LINEAR_TO_SRGB(color.rgb);
    
    SCENE_BLOOM_MUL(a);
    half finalAlpha = _Surface == 1 ? color.a : a;
    return half4(color.rgb, finalAlpha);
}

#endif

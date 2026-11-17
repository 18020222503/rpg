// SPDX-License-Identifier: (Not available for this version, you are only allowed to use this software if you have express permission from the copyright holder and agreed to the latest NiloToonURP EULA)
// Copyright (c) 2020 Kuroneko ShaderLab

// For more information, visit -> https://github.com/ColinLeung-NiloCat/UnityURPToonLitShaderExample

// This file is intented for you to extend this shader with your own custom logic.
// Add whatever code you want in this file, there are empty functions below for you to override by your own method

// #pragma once is a safeguard best practice in almost every .hlsl, 
// doing this can make sure your .hlsl's user can include this .hlsl anywhere anytime without producing any multi include conflict
#ifndef __ToonCharacter_ExtendFunctionsForUserCustomLogic__
#define __ToonCharacter_ExtendFunctionsForUserCustomLogic__

#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/Math.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/ProceduralNoise.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Character/ToonDissolveUtil.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Character/ToonDissolveDirUtil.hlsl"

#if _DISSOLVEE
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Character/ToonDissolveUtil_Opt.hlsl"
#endif
#if _FRESNELRAMP
TEXTURE2D(_FresnelRampTex);
TEXTURE2D(_FresnelRampNoise);
#endif

struct CustomVertexData
{
    half normalizeY;
};

//顶点的自定义操作        
CustomVertexData ApplyCustomUserLogicToVertexAttributeAtVertexShaderStart(inout Attributes attrubute)
{
    CustomVertexData vData = (CustomVertexData)0;
    
    half3 positionOS = half3(-attrubute.positionOS.z, -attrubute.positionOS.x, attrubute.positionOS.y);
    float3 positionWS = TransformObjectToWorld(attrubute.positionOS) - _HeadBonePositionWS.xyz;
    half3 povitPosRight = cross(_PovitPosWSUp, _PovitPosWSForward); 
    half3x3 povitPosSpaceMatrix = half3x3(povitPosRight, _PovitPosWSUp, _PovitPosWSForward); 
    half3 positionWSPovotPosSpace = mul(povitPosSpaceMatrix, positionWS);
    half3 normalWS = TransformObjectToWorldNormal(attrubute.normalOS, true);
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // VAT
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ApplyVertexAnimation(positionOS, attrubute.color.g);
    
    //Dissolve
#if _DISSOLVE
    #ifndef _DISSOLVE_STAGE   
    DISSOLVE_START(_DISSOLVE_ON)
    ApplyDissolveVertex(attrubute, positionWSPovotPosSpace, normalWS, positionOS, positionWS);
    DISSOLVE_END(_DISSOLVE_ON)
    #endif
#endif
    

    attrubute.positionOS = half3(-positionOS.y, positionOS.z, -positionOS.x);
    return vData;
}

// void ApplyCustomUserLogicToBaseColor(inout half4 baseColor)
// {
//
// }

//雾效前的自定义处理
void ApplyCustomUserLogicBeforeFog(inout half3 color, ToonSurfaceData surfaceData, ToonLightingData lightingData,inout half bloom)
{
    half3 positionWS = lightingData.positionWS.xyz - _HeadBonePositionWS.xyz;
    
    half3 povitPosRight = cross(_FaceUpDirection, _FaceForwardDirection); 
    half3x3 povitPosSpaceMatrix = half3x3(povitPosRight, _FaceUpDirection, _FaceForwardDirection); 
    half3 positionWSPovotPosSpace = mul(povitPosSpaceMatrix, positionWS);
    



    //FresnelRim
    half3 viewDirWS = normalize(_WorldSpaceCameraPos.xyz - lightingData.positionWS.xyz);
    half fresnelNdotV = (dot(lightingData.normalWS, viewDirWS));

#if _FRESNELRAMP
    half fresnel2 = (1-smoothstep(_FresnelRampParams.z - _FresnelRampParams.w, _FresnelRampParams.z + _FresnelRampParams.w, fresnelNdotV));
    
    //fresnelNdotV = lerp(fresnelNdotV, 1-fresnelNdotV, _FresnelRampInvert);
    half fresnel1 = ((1-smoothstep(_FresnelRampParams.x - _FresnelRampParams.y, _FresnelRampParams.x + _FresnelRampParams.y, fresnelNdotV)));
    fresnel1 = lerp(fresnel1, 1-fresnel1, _FresnelRampInvert);
    
    half rampNoise = SAMPLE_TEXTURE2D(_FresnelRampNoise, sampler_LinearRepeat , lightingData.uv.zw * _FresnelNoiseUV.z + _FresnelNoiseUV.xy * _Time.y);
    rampNoise = lerp(1, rampNoise, _FresnelNoiseUV.w);
    half3 ramp = SAMPLE_TEXTURE2D_X(_FresnelRampTex, sampler_LinearClamp, fresnel1 * rampNoise);
    ramp = FastSRGBToLinear(ramp);
    color = lerp(color, ramp, fresnel2);
    
#endif
    half rimMask = saturate((1 - smoothstep(_FXFresnelRimParams.x, _FXFresnelRimParams.x+ _FXFresnelRimParams.y, fresnelNdotV)) * _FXFresnelRimParams.z * _FXFresnelRim_ON);
    color = lerp(color, _FXFresnelRimColor, rimMask);
    bloom += BloomMaskRGB(_FXFresnelRimColor * rimMask, 1);

    
    #ifndef _DISSOLVE_STAGE   
    ApplyDissolveFragment(color, positionWSPovotPosSpace);
    #else
    ApplyTwoStageDissolveFrag(color, lightingData, positionWSPovotPosSpace,bloom);
    #endif
    
    #if _DISSOLVEE
    DISSOLVE_START(_DISSOLVEE_ON)        
        ApplyDissolveFragOpt(color, bloom, positionWSPovotPosSpace, lightingData.uv.zw, half2(_DissolveMaskUV, _DissolveMappUV), _DissolveMapp_ST, _DissolveSpeed, 
            _DissolProgress, _DissolDirect, _DissolDirectInvert, _DissolClipParams, _DissolEdgeColor, _DissolEdgeColorWidth);
    DISSOLVE_END(_DISSOLVEE_ON)
#endif
}

//雾效后的自定义处理
void ApplyCustomUserLogicAfterFog(inout half3 color, ToonSurfaceData surfaceData, ToonLightingData lightingData)
{
}

//clip的操作，应该优先处理，通用到深度和阴影
void ApplyClip(Varyings input)
{
    half3 positionWS = input.positionWS.xyz - _HeadBonePositionWS.xyz;
    
    half3 povitPosRight = cross(_PovitPosWSUp, _PovitPosWSForward); 
    half3x3 povitPosSpaceMatrix = half3x3(povitPosRight, _PovitPosWSUp, _PovitPosWSForward); 
    half3 positionWSPovotPosSpace = mul(povitPosSpaceMatrix, positionWS);
    
    #if _DITHER_FADEOUT
    ApplyDitherFadeoutFragment(input, _DITHERFADEOUT_ON);
    #endif
    
    #if _DISSOLVEE
        DISSOLVE_START(_DISSOLVEE_ON)        
            ApplyDissolveShadowOpt( positionWSPovotPosSpace, input.uv, half2(_DissolveMaskUV, _DissolveMappUV), _DissolveMapp_ST, _DissolveSpeed, 
            _DissolProgress, _DissolDirect, _DissolDirectInvert, _DissolClipParams);
        DISSOLVE_END(_DISSOLVEE_ON)
    #endif

}

#endif

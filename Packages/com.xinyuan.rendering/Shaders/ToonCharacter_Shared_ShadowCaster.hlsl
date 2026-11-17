// SPDX-License-Identifier: (Not available for this version, you are only allowed to use this software if you have express permission from the copyright holder and agreed to the latest NiloToonURP EULA)
// Copyright (c) 2020 Kuroneko ShaderLab

// For more information, visit -> https://github.com/ColinLeung-NiloCat/UnityURPToonLitShaderExample

// #pragma once is a safeguard best practice in almost every .hlsl, 
// doing this can make sure your .hlsl's user can include this .hlsl anywhere anytime without producing any multi include conflict
#ifndef __ToonCharacter_Shared_Shadow__
#define __ToonCharacter_Shared_Shadow__

#define STATIC_BRANCH_START(staticBranch)   UNITY_BRANCH if (staticBranch > 0) {
#define STATIC_BRANCH_ELSEIF(staticBranch)  else if (staticBranch > 0) {
#define STATIC_BRANCH_ELSE(staticBranch)    } else {
#define STATIC_BRANCH_END(staticBranch)     }

#define FACE_AREA_DEPTH_TEXTURE_ZOFFSET 0.04 // TODO: increase to 0.06?

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
//#include "Packages/com.xinyuan.rendering.character/ShaderLibrary/ToonDitherFadeModule.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
struct Attributes
{
    float3 positionOS   : POSITION;
    float3 normalOS     : NORMAL;       // GetVertexNormalInputs(...) expect float3 normalOS input, don't write half3 to produce unneeded type convertion cost
    // to support GPU instancing and Single Pass Stereo rendering(VR), add the following section
    //------------------------------------------------------------------------------------------------------------------------------
    UNITY_VERTEX_INPUT_INSTANCE_ID  // in non OpenGL / non PSSL, will turn into -> uint instanceID : SV_InstanceID;
    //------------------------------------------------------------------------------------------------------------------------------ 
};

struct Varyings
{
    float4 positionCS                           : SV_POSITION;
    // to support GPU instancing and Single Pass Stereo rendering(VR), add the following section
    //------------------------------------------------------------------------------------------------------------------------------
    UNITY_VERTEX_INPUT_INSTANCE_ID  // will turn into this in non OpenGL / non PSSL -> uint instanceID : SV_InstanceID;
    UNITY_VERTEX_OUTPUT_STEREO      // will turn into this in non OpenGL / non PSSL -> uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
    //------------------------------------------------------------------------------------------------------------------------------
};

CBUFFER_START(UnityPerMaterial)

    // Energy Filed
    half    _EFSize;
    half    _EFEdgeThreshold;
    half    _EFEdgeSmooth;
 
    half    _DitherFadeoutAmount;
    half    _DITHERFADEOUT_ON;
    //half3  _HeadBonePositionWS;
CBUFFER_END

half3 _LightDirection;
half _GlobalToonShaderNormalBiasMultiplier;
Varyings VertexShaderAllWork(Attributes input)
{

    Varyings output = (Varyings)0;
    
//     //Dither 0 直接剔除顶点   
// #if _DITHER_FADEOUT
//     ApplyDitherFadeoutVertex(output, _DITHERFADEOUT_ON)
// #endif
    // after invalid vertex part, do this part asap.
    // to support GPU instancing and Single Pass Stereo rendering(VR), add the following section
    //------------------------------------------------------------------------------------------------------------------------------
    UNITY_SETUP_INSTANCE_ID(input);                 // will turn into this in non OpenGL / non PSSL -> UnitySetupInstanceID(input.instanceID);
    UNITY_TRANSFER_INSTANCE_ID(input, output);      // will turn into this in non OpenGL / non PSSL -> output.instanceID = input.instanceID;
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);  // will turn into this in non OpenGL / non PSSL -> output.stereoTargetEyeIndexAsRTArrayIdx = unity_StereoEyeIndex;

    float3 positionWS = TransformObjectToWorld(input.positionOS);
    output.positionCS = TransformWorldToHClip(positionWS);
#if NiloToonShadowCasterPass
    half3 normalWS = TransformObjectToWorldNormal(input.normalOS);
    float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS * _GlobalToonShaderNormalBiasMultiplier, _LightDirection));
    #if UNITY_REVERSED_Z
        positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
    #else
        positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
    #endif
    output.positionCS = positionCS;
#endif
    
    return output;
}

void BaseColorAlphaClipTest(Varyings input)
{

}

#endif
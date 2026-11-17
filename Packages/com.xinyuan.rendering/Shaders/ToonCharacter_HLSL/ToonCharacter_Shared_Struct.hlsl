// SPDX-License-Identifier: (Not available for this version, you are only allowed to use this software if you have express permission from the copyright holder and agreed to the latest NiloToonURP EULA)
// Copyright (c) 2020 Kuroneko ShaderLab

// For more information, visit -> https://github.com/ColinLeung-NiloCat/UnityURPToonLitShaderExample

// #pragma once is a safeguard best practice in almost every .hlsl, 
// doing this can make sure your .hlsl's user can include this .hlsl anywhere anytime without producing any multi include conflict
#ifndef __ToonCharacter_Shared_Struct__
#define __ToonCharacter_Shared_Struct__

// all pass will share this Attributes struct (define data needed from Unity app to our vertex shader)
struct Attributes
{
    float3 positionOS   : POSITION;
    float3 normalOS     : NORMAL;       // GetVertexNormalInputs(...) expect float3 normalOS input, don't write half3 to produce unneeded type convertion cost
    float4 tangentOS    : TANGENT;      // GetVertexNormalInputs(...) expect float4 tangentOS input, don't write half4 to produce unneeded type convertion cost
    float2 uv           : TEXCOORD0;
    float2 uv2          : TEXCOORD1;
    float3 smoothNormal : TEXCOORD2;
    float4 color        : COLOR;        // used for outline width mask, so float not half
    // to support GPU instancing and Single Pass Stereo rendering(VR), add the following section
    //------------------------------------------------------------------------------------------------------------------------------
    UNITY_VERTEX_INPUT_INSTANCE_ID  // in non OpenGL / non PSSL, will turn into -> uint instanceID : SV_InstanceID;
    //------------------------------------------------------------------------------------------------------------------------------ 
};

// all pass will share this Varyings struct (define data needed from our vertex shader to our fragment shader)
// Note: once a field is written here, no matter fragment shader use it or not
// you will pay for the rasterization interpolation cost, 
// compiler won't help you in this case, you can check Unity's compiled shader code to confirm.
// so using #if to remove a field in Varyings is a meaningful optimization here
struct Varyings
{
    float4 positionCS                           : SV_POSITION;
    float4 uv                                   : TEXCOORD0;    // need float not half, if texture >= 2048 size, half is not enough
    half4 SH_fogFactor                          : TEXCOORD1;    // (4 half pack into 1 TEXCOORD)  xyz: SampleSH(0) * multipliers, w: fog factor
    float4 positionWS                           : TEXCOORD2;    // * can pack 1 float to this TEXCOORD.w in the future
    half4 normalWS_averageShadowAttenuation     : TEXCOORD3;    // (4 half pack into 1 TEXCOORD)  xyz: normalWS, w: averageShadowAttenuation

    //细节贴图用，暂时不需要
    // #if _DETAIL
    //     float2 detailUV                             : TEXCOORD4;
    // #endif
    
#if NeedCalculateAdditionalLight
    half3 additionalLightSum                    : TEXCOORD4;    // calculate in vertex shader to save fragment cycles
#endif
    float4 screenPos                            : TEXCOORD5;
//#if NeedFaceMaskArea
    //half flowVert                             : TEXCOORD5;
//#endif

//#if VaryingsHasTangentWS
    half4 tangentWS                             : TANGENT;      // xyz: tangent, w: sign
//#endif
   
//#if _DECAL_ON
    //float2 fulluv                               : TEXCOORD7;
//#endif
    // debug use
    //--------------------------------------------------------------------
    //#if _TOON_DEBUG_SHADING
    //float3 smoothNormal                         : TEXCOORD8;
    //#endif

//#if NeedVertexColorInFrag
    //half4 color                                 : COLOR;        // vertex color, currently only for debug shading
//#endif
    //--------------------------------------------------------------------

    // to support GPU instancing and Single Pass Stereo rendering(VR), add the following section
    //------------------------------------------------------------------------------------------------------------------------------
    UNITY_VERTEX_INPUT_INSTANCE_ID  // will turn into this in non OpenGL / non PSSL -> uint instanceID : SV_InstanceID;
    UNITY_VERTEX_OUTPUT_STEREO      // will turn into this in non OpenGL / non PSSL -> uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
    //------------------------------------------------------------------------------------------------------------------------------
};



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Data Structs
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
struct ToonSurfaceData
{
    half3   albedo;
    half    alpha;
    half3   emission;
    half    occlusion;
    half3   specular;
    half3   normalTS;
    half    roughness;
    half    normalizeY;
    half    samplingUvY;
};

struct ToonLightingData
{
    float4  uv;
    half3   normalWS;
    float3  positionWS;
    half3   viewDirectionWS;
    float   selfLinearEyeDepth; //深度边缘光用
    //half    averageShadowAttenuation; //平均阴影
    half3   SH;
    //half    isFaceArea; // default 0, = not face, see InitializeLightingData(...)
    //half    isSkinArea; // default 0, = not skin, see InitializeLightingData(...)
    float2  SV_POSITIONxy;
    //half4   vertcolor;

//#if VaryingsHasTangentWS
    half3x3 TBN_WS;
    half3   viewDirectionTS;
//#endif
    
#if NeedCalculateAdditionalLight
    half3   additionalLightSum;
#endif
    
//matcap需要
#if NeedNormalVS
    half3   normalVS;
#endif
//#if _DECAL_ON
    //float2  fulluv;
//#endif
    float4 screenPos;
};


#endif
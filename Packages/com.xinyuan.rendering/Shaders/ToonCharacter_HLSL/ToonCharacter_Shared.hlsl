// SPDX-License-Identifier: (Not available for this version, you are only allowed to use this software if you have express permission from the copyright holder and agreed to the latest NiloToonURP EULA)
// Copyright (c) 2020 Kuroneko ShaderLab

// For more information, visit -> https://github.com/ColinLeung-NiloCat/UnityURPToonLitShaderExample

// #pragma once is a safeguard best practice in almost every .hlsl, 
// doing this can make sure your .hlsl's user can include this .hlsl anywhere anytime without producing any multi include conflict
#ifndef __ToonCharacter_Shared__
#define __ToonCharacter_Shared__

// note:
// subfix OS means object spaces    (e.g. positionOS = position object space)
// subfix WS means world space      (e.g. positionWS = position world space)
// subfix VS means view space       (e.g. positionVS = position view space)
// subfix CS means clip space       (e.g. positionCS = position clip space)

// just helper defines to help us write less macro code
// write #define XXX 1, instead of just #define XXX, so we can use both #if or #ifdef without problem
#if defined(ToonSelfOutlinePass) || defined(ToonExtraThickOutlinePass) 
    #define ToonIsOutlinePass 1
#endif

#if defined(ToonForwardLitPass) || defined(ToonSelfOutlinePass)
    #define ToonIsColorPass 1
#endif
#if defined(_TOON_ADDITIONAL_LIGHTS)
    //#define _ADDITIONAL_LIGHTS 1 // we only require URP shader library's vertex level additional lighting
    #define _ADDITIONAL_LIGHTS_VERTEX 1
    #define NeedCalculateAdditionalLight 1
#endif
#if defined(_TOON_DEBUG_SHADING)
    #define NeedVertexColorInFrag 1
#endif
#if defined(_FLOWMAP_ON)
    #define _NORMALMAP 1
#endif
// because _DETAIL always sample detail normal map
#if defined(_NORMALMAP) || defined(_DETAIL) || defined(_KAJIYAKAY_SPECULAR) || defined(_DYNAMIC_EYE) || defined(_FROZEN_ON) || defined(_FLOW_LIGHT)
    #define VaryingsHasTangentWS 1
#endif

#if defined(_MATCAP_BLEND) || defined(_MATCAP_ADD)
    #define NeedNormalVS 1
#endif

#if defined(_ALPHAOVERRIDE) || defined(_NILOTOON_DITHER_FADEOUT)
#define _TOON_ENABLE_DEPTH_TEXTURE_RIMLIGHT_AND_SHADOW 0
#else
#define _TOON_ENABLE_DEPTH_TEXTURE_RIMLIGHT_AND_SHADOW 1
#endif


#define STATIC_BRANCH_START(staticBranch)   UNITY_BRANCH if (staticBranch > 0) {
#define STATIC_BRANCH_ELSEIF(staticBranch)  else if (staticBranch > 0) {
#define STATIC_BRANCH_ELSE(staticBranch)    } else {
#define STATIC_BRANCH_END(staticBranch)     }


#define FACE_AREA_DEPTH_TEXTURE_ZOFFSET 0.04 // TODO: increase to 0.06?

// We don't have "UnityCG.cginc" in SRP/URP's package anymore, so:
// Including the following two hlsl files is enough for shading with Universal Pipeline. Everything is included in them.
// - Core.hlsl will include SRP shader library, all constant buffers not related to materials (perobject, percamera, perframe).
//   It also includes matrix/space conversion functions and fog.
// - Lighting.hlsl will include the light functions/data to abstract light constants. You should use GetMainLight and GetLight functions
//   that initialize Light struct. Lighting.hlsl also include GI, Light BDRF functions. It also includes Shadows.

// Required by all Universal Render Pipeline shaders.
// It will include Unity built-in shader variables (except the lighting variables)
// (https://docs.unity3d.com/Manual/SL-UnityShaderVariables.html
// It will also include many utilitary functions. 
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

// Include this if you are doing a lit shader. This includes lighting shader variables,
// lighting and shadow functions
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#include "Packages/com.xinyuan.rendering/Shaders/ToonCharacter_HLSL/ToonCharacter_Shared_Input.hlsl"
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Data Structs
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#include "Packages/com.xinyuan.rendering/Shaders/ToonCharacter_HLSL/ToonCharacter_Shared_Struct.hlsl"

// include a few small utility .hlsl files to write less code
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Character/ToonAllUtilIncludes.hlsl"

///////////////////////////////////////////////////////////////////////////////////////
// vertex shared functions
///////////////////////////////////////////////////////////////////////////////////////
#include "Packages/com.xinyuan.rendering/Shaders/ToonCharacter_HLSL/ToonCharacter_Shared_VertexSharedFuntions.hlsl"
///////////////////////////////////////////////////////////////////////////////////////
// Fragment shared functions
///////////////////////////////////////////////////////////////////////////////////////
#include "Packages/com.xinyuan.rendering/Shaders/ToonCharacter_HLSL/ToonCharacter_Shared_FragmentSharedFuntions.hlsl"
///////////////////////////////////////////////////////////////////////////////////////
// InitializeData
///////////////////////////////////////////////////////////////////////////////////////
#include "Packages/com.xinyuan.rendering/Shaders/ToonCharacter_HLSL/ToonCharacter_Shared_InitializeData.hlsl"

// all lighting equation written inside this .hlsl,
// just by editing this .hlsl can control most of the visual result.
#include "Packages/com.xinyuan.rendering/Shaders/ToonCharacter_HLSL/ToonCharacter_LightingEquation.hlsl"

// all NiloToon supported ExternalAsset extension will goes here
//#include "Packages/com.xinyuan.rendering.character/Shaders/ToonCharacter_HLSL/ToonCharacter_ExtendFunctionsForExternalAsset.hlsl"

// if you want to extend this shader without future update merge conflict, you should edit this .hlsl
// it is made for NiloToonURP's user to extend more features by themselves
#include "Packages/com.xinyuan.rendering/Shaders/ToonCharacter_HLSL/ToonCharacter_ExtendFunctionsForUserCustomLogic.hlsl"

//Overdraw DEBUG 显示overdraw情况
#if DEBUG_DISPLAY

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceData.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Debug/Debugging3D.hlsl"

#endif


// [All pass's vertex shader will share this function]
// if "ToonIsOutlinePass" is not defined    = do regular MVP transform
// if "ToonIsOutlinePass" is defined        = do regular MVP transform + outline extrude vertex + all outline related task
Varyings VertexShaderAllWork(Attributes input)
{
    // init output struct with all 0 bits just to avoid "struct not init" warning/error
    // but passing 0 from vertex to fragment still has rasterization cost
    // so make sure Varyings struct is as small as possible
    Varyings output = (Varyings)0;
    //如果被半透抖动剔除则直接输出顶点
    if(_DitherFadeoutAmount == 1)
    {
        output.positionCS.w = 0;
        return output; 
    }

    //关闭描边直接输出CS顶点，针对单个角色，测试性能直接全局关闭描边的renderpass的就可以了
    // when rendering to _CameraColorTexture, this section will allow material's _RenderOutline toggle to control render outline or not, per material.
    // Be careful not to run this section in DepthOnly pass, 
    // in DepthOnly pass we only need to skip the outline extrude, not invalid the vertex!
    // so here only #if ToonSelfOutlinePass is used instead of #if ToonIsOutlinePass
// #if ToonSelfOutlinePass
//     if(!_RenderOutline)
//     {   
//         // [a trick to "delete" any vertex]
//         // if the output vertex's positionCS.w is 0, GPU will invalid this vertex and all connected vertices,
//         // we can use "positionCS.w = 0" to invalid all outline vertices if needed.
//         // Ideally you want to remove the outline pass completely and not use this trick if the material's _RenderOutline toggle is off for best performance,
//         // but it will require a custom material editor inspector, which may make things too complex without gaining much.
//         output.positionCS.w = 0;
//         return output;         
//     }
// #endif

    // after invalid vertex part, do this part asap.
    // to support GPU instancing and Single Pass Stereo rendering(VR), add the following section
    //------------------------------------------------------------------------------------------------------------------------------
    UNITY_SETUP_INSTANCE_ID(input);                 // will turn into this in non OpenGL / non PSSL -> UnitySetupInstanceID(input.instanceID);
    UNITY_TRANSFER_INSTANCE_ID(input, output);      // will turn into this in non OpenGL / non PSSL -> output.instanceID = input.instanceID;
    //UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);  // will turn into this in non OpenGL / non PSSL -> output.stereoTargetEyeIndexAsRTArrayIdx = unity_StereoEyeIndex;
    //------------------------------------------------------------------------------------------------------------------------------

    // allow external asset to edit Attributes
    //ApplyExternalAssetSupportLogicToVertexAttributeAtVertexShaderStart(input);
    // allow user to edit Attributes struct by custom .hlsl
    //修改模型顶点的自定义方法（顶点动画等）
    CustomVertexData cvData =  ApplyCustomUserLogicToVertexAttributeAtVertexShaderStart(input);

    //插入一个最简易的顶点着色器来对比shader的消耗情况
    // [insert a performance debug early exit]
    //------------------------------------------------------------------------------------------------------------------------------
    // exit as early as possible, to maximize performance difference
// #if _TOON_FORCE_MINIMUM_VERTEX_SHADER
//     #if ToonIsOutlinePass ||ToonDepthOnlyOrDepthNormalPass
//         output.positionCS = TransformObjectToHClip(input.positionOS + input.normalOS * 0.005); // any visible debug outline width is ok
//     #else
//         output.positionCS = TransformObjectToHClip(input.positionOS);
//     #endif
//
//     output.uv = input.uv;
//     return output;    
// #endif
    //------------------------------------------------------------------------------------------------------------------------------

    ///已迁移到customlogic.hlsl中
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // VAT 顶点动画 需要遮罩控制可动范围
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // #if _VAT_ON
    //     half offset = GetVertexAnimation(input.positionOS.xyz,input.color.g);
    //     half offsetX = lerp(0,offset,_offsetX);
    //     half offsetY = lerp(0,offset,_offsetY);
    //     half offsetZ = lerp(0,offset,_offsetZ);
    //
    //     input.positionOS.x += offsetX;
    //     input.positionOS.y += offsetY;
    //     input.positionOS.z += offsetZ;
    // #endif

    ///迁移到customlogic.hlsl中
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // FlowMap 顶点流动
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    #if defined(_FLOWMAP_ON)
            ///	FlowMap
            half2 uv = input.uv2.xy;
            half2 flowStrength = (-_FlowVert.xy * 0.1);
            half3 flowMapx = SAMPLE_TEXTURE2D_LOD(_FlowMap,sampler_FlowMap,uv,0);
           
            half2 flowMap= flowMapx.rg-half2(0,0.5)+0.5;
            float speed = _Time.y *  _FlowVert.z;
            float fracSpeed = frac(speed);

            float2 flow0 = uv * _VertFlowTex_ST.xy + _VertFlowTex_ST.zw + (flowMap*flowStrength*fracSpeed );  
            float2 flow1 = uv * _VertFlowTex_ST.xy + _VertFlowTex_ST.zw + (flowMap*flowStrength*frac(speed+0.5) );	
            half vertxx = lerp(SAMPLE_TEXTURE2D_LOD(_VertFlowTex,sampler_VertFlowTex,  flow0,0).r, SAMPLE_TEXTURE2D_LOD(_VertFlowTex,sampler_VertFlowTex,  flow1,0).r, (abs(fracSpeed-0.5))/0.5) -0.5;
            input.positionOS.xyz +=lerp(0, (input.normalOS) * saturate(vertxx) * _FlowVert.w * lerp(1, input.color.g, _useVertColB), _applyVertFlow);
            //output.flowVert = vertxx;
    #endif
    
   
    // VertexPositionInputs contains the position in multiple spaces (world, view, homogeneous clip space, NDC)
    // Unity compiler will strip all unused references (say you don't use view space).
    // Therefore there is more flexibility at no additional cost with this struct.
    VertexPositionInputs vertexPositionInput = GetVertexPositionInputs(input.positionOS);

    // Similar to VertexPositionInputs, VertexNormalInputs will contain normal, tangent and bitangent
    // in world space. If not used it will be stripped.
    // NormalWS and tangentWS are already normalized,
    // this is required to avoid skewing the direction during interpolation
    // also required for per-vertex lighting and SH evaluation if needed
    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

    
    float3 positionWS = vertexPositionInput.positionWS;
    // float3 positionVS = vertexPositionInput.positionVS;
    // float4 positionCSOutline = vertexPositionInput.positionCS;

    
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Fog 雾效
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    #if ToonIsColorPass
        /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // fog factor, calculate it before any positionHCS.z's edit
        /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        half fogFactor = ComputeFogFactor(vertexPositionInput.positionCS.z);
    #endif
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Outline 描边 (世界空间)
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // extrude positionWS if is outline pass and want to render outline
    #if ToonSelfOutlinePass
    ApplyToonOutline(positionWS, vertexNormalInput.normalWS, vertexNormalInput.tangentWS, vertexNormalInput.bitangentWS,
        -vertexPositionInput.positionVS.z, half4(input.smoothNormal, _OutlineUseBakedSmoothNormal),_OutlinePixelWidth * input.color.r);
    #endif

    // TRANSFORM_TEX is the same as the old shader library.
    output.uv.xy = input.uv;//TRANSFORM_TEX(input.uv,_MainTex);
    output.uv.zw = input.uv2;

    
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // DEBUG 显示用
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// #if _TOON_DEBUG_SHADING
//     output.smoothNormal = input.smoothNormal; // for showing tangent space smoothed normal as debug color
// #endif

    output.positionWS.xyz = positionWS;
    output.positionWS.w = cvData.normalizeY;
    
    half sign = input.tangentOS.w * GetOddNegativeScale();
    output.tangentWS = half4(vertexNormalInput.tangentWS.xyz, sign);

    //output.smoothNormal = input.smoothNormal;
    output.positionCS = TransformWorldToHClip(positionWS);

    half4 lightingNormalWS_faceArea = GetLightingNormalWS_FaceArea(vertexNormalInput.normalWS, output.uv);
    output.normalWS_averageShadowAttenuation.xyz = lightingNormalWS_faceArea.xyz; //normalized already by GetLightingNormalWS_FaceArea(...)


    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // 描边的深度偏移，可以剔除面部的眼睛描边（详见ToonZOffsetUtil.hlsl）
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // this section will apply clip space ZOffset (view space unit input) to outline position
    // doing this can hide ugly/unwanted outline, usually for face/eye
    // Only apply to _CameraColorTexture's outline pass
//#if ToonSelfOutlinePass
    // float outlineZOffsetMask = 1; 
    //
    // // [Apply ZOffset, Use remapped value as ZOffset mask]
    // float outlineZOffset = lerp(_OutlineZOffset,_OutlineZOffsetForFaceArea,lightingNormalWS_faceArea.w);
    // float finalZOffset = outlineZOffset * outlineZOffsetMask;
    //
    // // this line make ZOffset sync with camera distance corrected outline width
    // // If we don't do this, once camera is far away, zoffset will become not enough because outline width keep growing larger
    // // also stop reduce zoffset when camera is too close using max(1,x)
    // finalZOffset *= max(1,GetOutlineCameraFovAndDistanceFixMultiplier(positionVS.z, _CurrentCameraFOV) / 0.0025); 
    //
    // // apply ExtraThickOutlinePass's Zoffset (add) at the end, for isolated zoffset control
    // #if ToonExtraThickOutlinePass
    //     finalZOffset += _ExtraThickOutlineZOffset;
    // #endif
    //
    // output.positionCS = NiloGetNewClipPosWithZOffsetVS(output.positionCS, -finalZOffset);
//#endif

    //Shadow相关已拆分shader：ToonCharacter_ShadowCaster
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Shadow bias （详见Shadow.hlsl 得到阴影投射的裁剪坐标，避免shadow acne）
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // ShadowCaster pass needs special process to positionCS, else shadow artifact will appear
// #if NiloToonShadowCasterPass
//     // see GetShadowPositionHClip() in URP/Shaders/ShadowCasterPass.hlsl
//     // https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl
//
//     // normalBias will produce "holes" in shadowmap, so we add a slider to control it globally
//     float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, vertexNormalInput.normalWS * _GlobalToonShaderNormalBiasMultiplier, _LightDirection));
//     //float4 positionCS = mul(_LightRotationMatrix,float4(ApplyShadowBias(positionWS, vertexNormalInput.normalWS * _GlobalToonShaderNormalBiasMultiplier, _characterLight),1));
//     
//     #if UNITY_REVERSED_Z
//         positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
//     #else
//         positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
//     #endif
//
//     output.positionCS = positionCS;
//     
// #endif

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // ZOffset（眉毛眼睛通过简单的深度偏移显示在头发上，这种效果比较硬，使用半透的效果会更精致）
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // originally created to push eyebrow over hair / face expression mesh (e.g >///<) over face like a alpha blend decal/sticker
//#if ToonForwardLitPass
    // float zoffset = -_ZOffset;
    //
    // #if _ZOFFSETMAP
    //     float zOffsetTex2DlodExplicitMipLevel = 0;
    //     float zOffsetMultiplierByTex = dot(_ZOffsetMaskMapChannelMask,tex2Dlod(_ZOffsetMaskTex, float4(input.uv,0,zOffsetTex2DlodExplicitMipLevel)));
    //     zoffset *= zOffsetMultiplierByTex;
    // #endif
    //
    // output.positionCS =  NiloGetNewClipPosWithZOffsetVS(output.positionCS, zoffset);
//#endif

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // vertex color（DEBUG显示顶点色）
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//#if NeedVertexColorInFrag
    //output.color = input.color;
//#endif

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // 顶点着色的光照：球谐光照SH、AdditionalLight
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    #if ToonIsColorPass
        /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // SH (indirect from lightprobe) (moved to vertex shader for performance reason, it is ok due to low frequency result data)
        /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // [calculate SH in vertex shader to save some cycles]
        // hide 3D feeling by ignoring all detail SH
        // we only use this the constant term, = SampleSH(0)
        // we just want to get some average envi indirect color only
        // hardcode 0 can enable compiler optimization to remove no-op
        half3 SH = SampleSH(0);// * _GlobalIndirectLightMultiplier;

        output.SH_fogFactor = half4(SH, fogFactor);

        /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // All additional lights (moved to vertex shader for performance reason, it is ok due to low frequency result data)
        /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // #if NeedFaceMaskArea
        //     output.isFaceArea = lightingNormalWS_faceArea.w;
        // #endif
        #if NeedCalculateAdditionalLight
            half3 additionalLightNormalWS = lightingNormalWS_faceArea.xyz; //converted to face normal if is face area

            // Returns the number of lights affecting the object being renderer.
            // These lights are culled per-object in the forward renderer of URP.
            int additionalLightsCount = GetAdditionalLightsCount();
            for (int i = 0; i < additionalLightsCount; ++i)
            {
                // Similar to GetMainLight(), but it takes a for-loop index. This figures out the
                // per-object light index and samples the light buffer accordingly to initialized the
                // Light struct. If ADDITIONAL_LIGHT_CALCULATE_SHADOWS is defined it will also compute shadows.
                int perObjectLightIndex = GetPerObjectLightIndex(i);
                Light light = GetAdditionalPerObjectLight(perObjectLightIndex, positionWS); // use original positionWS for lighting

                // still no shadowmap for additional light(point light) in URP 10 (2020.3 LTS), so not supported
                // TODO: support it in URP 11
                /*
                if(_ReceiveSelfShadowMapping)
                {
                    light.shadowAttenuation = AdditionalLightShadow(perObjectLightIndex, perObjectLightIndex, 0, 0);         
                }
                */

                // Different function used to shade additional lights.
                output.additionalLightSum.rgb += CalculateAdditiveSingleAdditionalLight(additionalLightNormalWS, light);
                
            }

            output.additionalLightSum.rgb = min(output.additionalLightSum,_GlobalAdditionalLightMaxContribution) * _GlobalAdditionalLightMultiplier;
        #endif

        /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // average Shadow Attenuation 平均阴影的采样，针对实时阴影，烘焙阴影采样lightprobe即可
        /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // use LOAD instead of sample for simplify uv code and better performance
        // _TOONAverageShadowMapRT is a nx1 texture, so LOAD index is (charID,0)
        output.normalWS_averageShadowAttenuation.w = 1;//LOAD_TEXTURE2D(_TOONAverageShadowMapRT,float2(_AverageShadowMapRTSampleIndex,0)).r;
    #endif

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // detail texture uv（细节贴图，处理卡渲的贴图线条，减少锯齿感，对美术UV的要求较高，可见罪恶装备的做法）
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // #if _DETAIL
    //     // if we calculate UV in the vertex shader and use it directly in fragment shader without modifying it
    //     // GPU will have a chance to prefetch the texture before entering fragment shader
    //     // *atlease for PowerVR it is true
    //     output.detailUV = (_DetailUseSecondUv ? input.uv2 : input.uv) * _DetailMapsScaleTiling.xy + _DetailMapsScaleTiling.zw;
    // #endif

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // face（对脸部做深度偏移，以便深度图可分离出刘海阴影，避免一次对刘海的单独采样）
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // for face vertices, use ZOffset to push back depth write to _CameraDepthTexture, 
    // doing this can hide face depth texture cast self shadow on face's artifact
    //#if ToonDepthOnlyOrDepthNormalPass && _ISFACE
        // float cameraDepthTextureZOffsetMask = 1;
        // #if NeedFaceMaskArea
        //     cameraDepthTextureZOffsetMask = lightingNormalWS_faceArea.w;
        // #endif
        // // zoffset should be always greater or equal to depthDiffThreshold, to avoid face cast depth texture self shadow
        // output.positionCS = NiloGetNewClipPosWithZOffsetVS(output.positionCS, -FACE_AREA_DEPTH_TEXTURE_ZOFFSET * cameraDepthTextureZOffsetMask); 
    //#endif

    
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // remove perspective camera distortion（移除模型透视，便于做正交的展示效果）
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#if ToonIsColorPass || ToonDepthOnlyOrDepthNormalPass || ToonExtraThickOutlinePass
    output.positionCS = NiloDoPerspectiveRemoval(output.positionCS,positionWS,_HeadBonePositionWS,_PerspectiveRemovalRadius,_PerspectiveRemovalAmount);
#endif

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // 贴花（刀痕），输出全展的UV2
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //#if _DECAL_ON
        //output.fulluv = input.uv2;
    //#endif
    output.screenPos = ComputeScreenPos(output.positionCS);
    return output;
}


//////////////////////////////////////////////////////////////////////////////////////////
// only NiloToonCharacter.shader will call this function by 
// #pragma fragment FragmentShaderAllWork
//////////////////////////////////////////////////////////////////////////////////////////
///面对相机的变量：VFACE，正面为正，背面为负
half4 FragmentShaderAllWork(Varyings input, half facing : VFACE) : SV_TARGET
{
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // 先处理clip的内容
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    #if _DITHER_FADEOUT
    ApplyDitherFadeoutFragment(input, _DITHERFADEOUT_ON);
    #endif

    //检查法线正负
    // flip normal by VFace
    // TODO: recheck is this fix correct or not
    input.normalWS_averageShadowAttenuation.xyz *= facing;

    //支持GPUInstance
    // to support GPU instancing and Single Pass Stereo rendering(VR), add the following section
    //------------------------------------------------------------------------------------------------------------------------------
    UNITY_SETUP_INSTANCE_ID(input);                     // in non OpenGL / non PSSL, MACRO will turn into -> UnitySetupInstanceID(input.instanceID);
    //UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);    // in non OpenGL / non PSSL, MACRO will turn into -> unity_StereoEyeIndex = input.stereoTargetEyeIndexAsRTArrayIdx;
    //------------------------------------------------------------------------------------------------------------------------------

    //插入一个简易的片段着色器来对比shader的性能情况
    //////////////////////////////////////////////////////////////////////////////////////////
    // insert a performance debug early exit section here
    //////////////////////////////////////////////////////////////////////////////////////////
    // exit asap, to maximize performance difference
    // doing this can create a net GPU time difference between "Unlit/Texture" vs "full fragment shader"
    // which reflect the cost of this shader quite correctly on target device
    // #if _TOON_FORCE_MINIMUM_FRAGMENT_SHADER
    //     return Get_TOON_FORCE_MINIMUM_FRAGMENT_SHADER_result(input);
    // #endif

    //////////////////////////////////////////////////////////////////////////////////////////
    // prepare all data struct for lighting function
    //////////////////////////////////////////////////////////////////////////////////////////
    ToonSurfaceData surfaceData = InitializeSurfaceData(input);
    ToonLightingData lightingData = InitializeLightingData(input, surfaceData);

    //////////////////////////////////////////////////////////////////////////////////////////
    // insert debug shading early exit section here 用于DEBUG的显示
    //////////////////////////////////////////////////////////////////////////////////////////
// #if _TOON_DEBUG_SHADING
//     return Get_TOON_DEBUG_SHADING_result(input, surfaceData, lightingData);
// #endif

    //Overdraw DEBUG
#if DEBUG_DISPLAY
    half4 debugColor = half4(0, 0, 0, lerp(1, _MainColor.a, _RenderType_PARAM));
    InputData debugInputData = (InputData)0;
    SurfaceData debugSurfaceData = (SurfaceData)0;
    if (CanDebugOverrideOutputColor(debugInputData, debugSurfaceData, debugColor))
    {
        return debugColor;
    }
#endif

    
    //////////////////////////////////////////////////////////////////////////////////////////
    // Apply all lighting calculation
    //////////////////////////////////////////////////////////////////////////////////////////
    half bloom = 0;

    //计算光照
    half3 color = ShadeAllLights(surfaceData, lightingData, bloom);

    //ApplySurfaceToOutlineColorEditIfOutlinePass(color, surfaceData,lightingData);
    //ApplyVolumeEffectColorEdit(color);
    //ApplyPerCharacterEffectColorEdit(color, lightingData);
    
    //雾效前的自定义处理
    //ApplyExternalAssetSupportLogicBeforeFog(color, surfaceData, lightingData);
    ApplyCustomUserLogicBeforeFog(color, surfaceData, lightingData, bloom);

    //自定义距离雾和高度雾混合
    //ApplyFog(color, input);
    half3 worldPos = input.positionWS;
    half height = worldPos.y - _FogPosition;
    half3 originalCol = color.rgb;
    MixFogWithHeightAndDistance(originalCol.rgb, height, input.SH_fogFactor.w);
    color = lerp(color, originalCol, _GlobalCharFogEffect);

    //雾效后的自定义处理
    //ApplyExternalAssetSupportLogicAfterFog(color, surfaceData, lightingData);
    ApplyCustomUserLogicAfterFog(color, surfaceData, lightingData);
    
    //乘0.1，bloom乘算时*10，让RGB8格式的bloom强度超过1，
    half finalBloom  = (GetBloomPrefilter(color,_characterBloomThreshold) * _characterBloomIntensity + bloom) * 0.1;

    color.rgb = FastLinearToSRGB(color.rgb);
    
    //半透时需要bloom的处理：用额外的PASS输出一次bloom的值到A通道，原着色器屏蔽A通道输出半透值
    #if TRANPARENTBLOOM
        return half4(color, finalBloom);
    #else
        return half4(color, lerp(surfaceData.alpha, finalBloom, 1-_RenderType_PARAM));
    #endif
    
}

//针对DepthOnly的片段着色器，主要用于同步一些clip的操作避免穿帮
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// fragment shared functions 
// (only for ShadowCaster pass, DepthOnly and NiloToonSelfShadowCaster pass to use only)
// (not used in other pass)
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void BaseColorAlphaClipTest(Varyings input)
{
    //float2 uv = lerp(input.uv.xy, input.uv.zw, step(0, _DissNoiseUV));
    
    //同步溶解的clip
    // #ifndef _DISSOLVE_STAGE   
    // #else
    //     ApplyShadowDissolve(uv, input.positionWS - _PovitPosWS.xyz);
    // #endif
    
    // if _AlphaClip is off, there is no reason to call GetFinalBaseColor()
    // so here we use #if _ALPHATEST_ON to avoid calling GetFinalBaseColor() as an optimization
    // #if _ALPHATEST_ON
    //     DoClipTestToTargetAlphaValue(GetFinalBaseColor(input).a);
    // #endif
    
    ApplyClip(input);
}

//针对DepthNormal，已屏蔽
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// fragment shared functions 
// (only for DepthNormal pass to use only)
// (not used in other pass)
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// float4 BaseColorAlphaClipTest_AndDepthNormalColorOutput(Varyings input) : SV_TARGET
// {
//     UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
//
//     BaseColorAlphaClipTest(input);
//
//     return float4(PackNormalOctRectEncode(TransformWorldToViewDir(input.normalWS_averageShadowAttenuation.xyz, true)), 0.0, 0.0);
// }
//
 #endif
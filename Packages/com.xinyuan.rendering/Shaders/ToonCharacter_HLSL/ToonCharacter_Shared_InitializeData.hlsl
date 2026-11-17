// SPDX-License-Identifier: (Not available for this version, you are only allowed to use this software if you have express permission from the copyright holder and agreed to the latest NiloToonURP EULA)
// Copyright (c) 2020 Kuroneko ShaderLab

// For more information, visit -> https://github.com/ColinLeung-NiloCat/UnityURPToonLitShaderExample

// #pragma once is a safeguard best practice in almost every .hlsl, 
// doing this can make sure your .hlsl's user can include this .hlsl anywhere anytime without producing any multi include conflict
#ifndef __ToonCharacter_Shared_InitializeData__
#define __ToonCharacter_Shared_InitializeData__

ToonSurfaceData InitializeSurfaceData(Varyings input)
{
    ToonSurfaceData output;

    // albedo & alpha
    half4 baseColorFinal = GetFinalBaseColor(input);
    // ApplyExternalAssetSupportLogicToBaseColor(baseColorFinal);
    // ApplyCustomUserLogicToBaseColor(baseColorFinal);
    output.albedo = baseColorFinal.rgb;
    output.alpha = baseColorFinal.a;
    //DoClipTestToTargetAlphaValue(output.alpha);// let clip() early exit asap once alpha value is known
    
    half4 multiChannelTex = SAMPLE_TEXTURE2D(_RMAOMap, sampler_LinearRepeat, input.uv.xy);
    multiChannelTex = FastSRGBToLinear(multiChannelTex);
    // emission
    output.emission = GetFinalEmissionColor(input, baseColorFinal.rgb,multiChannelTex);
    // occlusion
    output.occlusion = GetFinalOcculsion(input, multiChannelTex);
    // specular & roughness
    //half4 specularRoughnessData = GetFinalSpeculaRGB_RoughnessA(input,baseColorFinal.rgb, multiChannelTex);
    output.specular = GetFinalSpecular(input,baseColorFinal.rgb, multiChannelTex);
    //output.roughness = specularRoughnessData.a;
    output.samplingUvY = multiChannelTex.a;
    // normalTS
    output.normalTS = GetFinalNormalTS(input);

// #if _DETAIL && !_TOON_DEBUG_SHADING
//     half detailMask = dot(_DetailMaskChannelMask, SAMPLE_TEXTURE2D(_DetailMask, sampler_DetailMask, input.uv));
//     output.albedo = ApplyDetailAlbedo(input.detailUV, output.albedo, detailMask);
//     output.normalTS = ApplyDetailNormal(input.detailUV, output.normalTS, detailMask);
// #endif

    output.normalizeY = input.positionWS.w;
    return output;
}
ToonLightingData InitializeLightingData(Varyings input, ToonSurfaceData surfaceData)
{
    ToonLightingData lightingData;
    lightingData.uv = input.uv;
    //lightingData.vertcolor = input.color;

//#if _DECAL_ON
    //lightingData.fulluv = input.fulluv;
//#endif
    lightingData.positionWS = input.positionWS.xyz;
    lightingData.viewDirectionWS = normalize(GetCameraPositionWS() - lightingData.positionWS);  

    half3 normalWS = input.normalWS_averageShadowAttenuation.xyz;

//#if VaryingsHasTangentWS
    // we have to do this when an odd number of dimensions in transform scale are negative.
    half sgn = input.tangentWS.w * unity_WorldTransformParams.w; // should be either +1 or -1

    // no need to normalize bitangentWS if you only use normalWS, 
    // since we normalize normalWS at the end when we assign normalWS's result to lightingData. (see LitForwardPass.hlsl)
    half3 bitangentWS = sgn * cross(normalWS, input.tangentWS.xyz);

   
    lightingData.TBN_WS = half3x3(input.tangentWS.xyz, bitangentWS, normalWS);
    lightingData.viewDirectionTS = TransformWorldToTangent(lightingData.viewDirectionWS,lightingData.TBN_WS);
//#endif

    // if any normalmap is enabled, convert normalTS in normalmap to normalWS
    #if _NORMALMAP || _DETAIL     
     normalWS = TransformTangentToWorld(surfaceData.normalTS,lightingData.TBN_WS); // apply normalmapped result normalWS (rotation-only matrix's transpose equals inverse)
    #endif

    // In theory we should re-normalize all directions vector after interpolation.
    // Here even _NORMALMAP is false, we still normalzie() to ensure correctness.
    // Not normalize() will affect specular result greatly!
    // The only case we want to skip normalize() is on mobile / switch
    lightingData.normalWS = NormalizeNormalPerPixel(normalWS);

    // input.positionCS(SV_POSITION) in fragment shader is in window space
    // x = [0, RT width]
    // y = [0, RT height]
    lightingData.SV_POSITIONxy = input.positionCS.xy;
    lightingData.screenPos = input.screenPos;
    // note for future XR development:
    // code to fix VR problem: https://docs.unity3d.com/Manual/SinglePassStereoRendering.html
    //lightingData.screenUV = input.screenPos.xy / input.screenPos.w;
    //lightingData.screenUV = UnityStereoTransformScreenSpaceTex(lightingData.screenUV);
    
    // [why not just pass abs(positionVS.z) from vertex shader?]
    // because we want selfLinearEyeDepth having the same format as Convert_SV_PositionZ_ToLinearViewSpaceDepth(_CameraDepthTexture's value)
    // recalcuate selfLinearEyeDepth from positionCS.z provided much better precision when doing depth texture shadow depth comparsion logic
    // a Samsung A70 mobile precision test @ 2021-3-23 confirmed depth texture shadow precision improved a lot using this line instead of abs(positionVS.z) from vertex shader  
    lightingData.selfLinearEyeDepth = Convert_SV_PositionZ_ToLinearViewSpaceDepth(input.positionCS.z);

    lightingData.SH = input.SH_fogFactor.xyz;
#if NeedCalculateAdditionalLight
    lightingData.additionalLightSum = input.additionalLightSum.rgb;
#endif
    //lightingData.averageShadowAttenuation = input.normalWS_averageShadowAttenuation.w;

//matcap
#if NeedNormalVS
    lightingData.normalVS = mul((half3x3)UNITY_MATRIX_V, lightingData.normalWS).xyz;
#endif
    return lightingData;
}
#endif
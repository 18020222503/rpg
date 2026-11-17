// SPDX-License-Identifier: (Not available for this version, you are only allowed to use this software if you have express permission from the copyright holder and agreed to the latest NiloToonURP EULA)
// Copyright (c) 2020 Kuroneko ShaderLab

// For more information, visit -> https://github.com/ColinLeung-NiloCat/UnityURPToonLitShaderExample

// #pragma once is a safe guard best practice in almost every .hlsl, 
// doing this can make sure your .hlsl's user can include this .hlsl anywhere anytime without producing any multi include conflict
#ifndef __ToonPerspectiveRemovalUtil__
#define __ToonPerspectiveRemovalUtil__

// warning: using perspective removal may make CPU per renderer culling not perfect, since CPU won't know what is happening in GPU
float4 NiloDoPerspectiveRemoval(float4 originalPositionCS, float perspectiveRemovalAmount, float centerPosVSz)
{
    // only do perspective removal if is perspective camera
    if(unity_OrthoParams.w == 1) 
        return originalPositionCS;

    // resources:
    // - https://zhuanlan.zhihu.com/p/268433650?utm_source=ZHShareTargetIDMore
    // - https://zhuanlan.zhihu.com/p/332804613

    // resources link's demo method
    /*
    float originalPositionCSZ = output.positionCS.z;
    float4 perspectiveCorrectPosVS = mul(UNITY_MATRIX_I_P, output.positionCS);
    perspectiveCorrectPosVS.z -= centerPosVSz;
    perspectiveCorrectPosVS.z *= lerp(1,0.1,perspectiveCorrectUsage); // Flatten model's pos z in view space
    perspectiveCorrectPosVS.z += centerPosVSz;    
    output.positionCS = mul(UNITY_MATRIX_P, perspectiveCorrectPosVS);
    output.positionCS.z = originalPositionCSZ;
    */

    // our method
    float2 newPosCSxy = originalPositionCS.xy;
    newPosCSxy *= abs(originalPositionCS.w); // cancel Hardware w-divide
    newPosCSxy *= rcp(abs(centerPosVSz)); // do our flattened w-divide
    originalPositionCS.xy = lerp(originalPositionCS.xy, newPosCSxy, perspectiveRemovalAmount); // apply 0~100% perspective removal  

    return originalPositionCS;    
}

// high level helper function
float4 NiloDoPerspectiveRemoval(float4 originalPositionCS, float3 positionWS, float3 removalCenterPositionWS, float removalRadius, float removalAmount)
{
    float perspectiveRemovalArea = saturate(removalRadius - distance(positionWS,removalCenterPositionWS) / removalRadius);
    float perspectiveRemovalFinalAmount = removalAmount * perspectiveRemovalArea;
    float centerPosVSz = mul(UNITY_MATRIX_V, float4(removalCenterPositionWS,1)).z;

    return NiloDoPerspectiveRemoval(originalPositionCS, perspectiveRemovalFinalAmount, centerPosVSz);
}

#endif

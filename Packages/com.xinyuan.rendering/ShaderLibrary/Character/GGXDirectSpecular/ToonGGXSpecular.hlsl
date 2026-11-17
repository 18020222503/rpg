// SPDX-License-Identifier: (Not available for this version, you are only allowed to use this software if you have express permission from the copyright holder and agreed to the latest NiloToonURP EULA)
// Copyright (c) 2020 Kuroneko ShaderLab

// For more information, visit -> https://github.com/ColinLeung-NiloCat/UnityURPToonLitShaderExample

// #pragma once is a safe guard best practice in almost every .hlsl, 
// doing this can make sure your .hlsl's user can include this .hlsl anywhere anytime without producing any multi include conflict
#ifndef __ToonGGXSpecular__
#define __ToonGGXSpecular__

// copied G1V(...) from https://github.com/bartwronski/CSharpRenderer/blob/master/shaders/optimized-ggx.hlsl
float G1V(float dotNV, float k)
{
    return 1.0f / (dotNV * (1.0f - k) + k);
}
// copied LightingFuncGGX_REF(...) from https://github.com/bartwronski/CSharpRenderer/blob/master/shaders/optimized-ggx.hlsl
float GGXDirectSpecular(float3 N, float3 V, float3 L, float roughness, float F0)
{
    float alpha = roughness * roughness;

    float3 H = normalize(V + L);

    float dotNL = saturate(dot(N, L));
    float dotNV = saturate(dot(N, V));
    float dotNH = saturate(dot(N, H));
    float dotLH = saturate(dot(L, H));

    float F, D, vis;

    // D
    float alphaSqr = alpha * alpha;
    float pi = 3.14159f;
    float denom = dotNH * dotNH * (alphaSqr - 1.0) + 1.0f;
    D = alphaSqr / (pi * denom * denom);

    // F
    float dotLH5 = pow(1.0f - dotLH, 5);
    F = F0 + (1.0 - F0) * (dotLH5);

    // V
    float k = alpha / 2.0f;
    vis = G1V(dotNL, k) * G1V(dotNV, k);

    float specular = dotNL * D * F * vis;
    return specular;
}

///////////////////////////////////////////////////////////////////////////////////////////
// These two are the same function as the above G1V(...) and GGXDirectSpecular(...), 
// but assumed L equals V (assumed light always come from camera, for NPR purpose), 
// when L equals V we can do some more optimization!
//
// Converted to half also.
///////////////////////////////////////////////////////////////////////////////////////////
half G1V_half(half dotNV, half k)
{
    return 1.0f / (dotNV * (1.0f - k) + k);
}
half GGXDirectSpecular_LequalsV_Optimized(half NdotV,half VdotV, half roughness, half F0)
{
    half alpha = roughness * roughness;

    half F, D, vis;

    // D
    half alphaSqr = alpha * alpha;
    half pi = 3.14159f;
    half denom = NdotV * NdotV * (alphaSqr - 1.0) + 1.0f;
    D = alphaSqr / (pi * denom * denom);

    // F
    half dotLH5 = pow(1.0f - VdotV, 5);
    F = F0 + (1.0 - F0) * (dotLH5);

    // V
    half k = alpha / 2.0f;
    half G1VResult = G1V_half(NdotV, k);
    vis = G1VResult * G1VResult;

    half directSpecular = NdotV * D * F * vis;
    return directSpecular;
}
///////////////////////////////////////////////////////////////////////////////////////////
// This is the same function as GGXDirectSpecular(...)
// But don't require calculating H,dotNL,dotNV,dotNH,dotLH again inside the function.
// User should provide all of the above data.
///////////////////////////////////////////////////////////////////////////////////////////
float GGXDirectSpecular_Optimized(float3 H, float dotNL, float dotNV, float dotNH, float dotLH, float roughness, float F0,float dis)
{
    //dotNL = saturate(dotNL -dis); //扩大阴影遮罩范围，高光到阴影有一段距离渐隐消失

    float alpha = roughness*roughness;

    float F, D, vis;

    // D
    float alphaSqr = alpha*alpha;
    float pi = 3.14159f;
    float denom = dotNH * dotNH *(alphaSqr-1.0) + 1.0f;
    D = alphaSqr/(pi * denom * denom);

    // F
    float dotLH5 = pow(1.0f-dotLH,5);
    F = F0 + (1.0-F0)*(dotLH5);

    // V
    float k = alpha/2.0f;
    vis = G1V(dotNL,k)*G1V(dotNV,k);

    float specular = dotNL * D * F * vis;
    return specular;
}
#endif


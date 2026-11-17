// SPDX-License-Identifier: (Not available for this version, you are only allowed to use this software if you have express permission from the copyright holder and agreed to the latest NiloToonURP EULA)
// Copyright (c) 2020 Kuroneko ShaderLab

// For more information, visit -> https://github.com/ColinLeung-NiloCat/UnityURPToonLitShaderExample

// #pragma once is a safe guard best practice in almost every .hlsl, 
// doing this can make sure your .hlsl's user can include this .hlsl anywhere anytime without producing any multi include conflict
#ifndef __ToonAllUtilIncludes__
#define __ToonAllUtilIncludes__

#include "Packages/com.xinyuan.rendering/ShaderLibrary/Character/ToonHSVRGBConvert.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Character/ToonNormalVectorUtil.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Character/ToonOutlineUtil.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Character/ToonZOffsetUtil.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Character/ToonInvLerpRemapUtil.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Character/ToonDepthTextureUtil.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Character/GGXDirectSpecular/ToonGGXSpecular.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Character/ToonStrandSpecular.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Character/ToonPerspectiveRemovalUtil.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Character/ToonDitherFadeoutClipUtil.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Scene/FogLib.hlsl"

//自定义bloom强度
half BloomMaskRGB(half3 bloomColor, half bloomSten)
{
    half brightness = Max3(bloomColor.r, bloomColor.g, bloomColor.b);
    // half bloomMaskGB = lerp(bloomColor.g, bloomColor.b, step(2,bloomColorRGB));
    // half bloomMask = lerp(bloomColor.r, bloomMaskGB, step(1,bloomColorRGB));
    half sten = max(bloomSten,0);
    return brightness * sten;
}
#endif

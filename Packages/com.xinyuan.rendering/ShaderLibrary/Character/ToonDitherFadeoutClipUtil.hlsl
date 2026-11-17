// SPDX-License-Identifier: (Not available for this version, you are only allowed to use this software if you have express permission from the copyright holder and agreed to the latest NiloToonURP EULA)
// Copyright (c) 2020 Kuroneko ShaderLab

// For more information, visit -> https://github.com/ColinLeung-NiloCat/UnityURPToonLitShaderExample

// #pragma once is a safe guard best practice in almost every .hlsl, 
// doing this can make sure your .hlsl's user can include this .hlsl anywhere anytime without producing any multi include conflict
#ifndef __ToonDitherFadeModule__
#define __ToonDitherFadeModule__

#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/DitherFadeoutClipUtil.hlsl"

#if _DITHER_FADEOUT
#if _DITHER_FADEOUT_BRANCH
    #define DITHER_FADEOUT_ON(ditherFadeOut)    half  ditherFadeOut
    #define DITHER_FADEOUT_START(ditherFadeOut) STATIC_BRANCH_START(ditherFadeOut)
    #define DITHER_FADEOUT_END(ditherFadeOut)   STATIC_BRANCH_END(ditherFadeOut) 
#else
    #define DITHER_FADEOUT_ON(ditherFadeOut)
    #define DITHER_FADEOUT_START(ditherFadeOut)
    #define DITHER_FADEOUT_END(ditherFadeOut)
#endif

#define ApplyDitherFadeoutVertex(output, ditherFadeOut) \
    DITHER_FADEOUT_START(ditherFadeOut) \
        if(_DitherFadeoutAmount == 1) { output.positionCS.w = 0; return output; } \
    DITHER_FADEOUT_END(ditherFadeOut)

#define ApplyDitherFadeoutFragment(input, ditherFadeOut) \
    DITHER_FADEOUT_START(ditherFadeOut) \
        DoDitherFadeoutClip(input.positionCS.xy, 1-_DitherFadeoutAmount); \
    DITHER_FADEOUT_END(ditherFadeOut)

#else
#define ApplyDitherFadeoutVertex(output, ditherFadeOut) 
#define ApplyDitherFadeoutFragment(input, ditherFadeOut)
#endif


#endif


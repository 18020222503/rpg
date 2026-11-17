#ifndef _SHADER_LIBRARY_UTILITIES_COLOR_SPACE_INCLUDE
#define _SHADER_LIBRARY_UTILITIES_COLOR_SPACE_INCLUDE

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
// 如果需要在不同Color Space 里面进行切换操作的话, 尽量使用宏进行操作 (by breen)

real4 FastSRGBToLinear4Channel(real4 c)
{
    return c * (c * (c * 0.305306011 + 0.682171111) + 0.012522878);
}

#if UNITY_COLORSPACE_GAMMA
#define FAST_SRGB_TO_LINEAR(x) FastSRGBToLinear(x)
#define FAST_SRGB_TO_LINEAR_FOUR(x) FastSRGBToLinear4Channel(x) 
#else
#define FAST_SRGB_TO_LINEAR(x) x
#define FAST_SRGB_TO_LINEAR_FOUR(x) x
#endif

#if UNITY_COLORSPACE_GAMMA
#define FAST_LINEAR_TO_SRGB(x) FastLinearToSRGB(x)
#else
#define FAST_LINEAR_TO_SRGB(x) x 
#endif

// 角色模块进行特殊控制, 方便后面统一特效取消做准备
#define CHAR_FAST_SRGB_TO_LINEAR(x) FAST_SRGB_TO_LINEAR(x)
#define CHAR_FAST_LINEAR_TO_SRGB(x) FAST_LINEAR_TO_SRGB(x)
// 场景模块进行特殊控制, 方便后面统一特效取消做准备
#define SCENE_FAST_SRGB_TO_LINEAR(x) FAST_SRGB_TO_LINEAR(x)
#define SCENE_FAST_LINEAR_TO_SRGB(x) FAST_LINEAR_TO_SRGB(x)
#define SCENE_FAST_LINEAR_TO_SRGB_FOUR(x) FAST_SRGB_TO_LINEAR_FOUR(x)
// 特效模块进行特殊控制, 方便后面统一特效取消做准备
#define FX_FAST_SRGB_TO_LINEAR(x) FAST_SRGB_TO_LINEAR(x)
#define FX_FAST_LINEAR_TO_SRGB(x) FAST_LINEAR_TO_SRGB(x)

#if UNITY_COLORSPACE_GAMMA
#define XY_GI_SAMPLE_LIGHTMAP(lightmapArgs, lightmapExtArgs, transformCoords, encodedLightmap, decodeInstructions) SampleForceLinearRGBMLightmap(lightmapArgs, lightmapExtArgs, transformCoords)
#else
#define XY_GI_SAMPLE_LIGHTMAP(lightmapArgs, lightmapExtArgs, transformCoords, encodedLightmap, decodeInstructions) SampleSingleLightmap(TEXTURE2D_LIGHTMAP_ARGS(LIGHTMAP_NAME, LIGHTMAP_SAMPLER_NAME), LIGHTMAP_SAMPLE_EXTRA_ARGS, transformCoords, encodedLightmap, decodeInstructions) 
#endif


#if UNITY_COLORSPACE_GAMMA
#define XY_INIT_META_SURFACEDATA(uv, surfacedata) _MetaInitializeStandardLitSurfaceData(uv, surfacedata)
#else
#define XY_INIT_META_SURFACEDATA(uv, surfacedata) InitializeStandardLitSurfaceData(uv, surfacedata)
#endif

#endif

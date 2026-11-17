#ifndef __ToonDissolveModuleOpt__
#define __ToonDissolveModuleOpt__

#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/Math.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/ProceduralNoise.hlsl"

TEXTURE2D(_DissolveMapp);          SAMPLER(sampler_DissolveMapp);
//TODO：临时开放遮罩图，后续美术调整完毕合并到主贴图
TEXTURE2D(_DissolveMask);          SAMPLER(sampler_DissolveMask);

#define X_DISSOLVE half3(1, 0, 0)
#define Y_DISSOLVE half3(0, 1, 0)
#define Z_DISSOLVE half3(0, 0, 1)

void ApplyDissolveVertexOpt(inout half3 positionOS, half3 position, half2 uv, half2 uvSelect, half3 normal, half clipWidth, half dissDirect, half invert,
    half clipProgress, half2 dissClipRemap, half3 vertParams, half4 mapST, half4 dissSpeed)
{
    half clipDirectionN = 1 - step(dissDirect, 0.5);
    half progressMask = step(0.01, clipProgress);
    //DirClip
    half progressRemap = XYRemap(clipProgress, half2(0, 1), half2(0 + dissClipRemap.x, 1 + dissClipRemap.y));
    half gradient = dissDirect > 2? position.z : (dissDirect > 1? -position.y : position.x);
    gradient *= invert * -1 + (1 - invert);
    half gradientSub = (gradient - progressRemap) * clipWidth;
    //ClipTex
    half dissolveMask = SAMPLE_TEXTURE2D_LOD(_DissolveMask, sampler_DissolveMask, lerp(position, uv, uvSelect.x) + dissSpeed.zw * _Time.y, 0);
    half dissolveTex = SAMPLE_TEXTURE2D_LOD(_DissolveMapp, sampler_DissolveMapp, lerp(position, uv, uvSelect.y) * mapST.xy + mapST.zw + dissSpeed.xy * _Time.y, 0)
                * dissolveMask;
    
    gradientSub += dissolveTex * smoothstep(1, 0, gradientSub);
    //VertMask
    gradientSub = saturate(gradientSub);
    half vertMask = (1 - smoothstep(0, vertParams.x, gradientSub)) * progressMask;
    half3 vertDir = dissDirect > 2? Z_DISSOLVE : (dissDirect > 1? Y_DISSOLVE : X_DISSOLVE);
    half3 vertValue = (vertDir * vertParams.y * 0.1 + normal * vertParams.z * 0.1) * vertMask * clipDirectionN;
    positionOS += vertValue;
}

void ApplyDissolveFragOpt(inout half3 color, inout half bloom, half3 position, half2 uv, half2 uvSelect,
    half4 mapST, half4 dissSpeed, half clipProgress, half dissDirect, half invert, half4 clipParams,
    half3 dissColor, half dissColorWidth)
{

    half clipDirectionN = step(dissDirect, 0.5);
    half progressMask = step(0.01, clipProgress);
    //DirClip
    half progressRemap = XYRemap(clipProgress, half2(0, 1), half2(0 + clipParams.z, 1 + clipParams.w));
    half gradient = dissDirect > 2? position.z : (dissDirect > 1? -position.y : position.x);
    gradient *= invert * -1 + (1 - invert);
    half gradientSub = (gradient - progressRemap) * clipParams.x;
    //ClipTex
    half dissolveMask = SAMPLE_TEXTURE2D(_DissolveMask, sampler_DissolveMask, lerp(position, uv, uvSelect.x) + dissSpeed.zw * _Time.y);
    half dissolveTex = SAMPLE_TEXTURE2D(_DissolveMapp, sampler_DissolveMapp, lerp(position, uv, uvSelect.y) * mapST.xy + mapST.zw + dissSpeed.xy * _Time.y)
                * dissolveMask;
    gradientSub += dissolveTex * smoothstep(1, 0, gradientSub);
    
    half clipValue = (dissolveTex - progressRemap) * clipDirectionN + gradientSub * (1 - clipDirectionN);
    clip(clipValue - clipParams.y);
    
    //EdgeColor
    gradientSub = saturate(gradientSub);
    half colorMaskDir = (1 - smoothstep(0, dissColorWidth, gradientSub)) * progressMask;
    
    //deparate
    half step1 = step(0, dissolveTex - progressRemap);
    half step2 = step(dissColorWidth * 0.2, dissolveTex - progressRemap);
    half3 colorMaskNDir = lerp(color, dissColor, saturate(step1 - step2));
    half3 colorNDir = lerp(0, colorMaskNDir, step1);
    
    color = lerp(color + dissColor * colorMaskDir, colorNDir, clipDirectionN);
    bloom += BloomMaskRGB(dissColor, lerp(colorMaskDir, saturate(step1 - step2), clipDirectionN));
    
}
void ApplyDissolveShadowOpt(half3 position, half2 uv, half2 uvSelect, half4 mapST, half4 dissSpeed, half clipProgress, half dissDirect, half invert, half4 clipParams)
{

    half clipDirectionN = step(dissDirect, 0.5);
    //DirClip
    half progressRemap = XYRemap(clipProgress, half2(0, 1), half2(0 + clipParams.z, 1 + clipParams.w));
    half gradient = dissDirect > 2? position.z : (dissDirect > 1? -position.y : position.x);
    gradient *= invert * -1 + (1 - invert);
    half gradientSub = (gradient - progressRemap) * clipParams.x;
    //ClipTex
    half dissolveMask = SAMPLE_TEXTURE2D(_DissolveMask, sampler_DissolveMask, lerp(position, uv, uvSelect.x) + dissSpeed.zw * _Time.y);
    half dissolveTex = SAMPLE_TEXTURE2D(_DissolveMapp, sampler_DissolveMapp, lerp(position, uv, uvSelect.y)  * mapST.xy + mapST.zw + dissSpeed.xy * _Time.y)
                * dissolveMask;
    gradientSub += dissolveTex * smoothstep(1, 0, gradientSub);
    
    half clipValue = (dissolveTex - progressRemap) * clipDirectionN + gradientSub * (1 - clipDirectionN);
    clip(clipValue - clipParams.y);
    
}

// #if _DISSOLVEE && _DISSOLVE_BRANCH
// #define DISSOLVE_ON(dissolve)      half  dissolve
// #define DISSOLVE_START(dissolve) STATIC_BRANCH_START(dissolve)
// #define DISSOLVE_END(dissolve)   STATIC_BRANCH_END(dissolve) 
// #else
// #define DISSOLVE_ON(dissolve)
// #define DISSOLVE_START(dissolve)
// #define DISSOLVE_END(dissolve)
// #endif
#endif

#ifndef _SHADER_LIBRARY_DISSOLVE_INCLUDE
#define _SHADER_LIBRARY_DISSOLVE_INCLUDE

#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/Math.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/ProceduralNoiseHelper.hlsl"


// Dissove noise type 
// public enum NoiseType
// {
//     Texture, //0
//     Simple, //1
//     Gradient, //2
//     Voroni, /3
// }


real Dissolve_GetThreshold(real noiseType, TEXTURE2D_PARAM(dissTex, sampler_dissTex), real2 uv, real noiseScale, 
real angleOffset, real cellDensity, real4 textureST = real4(1, 1, 0, 0), real4 textureChannel = real4(1, 0, 0, 0))
{
    if (ProceduralNoiseHelper_IsProceduralNoise(noiseType))
        return ProceduralNoiseHelper_GenerateNoise(noiseType, uv, noiseScale, angleOffset, cellDensity);
    
    uv = uv * textureST.xy + textureST.zw;
    return dot(SAMPLE_TEXTURE2D(dissTex, sampler_dissTex, uv), textureChannel); 
}


// Hard Dissolve
// return Edge Mask
real Dissolve_HardClip(real dissAmout, real threshold, real2 thresholdOffset = real2(0, 0), real edgeWidth = 0)
{

    dissAmout = XYRemap(dissAmout, real2(0, 1), real2(0, 1) + thresholdOffset);
  
    clip(threshold - dissAmout);

    return step(threshold, dissAmout + edgeWidth);
}

// Dissolve Value 和 颜色的alpha 相乘
real GetSoftDissolveValue(float dissolveAlpha = 1, float edgeRange = 0, float edgeSmoothness = 0, float progress = 0)
{
    half dissolveTexR = 1 - dissolveAlpha;  //金富自创算法
    progress *= (1 + edgeRange);
    half hardnessFactor = 2.0 - (1 - edgeSmoothness);
    half dissolve02 = (progress - edgeRange) * hardnessFactor + dissolveTexR;
    dissolve02 = PercentInRange(2.0 - dissolve02, 1 - edgeSmoothness, 1.0);

    return dissolve02;
}


void Dissolve(float dissVal, float dissIntensity, float edgeWidth, float innerEdgegSoftness, float outterEdgeSoftness, out float edgeNask, out float alpha)
{
    dissIntensity = XYRemap(dissIntensity, 0, 1, dissIntensity-edgeWidth-innerEdgegSoftness-outterEdgeSoftness, dissIntensity+edgeWidth);
    // half edge = step(dissIntensity, dissVal);
    // half outterEdge = step(dissIntensity-edgeWidth, dissVal) - edge;
    // half innerEdge = 1 - smoothstep(dissIntensity+edgeWidth-innerEdgegSoftness, dissIntensity+edgeWidth, dissVal);
    // edgeNask = innerEdge + outterEdge;
    //
    // alpha = max(smoothstep(dissIntensity-edgeWidth, dissIntensity-edgeWidth+outterEdgeSoftness, dissVal), edge);
    alpha  = smoothstep(dissIntensity, dissIntensity + outterEdgeSoftness, dissVal);

    outterEdgeSoftness *= 0.5;
    
    dissIntensity += (edgeWidth + outterEdgeSoftness);
    
    float x = smoothstep(dissIntensity , dissIntensity + innerEdgegSoftness, dissVal);

    edgeNask =  saturate(step(0.f, alpha) - x);
}


#endif

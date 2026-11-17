#ifndef _SHADER_LIBRARY_UI_INCLUDED
#define _SHADER_LIBRARY_UI_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

float2 FlipBookUVAnimation(float2 uv, half2 xyTiling, half speed, half startFrame, float time)
{
    // uv offset per tile
    float2 uvPerFrame = 1.f / xyTiling;

    half totalFrames = xyTiling.x * xyTiling.y;

    half frameIndexLinear =  round(fmod( time * speed + startFrame , totalFrames));

    frameIndexLinear += frameIndexLinear < 0 ? totalFrames : 0;

    half xIndex = round(fmod(frameIndexLinear, xyTiling.x));

    half yIndex =  round(fmod((frameIndexLinear - xIndex) / xyTiling.x, xyTiling.y));

    // start form top
    yIndex = xyTiling.y - 1 - yIndex;
    
    return uv * uvPerFrame + half2(xIndex, yIndex) * uvPerFrame;  
}



float2 PolarUV(float2 uv, half2 center, half2 angleST, half2 lengthST, bool invertRadial = false, bool invertLen = false)
{
    uv -= center;
    
    float distance = length(uv) * 2;
    distance = lerp(distance, 1 - distance, invertLen ? 1 : 0);

    float angle = atan2(uv.x, uv.y) / 6.28;
    angle = lerp(angle, 1 - angle, invertRadial ? 1 : 0);

    distance = distance * lengthST.x + lengthST.y;
    angle = angle * angleST.x + angleST.y;

    return float2(distance, angle);
}




float2 RotateUV(float2 uv, half2 center = half2(0.5h, 0.5h), half angle = 0,  bool angleIsDegree = false)
{
    angle = angleIsDegree ? DegToRad(angle) : angle;
    
    float cosAngle = cos(angle);
    float sinAngle = sin(angle);
 
    float2 newUV = mul(uv - center, float2x2(cosAngle, -sinAngle, sinAngle, cosAngle));

    return newUV + center;
}


float2 FlowUV(float2 uv, half2 speed, float time)
{
    return uv + frac(speed * time);
}




#endif 
#ifndef _FX_DEBUG_INCLUDED
#define _FX_DEBUG_INCLUDED

#if DEBUG_DISPLAY

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceData.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Debug/Debugging3D.hlsl"

#endif


half4 OutputFXFinalColor(half4 color)
{
#if DEBUG_DISPLAY
    half alpha = color.a;
    // 不同的BlendMode 对饮的无效像素逻辑是是不同的
    // Additive    = 2
    if (_Blend  == 2) { alpha = (color.r + color.g + color.b) * color.a ;}
    
    half4 debugColor = half4(0, 0, 0, alpha);

    InputData inputData = (InputData)0;
    SurfaceData surfaceData = (SurfaceData)0;
    surfaceData.albedo = color.rgb;
    surfaceData.alpha = color.a;
    if (CanDebugOverrideOutputColor(inputData, surfaceData, debugColor))
    {
        return debugColor;
    }

    
#endif
    
    return color;

}



#endif
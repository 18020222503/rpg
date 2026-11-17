#ifndef _UV_HELPER_INCLUDE
#define _UV_HELPER_INCLUDE

#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/Util.hlsl"

/* C# definition

public enum UVMode
{
    UV1,
    UV2,
    ScreenPosition,
    ObjectPosition,
    WorldPosition,
}

public enum UVMoveMode
{
    Off,
    TexOffsetAnimated,
    CustomDataZW,
    Polar
}


public enum UVWrapMode
{
    Repeat,
    Clamp,
}
*/

SamplerState particle_linear_clamp_sampler;
SamplerState particle_linear_repeat_sampler;
SamplerState particle_point_repeat_sampler;
SamplerState particle_point_clamp_sampler;



half4 SAMPLE_TEXTURE2D_WARP(Texture2D tex ,half2 uv,int warpMode)
{
    UNITY_BRANCH
    if(warpMode == 0)
        return  SAMPLE_TEXTURE2D(tex,particle_linear_repeat_sampler,uv);
        else
        uv = min(1,max(uv,0));
        return  SAMPLE_TEXTURE2D(tex,particle_linear_repeat_sampler,uv);
}

half4 SAMPLE_TEXTURE2D_WARP_LOD(Texture2D tex ,half2 uv,int warpMode)
{
    UNITY_BRANCH
    if(warpMode == 0)
        return  SAMPLE_TEXTURE2D_LOD(tex,particle_linear_repeat_sampler,uv,0);
    else
        return  SAMPLE_TEXTURE2D_LOD(tex,particle_linear_clamp_sampler,uv,0);
}

half4 SAMPLE_TEXTURE2D_WARP_POINT_LOD(Texture2D tex ,half2 uv,int warpMode)
{
     UNITY_BRANCH
     if(warpMode == 0)
         return  SAMPLE_TEXTURE2D_LOD(tex,particle_point_repeat_sampler,uv,0);
     else
         return  SAMPLE_TEXTURE2D_LOD(tex,particle_point_clamp_sampler,uv,0);   
}


inline bool UVHelper_IsScreenUV(float uvMode)
{
    return (uint)uvMode == 2;
}

inline bool UVHelper_IsObjectPositionUV(float uvMode)
{
    return (uint)uvMode == 3;
}

inline bool UVHelper_IsWorldPositionUV(float uvMode)
{
    return (uint)uvMode == 4;
}

inline int UVHelper_IsUVMoveOn(float uvMoveMode)
{
    return uvMoveMode > 0 ? 1 : 0; 
}

inline int UVHelper_IsUVMoveByCustomData(float uvMoveMode)
{
    return (uint)uvMoveMode==2 ? 1 : 0;
}

inline int UVHelper_IsUVClamped(float uvWrapMode)
{
    return uvWrapMode > 0 ? 1 : 0;
}

inline int UVHelper_IsPolarUV(float uvMoveMode)
{
    return (uint)uvMoveMode == 3 ? 1 : 0;
}




float2 UVHelper_TransformUV_NotWarp(float2 uv, float4 tileOffset, float2 speed, float2 customDataZW, float rotAngle,float uvMoveMode, float2 rotCenter = float2(0, 0))
{
    uv = abs(rotAngle) > 0 ? rotateUV(uv, rotAngle, rotCenter) : uv;

    float2 offset = lerp(tileOffset.zw, lerp(tileOffset.zw + frac(speed * _Time.y), customDataZW, UVHelper_IsUVMoveByCustomData(uvMoveMode)), UVHelper_IsUVMoveOn(uvMoveMode));
    uv = uv * tileOffset.xy + offset;
    return uv;
}





float2 UVHelper_TransformUV(float2 uv, float4 tileOffset, float2 speed, float2 customDataZW, float rotAngle,float uvMoveMode, float uvWrapMode, float2 rotCenter = float2(0, 0))
{
    uv = abs(rotAngle) > 0 ? rotateUV(uv, rotAngle, rotCenter) : uv;

    float2 offset = lerp(tileOffset.zw, lerp(tileOffset.zw + frac(speed * _Time.y), customDataZW, UVHelper_IsUVMoveByCustomData(uvMoveMode)), UVHelper_IsUVMoveOn(uvMoveMode));
    uv = uv * tileOffset.xy + offset;
	
    uv = lerp(uv, saturate(uv), UVHelper_IsUVClamped(uvWrapMode));
	
    return uv;
}

float2 UVHelper_TransformUVPolar(float2 uv, float2 speed, float uvWrapMode, float radialScale = 1, float lengthScale = 1)
{
    float2 polarUV = PolarCoordinates(uv, half2(0.5, 0.5), radialScale, lengthScale) + frac(_Time.y * speed);
    return polarUV;
}


//
// flow mode : 0 - off ; 1 - normal; 2 - polar
// polar uv tranformation should use fragment uv

// uv transform flow: TexAdjust - UVFlow - ApplyWrap

float2 UVHelper_UVFlow(float2 uv, float flowMode, float2 speed, float radialScale = 1, float lengthScale = 1, half2 customdata = half2(0,0))
{
    float2 timeFlow = frac(speed * _Time.y) * UVHelper_IsUVMoveOn(flowMode);
    float2 normalUV = lerp(uv + timeFlow, uv + customdata, UVHelper_IsUVMoveByCustomData(flowMode));
    float2 polarUV = PolarCoordinates(uv, half2(0.5, 0.5), radialScale, lengthScale) + timeFlow;
    return lerp(normalUV, polarUV, UVHelper_IsPolarUV(flowMode));
}

float2 UVHelper_TexAdjust(float2 uv, float4 tileOffset, float rotAngle, float2 rotCenter = float2(0, 0))
{
    uv = abs(rotAngle) > 0 ? rotateUV(uv, rotAngle, rotCenter) : uv;
    uv = uv * tileOffset.xy + tileOffset.zw;
    return uv;
}

float2 UVHelper_ApplyWrap(float2 uv, float uvWrapMode)
{
    return lerp(uv, saturate(uv), step(0.5, uvWrapMode));
}

#endif

#ifndef _SHADER_LIBRARY_UTILITIES_MATH_INCLUDE
#define _SHADER_LIBRARY_UTILITIES_MATH_INCLUDE

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

inline real SafePow(real base, real power)
{
    return pow(max(abs(base), real(HALF_EPS)), power);
}


inline real2 SafePow(real2 base, real2 power)
{
    return pow(max(abs(base), real2(HALF_EPS, HALF_EPS)), power);
}

real3 SafePow(real3 base, real3 power)
{
    return pow(max(abs(base), real3(HALF_EPS, HALF_EPS, HALF_EPS)), power);
}

real4 SafePow(real4 base, real4 power)
{
    return pow(max(abs(base), real4(HALF_EPS, HALF_EPS, HALF_EPS, HALF_EPS)), power);
}


real XYRemap(float In, real2 InMinMax, real2 OutMinMax)
{
    return OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
}

real2 rotateUV(real2 uv, real rotation)
{
    real cosAngle = cos(rotation);
    real sinAngle = sin(rotation);
    return real2(
        cosAngle * uv.x + sinAngle * uv.y,
        cosAngle * uv.y - sinAngle * uv.x
    );
}

real XYRemap(real x, real in_min, real in_max, real out_min, real out_max)
{
    real t = (x - in_min) / (in_max - in_min);
    return lerp(out_min, out_max, t);
}

real PercentInRange(real c, real minValue, real maxValue)
{
    c = (c - minValue)/(maxValue - minValue);
    c = saturate(c);
    return c;
}

real2 Rotator(real2 uv, real2 center = real2(0.5, 0.5), real angle = 0)
{
    real cosAngle = cos(angle);
    real sinAngle = sin(angle);

    real2 newUV = mul(uv - center, real2x2(cosAngle, -sinAngle, sinAngle, cosAngle));
    return newUV + center;
}


float rand(float2 co)
{
    return frac(sin(dot(co.xy ,float2(12.9898,78.233))) * 43758.5453);
}

float rand(float c)
{
    return rand(float2(c,1.0));
}


#endif
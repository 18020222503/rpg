#ifndef _SHADER_LIBRARY_UTILITIES_COLOR_ADJUSTMENT_INCLUDE
#define _SHADER_LIBRARY_UTILITIES_COLOR_ADJUSTMENT_INCLUDE

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

//
// Space Conversion
//
// half3 RGBToHSV(half3 rgb)
// {
//     // RGB to HSV
//     half4 K = half4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
//     float4 P = lerp(half4(rgb.bg, K.wz), half4(rgb.gb, K.xy), step(rgb.b, rgb.g));
//     float4 Q = lerp(half4(P.xyw, rgb.r), half4(rgb.r, P.yzx), step(P.x, rgb.r));
//     half D = Q.x - min(Q.w, Q.y);
//     half E = 1e-4;
//     half3 hsv = half3(abs(Q.z + (Q.w - Q.y)/(6.0 * D + E)), D / (Q.x + E), Q.x);
//
//     return hsv;
// }
//
//
// half3 HSVToRGB(half3 hsv)
// {
//     // HSV to RGB
//     half4 K = half4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
//     half3 P = abs(frac(hsv.xxx + K.xyz) * 6.0 - K.www);
//     half3 rgb = hsv.z * lerp(K.xxx, saturate(P - K.xxx), hsv.y);
//
//     return rgb;
// }


//
// Hue Saturation Contrast WhiteBlance
//

half3 HueDegrees(half3 In, half Offset)
{
    // RGB to HSV
    // half3 hsv = RGBToHSV(In);
    half3 hsv = RgbToHsv(In);

    float hue = hsv.x + Offset / 360;
    hsv.x = (hue < 0)
            ? hue + 1
            : (hue > 1)
                ? hue - 1
                : hue;

    // HSV to RGB
    half3 Out = HsvToRgb(hsv);

    return Out;
}


half3 HueNormalized(float3 In, float Offset)
{
    // RGB to HSV
    float3 hsv = RgbToHsv(In);

    float hue = hsv.x + Offset;
    hsv.x = (hue < 0)
            ? hue + 1
            : (hue > 1)
                ? hue - 1
                : hue;

    // HSV to RGB
    half3 Out = HsvToRgb(hsv);

    return Out;
}


half3 Saturation(half3 In, half Saturation)
{
    half luma = dot(In, half3(0.2126729, 0.7151522, 0.0721750));
    half3 saturated =  luma.xxx + Saturation.xxx * (In - luma.xxx);
    
    return saturated;
}


half3 Contrast(half3 In, half Contrast)
{
    half midpoint = pow(0.5, 2.2);
    half3 Out =  (In - midpoint) * Contrast + midpoint;

    return Out;
}



half3 WhiteBalance(half3 In, half Temperature, half Tint)
{
    // Range ~[-1.67;1.67] works best
    half t1 = Temperature * 10 / 6;
    half t2 = Tint * 10 / 6;

    // Get the CIE xy chromaticity of the reference white point.
    // Note: 0.31271 = x value on the D65 white point
    half x = 0.31271 - t1 * (t1 < 0 ? 0.1 : 0.05);
    half standardIlluminantY = 2.87 * x - 3 * x * x - 0.27509507;
    half y = standardIlluminantY + t2 * 0.05;

    // Calculate the coefficients in the LMS space.
    half3 w1 = half3(0.949237, 1.03542, 1.08728); // D65 white point

    // CIExyToLMS
    half Y = 1;
    half X = Y * x / y;
    half Z = Y * (1 - x - y) / y;
    half L = 0.7328 * X + 0.4296 * Y - 0.1624 * Z;
    half M = -0.7036 * X + 1.6975 * Y + 0.0061 * Z;
    half S = 0.0030 * X + 0.0136 * Y + 0.9834 * Z;
    half3 w2 = half3(L, M, S);

    half3 balance = half3(w1.x / w2.x, w1.y / w2.y, w1.z / w2.z);

    half3x3 LIN_2_LMS_MAT = {
        3.90405e-1, 5.49941e-1, 8.92632e-3,
        7.08416e-2, 9.63172e-1, 1.35775e-3,
        2.31082e-2, 1.28021e-1, 9.36245e-1
    };

    half3x3 LMS_2_LIN_MAT = {
        2.85847e+0, -1.62879e+0, -2.48910e-2,
        -2.10182e-1,  1.15820e+0,  3.24281e-4,
        -4.18120e-2, -1.18169e-1,  1.06867e+0
    };

    half3 lms = mul(LIN_2_LMS_MAT, In);
    lms *= balance;
    half3 Out = mul(LMS_2_LIN_MAT, lms);

    return Out;
}


//
// Invert Color
//
inline half3 InvertColor(half3 In, half3 InvertColors) // InvertColors: invert R/G/B channels
{
    return abs(InvertColors - In);
}


//
// Replace Color
//
void ReplaceColor(half3 In, half3 From, half3 To, half Range, half Fuzziness)
{
    half Distance = distance(From, In);
    half3 Out = lerp(To, In, saturate((Distance - Range) / max(Fuzziness, 1e-5f)));

}

// Apply Color Grading
half3 DoHSV(half3 rgb, half3 hsv)
{
    half3 col = RgbToHsv(rgb);
    col.x = RotateHue(col.x + hsv.x * 0.1, 0, 1);
    col = HsvToRgb(col);

    // Unity 自带的降饱和度函数，在颜色值特别低的时候，有可能算出负数的颜色值
    // 需要将最小值限制在0
    col = max(Desaturate(col, clamp(hsv.y, 0, 10)), (0).xxx) ;
    col *= clamp(hsv.z, 0, 10);
    return col;
}

// void GreyNegative(real negativeBright, real negativeStren, inout real4 orignalColor, real lumThreshold = 0)
// {
//     real grey = negativeBright * smoothstep(lumThreshold,1-lumThreshold,FastSRGBToLinear(1 - FastLinearToSRGB(Luminance(orignalColor.rgb))));
//     real3 Negative = real3(grey,grey,grey);
//     orignalColor.rgb = lerp(orignalColor.rgb, Negative, negativeStren);
// }

void GreyNegativeWithTint(real negativeBright, real negativeStren, inout real4 orignalColor, real3 tint = real3(1,1,1), real lumThreshold = 0)
{
    real grey = negativeBright * smoothstep(lumThreshold,1-lumThreshold,FastSRGBToLinear(1 - FastLinearToSRGB(Luminance(orignalColor.rgb))));
    real3 Negative = real3(grey,grey,grey);
    orignalColor.rgb = lerp(orignalColor.rgb, Negative * tint, negativeStren);
}

void GreyNegativeWithTint(real negativeBright, real negativeStren, inout real3 orignalColor, real3 tint = real3(1,1,1), real lumThreshold = 0)
{
    real grey = negativeBright * smoothstep(lumThreshold,1-lumThreshold,FastSRGBToLinear(1 - FastLinearToSRGB(Luminance(orignalColor.rgb))));
    real3 Negative = real3(grey,grey,grey);
    orignalColor.rgb = lerp(orignalColor.rgb, Negative * tint, negativeStren);
}

// void GreyNegativeByAlpha(real negativeBright, real negativeStren, inout real4 orignalColor)
// {
//     real grey = lerp(1, 0, orignalColor.a);
//     real negative = real3(grey, grey, grey);
//     orignalColor.rgb = lerp(orignalColor.rgb, negative, negativeStren);
// }
//
// void GreyNegative(real negativeBright, real negativeStren, inout real3 orignalColor, real lumThreshold = 0)
// {
//     real grey = negativeBright * smoothstep(lumThreshold,1-lumThreshold,FastSRGBToLinear(1 - FastLinearToSRGB(Luminance(orignalColor.rgb))));
//     real3 Negative = real3(grey,grey,grey);
//     orignalColor.rgb = lerp(orignalColor.rgb, Negative, negativeStren);
// }

#endif
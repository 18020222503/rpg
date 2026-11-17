#ifndef XINYUAN_FOGLIB_INCLUDED
#define XINYUAN_FOGLIB_INCLUDED
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderVariablesFunctions.hlsl"

// Warning : include的shader 必须声明高度雾相关变量！
// Fog
half4 _FogParams1;
half4 _FogParams2;

#define _FogDensity _FogParams1.x
#define _FogWidthRcp1 _FogParams1.y
#define _FogWidthRcp2 _FogParams1.z
#define _FogPosition _FogParams1.w

#define _FogColorBlur _FogParams2.x
#define _EnableRevertFogMask _FogParams2.y
#define _Fog1ExpEdge _FogParams2.z
#define _Fog2ExpEdge _FogParams2.w

half4 _FogColor1;
half4 _FogColor2;
half4 _FogDepthColor;

half3 FogColor(float center)
{
    half blur = _FogColorBlur * 200.0h;
    half heightFactor = lerp(0.0h ,1.0h,smoothstep(-blur,blur,center));
    half3 fogColor;
    fogColor = lerp(_FogColor1.rgb,_FogColor2.rgb,heightFactor);
    return fogColor;
}

half3 FogColor(float center, half fogColorBlur, half3 fogColor1, half3 fogColor2)
{
    half blur = fogColorBlur * 200;
    float heightFactor = lerp(0,1,smoothstep(-blur,blur,center));
    half3 fogColor;
    fogColor = lerp(fogColor1.rgb,fogColor2.rgb,heightFactor);
    return fogColor;
}

half3 MixHeightFog(half3 outcolor,half center)
{
    //float mask = FogMask(center);
    half FogDensity1 = 1.0h - smoothstep(0.0, _Fog1ExpEdge, exp(_FogWidthRcp1 * - center));
    half FogDensity2 = 1.0h - smoothstep(0.0, _Fog2ExpEdge, exp(-_FogWidthRcp2 * - center));
    half fogFac = 1.0h - saturate(FogDensity1 + FogDensity2);
    fogFac = lerp(fogFac, 1.0h - fogFac, _EnableRevertFogMask) * _FogDensity;
    half3 fogColor = FogColor(center);
    outcolor = lerp(outcolor,fogColor,fogFac);
    return outcolor;

}

half3 MixHeightFogExp(half3 outcolor,float center, half falloff, half fogWidth1, half fogWidth2, half fogDensity, half fogColorBlur, half3 fogColor1, half3 fogColor2, bool enableRevert = false)
{
    //float mask = FogMask(center);
    float FogDensity1 = 1-saturate(exp(-center * falloff * rcp(fogWidth1)));
    float FogDensity2 = 1-saturate(exp(center * falloff * rcp(fogWidth2)));
    float fogFac = fogDensity *(1-saturate(FogDensity1 + FogDensity2));
        
    fogFac = lerp(fogFac, 1- fogFac, enableRevert);
    half3 fogColor = FogColor(center, fogColorBlur, fogColor2, fogColor1);
    outcolor = lerp(outcolor,fogColor,saturate(fogFac));
    return outcolor;
}

half3 MixHeightFogExp2(half3 outcolor,float center, half falloff, half fogWidth1, half fogWidth2, half fogDensity, half fogColorBlur, half3 fogColor1, half3 fogColor2, bool enableRevert = false)
{
    float rcpWidth1 = rcp(fogWidth1);
    float rcpWidth2 = rcp(fogWidth2);
    half isNagetive = center <= 0 ? -1 : 1;
    float centerSqr = center * center * isNagetive;
    float expVal1 = centerSqr * rcpWidth1 * rcpWidth1;
    float expVal2 = centerSqr * rcpWidth2 * rcpWidth2;
    float FogDensity1 = 1-saturate(exp(-expVal1 * falloff));
    float FogDensity2 = 1-saturate(exp(expVal2 * falloff));
    float fogFac = fogDensity *(1-saturate(FogDensity1 + FogDensity2));
        
    fogFac = lerp(fogFac, 1- fogFac, enableRevert);
    half3 fogColor = FogColor(center, fogColorBlur, fogColor2, fogColor1);
    outcolor = lerp(outcolor,fogColor,saturate(fogFac));
    return outcolor;
}

half3 MixHeightFog(half3 outcolor,float center, half fogWidth1, half fogWidth2, half fogDensity, half fogColorBlur, half3 fogColor1, half3 fogColor2, bool enableRevert = false)
{
    //float mask = FogMask(center);
    float FogDensity1 = 1- saturate(smoothstep(0, _Fog1ExpEdge, exp(_FogWidthRcp1 * - center)));
    float FogDensity2 = 1- saturate(smoothstep(0, _Fog2ExpEdge, exp(-_FogWidthRcp2 * - center)));;
    float fogFac = fogDensity *(1-saturate(FogDensity1 + FogDensity2));
        
    fogFac = lerp(fogFac, 1- fogFac, enableRevert);
    half3 fogColor = FogColor(center, fogColorBlur, fogColor2, fogColor1);
    outcolor = lerp(outcolor,fogColor,saturate(fogFac));
    return outcolor;
}

half ComputeHeightFogFac(half baseHeight)
{
    half FogDensity1 = 1.0h - smoothstep(0.0h, _Fog1ExpEdge, exp(_FogWidthRcp1 * - baseHeight));
    half FogDensity2 = 1.0h - smoothstep(0.0h, _Fog2ExpEdge, exp(-_FogWidthRcp2 * - baseHeight));
    half fogFac = (1.0h - saturate(FogDensity1 + FogDensity2));
    fogFac = lerp(fogFac, 1.0h - fogFac, _EnableRevertFogMask) * _FogDensity;
    return fogFac;
}

half ComputeMixFogIntensity(half distanceFogFac, half baseHeight)
{
    half distanceFogIntensity = ComputeFogIntensity(distanceFogFac); // unity内置雾效哎，0是雾最浓，1是无雾
    half heightFogIntensity = ComputeHeightFogFac(baseHeight); 
    return lerp(heightFogIntensity, 0, distanceFogIntensity);
}

void MixFogWithHeightAndDistance(inout half3 fragColor, half height, half fogCoord)
{
    #if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2) || defined(FOG_HEIGHT_PASS_APPLY)
    #if (defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)) && defined(FOG_HEIGHT_PASS_APPLY) // 高度和距离同时生效
    half3 heightFogColor = FogColor(height);
    fragColor.rgb = lerp(fragColor.rgb, heightFogColor, ComputeMixFogIntensity(fogCoord, height));
    #elif defined(FOG_HEIGHT_PASS_APPLY)                                                                 // 仅高度雾
    fragColor.rgb = MixHeightFog(fragColor.rgb, height);     
    #else                                                                                                // 仅距离雾
    fragColor.rgb = MixFog(fragColor.rgb, fogCoord);
    #endif
    #else
    #endif
}
#endif
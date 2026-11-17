// SPDX-License-Identifier: (Not available for this version, you are only allowed to use this software if you have express permission from the copyright holder and agreed to the latest NiloToonURP EULA)
// Copyright (c) 2020 Kuroneko ShaderLab

// For more information, visit -> https://github.com/ColinLeung-NiloCat/UnityURPToonLitShaderExample

// #pragma once is a safeguard best practice in almost every .hlsl, 
// doing this can make sure your .hlsl's user can include this .hlsl anywhere anytime without producing any multi include conflict
#ifndef __ToonCharacter_Shared_FragmentSharedFuntions__
#define __ToonCharacter_Shared_FragmentSharedFuntions__

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// fragment shared functions (Step2: prepare data structs for lighting calculation)
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
half4 GetFinalBaseColor(Varyings input)
{
    half2 uv = input.uv.xy;
    half4 color = 0;
    #if defined(_FLOWMAP_ON)
        half2 flowStrength = (-_ColorFlowOffsetSpeed.xy * 0.1);
        half3 flowMapx = SAMPLE_TEXTURE2D(_FlowMap,sampler_FlowMap,uv);
        half2 flowMap= flowMapx.rg-half2(0.5,0)+0.5;
        float speed = _Time.y *  _ColorFlowOffsetSpeed.z;
        float fracSpeed = frac(speed);
        float2 flow0 = uv - (flowMap*flowStrength*fracSpeed * _applyColorFlow);
        float2 flow1 = uv - (flowMap*flowStrength*frac(speed+0.5) * _applyColorFlow);	
        color = lerp(SAMPLE_TEXTURE2D(_MainTex, sampler_LinearRepeat, flow0), SAMPLE_TEXTURE2D(_MainTex, sampler_LinearRepeat, flow1), (abs(fracSpeed-0.5))/0.5);
    #else
        color = SAMPLE_TEXTURE2D(_MainTex, sampler_LinearRepeat, uv);;
    #endif
    
    color = FastSRGBToLinear(color);

    half4 detailTex = FastSRGBToLinear(SAMPLE_TEXTURE2D(_DecalTex, sampler_LinearRepeat, lerp(input.uv.xy, input.uv.zw, _DetailMapUV)));
    //detailTex.rgb *= detailTex.a * _DecalTexAlpha;
    color.rgb = lerp(color.rgb, detailTex.rgb, detailTex.a * _DecalTexAlpha);
    
    color *= _MainColor;
    color.rgb *= _GlobalCharacterBaseColorTint;
    
    return color;
}


half3 GetFinalEmissionColor(Varyings input, half3 albedo, half4 multiChannelTex)
{
    half3 result = multiChannelTex.b * _EmissionColor * _UseEmission;
    return result;
}

half GetFinalOcculsion(Varyings input, half4 multiChannelTex)
{
   half result = 1;
    half occlusionValue = multiChannelTex.g;
    occlusionValue = lerp(1, occlusionValue, _OcclusionStrength);
    result = occlusionValue;

  /*
#if defined(_ISFACE)
    float3 lightDirection = _MainLightPosition.xyz; //GetMainLight().direction;
    float4 objPos = mul ( unity_ObjectToWorld, float4(0,0,0,1) );
    //half3 lookDir = normalize(GetCameraPositionWS() - objPos.xyz); lookDir.y = 0; lookDir = normalize(lookDir);
    half3 lookDir = normalize(half3(lightDirection.x, 0, lightDirection.z));
    half3 faceDir = _FaceForwardDirection; faceDir.y = 0; faceDir = normalize(faceDir);
    half fDotV = clamp(dot(faceDir, lookDir) - _FaceAoOffset + 0.5 , -1, 1);
    half fCrossV = step(cross(faceDir, lookDir).y, 0) * 2 - 1;
    half4 faceAoColor = tex2D(_FaceAoMap, half2(input.uv.x * fCrossV, input.uv.y));
    half mask = 1 - dot(faceAoColor, _FaceAoMapChannelMask);
    mask = step(mask, fDotV);
    //mask = clamp((fDotV - mask) / 0.02, 0.0, 1.0);
    result = min(result, mask);
#endif
*/
    return result;
}
half3 GetFinalSpecular(Varyings input, half3 baseColor, half4 multiChannelTex)
{
    half3 specularResult = 0;
#if _SPECULARHIGHLIGHTS

    half specularValue = multiChannelTex.r;
    specularResult = _SpecularColor * (specularValue * _SpecularIntensity);
    specularResult *= lerp(1,baseColor,_MultiplyBaseColorToSpecularColor);
#endif
    return specularResult;
}
half3 GetFinalNormalTS(Varyings input)
{
    half3 result = half3(0,0,1); //default pointing out, same as vertex normal

    // Not using UnpackNormal(...) for mobile & switch now
    // because we want to unify mobile and non mobile detail normalmap rendering, since performance differernce is small
    // honestly no one will care 1 more MUL in 2021, even for mobile
#if defined(_FLOWMAP_ON)
        ///	FlowMap
        half2 uv = input.uv;
        half2 flowStrength = (-_FlowOffsetSpeed.xy * 0.1);
        half3 flowMapx = SAMPLE_TEXTURE2D(_FlowMap,sampler_FlowMap,uv);
        /*#ifdef UNITY_COLORSPACE_GAMMA
            flowMapx = FastSRGBToLinear(flowMapx);
        #endif*/
        half2 flowMap= flowMapx.rg-half2(0.5,0)+0.5;
        float speed = _Time.y *  _FlowOffsetSpeed.z;
        float fracSpeed = frac(speed);
        half2 normalUV = uv; 
        float2 flow0 = normalUV - (flowMap*flowStrength*fracSpeed);
        float2 flow1 = normalUV - (flowMap*flowStrength*frac(speed+0.5));	
        half4 normalMap = lerp(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, flow0),SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, flow1),(abs(fracSpeed-0.5))/0.5);
        result = UnpackNormalScale(normalMap, _BumpScale);
#endif
#if _NORMALMAP
    
#endif
    return  result;
}
void DoClipTestToTargetAlphaValue(half alpha) 
{
#if _ALPHATEST_ON
    clip(alpha - _Cutoff);
#endif
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// fragment shared functions (Step3: calculate lighting & final color)
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// [Second Pass Extrude Cull front Outline]
// void ApplySurfaceToOutlineColorEditIfOutlinePass(inout half3 originalSurfaceColor, ToonSurfaceData surfaceData,ToonLightingData lightingData)
// {
//    
// #if ToonIsOutlinePass
//     
//     originalSurfaceColor *= _OutlineTintColor;
//     originalSurfaceColor = lerp(originalSurfaceColor, _OutlineReplaceColor, _PerCharUseEffectAddColor);
// #endif
// }
// void ApplySurfaceToOutlineColorEditIfOutlinePass(inout half3 originalSurfaceColor)
// {
//     ToonSurfaceData surfaceData = (ToonSurfaceData)0;
//     ToonLightingData lightingData = (ToonLightingData)0;
//     
//     ApplySurfaceToOutlineColorEditIfOutlinePass(originalSurfaceColor, surfaceData,lightingData);
// }

// [Screen Space Outline]
// very similar to depth texture rim light & shadow's logic, 
// see "_CameraDepthTexture depth" vs "self depth" difference 2D rim light and 2D shadow in ToonCharacter_LightingEquation.hlsl
// but ignore light direction, used for outline (brute force 4 directional sample)
// TODO: extract this function to a reusable .hlsl, since we don't have user uniform in this function
// TODO: result is not consistance when screen resolution / renderscale is changing
// float IsScreenSpaceOutline(float2 SV_POSITIONxy, float outlineWidth, float depthThreshold, float selfLinearEyeDepth)
// {
//     float halfScaleFloor = /*floor*/(outlineWidth * 0.3);
//     float halfScaleCeil = /*ceil*/(outlineWidth * 0.3);
//
//     // for perspective camera, reduce width when camera move away, but clamp at max = 1 using 1/(1+x) if camera is very close to vertex
//     // for orthographic camera, disable camera distance fix(only return a constant 0.7 to match perspective's result) since distance/depth will not affect polygon NDC xy position on screen
//     float cameraDistanceFix = unity_OrthoParams.w ? 0.7 : rcp(selfLinearEyeDepth+1); // no need to care orthographicCameraAmount, this line is already correct
//     // allow width per material and global edit
//     // group all float1 to calculate first for better performance
//     float2 UvOffsetMultiplier = _GlobalAspectFix * _GlobalFOVorOrthoSizeFix * cameraDistanceFix; // TODO: volume global outline width control multiply
//
//     // _Texture_TexelSize.xyzw is {1/width,1/height,width,height}
//     // https://forum.unity.com/threads/_maintex_texelsize-whats-the-meaning.110278/#post-1579985
//     float2 loadPosOffsetMultiplier = UvOffsetMultiplier * _CameraDepthTexture_TexelSize.zw;
//     int2 bottomLeftLoadPos   = SV_POSITIONxy + float2(+halfScaleFloor, +halfScaleFloor) * loadPosOffsetMultiplier; 
//     int2 topRightLoadPos     = SV_POSITIONxy + float2(+halfScaleCeil , +halfScaleCeil ) * loadPosOffsetMultiplier;
//     int2 bottomRightLoadPos  = SV_POSITIONxy + float2(+halfScaleCeil , -halfScaleFloor) * loadPosOffsetMultiplier;
//     int2 topLeftLoadPos      = SV_POSITIONxy + float2(-halfScaleFloor, +halfScaleCeil ) * loadPosOffsetMultiplier;
//
//     // clamp loadTexPos to prevent loading outside of _CameraDepthTexture's valid area
//     int2 maxAllowedIndex = _CameraDepthTexture_TexelSize.zw-1;
//     bottomLeftLoadPos = min(bottomLeftLoadPos,maxAllowedIndex);
//     topRightLoadPos = min(topRightLoadPos,maxAllowedIndex);
//     bottomRightLoadPos = min(bottomRightLoadPos,maxAllowedIndex);
//     topLeftLoadPos = min(topLeftLoadPos,maxAllowedIndex);
//
//     float depth0 = LOAD_TEXTURE2D(_CameraDepthTexture, bottomLeftLoadPos).r;
//     float depth1 = LOAD_TEXTURE2D(_CameraDepthTexture, topRightLoadPos).r;
//     float depth2 = LOAD_TEXTURE2D(_CameraDepthTexture, bottomRightLoadPos).r;
//     float depth3 = LOAD_TEXTURE2D(_CameraDepthTexture, topLeftLoadPos).r;
//
//     depth0 = Convert_SV_PositionZ_ToLinearViewSpaceDepth(depth0);
//     depth1 = Convert_SV_PositionZ_ToLinearViewSpaceDepth(depth1);
//     depth2 = Convert_SV_PositionZ_ToLinearViewSpaceDepth(depth2);
//     depth3 = Convert_SV_PositionZ_ToLinearViewSpaceDepth(depth3);
//
//     float depthDerivative0 = depth1 - depth0;
//     float depthDerivative1 = depth3 - depth2;
//
//     float edgeDepth = sqrt(depthDerivative0*depthDerivative0 + depthDerivative1*depthDerivative1) * 10;
//     edgeDepth = edgeDepth > (selfLinearEyeDepth * depthThreshold) ? 1 : 0; // TODO: convert to smooth fade out?
//
//     return edgeDepth;
// }
/*
void ApplySurfaceToScreenSpaceOutlineColorEditIfSurfacePass(inout half3 originalSurfaceColor, ToonSurfaceData surfaceData, ToonLightingData lightingData)
{
    // this function will only affect ForwardLit pass's surface pixels!
    // while outline pass will only use ApplySurfaceToOutlineColorEditIfOutlinePass(...), not this function
#if ToonForwardLitPass && _SCREENSPACE_OUTLINE
    float isScreenSpaceOutlineArea = IsScreenSpaceOutline(lightingData.SV_POSITIONxy,_ScreenSpaceOutlineWidth,_ScreenSpaceOutlineDepthThreshold,lightingData.selfLinearEyeDepth);
    originalSurfaceColor *= lerp(1,_ScreenSpaceOutlineTintColor,isScreenSpaceOutlineArea); // TODO: * _GlobalScreenSpaceOutlineTintColor by volume
    originalSurfaceColor *= lerp(_ScreenSpaceOutlineOcclusionAreaTintColor, 1, surfaceData.occlusion);

    originalSurfaceColor = lerp(originalSurfaceColor, _ScreenSpaceOutlineReplaceColor, _ScreenSpaceOutlineUseReplaceColor * isScreenSpaceOutlineArea);
#endif
}
*/
// [Volume]
// void ApplyVolumeEffectColorEdit(inout half3 color)
// {
//     //////////////////////////////////////////////////////////////////////////////////
//     // (not lighting, usually for cinematic needs like cut scene)
//     //////////////////////////////////////////////////////////////////////////////////
//     color *= _GlobalVolumeMulColor;
//     color = lerp(color,_GlobalVolumeLerpColor.rgb,_GlobalVolumeLerpColor.a);
// }
// [Per Character script]
// void ApplyPerCharacterEffectColorEdit(inout half3 color, ToonLightingData lightingData)
// {
//     //////////////////////////////////////////////////////////////////////////////////
//     // (not lighting, usually for gameplay needs like charcater selection)
//     //////////////////////////////////////////////////////////////////////////////////
//     // mul add
//     color.rgb = color.rgb * _PerCharEffectTintColor;// + _PerCharEffectAddColor;
//
//     // desaturate
//     color = lerp(color,Luminance(color), _PerCharEffectDesaturatePercentage);
//
//     // lerp
//     color.rgb = lerp(color.rgb,_PerCharEffectLerpColor.rgb,_PerCharEffectLerpColor.a);
//
//     // rim light (outline pass don't need this)
// #if ToonForwardLitPass
//     // Use normalWS from ToonLightingData, not Varying input, 
//     // because ToonLightingData's normalWS is normalmap applied & normalized.
//     // But using normalWS from Varying is ok also, it is just shader design choice
//     half NdotV = saturate(dot(lightingData.normalWS,lightingData.viewDirectionWS));
//     half rim = 1-NdotV;
//     // pow(x,4)
//     rim*=rim;
//     rim*=rim;
//
//     // apply(additive)
//     color.rgb += rim * _PerCharEffectRimColor * (1-lightingData.isFaceArea); // rim light not show on face because it looks ugly
// #endif
//
// }
// [Fog]
// void ApplyFog(inout half3 color, Varyings input)
// {
//     // Mix the pixel color with fog color. 
//     // You can optionally use MixFogColor to override the fog color with a custom one.
//     color = MixFog(color, input.SH_fogFactor.w);
// }
// // [Edit Alpha]
// void ApplyOverrideOutputAlpha(inout half outputAlpha)
// {
//     outputAlpha = _ForceFinalOutputAlphaEqualsOne ? 1.0 : outputAlpha;
// }

// void ApplyShowVertexColor(inout half3 color, ToonLightingData lightingData)
// {
//     half vertColorR = step(_showVertColorChannel,0);
//     half vertColorG = step(_showVertColorChannel,1);
//     half vertColorB = step(_showVertColorChannel,2);
//
//     half3 vertR = lerp(lightingData.vertcolor.r, color, vertColorR);
//     half3 vertG = lerp(lightingData.vertcolor.g, vertR, vertColorG);
//     color = lerp(lightingData.vertcolor.b,vertG,vertColorB);
//     
// }
///////////////////////////////////////////////////////////////////////////////////////
// fragment shared DEBUG functions (Step1: calculate lighting & final color)
///////////////////////////////////////////////////////////////////////////////////////
// half4 Get_TOON_FORCE_MINIMUM_FRAGMENT_SHADER_result(Varyings input)
// {
//     half3 debugColor = tex2D(_MainTex, input.uv.xy).rgb;
//     ApplySurfaceToOutlineColorEditIfOutlinePass(debugColor);
//     return half4(debugColor,1);   
// }
// half4 Get_TOON_DEBUG_SHADING_result(Varyings input, ToonSurfaceData surfaceData, ToonLightingData lightingData)
// {
// #if _TOON_DEBUG_SHADING
//     // example of switch case in hlsl:
//     // https://github.com/SickheadGames/HL2GLSL/blob/master/tests/HL2GLSL/FlowControl.hlsl
//     switch(_GlobalToonShadeDebugCase)
//     {
//         case 0:     return half4(surfaceData.albedo, surfaceData.alpha);
//         case 1:     return 1;
//         case 2:     return surfaceData.occlusion;
//         case 3:     return half4(surfaceData.emission,1);
//         case 4:     return half4(lightingData.normalWS * 0.5 + 0.5,1);
//         case 5:     return half4(input.uv.xy,0,1);
//         case 6:     return input.color.r;
//         case 7:     return input.color.g;
//         case 8:     return input.color.b;
//         case 9:     return input.color.a;
//         case 10:    return half4(input.color.rgb,1);
//         case 11:    return half4(surfaceData.specular.rgb,1);
//         case 12:    return half4(input.smoothNormal,1);
//     }
// #endif
//
//     return 1;    
// }
half GetBloomPrefilter(half3 color, half Threshold)
{
    // Unity 内置的亮度算法是取颜色的最大分量...
    // half brightness = Max3(color.r, color.g, color.b);
    half brightness = dot(color, half3(0.2126729, 0.7151522, 0.0721750));
    half ThresholdKnee = Threshold * 0.5;// unity内置的软阈值写死为阈值的一半
    half softness = clamp(brightness - Threshold + ThresholdKnee, 0.0, 2.0 * ThresholdKnee);
    softness = (softness * softness) / (4.0 * ThresholdKnee + 1e-4);
    half multiplier = max(brightness - Threshold, softness) / max(brightness, 1e-4);
    return multiplier;
}

#endif
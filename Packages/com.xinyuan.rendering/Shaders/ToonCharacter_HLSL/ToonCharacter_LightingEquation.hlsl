// SPDX-License-Identifier: (Not available for this version, you are only allowed to use this software if you have express permission from the copyright holder and agreed to the latest NiloToonURP EULA)
// Copyright (c) 2020 Kuroneko ShaderLab

// For more information, visit -> https://github.com/ColinLeung-NiloCat/UnityURPToonLitShaderExample

// #pragma once is a safeguard best practice in almost every .hlsl, 
// doing this can make sure your .hlsl's user can include this .hlsl anywhere anytime without producing any multi include conflict
#ifndef __ToonCharacter_LightingEquation__
#define __ToonCharacter_LightingEquation__

//宏控制转为变量控制，减少变体数
#if _TOON_ENABLE_DEPTH_TEXTURE_RIMLIGHT_AND_SHADOW && _TOON_ENABLE_DEPTH_TEXTURE_RIMLIGHT_AND_SHADOW_BRANCH
   #define LOADING_DEPTH_TEXTURE_ON(loadingDepthTex)      half  loadingDepthTex
   #define LOADING_DEPTH_TEXTURE_START(loadingDepthTex) STATIC_BRANCH_START(loadingDepthTex)
   #define LOADING_DEPTH_TEXTURE_END(loadingDepthTex)   STATIC_BRANCH_END(loadingDepthTex) 
#else
   #define LOADING_DEPTH_TEXTURE_ON(loadingDepthTex)
   #define LOADING_DEPTH_TEXTURE_START(loadingDepthTex)
   #define LOADING_DEPTH_TEXTURE_END(loadingDepthTex)
#endif
#if _TOON_RECEIVE_SELF_SHADOW && _TOON_RECEIVE_SELF_SHADOW_BRANCH
   #define SELF_SHADOW_ON(selfShadowON)      half  selfShadowON
   #define SELF_SHADOW_START(selfShadowON) STATIC_BRANCH_START(selfShadowON)
   #define SELF_SHADOW_ELSE(selfShadowON) STATIC_BRANCH_ELSE(selfShadowON)
   #define SELF_SHADOW_END(selfShadowON)   STATIC_BRANCH_END(selfShadowON) 
#else
   #define SELF_SHADOW_ON(selfShadowON)
   #define SELF_SHADOW_START(selfShadowON)
   #define SELF_SHADOW_ELSE(selfShadowON)
   #define SELF_SHADOW_END(selfShadowON)
#endif

// calculate main light's shadow area's color, 
// main light's light color is NOT considered!
// this function only apply hsv then tint to findout shadow color
half3 CalculateLightIndependentSelfShadowAlbedoColor(half3 rawAlbedo, half ShadowArea, half Hue, half Saturate, half Value, half4 TintColor)
{
    half isLitToShadowTransitionArea = saturate((1-abs(ShadowArea-0.5)*2));
    // [hsv]
    half HueOffset = Hue;// + _LitToShadowTransitionAreaHueOffset * isLitToShadowTransitionArea;
    half SaturationBoost = Saturate;// + _LitToShadowTransitionAreaSaturationBoost * isLitToShadowTransitionArea;
    half ValueMul =Value* lerp(1,0.5, isLitToShadowTransitionArea);
    
    half3 originalColorHSV; // for output from ApplyHSVChange(...)
    half3 result = ApplyHSVChange(rawAlbedo, HueOffset, SaturationBoost, ValueMul, originalColorHSV);
    
    // [suppress hsv result's 0/low saturation color's random hue artifact due to GPU texture compression]
    //half3 fallbackColor = rawAlbedo * _LowSaturationFallbackColor;
    //result = lerp(fallbackColor,result, lerp(1,saturate(originalColorHSV.y * 5),_LowSaturationFallbackColor.a)); //only 0~20% saturation area affected, 0% saturation area use 100% fallback

    // [tint]
    result *= TintColor;
    
    return result;
}

//根据贴图颜色按HSV区分区域
void ApplyHSVColorMask(inout half3 finalColor, half HSVLightMask, half HSVSaturateMask)
{
    
    half showLightColorMask = saturate(_ShowLightColorMask);
    half maskSelect = step(_ShowLightColorMask,1);
    half SVMask = saturate(HSVLightMask * HSVSaturateMask);
    half V_SMask = saturate(HSVLightMask - SVMask);
    half Mask1 = lerp( V_SMask,SVMask, maskSelect);
    
    finalColor = lerp(finalColor, Mask1, showLightColorMask);
}

// Most important function: lighting equation for main direcional light
// Also this is the heaviest method!
half3 ShadeMainLight(ToonSurfaceData surfaceData, ToonLightingData lightingData, Light light, inout half bloom)
{
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Common data
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // unused LitResult will be removed by compiler, don't worry performance if you don't use it
    //模拟球形法线
    half3 normalSH = normalize(lightingData.positionWS - _HeadBonePositionWS + _HeadBonePosOffset);
    //法线
    half3 N = lerp(lightingData.normalWS, normalSH, _UseSphereNormal);
    //光源，可选相机方向保证打正面光
    half3 L = lerp(light.direction, normalize(_CameraLightPosWS.xyz), _UseCameraLight);

    half3 lightCol = lerp(1, light.color, _MainLightColorEffect);
    half3 V = lightingData.viewDirectionWS;
    half3 H = normalize(L+V);

    half NoL = dot(N,L); // no need saturate() due to smoothstep()
    half saturateNoL = saturate(NoL);
    //
    half NoH = dot(N,H);
    half LoH = saturate(dot(L,H));
    half VoV = saturate(dot(V,V));
    half VoH = saturate(dot(V,H));

    //FresnelRim
    half orthographicCameraAmount = lerp(unity_OrthoParams.w,1,_PerspectiveRemovalAmount);
    
    half NoV = (dot(lightingData.normalWS,V));
    half NoVForRimOrtho = saturate(dot(lightingData.normalWS, UNITY_MATRIX_I_V._m02_m12_m22));
    half NoVRimAttenuation = lerp(NoV,NoVForRimOrtho, orthographicCameraAmount);
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Lit
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // remapped N dot L
    // simplest 1 line cel shade, you can always replace this line by your method, like a grayscale ramp texture.
    // celShadeResult: 0 is in shadow, 1 is in light
    half smoothstepNoL = smoothstep(_CelShadeMidPoint - _CelShadeSoftnessx, _CelShadeMidPoint + _CelShadeSoftnessx, NoL);
    half NoLMask = step(_CelShadeMidPoint + _FresnelRimParams.w, NoL);
    half selfLightAttenuation = smoothstepNoL;

  
    ///////////////////////////////////////
    // face SDF shadow 脸部的阴影使用SDF
    ///////////////////////////////////////
    #if _ISFACE
    //----------------------------------------------------------------------------------------
    // [correct implementation ref]
    /*
    float thresholdCompareValue = 1 - (dot(L, faceForward) * 0.5 + 0.5);
    float filpUVu = sign(dot(L, faceLeft));
    float shadowThresholdGradientFromTexture = tex2D(_FaceAoMap, uv * flaot2(filpUVu, 1)).g;

    float faceShadow = step(thresholdCompareValue, shadowThresholdGradientFromTexture); // or smoothstep depending on style preferred
    */
    //----------------------------------------------------------------------------------------
    // TODO: move this whole section to C# for optimization, when it is proven stable and bug free
    half3 faceRightDirWS = -cross(_FaceUpDirection, _FaceForwardDirection); //  right-hand rule cross(). Since both inputs are unit vector, normalize() is not needed

    // we can't just discard y (simply call directionVectorWS.xz) in world space, because character's head can have any kind of rotation,
    // we must transform all direction vector to head space first, then discard y (simply call directionVectorHeadSpace.xz in head space)
    // (what is head space? head space is a space where x basis vector is face's right, y basis vector is face's up, and z basis vector is face forward) 
    // Change of basis: https://www.3blue1brown.com/lessons/change-of-basis

    // fill in head space's basis vector x,y,z, similar to filling in a TBN matrix
    // since we only care rotation, 3x3 matrix is enough
    half3x3 worldSpaceToHeadSpaceMatrix = half3x3(faceRightDirWS, _FaceUpDirection, _FaceForwardDirection); 

    // [transform all directions to head space]
    // after a "rotation only" matrix mul, unit vector is still unit vector, no normalize() is needed 
    half3 faceForwardDirectionHeadSpace = mul(worldSpaceToHeadSpaceMatrix,_FaceForwardDirection);
    half3 faceRightDirectionHeadSpace = mul(worldSpaceToHeadSpaceMatrix,faceRightDirWS);
    half3 lightDirectionHeadSpace = mul(worldSpaceToHeadSpaceMatrix,L);

    // TODO: we need to handle a special case when "light(L) is parallel to _FaceUpDirection", 
    // which means we are going to call normalize(0 length vector) that will produce undefined result in GPU.
    // Currently we will just SafeNormalize(lightDirectionHeadSpace.xz) to make result atleast consistance
    lightDirectionHeadSpace.y = 0;
    float2 lightDirectionHeadSpaceXZ = SafeNormalize(lightDirectionHeadSpace).xz;
    
    float2 faceForwardDirectionHeadSpaceXZ = normalize(faceForwardDirectionHeadSpace.xz);
    float2 faceRightDirectionHeadSpaceXZ = normalize(faceRightDirectionHeadSpace.xz);

    float FaceForwardDotL = dot(faceForwardDirectionHeadSpaceXZ, lightDirectionHeadSpaceXZ); 
    float FaceRightDotL = dot(faceRightDirectionHeadSpaceXZ, lightDirectionHeadSpaceXZ);

    float2 faceUV = lightingData.uv;
    float2 faceShadowGraientMapValueUV = faceUV * float2(sign(FaceRightDotL), 1);
    //----------------------------------------------------------------------------------------
    // assume texture _FaceAoMap can be x-axis mirrored, so we just flip uv.x to get another side's gradient data
    half faceShadowGraientMapValue = tex2D(_FaceAoMap, faceShadowGraientMapValueUV).g; // hardcoded g channel. TODO: should expose it to material UI?)
    //----------------------------------------------------------------------------------------
    // final threshold test
    faceShadowGraientMapValue += _FaceAoOffset; // user controlled offset
    float resultThresholdValue = 1- (FaceForwardDotL * 0.5 + 0.5);

    half faceShadowResult = smoothstep(resultThresholdValue, resultThresholdValue, faceShadowGraientMapValue); //TODO: provide smoothstep option?
    selfLightAttenuation = faceShadowResult;
    NoLMask =   selfLightAttenuation;
#endif

    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // DepthTextureRimLight
    // 深度偏移产生的边缘光，类似描边，加入光向的影响。以及脸部的深度刘海阴影。
    // "_CameraDepthTexture depth" vs "self depth" difference 2D rim light and 2D shadow
    // (if _TOON_ENABLE_DEPTH_TEXTURE_RIMLIGHT_AND_SHADOW is off, 2D rim light will fall back to classic NoV rim light)
    // (if _TOON_ENABLE_DEPTH_TEXTURE_RIMLIGHT_AND_SHADOW is off, 2D shadow don't have fallback)
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    half depthDiffShadow = 1;
    half3 depthOrNoVRim = 0;
    #if _ISFACE
    if(_EnableHairShadow)
    {
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Get _CameraDepthTexture's linear view space depth at offseted screen position(screen space uv offset)
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // for perspective camera:
        //      reduce width(screen space uv offset amount) when camera move away, 
        //      but clamp at max = 1 using 1/(1+distanceToCamera) if camera is very close to vertex(where distanceToCamera is close to 0)
        // for orthographic camera:
        //      disable camera distance fix(only return a constant 0.7 to match perspective's result) since distance/depth will not affect polygon NDC xy position on screen in orthographic camera
        float cameraDistanceFix = unity_OrthoParams.w ? 0.7 : rcp(1+lightingData.selfLinearEyeDepth); // no need to care orthographicCameraAmount, this line is already correct

        // [calculate finalDepthTexRimLightAndShadowWidthMultiplier]
        // allow width edit by global/per material/per vertex/per fragment
        // (* global * per material width multiplier)
        float finalDepthTexRimLightAndShadowWidthMultiplier = _DepthTexRimLightAndShadowWidthMultiplier;
    
        #if _ISFACE
        {
            // face area shadow width is smaller since it is usually for receiving hair shadow
            // (in theory hair shadow caster is very close to face surface), so smaller shadow width is better
            //finalDepthTexRimLightAndShadowWidthMultiplier *= 0.66666; // hardcode 0.666. TODO: should we expose it to material UI?            
        }
        #endif

        // group all float1 to calculate first for better performance
        float2 UvOffsetMultiplier = _GlobalAspectFix * (finalDepthTexRimLightAndShadowWidthMultiplier * _GlobalFOVorOrthoSizeFix * cameraDistanceFix);

        // offset according to view space light direction
        float2 finalUVOffset = _GlobalMainLightDirVS.xy * UvOffsetMultiplier; 

        // [get _CameraDepthTexture's camera depth data for finding the edge of large depth difference to character]
        // here we load _CameraDepthTexture once only, and use it as both rim light and shadow's input, 
        // very nice performance win if compared to load _CameraDepthTexture twice, but we lost the ability to edit width separately (e.g. rim and shadow separated width)
        // use LOAD instead of sample for better performance since we don't need mipmap of depth texture, and don't want bilinear filtering to depth data,which is meaningless
        // int2 loadTexPos = lightingData.SV_POSITIONxy + finalUVOffset * _ToonHairDepthTexture_TexelSize.zw;
        // loadTexPos = min(loadTexPos,_ToonHairDepthTexture_TexelSize.zw-1); // clamp loadTexPos to prevent loading outside of _CameraDepthTexture's valid area
        // float depthTextureRawSampleValue = LoadSceneDepth(loadTexPos); // using URP provided LoadSceneDepth(pos), this will make rendering correct in VR also
        float2 depthUV = (lightingData.screenPos/lightingData.screenPos.w).xy + finalUVOffset;
        float hairDepth = SAMPLE_TEXTURE2D_X(_ToonHairDepthTexture, sampler_LinearClamp, depthUV).r;    
        float depthTextureLinearDepthVS = Convert_SV_PositionZ_ToLinearViewSpaceDepth(hairDepth);
    
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // calculate depth texture screen space shadow
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // hardcode threshold to reduce material inspector complexity
        float depthTexShadowDepthDiffThreshold = 0.03;
        // face area using a smaller threshold, since face area's depth was pushed in _CameraDepthTexture already
        #if _ISFACE
            depthTexShadowDepthDiffThreshold = 0.01;
        #endif
        // give user per material control (default 0)
        depthTexShadowDepthDiffThreshold += _DepthTexShadowThresholdOffset;

        // let shadow fadeout softly and smoothly when depth difference is too small
        // _DepthTexShadowFadeoutRange will allow user controlling how the fadeout should look like
        depthDiffShadow = saturate((depthTextureLinearDepthVS - (lightingData.selfLinearEyeDepth - depthTexShadowDepthDiffThreshold))*50 / 0.1);
        
    }
    else
    {
        depthDiffShadow = 1;
    }
   #endif
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Char self shadow map
    // 角色自投影。可以实现裙子阴影，下颌投影等细腻的阴影，缺点是多一张阴影图(剔除脸部，脸部使用深度阴影，自投影精度不高)
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    half selfShadowMapShadow = 1; // default no self shadow map effect
    #if _TOON_RECEIVE_SELF_SHADOW
    SELF_SHADOW_START(_SELF_SHADOW_ON)
    // if() check to avoid face sampling self shadow map because most of the time it is ugly
    #ifndef _ISFACE
    //if(lightingData.isFaceArea < 0.5)// = true if not face
    //{
        // matrix mul is heavy(= 3 dot()), but better than passing from Varyings due to interpolation cost 
        float4 positionSelfShadowCS = mul(_TOONSelfShadowWorldToClip, float4(lightingData.positionWS.xyz,1)); 

        // ortho camera shadow map can remove /w since positionSelfShadowCS.w is always 1
        //float3 positionSelfShadowNDC = positionSelfShadowCS.xyz / positionSelfShadowCS.w; // no need this line's /w
        float3 positionSelfShadowNDC = positionSelfShadowCS.xyz; // this line is enough

        // convert ndc.xy[-1,1] to uv[0,1]
        float2 shadowMapUV_XY = positionSelfShadowNDC.xy * 0.5 + 0.5;

        // calculate SAMPLE_TEXTURE2D_SHADOW(...)'s ndc.z compare value
        //---------------------------------------------------------
        float ndcZCompareValue = positionSelfShadowNDC.z;

        // if OpenGL, convert ndc.z [-1,1] to shadowmap's [0,1], because shadowmap always within 0~1 range, for any platform
        // if DirectX, do nothing, it is 0~1 range already
        ndcZCompareValue = UNITY_NEAR_CLIP_VALUE < 0 ? ndcZCompareValue * 0.5 + 0.5 : ndcZCompareValue;

        // +z compare bias in ndc.z [0,1] space, also apply DirectX's reverse depth to bias
        ndcZCompareValue += _TOONSelfShadowDepthBias * UNITY_NEAR_CLIP_VALUE;
        //---------------------------------------------------------

        // if DirectX, flip uv's y (y = 1-y)
        // if OpenGL, do nothing
        #if UNITY_UV_STARTS_AT_TOP
        shadowMapUV_XY.y = 1 - shadowMapUV_XY.y;
        #endif

        float4 selfShadowmapUV = float4(shadowMapUV_XY,ndcZCompareValue,0); // packing for SAMPLE_TEXTURE2D_SHADOW

        // URP's 4 tap(mobile)/ 9 tap(non-mobile) soft shadow, reuse URP's _SHADOWS_SOFT keyword to avoid using more multi_compile, 
        // but it may be still too costly for mobile even it is just 4 tap
    #if _SHADOWS_SOFT
        ShadowSamplingData shadowData;
        shadowData.shadowOffset0 = float4(+_TOONSelfShadowParam.x,+_TOONSelfShadowParam.y,0,0);
        shadowData.shadowOffset1 = float4(-_TOONSelfShadowParam.x,+_TOONSelfShadowParam.y,0,0);
        shadowData.shadowOffset2 = float4(+_TOONSelfShadowParam.x,-_TOONSelfShadowParam.y,0,0);
        shadowData.shadowOffset3 = float4(-_TOONSelfShadowParam.x,-_TOONSelfShadowParam.y,0,0);
        shadowData.shadowmapSize = _TOONSelfShadowParam;
        selfShadowMapShadow = SampleShadowmapFiltered(TEXTURE2D_SHADOW_ARGS(_TOONCharSelfShadowMapRT, sampler_TOONCharSelfShadowMapRT),selfShadowmapUV,shadowData);
        // (optional) sharpen shadow
        //selfShadowMapShadow = smoothstep(0.25,0.75,selfShadowMapShadow);
    #else
        // 1 sample only, let hardware do the 1 tap bilinear filter, which is 0 cost filtering
        selfShadowMapShadow = SAMPLE_TEXTURE2D_SHADOW(_TOONCharSelfShadowMapRT, sampler_TOONCharSelfShadowMapRT, selfShadowmapUV);
    #endif

        // fadeout shadow if reaching the end of shadow distance (always use 2m from start fade to end fade)
        float fadeTotalDistance = 2; // hardcode now, can expose to C# if needed
        selfShadowMapShadow = lerp(selfShadowMapShadow,1, saturate((1/fadeTotalDistance) * (abs(lightingData.selfLinearEyeDepth)-(_TOONSelfShadowRange-fadeTotalDistance))));       
    //}
    #endif
    SELF_SHADOW_ELSE(_SELF_SHADOW_ON)
    selfShadowMapShadow = 1;
    
    SELF_SHADOW_END(_SELF_SHADOW_ON)
#endif

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Specular
    // 高光（头发、金属）
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    half3 specularLitAdd = 0;
#if _SPECULARHIGHLIGHTS
    specularLitAdd = surfaceData.specular;
    // allow user select simple NoV or GGX specular method
    half SpecularRawArea;
    // GGX
    if(_UseGGXDirectSpecular)
    {
        // [GGX specular method]
        half roughness = 1-saturate(0.5* _GGXDirectSpecularSmoothnessMultiplier);
        half F0 = 0.04; // only support non-metal now, hardcord 0.04 F0

        SpecularRawArea = GGXDirectSpecular_Optimized(H,saturateNoL,NoV,NoH,LoH, roughness, F0,_SpecularFadeDistance);
        SpecularRawArea *= 100;
        
    }
    else
    {
        SpecularRawArea = saturate(NoH);
    }
    
    half specularRemapStartPoint = max(0,_SpecularAreaRemapMidPoint-_SpecularAreaRemapRange);
    half specularRemapEndPoint = min(1,_SpecularAreaRemapMidPoint+_SpecularAreaRemapRange);
    half remappedSpecularRawArea = smoothstep(specularRemapStartPoint,specularRemapEndPoint, SpecularRawArea);

    remappedSpecularRawArea = lerp(SpecularRawArea, remappedSpecularRawArea, _SpecularAreaRemapUsage); // allow user to cancel specular remap
    specularLitAdd *= remappedSpecularRawArea;
    
    // max(0.25,x), to prevent 0 specular if Directional Light is off
    // saturate(x), to prevent over bright
    specularLitAdd *= saturate(max(0.25,light.color));// * _GlobalSpecularIntensityMultiplier; 
    // keep 25% specular in 0% direct light(in shadow) enviroment
    //specularLitAdd *= lerp(lightingData.averageShadowAttenuation,1,_GlobalSpecularMinIntensity); 
    
#endif
   
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Lit，计算阴影颜色，可采样Ramp图作为Tint
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    
    half3 lightColorIndependentLitColor = 1;
#ifndef _RAMP_LIGHTING
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // 不使用Ramp贴图，自定义阴影颜色
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
    //阴影遮罩
    half finalShadowArea = selfLightAttenuation * selfShadowMapShadow * depthDiffShadow;// * lerp(depthDiffShadow, 1, _UseDepthShadowTintColorToAO);
    
    //AO
    half directOcclusion = surfaceData.occlusion;// * lerp(1, depthDiffShadow, _UseDepthShadowTintColorToAO); 
    finalShadowArea *= lerp(1, directOcclusion, _OcclusionStrength);
    finalShadowArea = lerp(1, finalShadowArea, _CelShadowIntensity);
    
    //固有色HSV分层：先按明度V分明暗颜色，然后再按饱和度S分高低饱和度，取低饱和度高明度的交集。
    half3 BaseColorHSV = RGB2HSV(surfaceData.albedo);
    half HSVLightMask = step(_lightColorThreshold, BaseColorHSV.z);
    half HSVSaturateMask = (1 - step(_LowSaturationThreshold, BaseColorHSV.y)) * HSVLightMask;
    
    // #if _DEBUG_DISPLAY
    //     if(_ShowLightColorMask == 1)
    //         return HSVSaturateMask;
    //     else if(_ShowLightColorMask == 2)
    //         return HSVLightMask;
    //     else if(_ShowLightColorMask == 3)
    //         return 1 - HSVLightMask;
    // #endif
    
    //暗部边缘光
    half ShadowReflectAttenuation = 1 - NoVRimAttenuation;
    half CelShadowReflectWidth = 1 - _CelShadowReflectWidthx;
    half CelShadowReflectIntensity = _CelShadowReflectIntensity * lerp(1, _CelShadowReflectIntensityLightMulty, HSVLightMask);
    ShadowReflectAttenuation =
        smoothstep(CelShadowReflectWidth - _CelShadowReflectSmooth, CelShadowReflectWidth + _CelShadowReflectSmooth, ShadowReflectAttenuation) * CelShadowReflectIntensity * 0.1;
    half3 ShadowReflectColor = ShadowReflectAttenuation * _CelShadowReflectColor * (1 - smoothstepNoL);//去除亮部的AO影响
    
    #if _ISFACE //脸部去除边缘光
        ShadowReflectColor = 0;
    #endif
    
    //固有色按明度区分阴影色
    //高明度
    half3 inSelfShadowAlbedoColor_light = CalculateLightIndependentSelfShadowAlbedoColor(surfaceData.albedo, HSVLightMask,
        _SelfShadowAreaHueOffset_light, _SelfShadowAreaSaturationBoost_light, _SelfShadowAreaValueMul_light, _SelfShadowTintColor_light);
    inSelfShadowAlbedoColor_light *= lerp( _CelShadowOcclusionColorV, 1, directOcclusion);

    //高明度低饱和度
    inSelfShadowAlbedoColor_light = lerp(inSelfShadowAlbedoColor_light,
        surfaceData.albedo * _LowSaturationFallbackColor * lerp(_CelShadowOcclusionColorSV, 1,  directOcclusion),
        HSVSaturateMask);
    
    //低明度
    half3 inSelfShadowAlbedoColor_dark = CalculateLightIndependentSelfShadowAlbedoColor(surfaceData.albedo, 1-HSVLightMask,
            _SelfShadowAreaHueOffset_dark, _SelfShadowAreaSaturationBoost_dark, _SelfShadowAreaValueMul_dark, _SelfShadowTintColor_dark);
    inSelfShadowAlbedoColor_dark *= lerp(_CelShadowOcclusionColorD ,1, directOcclusion);

    
    //阴影颜色 + 反光
    half3 finalShadowAlbedoColor = lerp(inSelfShadowAlbedoColor_dark, inSelfShadowAlbedoColor_light, HSVLightMask);
    
    finalShadowAlbedoColor += ShadowReflectColor;
    
    //全局参数
    finalShadowAlbedoColor *= _GlobalCharacterShadowColor;
    half3 finalLightColor = surfaceData.albedo * _GlobalCharacterLightColor;
    
    //结合亮暗部颜色
    lightColorIndependentLitColor = lerp(finalShadowAlbedoColor, finalLightColor, finalShadowArea);
        
        
#else

    // 使用Ramp贴图的颜色作为阴影Tint，复用性高，需要角色有一个区分basecolor不同明度的灰度图，不同灰度区域对应Ramp的不同颜色带
    half rampUvX = selfLightAttenuation * selfShadowMapShadow * surfaceData.occlusion * depthDiffShadow;;//(selfLightAttenuation * selfShadowMapShadow * surfaceData.occlusion ) * 0.5 + 0.5;//(NoL * 0.5 + 0.5);
    //rampUvX *= (1.0 / _CelShadowIntensity - 0.003);
    //rampUvX = saturate(rampUvX);
    lightColorIndependentLitColor = lerp(surfaceData.albedo, surfaceData.albedo * SAMPLE_TEXTURE2D(_RampLightingTex,linear_clamp_sampler,half2(rampUvX, surfaceData.samplingUvY)), _CelShadowIntensity);
    
    
#endif
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // 描边的阴影颜色可输出纯色，减少计算
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    #if ToonIsOutlinePass
        lightColorIndependentLitColor =  finalShadowAlbedoColor * _OutlineTintColor;
    #endif
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Composite final main light color
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // apply light color to the whole body at the final stage, it is better for toon shading style's need 
    // min(X,lightCol) to prevent over bright, ideally we want to tonemap it, but for performance reason, just min looks good enough
    // apply all add light to lit pass (ignore outline pass)
    // 
    //最终输出的Lit结果 = LitResult + LitAdd
    half3 LitResult = 1;
    half3 LitAdd = 0;
    //half3 lightColor = lightCol;// * lightingData.averageShadowAttenuation;
    //LitResult = min(_GlobalMainDirectionalLightMaxContribution, lightColor) * lightColorIndependentLitColor * _GlobalMainDirectionalLightMultiplier;
    LitResult = min(1, lightCol) * lightColorIndependentLitColor;
    LitResult *= lerp(_DepthTexShadowTintColor, 1, depthDiffShadow);
    //LitResult = lightColorIndependentLitColor * _GlobalMainDirectionalLightMultiplier;
    LitAdd = specularLitAdd + depthOrNoVRim;
    bloom += BloomMaskRGB(LitAdd, 1);
    
    #if ToonIsOutlinePass
        LitResult = lerp(LitResult, _OutlineEmissionCol, _OutlineReplace);
        bloom += lerp(0, BloomMaskRGB(_OutlineEmissionCol, 1), _OutlineReplace);  
    #endif
    
    half3 color = LitResult + LitAdd;
    
    //边缘光
    half rimAttenuation = NoVRimAttenuation;
    
    //half fwidthFix = saturate(fwidth(rimAttenuation) * 50);//可以避免大块的边缘光
    rimAttenuation = (1-smoothstep(_FresnelRimParams.x, _FresnelRimParams.x+ _FresnelRimParams.y, rimAttenuation)) * _FresnelRimParams.z * _FresnelRim_ON ;
    // rim light area *= NoL mask
    
    half NoLEffect = NoLMask;//(saturateNoL * 0.25 + 0.75) * (NoL > 0);
    
    rimAttenuation *= NoLEffect;//lerp(1, NoLEffect, _FresnelRimMainLightEffect);
    rimAttenuation = saturate(rimAttenuation);
    #if ToonIsOutlinePass
        rimAttenuation = 0;
    #endif
    // let rim light fadeout softly when character is very far away from camera, to avoid rim light flicker artifact(due to pixel count not enough)
    // 还需要考虑FOV的影响
    //rimAttenuation = lerp(rimAttenuation, 0, smoothstep(5, 10, lightingData.selfLinearEyeDepth));
    half3 rimColor = lerp(_FresnelRimColor, lightCol * _FresnelRimColor, _FresnelRimMainLightEffect);

    #if _ISFACE
    half4 blushTex = tex2D(_BlushMap, lightingData.uv);
    half blushAlphaValue = blushTex.r * _BlushParams.r  + blushTex.g * _BlushParams.g + blushTex.b * _BlushParams.b;
    half cAa = (blushAlphaValue) * (_BlushParams.r * _BlushRColor.a+ _BlushParams.g * _BlushGColor.a + _BlushParams.b * _BlushBColor.a);
    color = lerp (color, _BlushRColor.rgb * _BlushParams.r + _BlushGColor.rgb * _BlushParams.g + _BlushBColor.rgb * _BlushParams.b, cAa) ;
    #endif
    color = lerp(color, rimColor, rimAttenuation);

    
    bloom += BloomMaskRGB(_FresnelRimColor * rimAttenuation, 1);
    
    return color;
}

////////////////////////////////////////////////////////////////////////////////
// 在VS逐顶点计算AdditionalLight
////////////////////////////////////////////////////////////////////////////////
half3 CalculateAdditiveSingleAdditionalLight(half3 N, Light light)
{
    ////////////////////////////////////////////////////////////////////////////////
    // there can be LOTs of additional lights, 
    // so additional lights use a very simple method for performance reason
    ////////////////////////////////////////////////////////////////////////////////

    half SphereNoL = dot(N,light.direction);
  
    half lightAttenuation = SphereNoL * 0.2 + 0.8; // 1/5 lambert, we want to hide 3D feel

    // distance and shadow
    // distance attenuation min(1,x) to prevent over bright if light too close to vertex
    lightAttenuation *= min(1,light.distanceAttenuation) * light.shadowAttenuation * 0.5; // default * 0.5 to make additional light weaker 

    //相比上一版改进加入了光照颜色的影响
    return light.color * lightAttenuation;
    //return lightAttenuation; 
}

//////////////////////////////////////////////////////////////////////////////////////////
// 全局光照GI计算，SH间接光
//////////////////////////////////////////////////////////////////////////////////////////
half3 ShadeGI(ToonSurfaceData surfaceData, ToonLightingData lightingData)
{
    // default weaker occlusion for indirect
    half indirectOcclusion = lerp(1, surfaceData.occlusion, 0.5); // hardcode 50% usage

    // max() can prevent result completely black, if lightprobe was not baked and no direct light is active
    //half3 indirectLight = max(lightingData.SH,_GlobalIndirectLightMinColor) * indirectOcclusion;
    half3 indirectLight = lightingData.SH * indirectOcclusion;
    
    return indirectLight * surfaceData.albedo; 
}

//////////////////////////////////////////////////////////////////////////////////////////
// 所有光照的汇总计算，MainLight、indirectLight、AdditionalLight、Emission、ProbeOcclusion
//////////////////////////////////////////////////////////////////////////////////////////
// This function contains no lighting logic, it just pass lighting results data around.
// The job done in this function is "do shadow mapping depth test positionWS offset"
half3 ShadeAllLights(ToonSurfaceData surfaceData, ToonLightingData lightingData, inout half bloom)
{
    
    //MainLight
    Light mainLight = GetMainLight();
    half3 directLightResult = ShadeMainLight(surfaceData, lightingData, mainLight, bloom);
    
    ///////////////////////////////////////////////////////////////////
    // Composite all lighting result
    ///////////////////////////////////////////////////////////////////
    
    //ProbeOcclusion 角色进入烘焙阴影变黑
    half probeOcclusion = BakedShadow(unity_ProbesOcclusion,  _MainLightOcclusionProbes);
    directLightResult *= lerp(1, probeOcclusion, _GlobalCharProbeOcclusionEffect);

    //AdditionalLight
    half3 additionalLightResult = 0;
    #if NeedCalculateAdditionalLight
    
        // default weaker occlusion for additional light
        half directOcclusion = lerp(1, surfaceData.occlusion, 0.5); // hardcode 50% usage
        additionalLightResult = lightingData.additionalLightSum * surfaceData.albedo * directOcclusion;
    
        directLightResult += additionalLightResult;
    
    #endif

    //IndirectLight
    half3 indirectResult =  ShadeGI(surfaceData, lightingData) * _IndirectLightColorEffect;
    
    
    //取直接光和间接光的最大值，即只有在黑暗环境中才加入lightprobe等间接光的影响
    // [pick the highest between indirect and direct light]
    // character artist don't want the concept of indirect + direct light
    // because it will ruin the final color easily,
    // what character artist want is -> keep char's result same as albedo they draw if bright enough,
    // but in a dark enviroment, switch to use light probe to make character blend into enviroment
    
    //half3 finalLightResult = max(indirectResult, directLightResult);
    
    //需要lightprobe的影响更明显，改成叠加的效果
    half3 finalLightResult = directLightResult + indirectResult;

    // Emission
    half3 emissionResult = surfaceData.emission;
    bloom += BloomMaskRGB(emissionResult, 1);
    finalLightResult += emissionResult;


    return finalLightResult;
    
}
#endif

// SPDX-License-Identifier: (Not available for this version, you are only allowed to use this software if you have express permission from the copyright holder and agreed to the latest NiloToonURP EULA)
// Copyright (c) 2020 Kuroneko ShaderLab

// For more information, visit -> https://github.com/ColinLeung-NiloCat/UnityURPToonLitShaderExample

// #pragma once is a safeguard best practice in almost every .hlsl, 
// doing this can make sure your .hlsl's user can include this .hlsl anywhere anytime without producing any multi include conflict
#ifndef __ToonCharacter_Shared_VertexSharedFuntions__
#define __ToonCharacter_Shared_VertexSharedFuntions__




///////////////////////////////////////////////////////////////////////////////////////
// vertex shared functions
///////////////////////////////////////////////////////////////////////////////////////
void ApplyVertexAnimation(inout half3 positionOS, half vertColor)
{
    
    half sinoffset = _sinoffset * (1.0 - sin( _sinpinlv * (positionOS.y + _Time.y * _speedsin)));
    half offset = sinoffset * (1 - vertColor) * _VAT_ON;
    
    #if _ISFACE
    offset = 0;
    #endif
    
    half offsetX = lerp(0,offset,_offsetZ);
    half offsetY = lerp(0,offset,_offsetX);
    half offsetZ = lerp(0,offset,_offsetY);
        
    positionOS.x += offsetX;
    positionOS.y += offsetY;
    positionOS.z += offsetZ;
    
}

// output: xyz = lightingNormalWS, w = isFaceArea
half4 GetLightingNormalWS_FaceArea(half3 normalWS, float2 uv)
{
    // default not face
    half3 resultNormalWS = normalWS;
    half isFaceArea = 0;

#if _ISFACE && !ToonSelfOutlinePass
    //#if _FACE_MASK_ON
        //isFaceArea = dot(tex2Dlod(_FaceMaskMap, float4(uv,0,0)), _FaceMaskMapChannelMask);             
    //#else
        isFaceArea = 1;
    //#endif
    //resultNormalWS = normalize(lerp(normalWS, _FaceForwardDirection, isFaceArea * _FixFaceNormalAmount)); 
#endif
    return half4(resultNormalWS,isFaceArea); 
}
//clipspace outline
//在裁剪空间做屏幕修正，去掉了透视影响，保证描边保持固定像素，但是当屏幕像素变多或变少时依然不可控，并且要加入角色透视的影响，目前感觉还是不如worldspace，透视修正一样要做。
// float3 TransformPositionWSToOutlinePositionWS(float width, VertexPositionInputs vertexPositionInputs, VertexNormalInputs vertexNormalInputs, float3 smoothedNormalTS, float3 VertexNormal)
// {
//     half positionVSZ = -(vertexPositionInputs.positionVS.z);
//     //width *= GetOutlineCameraFovAndDistanceFixMultiplier(vertexPositionInputs.positionVS.z, _CurrentCameraFOV) * 400;
//     float3 extrudeDirectionWS = vertexNormalInputs.normalWS;
//     /*extrudeDirectionWS = _OutlineUseBakedSmoothNormal ? 
//                            ConvertNormalTSToNormalTargetSpace(smoothedNormalTS, vertexNormalInputs.tangentWS,vertexNormalInputs.bitangentWS, vertexNormalInputs.normalWS) :
//                            extrudeDirectionWS;*/
//     // by default we will use lighting normalWS as extrude direction also,
//     // it is usable but not perfect
//     float4 PositionCS = vertexPositionInputs.positionCS;
//     float3 extrudeDirectionCS =  normalize(mul((float3x3) UNITY_MATRIX_VP, extrudeDirectionWS));
//     //抵消透视除法
//     extrudeDirectionCS *= PositionCS.w;
//    
//     //PositionCS_z = LinearEyeDepth(PositionCS_z)
//     /*float4 nearUpperRight = mul(unity_CameraInvProjection, float4(1, 1, UNITY_NEAR_CLIP_VALUE, _ProjectionParams.y));//将近裁剪面右上角位置的顶点变换到观察空间
//     float aspect = abs(nearUpperRight.y / nearUpperRight.x);//求得屏幕宽高比*/
//     //extrudeDirectionCS.x *= aspect;
//     extrudeDirectionCS.xy /= _ScreenParams.xy;
//     //////////////////////////////////////////////////////////////////////
//     // ^ (width)
//     // |
//     // | \  (0,2width)
//     // |  \
//     // |   \
//     // |     ——————————————  (nearStart2,width)
//     // | (nearStart1,width)  \
//     // |                      \
//     // |                       \  (farFadout,width)
//     // | ——————————————————————————————————————————————> (positionVS.z)
//     //////////////////////////////////////////////////////////////////////
//
//     half nearStart1 = 2;  //近距离点
//     half nearStart2 = 4;  //开始减小的点
//     half farFadeout = 40;   //远距离fadeout的点
//     
//     half widthMax = 2 * width;
//     half k1 = (width - widthMax) / nearStart1;
//     half k2 = width / (nearStart2 - farFadeout);
//     half widthNearFix = (k1 * positionVSZ) + widthMax;
//     half widthFarFix = max(0, k2 * (positionVSZ - farFadeout) );
//     
//     half widthLerp = lerp(width, widthNearFix, step(positionVSZ, nearStart1));
//     half finalWidth = lerp(widthFarFix  ,widthLerp, step(positionVSZ, nearStart2));
//     //NDC w Range[-1,1], project to screen w Range[0,1] * 2 Range[0,2], 1width = 1pixel
//     PositionCS.xy += extrudeDirectionCS.xy * finalWidth * 2 ;
//     //positionVSZ
//     // but "world space smoothed normal" is a much better extrude direction for outline than simply using lighting normal,
//     // because smoothed normal doesn't have any split normal, so the outline will always be continuous, which looks much better. 
//     // If we baked "tangent space smoothed normal" in model's uv8, 
//     // we can convert it back to world space and use it as a much better extrude direction  
//
//     return mul(UNITY_MATRIX_I_VP, PositionCS);
// }

//worldspace outline 
void ApplyToonOutline(inout float3 positionWS, half3 normalWS, half3 tangentWS, half3 bitangentWS,
    half positionVSZ, half4 smoothedNormalTS, half width)
{
    // by default we will use lighting normalWS as extrude direction also,
    // it is usable but not perfect
    // but "world space smoothed normal" is a much better extrude direction for outline than simply using lighting normal,
    // because smoothed normal doesn't have any split normal, so the outline will always be continuous, which looks much better. 
    // If we baked "tangent space smoothed normal" in model's uv8, 
    // we can convert it back to world space and use it as a much better extrude direction  
    //平滑法线，平均法线
    half3 extrudeDirectionWS = smoothedNormalTS.w? 
    ConvertNormalTSToNormalTargetSpace(smoothedNormalTS.xyz, tangentWS,bitangentWS, normalWS) :
    normalWS;
    
    //透视相机
    half finalWidth;
    if(unity_OrthoParams.w == 0)
    {
        //距离修正
        ////////////////////////////////////////////////////////
        // ^(width)
        // |
        // |            —————————————
        // |           /（width）
        // |          /        
        // |         /          
        // |        /            
        // | ———————(widthMin)    
        // | ——————————————————————————————————————————————> (positionVS.z)
        // |       (Min) (Max)
        //////////////////////////////////////////////////////////////////////
        half distanceMin = _GlobalToonOutlineWidthFixDistMin;
        half distanceMiddle = 5;
        half distanceMax = _GlobalToonOutlineWidthFixDistMax;

        half widthDistanceMin = 0.15;
        half widthDistanceMax = 2;
        
        // half widthDistanceMin = width * 0.15;
        // half widthDistanceMax = width * 2;
        //
        //
        // half distanceK1 = (width - widthDistanceMin) / (distanceMiddle - distanceMin);
        // half widthDistanceFix1 = distanceK1 * (positionVSZ - distanceMiddle) + width;
        // widthDistanceFix1 = clamp(widthDistanceFix1, widthDistanceMin, width);
        //
        // half distanceK2 = (widthDistanceMax - width) / (distanceMax - distanceMiddle);
        // half widthDistanceFix2 = distanceK2 * (positionVSZ - distanceMax) + widthDistanceMax;
        // widthDistanceFix2 = clamp(widthDistanceFix2, width, widthDistanceMax);
        //
        // half widthDistance = lerp(widthDistanceFix2, widthDistanceFix1, step(positionVSZ, distanceMiddle));
        half distanceK = (widthDistanceMax - widthDistanceMin) / (distanceMax - distanceMin);
        half distanceB = widthDistanceMax - distanceK * distanceMax;
        half distanceClamp = clamp(positionVSZ, distanceMin, distanceMax);
        half widthDistanceFix = distanceK * distanceClamp + distanceB;

        //在距离基础上叠加FOV修正
        ////////////////////////////////////////////////////////
        // ^(widthDistance)
        // |                 ———————
        // |               / (finalWidthMax)
        // |              /  
        // |             /
        // |            /
        // |           /（widthDistance）
        // |          /        
        // |         /          
        // |        /            
        // | ———————(finalWidthMin)    
        // | ——————————————————————————————————————————————> (fov)
        // |       (Min) (Middle) (Max)
        //////////////////////////////////////////////////////////////////////
        half fov = GetCameraFOV();
        half fovMin = _GlobalToonOutlineWidthFixFOVMin;
        half fovMiddle = 40;
        half fovMax = _GlobalToonOutlineWidthFixFOVMax;

        half WidthFOVMin = widthDistanceFix * 0.15;
        half WidthFOVMax = widthDistanceFix * 2;
        // 
        // half fovK1 = (widthDistance - WidthFOVMin) / (fovMiddle - fovMin);
        // half fovK2 = (WidthFOVMax - widthDistance) / (fovMax - fovMiddle);
        //
        // half finalWidthFix1 = fovK1 * (fov - fovMiddle) + widthDistance;
        // finalWidthFix1 = clamp(finalWidthFix1, WidthFOVMin, widthDistance);
        //
        // half finalWidthFix2 = fovK2 * (fov - fovMax) + WidthFOVMax;
        // finalWidthFix2 = clamp(finalWidthFix2, widthDistance, WidthFOVMax);
        //
        // finalWidth = lerp(finalWidthFix2, finalWidthFix1, step(fov, fovMiddle));
        half fovK = (WidthFOVMax - WidthFOVMin) / (fovMax - fovMin);
        half fovB = WidthFOVMax - fovK * fovMax;
        half fovClamp = clamp(fov, fovMin, fovMax);
        half WidthFixMul = fovK * fovClamp + fovB;
        finalWidth = width * WidthFixMul;
 
    }
    //正交相机
    else
    {
        half orthoSize = abs(unity_OrthoParams.y);
        half orthoSizeMin = 0.1;
        half orthoSizeMax = 2;
        half widthOrthoMin = width * 0.1;
        half orthoK = (width - widthOrthoMin) / (orthoSizeMax - orthoSizeMin);
        half widthOrthoFix = orthoK * (orthoSize - orthoSizeMax) + width;
        widthOrthoFix = clamp(widthOrthoFix, widthOrthoMin, width);
        finalWidth = widthOrthoFix;
    }
    positionWS += extrudeDirectionWS * finalWidth * 0.005;
}
#endif
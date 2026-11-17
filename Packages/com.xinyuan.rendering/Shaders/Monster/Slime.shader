Shader "XinYuan/Character/Monster/Slime"
{
    Properties
    {
        [Main(BaseMapGroup)] BaseMapGroup("基础贴图", Float) = 1
        [Header(BaseMap)][Space(10)]
        [Sub(BaseMapGroup)] _StencilRef("模板测试写入值", Float) = 201
        [SubEnum(BaseMapGroup,Keep,0,Replace,2)] _StencilPassOp("模板通过值", Float) = 2
        [Sub(BaseMapGroup)] [NoScaleOffset] _BaseMap ("基础贴图", 2D) = "white" {} 
        [Header(NoiseIntensity)][Space(10)]
        [Sub(BaseMapGroup)] _BaseNoiseIntensity2("前面扰动强度((基于法线贴图)遮罩用顶点色G通道)" ,Range(0,1)) = 0 
        [Sub(BaseMapGroup)] _BaseNoiseIntensity("后面扰动强度((基于法线贴图)遮罩用顶点色G通道)" ,Range(0,1)) = 0 
        [Header(FlowMap)][Space(10)]
        [SubNumToggle(BaseMapGroup)] _IsuseFlow("是否用流动图", Float) = 0
        [Sub(BaseMapGroup)] _Flowmap ("流动图(XY平铺数量||ZW方向)", 2D) = "white" {}  
        [Header(FlowIntensity)][Space(10)]
        [Sub(BaseMapGroup)] _FlowIntensity2("前面流动强度" ,Range(0,1)) = 0.2             
        [Sub(BaseMapGroup)] _Flowspeed2("前面流动速度" ,Float) = 0     
        [Sub(BaseMapGroup)] _FlowNoiseIntensity2("前面流动图的扰动强度" ,Range(0,1)) = 0.2
        [Sub(BaseMapGroup)] _FlowIntensity("后面流动强度" ,Range(0,1)) = 0.2 
        [Sub(BaseMapGroup)] _Flowspeed("后面流动速度" ,Float) = 0     
        [Sub(BaseMapGroup)] _FlowNoiseIntensity("后面流动图的扰动强度" ,Range(0,1)) = 0.2

        [Main(NormalMapGroup, _NORMAL_ON)] _NORMAL_ON("法线贴图", Float) = 0
        [Header(NormalMap)][Space(10)]
        [Sub(NormalMapGroup)] _NormalMap("法线贴图(XY平铺数量||ZW方向)" , 2D) = "bump"{}
        [Space(10)]
        [Sub(NormalMapGroup)] _NormalSpeed2("前面法线图流动速度" , Float) = 0
        [Sub(NormalMapGroup)] _NormalIntensity2("前面法线图强度 " , Float) = 1
        [Sub(NormalMapGroup)] _NormalSpeed("后面法线图流动速度" , Float) = 0
        [Sub(NormalMapGroup)] _NormalIntensity("后面法线图强度 " , Float) = 1

        [Main(AlphaGroup)] AlphaGroup("透明方式", Float) = 1
        [SubNumToggle(AlphaGroup)] _IsuseAlpha("是否使用基础贴图的A作为透明", Float) = 0
        [Sub(AlphaGroup)] _AlphaPower2("前面透明范围" , Float) = 1
        [Sub(AlphaGroup)] _AlphaIntensity2("前面透明强度" ,Float) = 1
        [Sub(AlphaGroup)] _AlphaPower("后面透明范围" , Float) = 1
        [Sub(AlphaGroup)] _AlphaIntensity("后面透明强度" ,Float) = 1

        [Main(FrenselGroup)] FrenselGroup("菲涅尔", Float) = 1
        [Sub(FrenselGroup)] _FrenselColor("菲涅尔颜色" ,Color) = (1,1,1,1)
        [Space(10)]
        [SubNumToggle(FrenselGroup)] _IsuseNormal2("前面是否使用法线贴图作为输入值", Float) = 0
        [Space(10)]
        [Sub(FrenselGroup)] _FrenselPower2 ("前面菲涅尔范围" , Float) = 1
        [Sub(FrenselGroup)] _FrenselIntensity2("前面菲涅尔强度" , Float) = 1
        [Space(10)]
        [SubNumToggle(FrenselGroup)] _IsuseNormal("后面是否使用法线贴图作为输入值", Float) = 0
        [Space(10)]
        [Sub(FrenselGroup)] _FrenselPower ("后面菲涅尔范围" , Float) = 1
        [Sub(FrenselGroup)] _FrenselIntensity("后面菲涅尔强度" , Float) = 1

        [Main(VertexanimGroup, _VERTEXANIM_ON)] _VERTEXANIM_ON("顶点动画", Float) = 0
        [Header(VertexAnim)][Space(10)]
        [Sub(VertexanimGroup)] _VertexanimIntensity("顶点动画强度",Float) = 1
        [Sub(VertexanimGroup)] _VertexFrequency("顶点噪波频率",Float)= 1 
        [Header(VertexDireciton)][Space(10)]
        [SubNumToggle(VertexanimGroup)] _IsuseVertexDir("是否使用方向动画(遮罩用顶点色R通道)", Float) = 0
        [Sub(VertexanimGroup)] _VertexDireciton("运动方向:X,Y,Z||W:强度",Vector)= (0,0,0,0)
        [Sub(VertexanimGroup)] _VertexDirecitonFrequency("运动频率",Float)= 0
        [Header(VertexNoise)][Space(10)]
        [SubNumToggle(VertexanimGroup)] _IsuseNoise("是否用顶点噪波", Float) = 0
        [Sub(VertexanimGroup)] _VertexwindScale("XY:噪波大小||Z:噪波频率||W:噪波强度" , Vector) = (1,1,0.1,0.1)
        
//        [Main(DistortionGroup, _DISTORTION_ON)] _DISTORTION_ON("透明扰动", Float) = 0
//        [Sub(DistortionGroup)] _DistortionMap ("扰动贴图", 2D) = "black" {} 
//        [Space(10)]
//        [Sub(DistortionGroup)] _DistortionMaskPower ("扰动遮罩范围" , Float) = 1
//        [Sub(DistortionGroup)] _DistortionMaskIntensity("扰动遮罩强度" , Float) = 1
//        [Space(10)]
//        [Sub(DistortionGroup)] _DistortionIntensity("扰动强度" ,Float)= 0
//        [Sub(DistortionGroup)] _DistortionSpeed("扰动运动速度" ,Float)= 0

        [Main(MatCapGroup, _MATMAP_ON)] _MATMAP_ON("MatCap", Float) = 0
        [Sub(MatCapGroup)] [NoScaleOffset] _Mat("MatCap",2D) = "black"{}
        [Space(10)]
        [Sub(MatCapGroup)] _MatIntensity2("前面MatCap强度" ,Range(0,1)) = 1
        [Sub(MatCapGroup)] _MatNoise2("前面MatCap扰动强度(基于法线贴图)" ,Range(0,1)) = 0
        [Space(10)]
        [Sub(MatCapGroup)] _MatIntensity("后面MatCap强度" ,Range(0,1)) = 1
        [Sub(MatCapGroup)] _MatNoise("后面MatCap扰动强度(基于法线贴图)" ,Range(0,1)) = 0

        [Main(DiffuseGroup,_DIFFUSE_ON)] _DiffuseOn("明暗", Float) = 1
        [Sub(DiffuseGroup)] _DiffuseIntensity("明暗强度" ,Range(0,1)) = 0.3

        [Main(EFOutlineGroup)]EFOutlineGroup("能量气场", Float) = 1
        [Sub(EFOutlineGroup)] _EFSize("气场大小" ,Float) = 0.3
        [Sub(EFOutlineGroup)] _EFEdgeSmooth("颜色边界平滑度" ,Float) = 1
        [Sub(EFOutlineGroup)] _EFEdgeThreshold("颜色边界阈值" ,Float) = 0.3

        [Main(OutlineGroup)]OutlineGroup("描边", Float) = 1
        [SubNumToggle(OutlineGroup)]_isSmoothNormal("是否开始平滑法线",float)=0
        [Sub(OutlineGroup)] _OutlineWidth("描边大小" ,Float) = 0.3
        [Sub(OutlineGroup)] _OutlineColor("描边颜色" ,Color) = (1,1,1,1)

        [HideInInspector] _FXFresnelRim_ON("边缘光特效", Float) = 0
        [HideInInspector][HDR] _FXFresnelRimColor("边缘光颜色" ,Color) = (1,1,1,1)
        [HideInInspector]  _FXFresnelRimParams("x宽度;y平滑;z强度" ,Vector) = (0.2,0.2,0,0)
        
        [HideInInspector] _DitherFadeoutAmount("DitherFadeoutAmount",float) = 1
    }

    
    SubShader
    {
       
        Tags { "RenderType"="Transparent"
               "Queue"="Transparent"
             }
       
         Pass
         {   
             
             Name "RenderBack"
            Tags
            {
              "LightMode" = "SRPDefaultUnlit" 
            }
            LOD 300
            Cull Front         
            Blend SrcAlpha OneMinusSrcAlpha
            ColorMask RGB
             ZWrite Off
            Stencil
            {
                Ref [_StencilRef]
                Pass [_StencilPassOp]
            }
            HLSLPROGRAM
            #pragma target 4.5
            
            #pragma multi_compile_fog
			#pragma skip_variants FOG_EXP
            // Fog
			#pragma shader_feature FOG_HEIGHT_PASS_APPLY
            
            #pragma vertex vert
            #pragma fragment backFrag
            #pragma shader_feature_local_vertex _VERTEXANIM_ON
            #pragma shader_feature_local_fragment _NORMAL_ON
            #pragma shader_feature_local_fragment _MATMAP_ON
            #pragma shader_feature_local_fragment _DITHER_FADEOUT
            
            #include "Packages/com.xinyuan.rendering/Shaders/Monster/SlimeInput.hlsl"
            #include "Packages/com.xinyuan.rendering/Shaders/Monster/SlimePass.hlsl"
            
            ENDHLSL
        }
         Pass
         {   
             Name "RenderFront"
             Tags { 
              "LightMode" = "UniversalForward"}
             LOD 300
             Cull Back    
             ColorMask RGB
             ZWrite On
             Blend SrcAlpha OneMinusSrcAlpha
            Stencil
            {
                Ref [_StencilRef]
                Pass [_StencilPassOp]
            }
             HLSLPROGRAM
             #pragma target 4.5
             #pragma multi_compile_fog
			 #pragma skip_variants FOG_EXP
             // Fog
			 #pragma shader_feature FOG_HEIGHT_PASS_APPLY
             #pragma vertex vert
             #pragma fragment frontFrag
             #pragma shader_feature_local_vertex _VERTEXANIM_ON
             #pragma shader_feature_local_fragment _NORMAL_ON
             #pragma shader_feature_local_fragment _MATMAP_ON
             #pragma shader_feature_local_fragment _DITHER_FADEOUT
           
            #include "Packages/com.xinyuan.rendering/Shaders/Monster/SlimeInput.hlsl"
            #include "Packages/com.xinyuan.rendering/Shaders/Monster/SlimePass.hlsl"
            
             
             ENDHLSL
         }
         Pass
         {   
             Name "SlimeOutline"
             Tags { "LightMode" = "NiloToonOutline"}
             LOD 300
             Cull Front  
             ColorMask RGB  
             ZWrite On
             Stencil
            {
                Ref [_StencilRef]
                Pass [_StencilPassOp]
            }
             HLSLPROGRAM
             #pragma target 4.5
             
             #pragma multi_compile_fog
			 #pragma skip_variants FOG_EXP
             // Fog
			 #pragma shader_feature FOG_HEIGHT_PASS_APPLY
             
             #pragma vertex vertoutline
             #pragma fragment fragoutline
             #pragma shader_feature_local_vertex _VERTEXANIM_ON
             #pragma shader_feature_local_fragment _DITHER_FADEOUT
             
             #include "Packages/com.xinyuan.rendering/Shaders/Monster/SlimeInput.hlsl"
             #include "Packages/com.xinyuan.rendering/Shaders/Monster/SlimePass.hlsl"        

             ENDHLSL
         }

//         Pass
//         {   
//             Name "XYPostProcessDistortionFX"
//             Tags { 
//              "LightMode" = "XYPostProcessDistortionFX"}
//             LOD 300
//             Cull Back    
//             ZWrite Off
//            
//             HLSLPROGRAM
//             #pragma target 4.5
//             #pragma vertex vert
//             #pragma fragment frag
//             #pragma shader_feature_local_vertex _VERTEXANIM_ON
//             #pragma shader_feature_local_fragment _VERTEXANIM_ON
//             #pragma shader_feature_local_fragment _DISTORTION_ON
//             
//             #include "Packages/com.xinyuan.rendering.char/Shaders/Monster/SlimeInput.hlsl"
//             #include "Packages/com.xinyuan.rendering.char/Shaders/Monster/SlimePass.hlsl"  
//             
//             half4 frag (v2f i) : SV_Target
//            {   
//          
//                half2 uvoffset = 0;
//              #ifdef _DISTORTION_ON    
//                half3 normaldir = normalize(i.normal_dir.xyz);
//                half3 view = half3(i.normal_dir.w,i.tangent.w , i.binormal.w);
//                half frensel =max(0.01,dot(normaldir , normalize(view))) ;             
//                half distortionmask = saturate( pow(frensel , _DistortionMaskPower) * _DistortionMaskIntensity );
//                half2 screenuv = i.screenuv.xy / i.screenuv.w ;
//                half4 Distortion = SAMPLE_TEXTURE2D(_DistortionMap,sampler_DistortionMap,screenuv * _DistortionMap_ST.xy + _DistortionMap_ST.zw * _Time.y * _DistortionSpeed) *2 -1   ;
//                Distortion.xy  =   Distortion.xy * _DistortionIntensity.xx * 0.1;       
//                uvoffset =  Distortion.xy  * saturate(1 - i.vertexcolor.r) * distortionmask  ; 
//              #endif 
//                return half4(uvoffset.x,uvoffset.y,0,0);
//          
//            }
//
//
//             ENDHLSL
//         }
//         
////          Pass
////         {
////            Tags{
////                "LightMode"="ToonEFOutlineArea"
////                 }
////            ZWrite On
////            ZTest Less
////            Cull Back
////            HLSLPROGRAM
////            #pragma target 4.5
////            #pragma vertex EFvert
////            #pragma fragment frag
////
////
////             struct EFAttributes
////            {
////                float4 vertex : POSITION;
////                float3 normal:NORMAL;
////
////            };
////
////            struct Varyings
////            {
////                float4 pos : SV_POSITION;              
////                float3 nDotV : TEXCOORD0 ;
////            };
////            
////            
////            
////            Varyings EFvert (EFAttributes v)
////
////            {  
////                Varyings o = (Varyings)0;
////                half3 positionWS = TransformObjectToWorld(v.vertex.xyz);
////                half3 normalWS = TransformObjectToWorldNormal(v.normal.xyz);
////                half ndotv = saturate(dot(normalize(_WorldSpaceCameraPos - positionWS), normalWS));
////                positionWS += normalWS * _EFSize * 0.1;                 
////                o.nDotV = smoothstep(saturate(ndotv-_EFEdgeSmooth), ndotv, _EFEdgeThreshold);
////                o.pos = TransformWorldToHClip(positionWS);                                      
////
////                return o;
////
////            }
////            half4 frag(Varyings i) : SV_TARGET
////            {              
////                return half4(i.nDotV,1);
////            }     
////            ENDHLSL
////        }
         Pass
         {
             
             name"Shadow"
            Tags{
                "LightMode"="ShadowCaster"
                   "Queue" = "AlphaTest"
            }
            ZWrite On
            ZTest LEqual
            ColorMask 0

            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #pragma shader_feature_local_vertex _VERTEXANIM_ON
            #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            #include "Packages/com.xinyuan.rendering/Shaders/Monster/SlimeInput.hlsl"
            #include "Packages/com.xinyuan.rendering/Shaders/Monster/SlimePass.hlsl"
            
            half _Cutoff;
            half3 _LightDirection;
            
            
            
            v2f ShadowPassVertex (appdata v)

            {  
                v2f o;
              
              
                half3 positionWS = TransformObjectToWorld(v.vertex.xyz);
                half3 normalWS = TransformObjectToWorldNormal(v.normal.xyz);              
                o.uv = v.texcoord;
                o.vertexcolor = v.color.rgba;
                
              #ifdef _VERTEXANIM_ON
                half3 vertexAinmposition = VertexAnim(v.vertex.xy , o.vertexcolor.r , normalWS.xyz);
                v.vertex.xyz += vertexAinmposition;   
                positionWS = TransformObjectToWorld(v.vertex.xyz);      
               
              #endif

                half4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS,_LightDirection));                                     
                o.pos = positionCS;
                return o;

            }
           

            half4 ShadowPassFragment(v2f i) : SV_TARGET
            {
                half alpha = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,i.uv).a;
                clip(alpha - _Cutoff);
                return 0;
            }
            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
	CustomEditor "XYRendering.Editor.XYRendingBaseGUI"
}

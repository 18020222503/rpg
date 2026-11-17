
Shader "XinYuan/Character/ToonCharacter_ShadowCaster"
{
    Properties
    {
        [Main(_ISFACE,_ISFACE)]_IsFace("是否脸部", Float) = 0
        
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Energy Field
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        [Main(_EnergyField)] _EnergyField("能量气场", Float) = 0
        [Sub(_EnergyField)]_EFSize("气场大小", Float) = 0        // Filed Size and Color
        [Sub(_EnergyField)]_EFEdgeThreshold("颜色边界阀值", Range(0,1)) = 0.5
        [Sub(_EnergyField)]_EFEdgeSmooth("颜色边界平滑度", Range(0, 1)) = 0.1
        [SubNumToggle(_EnergyField)]_EFZWrite("深度写入", Float) = 0
        [HideInInspector]_DITHERFADEOUT_ON("_DITHERFADEOUT_ON", Float) = 0
        [HideInInspector]_DitherFadeoutAmount("_DitherFadeoutAmount", Range(0,1)) = 0
        
        [HideInInspector]_PerspectiveRemovalAmount("_PerspectiveRemovalAmount", Range(0,1)) = 0
        [HideInInspector]_PerspectiveRemovalRadius("_PerspectiveRemovalRadius", Float) = 1
        [HideInInspector]_HeadBonePositionWS("_HeadBonePositionWS", Vector) = (0,0,0)
        
    }
    SubShader
    {       
        Tags 
        {
           
            "RenderPipeline" = "UniversalPipeline"

            "ShaderModel"="4.5" 

            "RenderType"="Opaque"
            "UniversalMaterialType" = "Lit"
            "IgnoreProjector" = "True"
            "Queue"="Geometry"
        }


        Pass
        {
            Tags 
            { 
                "LightMode"="ToonEFOutlineArea"
            }            

            Cull Back
            ZTest Always
            ZWrite [_EFZWrite]

            HLSLPROGRAM
            #pragma target 4.5
            #include "Packages/com.xinyuan.rendering/Shaders/ToonCharacter_Shared_ShadowCaster.hlsl"
            #pragma vertex vert
            #pragma fragment frag

            struct EFAttributes
            {
                float3 positionOS : POSITION;
                half3 normalOS : NORMAL;
            };

            struct Varyins
            {
                float4 positionCS : SV_POSITION;
                half4 positionSS : TEXCOORD0;
                half3 nDotV : TEXCOORD1;
            };
            
            Varyins  vert(EFAttributes IN)
            {
                Varyins OUT = (Varyins)0;
                
                
                float3 positionWS = TransformObjectToWorld(IN.positionOS);
                half3 normalWS = TransformObjectToWorldNormal(IN.normalOS);
                
                half ndotv = saturate(dot(normalize(_WorldSpaceCameraPos - positionWS), normalWS));
                positionWS += normalWS * _EFSize * 0.1; 
                
                OUT.nDotV = smoothstep(saturate(ndotv-_EFEdgeSmooth), ndotv, _EFEdgeThreshold);
                OUT.positionCS = TransformWorldToHClip(positionWS);     

                return OUT;
            }

            half4 frag(Varyins IN) : SV_TARGET
            {
            #if _ALPHAOVERRIDE
                return half4(IN.nDotV.xxx, _UseAlphaOverrideVal);
            #else
                return half4(IN.nDotV.xxx, 1);
            #endif
            }
            ENDHLSL
        }

        
 
        // ShadowCaster pass. Used for rendering URP's shadow maps
        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            // more explicit render state to avoid confusion
            ZWrite On // the only goal of this pass is to write depth!
            ZTest LEqual // early exit at Early-Z stage if possible (possible if _AlphaClip is off)            
            ColorMask 0 // we don't care about color, we just want to write depth, ColorMask 0 will save some write bandwidth
            //Cull [_Cull]

            HLSLPROGRAM

            //#pragma exclude_renderers ... // no need to exclude renderers, all platforms will run the same Pass
            #pragma target 4.5 // need ShaderModel 4.5 (= OpenGL ES 3.1 capabilities) because of SRP-batcher

            // #define _DITHER_FADEOUT 1
            // #define _DITHER_FADEOUT_BRANCH 1
            #pragma multi_compile _ _DITHER_FADEOUT

            #define NiloToonShadowCasterPass 1

            #pragma vertex VertexShaderAllWork
            #pragma fragment BaseColorAlphaClipTest // we only need to do Clip(), no need color shading

            // all shader logic written inside this .hlsl, remember to write all #define BEFORE writing #include
            #include "Packages/com.xinyuan.rendering/Shaders/ToonCharacter_Shared_ShadowCaster.hlsl"

            ENDHLSL
        }

        // DepthOnly pass. Used for rendering URP's offscreen depth prepass (you can search DepthOnlyPass.cs in URP package)
        // When URP's depth texture is on, and if CopyDepthPass is not possible due to MSAA for example, 
        // URP will perform this offscreen depth prepass for this toon shader to draw depth into _CameraDepthTexture

        // NiloToonSelfShadowCaster pass. Used for rendering character's self shadow map (not related to URP's shadow map system)
        
        Pass
        {
            Name "NiloToonSelfShadowCaster"
            Tags{"LightMode" = "NiloToonSelfShadowCaster"}

            // more explicit render state to avoid confusion
            ZWrite On // the only goal of this pass is to write depth!
            ZTest LEqual // early exit at Early-Z stage if possible (possible if _AlphaClip is off)            
            ColorMask 0 // we don't care about color, we just want to write depth, ColorMask 0 will save some write bandwidth
            //Cull [_Cull]

            HLSLPROGRAM
            #pragma target 4.5

            #pragma vertex VertexShaderAllWork
            #pragma fragment BaseColorAlphaClipTest // we only need to do Clip(), no need color shading

            // [important]
            // because it is a ShadowCaster pass, define "NiloToonShadowCasterPass" to inject "remove shadow mapping artifact" code into VertexShaderAllWork().
            // We don't want to do outline extrude here because if we do it, the whole mesh will always receive self shadow, 
            // so don't #define ToonShaderIsOutline here
            #define NiloToonCharSelfShadowCasterPass 1
            //#pragma multi_compile_local _DITHER_FADEOUT

            // all shader logic written inside this .hlsl, remember to write all #define BEFORE writing #include
            #include "Packages/com.xinyuan.rendering/Shaders/ToonCharacter_Shared_ShadowCaster.hlsl"

            ENDHLSL
        }
        
    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "XYRendering.Editor.XYRendingBaseGUI" 
}

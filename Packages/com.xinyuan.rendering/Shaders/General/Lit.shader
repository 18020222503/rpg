Shader "XinYuan/Scene/General/Lit"
{
    Properties
    {
		_NoiseMap ("Noise",2D) = "black" {}
    	[Toggle]_VertexAniUseVertexCol("使用顶点色作为动画权重(R)", float) = 0
		_AnimWeightMap("顶点动画权重贴图",2D)  = "white" {}
        _Anchor ("pos",Vector)  = (0,0,0,0)
        _Switcher("控制",range(0,1)) = 0
        _WindDirection("方向",Vector) = (0,0,1)
    	_WindDirectionB("方向2", Vector) = (0,1,0,0)
        _MinMaxStrength ("设置",Vector) =(0,1,0,1) 
        _MinMaxStrengthB ("设置2",Vector) =(0,1,0,1) 
		_UseVertexAnim ("使用顶点动画",Int) = 0
        [Toggle(_UVMove_On)] _UVMove("开启UV流动", Int) = 0
        _UVSpeed ("UVSpeed", Vector) = (0.0, 0.0, 0.0, 0.0)
        [HideInInspector] _WorkflowMode("WorkflowMode", Float) = 1.0
        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        [MainColor] _BaseColor("Color", Color) = (1,1,1,1)
        _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5        
        _RMAOMap("RMAO Map", 2D) = "white" {}   
        _Rounghness("Rounghness Scale", Range(0, 1)) = 1.0
        _Metallic("Metallic Scale", Range(0.0, 1.0)) = 0.0     
        _OcclusionStrength("Occlusion Stren", Range(0.0, 1.0)) = 0.5        
        _BumpScale("Scale", Float) = 1.0
        _BumpMap("Normal Map", 2D) = "bump" {}
        _Parallax("Scale", Range(0.005, 0.08)) = 0.005
        _ParallaxMap("Height Map", 2D) = "black" {}
        [HDR] _EmissionColor("Color", Color) = (0,0,0)
        _EmissionMap("Emission", 2D) = "white" {}
        _DetailMask("Detail Mask", 2D) = "white" {}
        _DetailAlbedoMapScale("Scale", Range(0.0, 2.0)) = 1.0
        _DetailAlbedoMap("Detail Albedo x2", 2D) = "linearGrey" {}
        _DetailNormalMapScale("Scale", Range(0.0, 2.0)) = 1.0
        [Normal] _DetailNormalMap("Normal Map", 2D) = "bump" {}

        [ToggleOff] _SpecularHighlights("Specular Highlights", Float) = 1.0
        [ToggleOff] _EnvironmentReflections("Environment Reflections", Float) = 1.0
    	[Toggle] _DitherOn("开启自动半透明抖动虚化", Float) = 0
        [Toggle] _SphereShadowOn("开启虚片阴影", Float) = 0
    	[Toggle] _EmissionOnly("开启无光照自发光",float) = 0
    	[Toggle] _FlowNormalOn("开启流动法线", Float) = 0
    	[NoScaleOffset] _FlowMap("流动图(RG)", 2d) = "white" {}
    	_FlowOffsetSpeed("流动控制 方向(xy) 速度(z)", vector) = (0,1,0,0)
    	_VertexOffsetOn("开启顶点偏移", Float) = 0
    	[NoScaleOffset] _VertexOffsetMap("顶点偏移强度图", 2d) = "Grey" {}
    	_VertexOffsetParam("顶点偏移参数 强度图流动速度(XY) | 偏移强度(Z)", Vector) = (0,0,1,0)
        // SRP batching compatibility for Clear Coat (Not used in Lit)
        [HideInInspector] _ClearCoatMask("_ClearCoatMask", Float) = 0.0
        [HideInInspector] _ClearCoatSmoothness("_ClearCoatSmoothness", Float) = 0.0
        [HideInInspector]_Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5
        // Blending state
        [HideInInspector] _Surface("__surface", Float) = 0.0
        [HideInInspector] _Blend("__blend", Float) = 0.0
        [HideInInspector] _AlphaClip("__clip", Float) = 0.0
        [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0
        [HideInInspector] _ZWrite("__zw", Float) = 1.0
        [HideInInspector] _Cull("__cull", Float) = 2.0    	
        [HideInInspector] _ColorMask("__ColorMask", Int) = 15 // RGBA Default    	
    	// Bloom Control
        [HideInInspector] _SceneBloomOn("__SceneBloomOn", Float) = 0.0 	
        [HideInInspector] _LightMode("LightMode", Float) = 0.0        
        // Stencil Test
        [HideInInspector][ToggleOff] _StencilOn("__Stencil On", Float) = 0
        [HideInInspector] _StencilRef("__StencilRef", Float) = 0
        [HideInInspector] _StencilReadMask("__StencilReadMask", Float) = 255
        [HideInInspector] _StencilWriteMask("__StencilWriteMask", Float) = 255
        [HideInInspector] _StencilComp("__Stencil Comp", Float) = 0
        [HideInInspector] _StencilPassOp("__StencilPassOp", Float) = 0
        [HideInInspector] _StencilZFailOp("__StencilZFailOp", Float) = 0
        [HideInInspector] _StencilFailOp("__StencilFailOp", Float) = 0
        _ReceiveShadows("Receive Shadows", Float) = 1.0
        _HeightFogEnable("Heightfog Enable", Float) = 1.0                
        // Editmode props
        [HideInInspector] _QueueOffset("Queue offset", Float) = 0.0
        [HideInInspector] _DitherOpacity("_DitherOpacity", Float) = 1
    	[HideInInspector] _DitherType("_DitherType", Float) = 0
        // ObsoleteProperties
        [HideInInspector]_MetallicGlossMap("Metallic", 2D) = "white" {}
        [HideInInspector]_OcclusionMap("Occlusion", 2D) = "white" {}        
        [HideInInspector]_GlossMapScale("Smoothness Scale", Range(0.0, 1.0)) = 1.0
        [HideInInspector]_SmoothnessTextureChannel("Smoothness texture channel", Float) = 0
        [HideInInspector]_SpecColor("Specular", Color) = (0.2, 0.2, 0.2)
        [HideInInspector]_SpecGlossMap("Specular", 2D) = "white" {}        
        [HideInInspector] _MainTex("BaseMap", 2D) = "white" {}
        [HideInInspector] _Color("Base Color", Color) = (1, 1, 1, 1)
        [HideInInspector] _GlossMapScale("Smoothness", Float) = 0.0
        [HideInInspector] _Glossiness("Smoothness", Float) = 0.0
        [HideInInspector] _GlossyReflections("EnvironmentReflections", Float) = 0.0
        [HideInInspector][NoScaleOffset]unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
    }

    SubShader
    {
        //  Forward pass. Shades all light in a single pass. GI + emission + Fog
        Pass
        {
            // Lightmode matches the ShaderPassName set in UniversalRenderPipeline.cs. SRPDefaultUnlit and passes with
            // no LightMode tag are also rendered by Universal Render Pipeline
            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}
			ColorMask[_ColorMask]
            Blend[_SrcBlend][_DstBlend]
            ZWrite[_ZWrite]
            Cull[_Cull]
            Stencil 
            {
                Ref [_StencilRef]
                ReadMask [_StencilReadMask]
                WriteMask [_StencilWriteMask]
                Comp [_StencilComp]
                Pass [_StencilPassOp]
                ZFail [_StencilZFailOp]
                Fail [_StencilFailOp]
            }
            HLSLPROGRAM
            // #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5
            // -------------------------------------
            // Material Keywords
            // #pragma shader_feature_local _NORMALMAP
            #define _NORMALMAP 1
            // 开启depth priming 光照pass 不需要alpha test
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            // #pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON
            #pragma shader_feature_local_fragment _EMISSION
            // #pragma shader_feature_local_fragment _METALLICSPECGLOSSMAP
            // #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            // #pragma shader_feature_local_fragment _OCCLUSIONMAP
            // #pragma shader_feature_local _PARALLAXMAP
            // #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
            // #pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
            // #pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF
            #pragma shader_feature_local_fragment _BLINNPHONG
            // #pragma shader_feature_local_fragment _SPECULAR_SETUP
            #pragma shader_feature_local _RECEIVE_SHADOWS_OFF
            #pragma shader_feature_local _FLOWMAP_NORMAL
            // #pragma shader_feature_local_vertex _VERTEXOFFSET_ON
            #pragma shader_feature_local _ _VERTEXANIM_ON	// 自定义定点动画
            #pragma shader_feature_local _SHADOWTEX_ON  //自定义虚投影
			// TODO 兼容旧版虚化 版署终版后去掉
            // TIPS 深度全部移植到Depthonly [by breen]
            #pragma shader_feature_local_fragment _ _DITHER_LOCAL_ON
            #pragma shader_feature FOG_HEIGHT_PASS_APPLY
            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            // #define _MAIN_LIGHT_SHADOWS_CASCADE 1
            //注释VertexCompress
            #pragma multi_compile_vertex _ _VERTEXCOMPRESSION_ON
            //#define _MAIN_LIGHT_SHADOWS 1
            // #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            //#define _MAIN_LIGHT_SHADOWS_CASCADE 1
            // #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            // #pragma multi_compile_fragment _ _SHADOWS_SOFT
            // #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            // #pragma multi_compile_fragment _ LIGHTMAP_SHADOW_MIXING
            #define LIGHTMAP_SHADOW_MIXING 1
            // #pragma multi_compile_fragment _ SHADOWS_SHADOWMASK
            #define SHADOWS_SHADOWMASK 1
            // #pragma multi_compile_fragment _DEPTH_PRIMING_OFF _DEPTH_PRIMING_ON
            // -------------------------------------
            // Unity defined keywords
            // #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            // #pragma multi_compile_fog
            #pragma multi_compile_fog
            #pragma skip_variants FOG_EXP FOG_EXP2
            // #define 
            // #pragma skip_variants FOG_EXP FOG_EXP2
			// -------------------------------------
            // Debug and editor only Keyword
            // 打包阶段会剔除对应变体
            #pragma multi_compile_fragment _ DEBUG_DISPLAY
            #pragma multi_compile_fragment _ ADDITIONAL_LIGHTS_LIMIT_OFF
            #pragma multi_compile_fragment _ _UNITY_EDITOR_HLSL
            // -------------------------------------
            //--------------------------------------
            // GPU Instancing
            // #pragma multi_compile_instancing
            // #pragma multi_compile _ DOTS_INSTANCING_ON
            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment            
            #define UNITY_SPECCUBE_LOD_STEPS 3
            #include "Packages/com.xinyuan.rendering/Shaders/General/XYOptSceneInput.hlsl"
            #include "Packages/com.xinyuan.rendering/Shaders/General/SceneLitForwardPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]
            Stencil 
            {
                Ref [_StencilRef]
                ReadMask [_StencilReadMask]
                WriteMask [_StencilWriteMask]
                Comp [_StencilComp]
                Pass [_StencilPassOp]
                ZFail [_StencilZFailOp]
                Fail [_StencilFailOp]
            }

            HLSLPROGRAM
            // #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5
            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            // #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            //--------------------------------------
            // GPU Instancing
            // TODO : 有需要再加回来，目前没有lit材质需要使用gpu intanse的操作
            // #pragma multi_compile_instancing
            // #pragma multi_compile _ DOTS_INSTANCING_ON
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment
            #include "Packages/com.xinyuan.rendering/Shaders/General/XYOptSceneInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }
        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}
            ZWrite On
            ColorMask 0
        	Cull [_Cull]
            Stencil 
            {
                Ref [_StencilRef]
                ReadMask [_StencilReadMask]
                WriteMask [_StencilWriteMask]
                Comp [_StencilComp]
                Pass [_StencilPassOp]
                ZFail [_StencilZFailOp]
                Fail [_StencilFailOp]
            }
            HLSLPROGRAM
            // #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5
            #pragma vertex LitPassVertexDepthOnly
            #pragma fragment LitPassFragmentDepthOnly
            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_vertex _VERTEXOFFSET_ON
			#pragma shader_feature _DITHER_ON
            // #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature _DITHER_GLOBAL_ON
            #pragma shader_feature_local _ _VERTEXANIM_ON _VERTEXANIM_ANCHOR_ON	// 自定义定点动画
            #define TIME fmod(_Time.y, HALF_MAX)
            //--------------------------------------
            // GPU Instancing
            // #pragma multi_compile_instancing
            // #pragma multi_compile _ DOTS_INSTANCING_ON
            #include "Packages/com.xinyuan.rendering/Shaders/General/XYOptSceneInput.hlsl"
			#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/DitherFadeoutClipUtil.hlsl"
            // #include "Packages/com.xinyuan.render-pipelines/Shaders/DepthOnlyPass.hlsl"            
			#if !defined(_DITHER_OFF) && defined(_DITHER_GLOBAL_ON)
				#define  REQUIRES_WORLD_SPACE_POS_INTERPOLATOR 1
            #endif            
			struct Attributes
			{
				float3 positionOS   : POSITION;
				float2 texcoord     : TEXCOORD0;
            	float3 normalOS		: TEXCOORD1;
            	half4 color			: COLOR0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			struct Varyings
			{
				float2 uv                       : TEXCOORD0;
#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
				half3 positionWS				: TEXCOORD1;
#endif
				float4 positionCS               : SV_POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			Varyings LitPassVertexDepthOnly(Attributes input)
            {
				Varyings output = (Varyings)0;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
				#ifdef _VERTEXOFFSET_ON
                    half base = SAMPLE_TEXTURE2D_LOD(_VertexOffsetMap, sampler_VertexOffsetMap, (input.texcoord.xy + TIME * _VextexOffsetSpeed), 0).r;
                    half3 vertexOffset = ((base * 2.0) - 1.0) * _VertexOffsetIntensity * input.normalOS;
                    input.positionOS.xyz += vertexOffset;
				#endif
				output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
				INIT_VERTEX_ANIM_DATA
				DOVERTEXANIM
				output.positionCS = TransformObjectToHClip(input.positionOS);
#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
				output.positionWS = TransformObjectToWorld(input.positionOS);
#endif
				return output;	            
            }
			half4 LitPassFragmentDepthOnly(Varyings input) : SV_Target
            {
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            	DO_DITHER(input.positionWS, input.positionCS.xy, _DitherType);
				Alpha(SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a, _BaseColor, _Cutoff);
            	return 0;
            }            
            ENDHLSL
        }

        Pass
        {
            Name "Meta"
            Tags{"LightMode" = "Meta"}
            Cull Off
            Stencil 
            {
                Ref [_StencilRef]
                ReadMask [_StencilReadMask]
                WriteMask [_StencilWriteMask]
                Comp [_StencilComp]
                Pass [_StencilPassOp]
                ZFail [_StencilZFailOp]
                Fail [_StencilFailOp]
            }
            HLSLPROGRAM
            // #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5
            #pragma vertex UniversalVertexMeta
            #pragma fragment UniversalFragmentMetaLit
            // #pragma shader_feature_local_fragment _SPECULAR_SETUP
            #pragma shader_feature_local_fragment _EMISSION
            // #pragma shader_feature_local_fragment _METALLICSPECGLOSSMAP
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            // #pragma shader_feature_local_fragment _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            // #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
            // 旧shader使用高光工作流的keyword
            // #pragma shader_feature_local_fragment _SPECGLOSSMAP
            #include "Packages/com.xinyuan.rendering/Shaders/General/XYOptSceneInput.hlsl"
            #include "Packages/com.xinyuan.rendering/Shaders/General/XYLitMetaPass.hlsl"
            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "XYRendering.Editor.LitShaderGUI"
}

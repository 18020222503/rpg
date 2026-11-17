Shader "XinYuan/FX/Particles/PostProcessScreenDistortion" 
{
	Properties 
	{	
		// Distortion
		_DistortionMap ("Main Distortion Map(RG)", 2D) = "gray" {}
		_DistortionWrapMode ("Main Wrap Mode", Float) = 0.0
		_DistortionUVMoveMode ("Main UV Move Mode", Float) = 0.0  // 0-Off 1-OffsetAnimated 2-CustomData_ZW
		[Toggle]_DistortionScreenUV("Main Screen UV",Float) = 0
		_DistortionUSpeed ("Main U Speed", Float) = 0.0
		_DistortionVSpeed ("Main V Speed", Float) = 0.0
		//_DistortionRotAngle ("Main Rotate Angle", Float) = 0.0
		_DistortionStrenByCustomData1Y ("Distortion Stren By CumstomData1 Y", Float) = 0.0		
		_DistortionStren("Distortion Stren", Range(0, 1)) = 0.5
		
		_DetailDistortionMap ("Detail Distortion Map", 2D) = "white" {}
		_DetailDistortionWrapMode ("Detail Wrap Mode", Float) = 0.0
		_DetailDistortionUVMoveMode ("Detail UV Move Mode", Float) = 0.0
		_DetailDistortionUSpeed ("Detail U Speed", Float) = 0.0
		_DetailDistortionVSpeed ("Detail V Speed", Float) = 0.0
		//_DetailDistortionRotAngle ("Detail Rotate Angle", Float) = 0.0
		// Mask
		_MaskMap ("Mask Map(R)", 2D) = "white" {}
		_MaskWrapMode ("Mask Wrap Mode", Float) = 0.0 
		_MaskUVMoveMode ("Mask UV Move Mode", Float) = 0.0
		_MaskUSpeed ("Mask U Speed", Float) = 0.0
		_MaskVSpped ("Mask V Speed", Float) = 0.0
		//_MaskRotAngle ("Mask Rotate Angle", Float) = 0.0
		_MaskStren ("Mask Strength", Range(0,1)) = 1.0
		
		_Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
		
		[Toggle]_TransparentZWrite ("Z Write", Float) = 0.0
		
		[Toggle(_DEPTH_OFFSET_ON)] _DepthOffsetOn("开启深度偏移", Float) = 0
	    _ZOffset("开启深度偏移", Float) = 0

		 // Blending state
		[HideInInspector] _Surface("__surface", Float) = 1.0
		[HideInInspector] _Blend("__blend", Float) = 1.0
        [HideInInspector] _AlphaClip("__clip", Float) = 0.0
        [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0
        [HideInInspector] _ZWrite("__ZWrite", Float) = 0.0
		[HideInInspector] _Cull("__Cull", Float) = 0.0

        [HideInInspector] _QueueOffset("Queue offset", Float) = 0

	}

	SubShader 
	{
		Tags
		{
			"RenderType"="Transparent"
			"Queue"="Transparent" 
			"RenderPipeline"="UniversalPipeline" 
			"IgnoreProjector"="True" 
			"PreviewType"="Plane" 
			"PerformanceChecks"="False" 
		}
		
		Pass 
		{
			Tags{"LightMode" = "XYPostProcessDistortionFX"}

			Cull [_Cull]
			ZTest LEqual
			ZWrite [_ZWrite]
			Blend One One
			
			HLSLPROGRAM

            #pragma target 4.5

			#pragma vertex vert
			#pragma fragment frag
			
			//#pragma shader_feature_local_fragment _MASK_MAP
			#define _MASK_MAP
			//#pragma shader_feature_local_fragment _DISTORTION_MAP
			#define _DISTORTION_MAP
			#pragma shader_feature_local_fragment _ALPHATEST_ON	
			#pragma shader_feature_local _DEPTH_OFFSET_ON

            #pragma multi_compile_instancing

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.xinyuan.rendering/ShaderLibrary/FX/FXCommonGlobalVar.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
			#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/Util.hlsl"
			#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/UVHelper.hlsl"
			#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/ColorSpace.hlsl"

			TEXTURE2D(_DistortionMap);          //SAMPLER(sampler_DistortionMap);
			TEXTURE2D(_DetailDistortionMap);    //SAMPLER(sampler_DetailDistortionMap);
			TEXTURE2D(_MaskMap);                //SAMPLER(sampler_MaskMap);
		    //感觉已经弃用先注释掉
			//TEXTURE2D(_DitherMask);				SamplerState DitherMask_point_clamp_sampler;


			CBUFFER_START(UnityPerMaterial)
			float4 _DistortionMap_ST;
			float4 _DetailDistortionMap_ST;
			float4 _MaskMap_ST;

			// distortion
			half _DistortionWrapMode;
			half _DistortionUVMoveMode;
			half _DistortionScreenUV;
			half _DistortionUSpeed;
			half _DistortionVSpeed;
			//half _DistortionRotAngle;
			half _DistortionStrenByCustomData1Y;
			half _DistortionStren;

			half _DetailDistortionWrapMode;
			half _DetailDistortionUVMoveMode;
			half _DetailDistortionUSpeed;
			half _DetailDistortionVSpeed;
			//half _DetailDistortionRotAngle;

			// Mask
			half _MaskWrapMode;
			half _MaskUVMoveMode;
			half _MaskUSpeed;
			half _MaskVSpped;
			//half _MaskRotAngle;
			half _MaskStren;

			half _Cutoff;

			half _ZOffset;

			CBUFFER_END


			#define TIME fmod(_Time.y, HALF_MAX)
			
			struct Attributes
			{
				float3 positionOS				: POSITION;
				float2 uv						: TEXCOORD0;
			    float4 customData				: TEXCOORD1;
			    UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct Varyings
			{
				float4 positionCS				: SV_POSITION;
				float4 distortionUV				: TEXCOORD0;
				float2 maskUV					: TEXCOORD1;
				half4 ScreenPosition			: TEXCOORD2;
				half4 customData				: TEXCOORD3;
			    UNITY_VERTEX_INPUT_INSTANCE_ID
			};



			Varyings vert (Attributes i)
			{
				Varyings o = (Varyings)0;
				UNITY_SETUP_INSTANCE_ID(i);
			    UNITY_TRANSFER_INSTANCE_ID(i, o);
				
				o.positionCS = TransformObjectToHClip(i.positionOS);
				#if defined(_DEPTH_OFFSET_ON)
				o.positionCS += _ZOffset;
				#endif
				o.ScreenPosition = ComputeScreenPos(o.positionCS);
				
				o.distortionUV.xy = UVHelper_TransformUV_NotWarp(i.uv, _DistortionMap_ST, float2(_DistortionUSpeed, _DistortionVSpeed), i.customData.zw, 0, _DistortionUVMoveMode);
				o.distortionUV.zw = UVHelper_TransformUV_NotWarp(i.uv, _DetailDistortionMap_ST, float2(_DetailDistortionUSpeed, _DetailDistortionVSpeed), 0, 0, _DetailDistortionUVMoveMode);
				o.distortionUV.xy = lerp(o.distortionUV.xy , (o.ScreenPosition.xy/o.ScreenPosition.w),_DistortionScreenUV);
				o.maskUV =  UVHelper_TransformUV_NotWarp(i.uv, _MaskMap_ST, float2(_MaskUSpeed, _MaskVSpped), 0, 0, _MaskUVMoveMode);
				o.customData = i.customData;

				return o;
			}


			half4 frag(Varyings i) : SV_Target
			{
			    UNITY_SETUP_INSTANCE_ID(i);

				half4 result = 0;

				// Mask
			#if defined(_MASK_MAP)
				half mask = FX_FAST_SRGB_TO_LINEAR(SAMPLE_TEXTURE2D_WARP(_MaskMap, i.maskUV,_MaskWrapMode).r);
			#else
				half mask = 1;
			#endif
				
				// Distortion
				//float2 uv = i.ScreenPosition.xy / i.ScreenPosition.w;
				float2 uvOffset = 0;
			#if defined(_DISTORTION_MAP)
				half4 mainDistortion = FX_FAST_SRGB_TO_LINEAR(SAMPLE_TEXTURE2D_WARP(_DistortionMap, i.distortionUV.xy ,_DistortionWrapMode));
				mainDistortion.rgb = mainDistortion.rgb * 2 - 1;
				half4 detailDistortion = FX_FAST_SRGB_TO_LINEAR(SAMPLE_TEXTURE2D_WARP(_DetailDistortionMap, i.distortionUV.zw ,_DetailDistortionWrapMode));
				detailDistortion.rgb = detailDistortion.rgb * 2 - 1;
				half2 distortion =  mainDistortion.rg * mainDistortion.a * detailDistortion.rg * detailDistortion.a * lerp(_DistortionStren, saturate(i.customData.y), _DistortionStrenByCustomData1Y) * 0.1;
				uvOffset =  lerp(distortion, distortion * mask, _MaskStren);
			#endif	
			    //感觉已经弃用先注释掉
				//float ditherMask = SAMPLE_TEXTURE2D(_DitherMask, DitherMask_point_clamp_sampler, uv + uvOffset);
				//uvOffset *= ditherMask;

			#if defined(_ALPHATEST_ON) && defined(_DISTORTION_MAP)
				half alphaClip = mainDistortion.a * detailDistortion.a * mask;
				clip( alphaClip - _Cutoff);
			#endif

				
				return half4(uvOffset.x, uvOffset.y, 0, 0);
			}

			
			ENDHLSL
		}

	}

	FallBack "Hidden/Universal Render Pipeline/FallbackError"
	CustomEditor "XYRendering.Editor.PostProcessScreenDistortionGUI"
}

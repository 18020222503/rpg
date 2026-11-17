// 把脚下阴影图（_PortedShadowMask）叠到地面上，对应原项目场景 shader 里的“虚投影”一段：
//   shadowuv = _WorldToClip * 世界坐标；shadow = 1 - saturate(mask * 2 - 1)；color *= shadow
// 原项目是每个场景 shader 自己采样，这里改成画面后处理：用深度图还原世界坐标，再按同样的公式计算。
// 角色像素（_PortedCharMask = 1）不压暗，和原项目角色 shader 不采样这张图一致。
Shader "Hidden/Ported/BlobShadowApply"
{
	SubShader
	{
		Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
		ZTest Always ZWrite Off Cull Off

		// 0：角色遮罩。用角色的网格画 1，深度和场景深度比较，被挡住的部分不算
		Pass
		{
			Name "CharMask"
			ZTest LEqual
			ZWrite Off
			Cull Off
			Offset -1, -1   // 和场景深度里的同一网格比较，往前推一点免得自己挡自己

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			float4 vert(float4 positionOS : POSITION) : SV_POSITION { return TransformObjectToHClip(positionOS.xyz); }
			half4 frag() : SV_Target { return 1; }
			ENDHLSL
		}

		// 1：叠加阴影，乘法混合到画面上
		Pass
		{
			Name "Apply"
			Blend DstColor Zero
			ColorMask RGB

			HLSLPROGRAM
			#pragma vertex Vert
			#pragma fragment Frag
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

			TEXTURE2D_X_FLOAT(_PortedSceneDepth);
			TEXTURE2D_X(_PortedCharMask);
			TEXTURE2D(_PortedShadowMask);
			float4x4 _PortedWorldToClip;
			float _PortedShadowMaxHeight;

			half4 Frag(Varyings input) : SV_Target
			{
				uint2 pixel = uint2(input.positionCS.xy);
				float depth = LOAD_TEXTURE2D_X(_PortedSceneDepth, pixel).r;
			#if UNITY_REVERSED_Z
				if (depth <= 0) return 1;             // 天空
			#else
				if (depth >= 1) return 1;
				depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, depth);
			#endif
				if (LOAD_TEXTURE2D_X(_PortedCharMask, pixel).r > 0.5) return 1;

				float2 positionSS = input.positionCS.xy * _ScreenSize.zw;
				float3 positionWS = ComputeWorldSpacePosition(positionSS, depth, UNITY_MATRIX_I_VP);
				// 原项目只在地面/草的 shader 里压暗，这里用高度近似：比脚底高出太多的像素不处理
				if (positionWS.y > _PortedShadowMaxHeight) return 1;

				float4 shadowuv = mul(_PortedWorldToClip, float4(positionWS, 1));
				float3 selfshadow = shadowuv.xyz / shadowuv.w;
				selfshadow.xy = selfshadow.xy * 0.5 + 0.5;
			#if UNITY_REVERSED_Z
				selfshadow.y = 1 - selfshadow.y;
			#endif
				if (any(selfshadow.xy < 0) || any(selfshadow.xy > 1)) return 1;

				half mask = SAMPLE_TEXTURE2D_LOD(_PortedShadowMask, sampler_LinearClamp, selfshadow.xy, 0).r;
				half shadow = saturate(1 - saturate(mask * 2 - 1));
				return half4(shadow, shadow, shadow, 1);
			}
			ENDHLSL
		}
	}
}

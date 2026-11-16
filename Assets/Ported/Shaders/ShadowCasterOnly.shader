// qq13 角色网格上的第二个材质槽（ToonCharacter_ShadowCaster）只负责写阴影深度、不画颜色。
// 这里保持同样的行为：只有 ShadowCaster pass，屏幕上不可见。
// 原项目的脚底假阴影（ShadowGenerator）也用这个，URP 自己的实时阴影已经够用。
Shader "Ported/ShadowCasterOnly"
{
	Properties
	{
		_Cutoff("Alpha Cutoff", Range(0, 1)) = 0.5
	}

	SubShader
	{
		Tags { "RenderType"="Opaque" "Queue"="Geometry" "RenderPipeline"="UniversalPipeline" }

		Pass
		{
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }

			ZWrite On
			ZTest LEqual
			ColorMask 0
			Cull Back

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

			float3 _LightDirection;
			float3 _LightPosition;

			struct Attributes
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
			};

			float4 vert(Attributes i) : SV_POSITION
			{
				float3 positionWS = TransformObjectToWorld(i.positionOS.xyz);
				float3 normalWS = TransformObjectToWorldNormal(i.normalOS);
			#if _CASTING_PUNCTUAL_LIGHT_SHADOW
				float3 lightDir = normalize(_LightPosition - positionWS);
			#else
				float3 lightDir = _LightDirection;
			#endif
				float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDir));
			#if UNITY_REVERSED_Z
				positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
			#else
				positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
			#endif
				return positionCS;
			}

			half4 frag() : SV_Target
			{
				return 0;
			}
			ENDHLSL
		}
	}
}

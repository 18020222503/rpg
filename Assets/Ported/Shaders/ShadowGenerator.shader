// qq13 角色脚下假阴影面片（Ch_11000_jueseyinying）用的 shader（XinYuan/Scene/SphereShadow/ShadowGenerator）原样移植。
// 面片本身不在画面里显示：只有 "ShadowGenerator" 这个 pass，由 PortedBlobShadow 用俯视正交相机画进一张灰底阴影图，
// 再在地面上按世界坐标采样这张图压暗。和原项目 DrawShadowRTFeature 的流程一致。
Shader "Ported/ShadowGenerator"
{
	Properties
	{
		_Shadowtex("椭圆阴影", 2D) = "black" {}
	}

	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent" "RenderPipeline"="UniversalPipeline" }

		Pass
		{
			Name "ShadowGenerator"
			Tags { "LightMode" = "ShadowGenerator" }
			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite Off

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			TEXTURE2D(_Shadowtex);
			SAMPLER(sampler_Shadowtex_LinearClamp);

			CBUFFER_START(UnityPerMaterial)
			float4 _Shadowtex_ST;
			CBUFFER_END

			struct Attributes { float4 positionOS : POSITION; float2 uv : TEXCOORD0; };
			struct Varyings { float4 positionCS : SV_POSITION; float2 uv : TEXCOORD0; };

			// 俯视阴影相机的 VP 矩阵，由 PortedBlobShadow 设置。不改全局相机矩阵，免得影响之后画的透明物体
			float4x4 _PortedShadowVP;

			Varyings vert(Attributes v)
			{
				Varyings o;
				o.positionCS = mul(_PortedShadowVP, float4(TransformObjectToWorld(v.positionOS.xyz), 1));
				o.uv = TRANSFORM_TEX(v.uv, _Shadowtex);
				return o;
			}

			half4 frag(Varyings i) : SV_Target
			{
				half r = SAMPLE_TEXTURE2D(_Shadowtex, sampler_Shadowtex_LinearClamp, i.uv).r;
				return half4(1, 1, 1, r);
			}
			ENDHLSL
		}
	}
}

// qq13 特效 Bloom 的移植（原 com.xinyuan.rendering/Shaders/PostProcessing/Bloom.shader 的逐物体模式 + UberPost 里的合成）。
// 原项目的特效 shader 额外输出一张 Bloom 图（颜色 × _BloomTint × _BloomOn），后处理只对这张图做模糊，再叠回画面，
// 所以只有特效发光，场景不受影响。这里由 PortedFXBloom.cs 驱动：
//   0 Prefilter   特效 Bloom 图 13 点降采样到半分辨率
//   1 BlurH / 2 BlurV   每级 mip 的高斯模糊
//   3 Upsample    逐级上采样，按 scatter 混合
//   4 Composite   在线性空间把 Bloom 叠到画面上
Shader "Hidden/Ported/FXBloom"
{
	HLSLINCLUDE
	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
	#include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
	#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"

	TEXTURE2D_X(_LowMip);
	float4 _LowMip_TexelSize;
	TEXTURE2D_X(_PortedBloomTex);
	float4 _PortedBloomTex_TexelSize;
	float4 _PortedBloomParams; // x scatter, y clamp, z intensity
	float4 _PortedBloomTint;

	half4 SampleSrc(float2 uv) { return SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_LinearClamp, uv); }

	half4 FragPrefilter(Varyings input) : SV_Target
	{
		float2 uv = input.texcoord;
		float2 t = _BlitTexture_TexelSize.xy;
		half4 A = SampleSrc(uv + t * float2(-1.0, -1.0));
		half4 B = SampleSrc(uv + t * float2( 0.0, -1.0));
		half4 C = SampleSrc(uv + t * float2( 1.0, -1.0));
		half4 D = SampleSrc(uv + t * float2(-0.5, -0.5));
		half4 E = SampleSrc(uv + t * float2( 0.5, -0.5));
		half4 F = SampleSrc(uv + t * float2(-1.0,  0.0));
		half4 G = SampleSrc(uv);
		half4 H = SampleSrc(uv + t * float2( 1.0,  0.0));
		half4 I = SampleSrc(uv + t * float2(-0.5,  0.5));
		half4 J = SampleSrc(uv + t * float2( 0.5,  0.5));
		half4 K = SampleSrc(uv + t * float2(-1.0,  1.0));
		half4 L = SampleSrc(uv + t * float2( 0.0,  1.0));
		half4 M = SampleSrc(uv + t * float2( 1.0,  1.0));

		half2 div = (1.0 / 4.0) * half2(0.5, 0.125);
		half4 o = (D + E + I + J) * div.x;
		o += (A + B + G + F) * div.y;
		o += (B + C + H + G) * div.y;
		o += (F + G + L + K) * div.y;
		o += (G + H + M + L) * div.y;

		half3 color = clamp(o.rgb, 0, _PortedBloomParams.y);
		return half4(color, 1);
	}

	half4 FragBlurH(Varyings input) : SV_Target
	{
		float texelSize = _BlitTexture_TexelSize.x * 2.0;
		float2 uv = input.texcoord;
		half3 c0 = SampleSrc(uv - float2(texelSize * 4.0, 0.0)).rgb;
		half3 c1 = SampleSrc(uv - float2(texelSize * 3.0, 0.0)).rgb;
		half3 c2 = SampleSrc(uv - float2(texelSize * 2.0, 0.0)).rgb;
		half3 c3 = SampleSrc(uv - float2(texelSize * 1.0, 0.0)).rgb;
		half3 c4 = SampleSrc(uv).rgb;
		half3 c5 = SampleSrc(uv + float2(texelSize * 1.0, 0.0)).rgb;
		half3 c6 = SampleSrc(uv + float2(texelSize * 2.0, 0.0)).rgb;
		half3 c7 = SampleSrc(uv + float2(texelSize * 3.0, 0.0)).rgb;
		half3 c8 = SampleSrc(uv + float2(texelSize * 4.0, 0.0)).rgb;
		half3 color = c0 * 0.01621622 + c1 * 0.05405405 + c2 * 0.12162162 + c3 * 0.19459459
		            + c4 * 0.22702703
		            + c5 * 0.19459459 + c6 * 0.12162162 + c7 * 0.05405405 + c8 * 0.01621622;
		return half4(color, 1);
	}

	half4 FragBlurV(Varyings input) : SV_Target
	{
		float texelSize = _BlitTexture_TexelSize.y;
		float2 uv = input.texcoord;
		half3 c0 = SampleSrc(uv - float2(0.0, texelSize * 3.23076923)).rgb;
		half3 c1 = SampleSrc(uv - float2(0.0, texelSize * 1.38461538)).rgb;
		half3 c2 = SampleSrc(uv).rgb;
		half3 c3 = SampleSrc(uv + float2(0.0, texelSize * 1.38461538)).rgb;
		half3 c4 = SampleSrc(uv + float2(0.0, texelSize * 3.23076923)).rgb;
		half3 color = c0 * 0.07027027 + c1 * 0.31621622 + c2 * 0.22702703 + c3 * 0.31621622 + c4 * 0.07027027;
		return half4(color, 1);
	}

	half4 FragUpsample(Varyings input) : SV_Target
	{
		float2 uv = input.texcoord;
		half3 highMip = SampleSrc(uv).rgb;
		half3 lowMip = SampleTexture2DBicubic(TEXTURE2D_X_ARGS(_LowMip, sampler_LinearClamp), uv, _LowMip_TexelSize.zwxy, (1.0).xx, 0).rgb;
		return half4(lerp(highMip, lowMip, _PortedBloomParams.x), 1);
	}

	// 原 UberPost：Gamma 工程里先把画面转到线性空间，加上 Bloom，再转回去
	half4 FragComposite(Varyings input) : SV_Target
	{
		float2 uv = input.texcoord;
		half4 color = SampleSrc(uv);
		half3 bloom = SampleTexture2DBicubic(TEXTURE2D_X_ARGS(_PortedBloomTex, sampler_LinearClamp), uv, _PortedBloomTex_TexelSize.zwxy, (1.0).xx, 0).rgb;
		bloom *= _PortedBloomParams.z * _PortedBloomTint.rgb;
	#if UNITY_COLORSPACE_GAMMA
		color.rgb = SRGBToLinear(color.rgb);
		color.rgb += bloom;
		color.rgb = LinearToSRGB(max(color.rgb, 0));
	#else
		color.rgb += bloom;
	#endif
		return color;
	}
	ENDHLSL

	SubShader
	{
		Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
		ZTest Always ZWrite Off Cull Off

		Pass { Name "Prefilter" HLSLPROGRAM
			#pragma vertex Vert
			#pragma fragment FragPrefilter
		ENDHLSL }

		Pass { Name "BlurH" HLSLPROGRAM
			#pragma vertex Vert
			#pragma fragment FragBlurH
		ENDHLSL }

		Pass { Name "BlurV" HLSLPROGRAM
			#pragma vertex Vert
			#pragma fragment FragBlurV
		ENDHLSL }

		Pass { Name "Upsample" HLSLPROGRAM
			#pragma vertex Vert
			#pragma fragment FragUpsample
		ENDHLSL }

		Pass { Name "Composite" HLSLPROGRAM
			#pragma vertex Vert
			#pragma fragment FragComposite
		ENDHLSL }
	}
}

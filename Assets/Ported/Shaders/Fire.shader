// qq13 火焰特效 shader（XinYuan/FX/Particles/Fire）的 URP 移植版。
// 火焰形状来自火焰贴图（R 外焰 / G 内焰 / B 透明度）+ 噪声扰动 + 溶解，
// 这些丢了的话火焰会画成整块方形。属性名和计算顺序和原版一致，原材质只换 shader 引用即可直接用。
// 没有移植的部分：雾、全局反相效果、GPU Instancing。
Shader "Ported/FX/Fire"
{
	Properties
	{
		[NoScaleOffset] _FireTex("火焰贴图", 2D) = "white" {}
		[HDR] _InnerCol("火焰内部颜色(RGB)", Color) = (1,0,0,1)
		[HDR] _OuterCol("火焰外部颜色(RGBA)", Color) = (1, 1, 0, 1)
		[HDR] _MainCol("火焰主颜色(RGBA)", Color) = (1, 1, 1, 1)
		_FireTexUVMoveMode("UV流动模式", Float) = 0
		_FireTexUVWrapMode("UV Wrap模式", Float) = 0
		_FireTexUSpeed("Fire U Speed", Float) = 0
		_FireTexVSpeed("Fire V Speed", Float) = 0
		_FresnelScale("Fresnel Scale", Float) = 0
		_FresnelPower("Fresnel Power", Float) = 0
		_FresnelMaskOn("开启Fresnel遮罩模拟", Float) = 0
		_FresnelMaskMul("Fresnel遮罩范围", Range(0, 5)) = 1
		_FresnelMaskPow("Fresnel遮罩过渡", Range(0, 100)) = 1
		_RemapNewMin("RemapNewMin", Float) = 0
		_RemapNewMax("RemapNewMax", Float) = 1

		_NoiseTex("噪声贴图", 2D) = "black" {}
		_NoiseTexUVWrapMode("UV Wrap模式", Float) = 0
		_InvertNoise("反向Noise", Float) = 0
		_NoiseStrenByCustomData("噪声强度 By Customdata", Float) = 0
		_NoiseStren("噪声强度", Float) = 1
		_NoiseUSpeed("Noise U Speed", Float) = 0
		_NoiseVSpeed("Noise V Speed", Float) = 0

		_Noise2Tex("噪声2贴图", 2D) = "black" {}
		_Noise2TexUVWrapMode("UV Wrap模式", Float) = 0
		_InvertNoise2("反向Noise2", Float) = 0
		_Noise2StrenByCustomData("噪声2强度 By Customdata", Float) = 0
		_Noise2Stren("噪声2强度", Float) = 1
		_Noise2USpeed("Noise2 U Speed", Float) = 0
		_Noise2VSpeed("Noise2 V Speed", Float) = 0

		_MaskType("遮罩类型", Float) = 0
		_NoiseMask("遮罩贴图(R)", 2D) = "white" {}
		_NoiseMaskPow("遮罩Power", Float) = 1
		_InvertMask("反向Mask", Float) = 0

		_DisplacementOn ("开启顶点置换", Float) = 0
		_DisplaceMap("置换图（R）", 2D) = "black" {}
		_InvertDisplaceMap("反向置换图", Float) = 0
		_DisplaceUVWrapMode("置换UV Wrap模式", Float) = 0
		_DisplaceUVMoveMode("置换UV流动模式", Float) = 0
		_DisplaceUSpeed("置换U速度", Float) = 0
		_DisplaceVSpeed("置换V速度", Float) = 0
		_DisplaceStrenByCustomData("置换强度 By Customdata", Float) = 0
		_DisplaceStren("置换强度", Float) = 0.5

		_DissovleOn("开启溶解", Float) = 0
		_DissMap ("溶解图（R）", 2D) = "white" {}
		_InvertDissMap("反向溶解图", Float) = 0
		_DissUVWrapMode("溶解UV Wrap模式", Float) = 0
		_DissUVMoveMode("溶解UV流动模式", Float) = 0
		_DissUSpeed("溶解U速度", Float) = 0
		_DissVSpeed("溶解V速度", Float) = 0
		_DissStrenByCustomData("溶解强度 By Customdata", Float) = 0
		_DissStren ("溶解强度", Range(0, 1)) = 1
		_DissSmooth("溶解平滑度", Range(0, 1)) = 0.25
		_DissovleRandomOn("开启随机溶解", Float) = 0

		_AlphaMaskOn("开启AlphaMask", Float) = 0
		_AlphaMaskUVWrapMode("UV Wrap模式", Float) = 0
		_AlphaMaskTex("遮罩贴图(R)", 2D) = "white" {}
		_AlphaMaskStren("遮罩强度", Range(0, 1)) = 1
		_AlphaMaskDistort("遮罩扰乱强度", Float) = 0
		_InvertAlphaMask("反向Mask", Float) = 0

		_AlphaSimulateOn("开启透明度模拟火焰形态", Float) = 0
		_Cutoff("Alpha Cutoff", Range(0,1)) = 0.5

		[Toggle]_BloomOn("开启Bloom", Float) = 1
		[HDR]_BloomTint("Bloom颜色", Color) = (1, 1, 1, 1)

		_AlphaMultiplyer ("GamePlay Alpha 相乘系数", Range(0, 1)) = 1

		[HideInInspector] _SrcBlend("__src", Float) = 1.0
		[HideInInspector] _DstBlend("__dst", Float) = 0.0
		[HideInInspector] _ZWrite("__ZWrite", Float) = 0.0
		[HideInInspector] _Cull("__Cull", Float) = 0.0

		_DepthOffsetOn("开启深度偏移", Float) = 0
		_ZOffsetViewSpace("Z Offset ViewSpace", Float) = 0
	}

	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent" "RenderPipeline"="UniversalPipeline" "IgnoreProjector"="True" }

		HLSLINCLUDE
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		#include "PortedFXCommon.hlsl"

		TEXTURE2D(_FireTex);
		TEXTURE2D(_NoiseTex);
		TEXTURE2D(_Noise2Tex);
		TEXTURE2D(_NoiseMask);
		TEXTURE2D(_DisplaceMap);
		TEXTURE2D(_DissMap);
		TEXTURE2D(_AlphaMaskTex);

		CBUFFER_START(UnityPerMaterial)
		float4 _FireTex_ST;
		float4 _NoiseTex_ST;
		float4 _Noise2Tex_ST;
		float4 _NoiseMask_ST;
		float4 _DisplaceMap_ST;
		float4 _DissMap_ST;
		float4 _AlphaMaskTex_ST;

		half4 _InnerCol;
		half4 _OuterCol;
		half4 _MainCol;
		half _FireTexUVMoveMode;
		half _FireTexUVWrapMode;
		half _FireTexUSpeed;
		half _FireTexVSpeed;
		half _FresnelScale;
		half _FresnelPower;
		half _RemapNewMin;
		half _RemapNewMax;

		half _NoiseStrenByCustomData;
		half _NoiseTexUVWrapMode;
		half _NoiseStren;
		half _NoiseUSpeed;
		half _NoiseVSpeed;
		half _InvertNoise;

		half _AlphaSimulateOn;
		half _Noise2StrenByCustomData;
		half _Noise2TexUVWrapMode;
		half _Noise2Stren;
		half _Noise2USpeed;
		half _Noise2VSpeed;
		half _InvertNoise2;

		half _MaskType;
		half _NoiseMaskPow;
		half _InvertMask;

		half _DisplacementOn;
		half _InvertDisplaceMap;
		half _DisplaceUVWrapMode;
		half _DisplaceUVMoveMode;
		half _DisplaceUSpeed;
		half _DisplaceVSpeed;
		half _DisplaceStrenByCustomData;
		half _DisplaceStren;

		half _DissovleOn;
		half _InvertDissMap;
		half _DissUVWrapMode;
		half _DissUVMoveMode;
		half _DissUSpeed;
		half _DissVSpeed;
		half _DissStren;
		half _DissSmooth;
		half _DissStrenByCustomData;
		half _DissovleRandomOn;

		half _AlphaMaskOn;
		half _AlphaMaskStren;
		half _InvertAlphaMask;
		half _AlphaMaskDistort;
		half _AlphaMaskUVWrapMode;
		half _AlphaMultiplyer;

		half _BloomOn;
		half4 _BloomTint;

		half _Cutoff;
		half _DepthOffsetOn;
		half _ZOffsetViewSpace;

		half _FresnelMaskOn;
		half _FresnelMaskMul;
		half _FresnelMaskPow;
		CBUFFER_END

		float _GlobalFXBloomOn;
		float _GlobalFXBloomIntensity;
		half3 BloomMultiplier() { return _GlobalFXBloomOn > 0 ? _BloomTint.rgb * _GlobalFXBloomIntensity : _BloomTint.rgb; }

		// 原 UVHelper_TransformUV_NotWarp（不含旋转，Fire 里旋转角都是 0）
		float2 MoveUV(float2 uv, float4 st, float2 speed, float2 customZW, half moveMode)
		{
			float2 moved = (uint)moveMode == 2 ? customZW : st.zw + frac(speed * _Time.y);
			float2 offset = moveMode > 0 ? moved : st.zw;
			return uv * st.xy + offset;
		}

		float RemapRange(float x, float inMin, float inMax, float outMin, float outMax)
		{
			return lerp(outMin, outMax, (x - inMin) / (inMax - inMin));
		}

		half4 SampleNoise(TEXTURE2D_PARAM(tex, unusedSampler), float2 uv, half wrapMode, half invert, half strenByCustom, float customY, half stren, bool lod)
		{
			half4 n = lod ? SampleWrapLod(TEXTURE2D_ARGS(tex, sampler_linear_repeat), uv, wrapMode)
			              : SampleWrap(TEXTURE2D_ARGS(tex, sampler_linear_repeat), uv, wrapMode);
			n = FX_DATA(n);
			n = invert > 0 ? 1 - n : n;
			return n * (strenByCustom > 0 ? customY : stren);
		}
		#define SAMPLE_NOISE(tex, uv, wrap, inv, byCustom, cy, stren, lod) SampleNoise(TEXTURE2D_ARGS(tex, sampler_linear_repeat), uv, wrap, inv, byCustom, cy, stren, lod)

		struct Attributes
		{
			float3 positionOS : POSITION;
			float3 normalOS : NORMAL;
			float2 baseUV : TEXCOORD0;
			float4 customData : TEXCOORD1;
			float4 customData2 : TEXCOORD2;
		};

		struct Varyings
		{
			float4 positionCS : SV_POSITION;
			float4 fireAndBaseUV : TEXCOORD0;
			float4 noiseAndMaskUV : TEXCOORD1;
			float4 dissUV : TEXCOORD2;
			float4 customData : TEXCOORD3;
			float4 noise2UVAndRandom : TEXCOORD4;
			float3 normalWS : TEXCOORD5;
			float3 positionWS : TEXCOORD6;
		};

		Varyings vert(Attributes a)
		{
			Varyings v = (Varyings)0;
			float2 baseUV = a.baseUV;

			v.noiseAndMaskUV.xy = MoveUV(baseUV, _NoiseTex_ST, float2(_NoiseUSpeed, _NoiseVSpeed), 0, 1);
			v.noise2UVAndRandom.xy = MoveUV(baseUV, _Noise2Tex_ST, float2(_Noise2USpeed, _Noise2VSpeed), 0, 1);
			v.noise2UVAndRandom.zw = a.customData2.zw; // customData2.zw 作随机因子

			if (_DisplacementOn > 0)
			{
				float2 dUV = MoveUV(baseUV, _DisplaceMap_ST, float2(_DisplaceUSpeed, _DisplaceVSpeed), 0, _DisplaceUVMoveMode);
				half amount = SAMPLE_WRAP_DATA_LOD(_DisplaceMap, dUV, _DisplaceUVWrapMode).r;
				amount = _InvertDisplaceMap > 0 ? 1 - amount : amount;
				amount *= _DisplaceStrenByCustomData > 0 ? a.customData2.x : _DisplaceStren;
				half3 noise = 1;
				if (_AlphaSimulateOn > 0)
				{
					half4 n1 = SAMPLE_NOISE(_NoiseTex, v.noiseAndMaskUV.xy, _NoiseTexUVWrapMode, _InvertNoise, _NoiseStrenByCustomData, a.customData.y, _NoiseStren, true);
					half4 n2 = SAMPLE_NOISE(_Noise2Tex, v.noise2UVAndRandom.xy, _Noise2TexUVWrapMode, _InvertNoise2, 0, 0, _Noise2Stren, true);
					noise = (n1 + n2).xyz;
				}
				a.positionOS += a.normalOS * noise * amount;
			}

			v.positionCS = TransformObjectToHClip(a.positionOS);
			float eps = 5.960464478e-8;
			float vz = -max(_ProjectionParams.y + eps, abs(v.positionCS.w) - _ZOffsetViewSpace);
			float cz = vz * UNITY_MATRIX_P[2].z + UNITY_MATRIX_P[2].w;
			v.positionCS.z = lerp(v.positionCS.z, cz * v.positionCS.w / -vz, _DepthOffsetOn);

			v.fireAndBaseUV.xy = MoveUV(baseUV, _FireTex_ST, float2(_FireTexUSpeed, _FireTexVSpeed), a.customData.zw, _FireTexUVMoveMode);
			v.fireAndBaseUV.zw = baseUV;
			v.noiseAndMaskUV.zw = MoveUV(baseUV, _NoiseMask_ST, 0, 0, 0);
			v.customData = a.customData;
			v.normalWS = TransformObjectToWorldNormal(a.normalOS);
			v.positionWS = TransformObjectToWorld(a.positionOS);
			v.dissUV.xy = MoveUV(baseUV, _DissMap_ST, float2(_DissUSpeed, _DissVSpeed), 0, _DissUVMoveMode);
			return v;
		}

		// 返回 Gamma 空间的结果（和原 shader 输出一致）
		half4 FragCore(Varyings v)
		{
			half4 noise = SAMPLE_NOISE(_NoiseTex, v.noiseAndMaskUV.xy, _NoiseTexUVWrapMode, _InvertNoise, _NoiseStrenByCustomData, v.customData.y, _NoiseStren, false);

			// _MaskType: 0 用 UV 的 v 做遮罩，1 用遮罩贴图
			half noiseMask = _MaskType > 0
				? pow(SAMPLE_WRAP_DATA(_NoiseMask, v.noiseAndMaskUV.zw, _NoiseTexUVWrapMode).r, _NoiseMaskPow)
				: pow(v.noiseAndMaskUV.w, _NoiseMaskPow);
			noiseMask = _InvertMask > 0 ? 1 - noiseMask : noiseMask;
			noise *= noiseMask;

			float2 noiseDir = float2(0, noise.x);
			float2 alphaUV = v.fireAndBaseUV.zw * _AlphaMaskTex_ST.xy + _AlphaMaskTex_ST.zw;
			half fresnelMask = lerp(1, pow(v.fireAndBaseUV.w * _FresnelMaskMul, _FresnelMaskPow), _FresnelMaskOn);

			half3 col;
			half alpha;
			if (_AlphaSimulateOn > 0)
			{
				half4 noise2 = SAMPLE_NOISE(_Noise2Tex, v.noise2UVAndRandom.xy, _Noise2TexUVWrapMode, _InvertNoise2, _Noise2StrenByCustomData, v.customData.y, _Noise2Stren, false);
				noiseDir = (noise + noise2).xy;
				noiseDir.x = RemapRange(noiseDir.x, 0, 1, _RemapNewMin, _RemapNewMax);
				noiseDir.y = RemapRange(noiseDir.y, 0, 1, _RemapNewMin, _RemapNewMax);
				half3 viewDir = normalize(_WorldSpaceCameraPos - v.positionWS);
				half fresnel = _FresnelScale * pow(1 - saturate(dot(viewDir, v.normalWS)), _FresnelPower) * fresnelMask;
				noiseDir *= fresnel;
				half4 fire = SAMPLE_WRAP_GAMMA(_FireTex, noiseDir, _FireTexUVWrapMode);
				col = fire.rgb * TO_GAMMA(_MainCol.rgb);
				alpha = 1.0;
				alphaUV += (noise + noise2).xy * _AlphaMaskDistort;
			}
			else
			{
				// 火焰贴图：R 外焰强度，G 内焰强度，B 透明度
				half4 fire = SAMPLE_WRAP_GAMMA(_FireTex, v.fireAndBaseUV.xy + noiseDir, _FireTexUVWrapMode);
				col = TO_GAMMA(_InnerCol.rgb) * fire.g + TO_GAMMA(_OuterCol.rgb) * fire.r;
				alpha = fire.b * _OuterCol.a;
			}

			if (_AlphaMaskOn > 0)
			{
				half m = SAMPLE_WRAP_GAMMA(_AlphaMaskTex, alphaUV, _AlphaMaskUVWrapMode).r;
				m = _InvertAlphaMask > 0 ? 1 - m : m;
				alpha *= m * _AlphaMaskStren;
			}

			if (_DissovleOn > 0)
			{
				half progress = _DissStrenByCustomData > 0 ? saturate(v.customData.x) : _DissStren;
				half2 dUV = lerp(v.dissUV.xy, v.dissUV.xy + v.noise2UVAndRandom.zw, _DissovleRandomOn);
				half diss = SAMPLE_WRAP_DATA(_DissMap, dUV, _DissUVWrapMode).r;
				diss = _InvertDissMap > 0 ? 1 - diss : diss;
				diss -= progress * 2 - 1;
				alpha *= smoothstep(0.5 - _DissSmooth, 0.5, diss);
			}

			alpha = saturate(alpha * _AlphaMultiplyer);
			return half4(max(col, 0), alpha);
		}

		half4 frag(Varyings v) : SV_Target
		{
			half4 c = FragCore(v);
		#if defined(_ALPHATEST_ON)
			clip(c.a - _Cutoff);
		#endif
			return half4(TO_LINEAR(c.rgb), GAMMA_ALPHA(c.a));
		}

		half4 fragBloom(Varyings v) : SV_Target
		{
			half4 c = FragCore(v);
		#if defined(_ALPHATEST_ON)
			clip(c.a - _Cutoff);
		#endif
			return half4(c.rgb * BloomMultiplier() * _BloomOn, c.a);
		}
		ENDHLSL

		Pass
		{
			Name "ForwardFX"
			Tags { "LightMode" = "UniversalForward" }
			ZWrite [_ZWrite]
			Cull [_Cull]
			ZTest LEqual
			Blend [_SrcBlend] [_DstBlend]
			ColorMask RGB

			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex vert
			#pragma fragment frag
			#pragma shader_feature_local_fragment _ALPHATEST_ON
			ENDHLSL
		}

		// 特效 Bloom 图，由 PortedFXBloom 单独绘制
		Pass
		{
			Name "PortedFXBloom"
			Tags { "LightMode" = "PortedFXBloom" }
			ZWrite Off
			Cull [_Cull]
			ZTest LEqual
			Blend [_SrcBlend] [_DstBlend]
			ColorMask RGB

			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex vert
			#pragma fragment fragBloom
			#pragma shader_feature_local_fragment _ALPHATEST_ON
			ENDHLSL
		}
	}

	FallBack "Hidden/Universal Render Pipeline/FallbackError"
}

// qq13 溶解特效 shader（XinYuan/FX/Particles/Dissolve）的 URP 移植版，刀光、拖尾大多用它。
// 属性名和计算顺序和原版一致，原材质只换 shader 引用即可直接用。
// 没有移植的部分：VAT 顶点动画、深度软化、Bloom MRT 输出、雾。
Shader "Ported/FX/Dissolve"
{
	Properties
	{
		_BlendMode("混合模式", Float) = 1
		_Cull("背面剔除", Float) = 0
		_ZWrite("开启深度写入", Float) = 0.0
		_DepthOffsetOn("开启深度偏移", Float) = 0
		_AlphaClip("Alpha Clipping", Float) = 0.0
		_Cutoff("Threshold", Range(0.0, 1.0)) = 0.5
		_ZOffsetViewSpace("Z Offset ViewSpace", Float) = 0
		_GlobalAlpha("总体透明度", Range(0, 1)) = 1
		_AlphaMultiplyer("淡出系数（运行时用）", Range(0, 1)) = 1

		_MainTex("主贴图", 2D) = "white" {}
		_MainUVWrapMode("UV Wrap 模式", Float) = 0
		_MainColorChannel("颜色模式", Float) = 0
		_MainChannel("Channel通道", Vector) = (0, 0, 0, 1)
		_MainAlphaChannel("Alpha通道", Vector) = (0, 0, 0, 1)
		[HDR]_MainColor("主颜色", Color) = (1,1,1,1)
		_IsGradient("是否用渐变色", Float) = 0
		[HDR]_GradientColor1("渐变色A", Color) = (1,1,1,1)
		[HDR]_GradientColor2("渐变色B", Color) = (1,1,1,1)
		_GradientRotateParams("渐变旋转中心(XY) 角度(Z)", Vector) = (0.5, 0.5, 0, 0)
		_GradientTillingParams("渐变Tilling和Offset", Vector) = (1,1, 0, 0)
		_MainUVFlowSpeed("UV流动速度(XY)", Vector) = (0, 0, 0, 0)
		_MainTexRotateParams("旋转中心(XY) 角度(Z)", Vector) = (0.5, 0.5, 0, 0)
		_MainTexDistortMode("UV扭曲模式", Float) = 0
		_MainTexUVDistortIntensity("UV扭曲强度", Range(0, 1)) = 0.5
		_MainHSV("HSV X(色相) Y(饱和度) Z(亮度)", Vector) = (0, 1, 1, 0)

		_DetailTex("细节贴图", 2D) = "white" {}
		_DetailUVWrapMode("UV Wrap 模式", Float) = 0
		_DetailAlphaChannel("Alpha通道", Vector) = (0, 0, 0, 1)
		_DetailUVFlowSpeed("UV流动速度(XY)", Vector) = (0, 0, 0, 0)
		_DetailTexDistortMode("UV扭曲模式", Float) = 0
		_DetailTexUVDistortIntensity("UV扭曲强度", Range(0, 1)) = 0.5

		_DistortionTex("扭曲贴图(RG)", 2D) = "black" {}
		_DistortionUVRandMode("UV随机模式", Float) = 0
		_DistortionUVSpeed("UV流动速度(XY)", Vector) = (0, 0, 0, 0)
		_IsDistortionMask("是否用Mask.B作为遮罩", Float) = 0

		_DissolveTex("溶解贴图(R)", 2D) = "white" {}
		_DissolveUVWrapMode("UV Wrap 模式", Float) = 0
		_DissolveChannel("溶解通道", Vector) = (1, 0, 0, 0)
		_DissolveUVRandMode("溶解UV随机模式", Float) = 0
		_DissolveUVFlowSpeed("UV流动速度(XY)", Vector) = (0, 0, 0, 0)
		_DissolveRotateParams("旋转中心(XY) 角度(Z)", Vector) = (0.5, 0.5, 0, 0)
		_DissolveUVDistortMode("溶解UV扭曲模式", Float) = 0
		_DissolveUVDistortIntensity("溶解UV扭曲强度", Range(0, 1)) = 0.5
		_DissolveMode("溶解模式", Float) = 0
		_DissolveIntensity("溶解强度", Range(0, 1)) = 0
		_DissolveColorMode("溶解颜色模式", Float) = 0
		[HDR]_DissolveEdgeColor("溶解边颜色", Color) = (1, 1, 1, 1)
		_DissolveEdgeWidth("溶解边宽度", Range(0, 1)) = 0
		_DissolveEdgeInnerSoftness("溶解边内羽化", Range(0, 1)) = 0
		_DissolveEdgeOutterSoftnessMode("溶解边外羽化模式", Float) = 0
		_DissolveEdgeOutterSoftness("溶解边外羽化", Range(0, 1)) = 0

		_SecDissolveTex("二级溶解贴图(R)", 2D) = "white" {}
		_SecDissolveUVWrapMode("UV Wrap 模式", Float) = 0
		_SecDissolveChannel("溶解通道", Vector) = (1, 0, 0, 0)
		_SecDissolveUVFlowSpeed("UV流动速度(XY)", Vector) = (0, 0, 0, 0)
		_SecDissolveMode("溶解模式", Float) = 0
		_SecDissolveIntensity("溶解强度", Range(0, 1)) = 0
		_SecDissolveEdgeInnerSoftness("溶解边内羽化", Range(0, 1)) = 0

		_MaskTex("遮罩贴图", 2D) = "white" {}
		_MaskUVWrapMode("UV Wrap 模式", Float) = 0
		_MaskRotateParams("旋转中心(XY) 角度(Z)", Vector) = (0.5, 0.5, 0, 0)
		_MaskChannel("遮罩通道", Float) = 0
		_MaskDistortMode("UV扭曲模式", Float) = 0
		_MaskUVDistortIntensity("UV扭曲强度", Range(0, 1)) = 0.5

		_CameraDepth("近平面渐隐", Float) = 0
		_NearFadeStar ("Near Fade Star", Float) = 5
		_NearFadeRange ("Near Fade Range", Float) = 10

		_AlphaRangeON("开启Alpha范围调整", Float) = 0
		_AlphaRangeMin("Min", Float) = 0
		_AlphaRangeMax("Max", Float) = 1

		_BloomOn("开启Bloom", Float) = 0
		[HDR]_BloomTint("Bloom颜色", Color) = (1, 1, 1, 1)

		[HideInInspector] _SrcBlend("__src", Float) = 1.0
		[HideInInspector] _DstBlend("__dst", Float) = 0.0
	}

	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent" "RenderPipeline"="UniversalPipeline" "IgnoreProjector"="True" }

		HLSLINCLUDE
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "PortedFXCommon.hlsl"

			TEXTURE2D(_MainTex);
			TEXTURE2D(_DetailTex);
			TEXTURE2D(_DistortionTex);
			TEXTURE2D(_DissolveTex);
			TEXTURE2D(_SecDissolveTex);
			TEXTURE2D(_MaskTex);

			CBUFFER_START(UnityPerMaterial)
			half _DepthOffsetOn;
			half _ZOffsetViewSpace;
			half _Cutoff;
			half _AlphaClip;

			half4 _DistortionTex_ST;
			half2 _DistortionUVSpeed;
			half _DistortionUVRandMode;
			half _IsDistortionMask;

			half4 _MainTex_ST;
			half4 _MainColor;
			half4 _MainTexRotateParams;
			half4 _MainAlphaChannel;
			half4 _MainChannel;
			half4 _MainUVFlowSpeed;
			half3 _MainHSV;
			half4 _GradientColor1;
			half4 _GradientColor2;
			half4 _GradientRotateParams;
			half4 _GradientTillingParams;
			half _MainColorChannel;
			half _MainTexDistortMode;
			half _MainTexUVDistortIntensity;
			half _MainUVWrapMode;
			half _IsGradient;

			half4 _DetailTex_ST;
			half4 _DetailAlphaChannel;
			half4 _DetailUVFlowSpeed;
			half _DetailTexDistortMode;
			half _DetailTexUVDistortIntensity;
			half _DetailUVWrapMode;

			half4 _DissolveTex_ST;
			half4 _DissolveEdgeColor;
			half4 _DissolveChannel;
			half4 _DissolveUVFlowSpeed;
			half4 _DissolveRotateParams;
			half _DissolveUVWrapMode;
			half _DissolveColorMode;
			half _DissolveUVRandMode;
			half _DissolveUVDistortMode;
			half _DissolveMode;
			half _DissolveEdgeOutterSoftnessMode;
			half _DissolveUVDistortIntensity;
			half _DissolveIntensity;
			half _DissolveEdgeWidth;
			half _DissolveEdgeInnerSoftness;
			half _DissolveEdgeOutterSoftness;

			half4 _SecDissolveTex_ST;
			half4 _SecDissolveChannel;
			half4 _SecDissolveUVFlowSpeed;
			half _SecDissolveUVWrapMode;
			half _SecDissolveIntensity;
			half _SecDissolveEdgeInnerSoftness;
			half _SecDissolveMode;

			half4 _MaskTex_ST;
			half4 _MaskRotateParams;
			half _MaskUVWrapMode;
			half _MaskChannel;
			half _MaskDistortMode;
			half _MaskUVDistortIntensity;

			half _CameraDepth;
			half _NearFadeStar;
			half _NearFadeRange;

			half _AlphaRangeON;
			half _AlphaRangeMin;
			half _AlphaRangeMax;
			half _GlobalAlpha;
			half _AlphaMultiplyer;
			half _BloomOn;
			half4 _BloomTint;
			CBUFFER_END

			// 原 UVTransform.hlsl 的 RotateUV（角度单位是度）
			float2 RotateAround(float2 uv, float2 center, float angleDeg)
			{
				float a = radians(angleDeg);
				float c = cos(a);
				float s = sin(a);
				return mul(uv - center, float2x2(c, -s, s, c)) + center;
			}

			// 原 Dissolve.hlsl 的 Dissolve()
			void DissolveEdge(float dissVal, float dissIntensity, float edgeWidth, float inner, float outter, out float edgeMask, out float alpha)
			{
				float lo = dissIntensity - edgeWidth - inner - outter;
				float hi = dissIntensity + edgeWidth;
				dissIntensity = lerp(lo, hi, dissIntensity);
				alpha = smoothstep(dissIntensity, dissIntensity + outter, dissVal);
				outter *= 0.5;
				dissIntensity += edgeWidth + outter;
				float x = smoothstep(dissIntensity, dissIntensity + inner, dissVal);
				edgeMask = saturate(step(0.0, alpha) - x);
			}

			struct Attributes
			{
				float3 positionOS : POSITION;
				float2 uv : TEXCOORD0;
				half4 color : COLOR;
				float4 customData1 : TEXCOORD1; // X 溶解强度  Y 溶解外羽化  Z 溶解扭曲强度  W 主贴图扭曲强度
				float4 customData2 : TEXCOORD2; // XY 扭曲贴图UV随机  ZW 溶解贴图UV随机
			};

			struct Varyings
			{
				float4 positionCS : SV_POSITION;
				half4 color : COLOR;
				float4 uv : TEXCOORD0;
				float4 uv1 : TEXCOORD1;
				float4 uv2 : TEXCOORD2;
				float4 customData1 : TEXCOORD3;
				float4 customData2 : TEXCOORD4;
				float3 positionWS : TEXCOORD5;
			};

			Varyings vert(Attributes input)
			{
				Varyings o = (Varyings)0;
				o.positionWS = TransformObjectToWorld(input.positionOS);
				o.positionCS = TransformObjectToHClip(input.positionOS);

				if (_DepthOffsetOn > 0)
				{
					float eps = 5.960464478e-8;
					float vz = -max(_ProjectionParams.y + eps, abs(o.positionCS.w) - _ZOffsetViewSpace);
					float cz = vz * UNITY_MATRIX_P[2].z + UNITY_MATRIX_P[2].w;
					o.positionCS.z = cz * o.positionCS.w / -vz;
				}

				o.color = input.color;
				o.uv.xy = input.uv * _MainTex_ST.xy + _MainTex_ST.zw + _MainUVFlowSpeed.xy * _Time.x;
				o.uv.zw = input.uv * _DissolveTex_ST.xy + _DissolveTex_ST.zw;
				o.uv1.xy = input.uv * _DetailTex_ST.xy + _DetailTex_ST.zw + _DetailUVFlowSpeed.xy * _Time.x;
				o.uv1.zw = input.uv * _DistortionTex_ST.xy + _DistortionTex_ST.zw;
				o.uv2.xy = input.uv * _MaskTex_ST.xy + _MaskTex_ST.zw;
				o.uv2.zw = input.uv;
				o.customData1 = input.customData1;
				o.customData2 = input.customData2;
				return o;
			}

			// 原版在 Gamma 下采样，所有贴图拿到的都是原值，这里统一用 SAMPLE_WRAP_GAMMA 还原
			// 返回 Gamma 空间的结果（和原 shader 输出一致），由下面两个入口分别处理
			half4 FragCore(Varyings input)
			{
				half dissolveMask = 1;
			#if defined(_MASK_ON)
				if (_IsDistortionMask > 0)
					dissolveMask = SAMPLE_WRAP_GAMMA(_MaskTex, input.uv2.xy, _MaskUVWrapMode).b;
			#endif

				// 扭曲
				float2 distortUV = input.uv1.zw;
				distortUV += _DistortionUVRandMode > 0 ? input.customData2.xy : 0;
				distortUV += frac(_DistortionUVSpeed * _TimeParameters.x);
				float2 uvDistorted = SAMPLE_WRAP_GAMMA(_DistortionTex, distortUV, 0).rg * dissolveMask;
				uvDistorted = uvDistorted * 2 - 1;

				// 主贴图
				float2 mainDist = uvDistorted * lerp(_MainTexUVDistortIntensity, input.customData1.w, saturate(_MainTexDistortMode - 1)) * step(0.1, _MainTexDistortMode);
				float2 mainUV = input.uv.xy + mainDist;
				if (_MainTexRotateParams.z != 0) mainUV = RotateAround(mainUV, _MainTexRotateParams.xy, _MainTexRotateParams.z);
				half4 mainSample = SAMPLE_WRAP_GAMMA(_MainTex, mainUV, _MainUVWrapMode);
				half mainAlpha = dot(mainSample, _MainAlphaChannel);
				half mainChannel = dot(mainSample, _MainChannel);
				mainSample.rgb = lerp(mainSample.rgb, mainChannel.xxx, _MainColorChannel);
				mainSample.rgb = DoHSV(mainSample.rgb, _MainHSV);
				half gradMask = RotateAround(input.uv2.zw * _GradientTillingParams.xy + _GradientTillingParams.zw, _GradientRotateParams.xy, _GradientRotateParams.z).x;
				half3 gradColor = lerp(TO_GAMMA(_GradientColor1.rgb), TO_GAMMA(_GradientColor2.rgb), gradMask);
				gradColor = lerp((half3)1, gradColor, _IsGradient);
				mainSample.rgb *= gradColor;
				mainSample.a = mainAlpha;

				// 细节贴图
				float2 detailUV = input.uv1.xy;
				detailUV += _DetailTexDistortMode > 0 ? uvDistorted * _DetailTexUVDistortIntensity : 0;
				half4 detailSample = SAMPLE_WRAP_GAMMA(_DetailTex, detailUV, _DetailUVWrapMode);
				detailSample.a = dot(detailSample, _DetailAlphaChannel);

				// 溶解
				float2 dissUV = input.uv.zw;
				dissUV += lerp(_DissolveUVFlowSpeed.xy * _Time.y * saturate(_DissolveUVRandMode), input.customData2.zw, saturate(_DissolveUVRandMode - 1));
				if (_DissolveRotateParams.z != 0) dissUV = RotateAround(dissUV, _DissolveRotateParams.xy, _DissolveRotateParams.z);
				dissUV += lerp(_DissolveUVDistortIntensity, input.customData1.z, saturate(_DissolveUVDistortMode - 1)) * uvDistorted * step(0.1, _DissolveUVDistortMode);
				half dissVal = dot(SAMPLE_WRAP_GAMMA(_DissolveTex, dissUV, _DissolveUVWrapMode), _DissolveChannel);
				half dissIntensity = lerp(_DissolveIntensity, input.customData1.x, step(0.1, _DissolveMode));
				float edgeMask, dissAlpha;
				DissolveEdge(dissVal, dissIntensity, _DissolveEdgeWidth, _DissolveEdgeInnerSoftness,
					lerp(_DissolveEdgeOutterSoftness, input.customData1.y, step(0.1, _DissolveEdgeOutterSoftnessMode)),
					edgeMask, dissAlpha);

				// 二级溶解
				half secAlpha = 1;
			#if defined(_SEC_DISSOLVE_ON)
				float2 secUV = input.uv2.zw * _SecDissolveTex_ST.xy + _SecDissolveTex_ST.zw + _SecDissolveUVFlowSpeed.xy * _Time.x;
				half secVal = dot(SAMPLE_WRAP_GAMMA(_SecDissolveTex, secUV, _SecDissolveUVWrapMode), _SecDissolveChannel);
				half secIntensity = lerp(_SecDissolveIntensity, input.color.a, _SecDissolveMode);
				if (_SecDissolveMode > 0) input.color.a = 1;
				secAlpha = smoothstep(secIntensity, secIntensity + _SecDissolveEdgeInnerSoftness, secVal);
			#endif

				// 遮罩
				half mask = 1;
			#if defined(_MASK_ON)
				float2 maskUV = input.uv2.xy;
				maskUV += _MaskDistortMode > 0 ? uvDistorted * _MaskUVDistortIntensity : 0;
				if (_MaskRotateParams.z != 0) maskUV = RotateAround(maskUV, _MaskRotateParams.xy, _MaskRotateParams.z);
				half4 maskSample = SAMPLE_WRAP_GAMMA(_MaskTex, maskUV, _MaskUVWrapMode);
				mask = lerp(maskSample.r, maskSample.r * maskSample.a, step(0.1, _MaskChannel));
			#endif

				// 合成
				half4 finalColor = mainSample * detailSample * GammaColor(_MainColor) * GammaColor(input.color);
				finalColor.a *= mask;

				half3 edgeTint = TO_GAMMA(_DissolveEdgeColor.rgb);
				half3 edgeAdd = finalColor.rgb + edgeTint * edgeMask;
				half3 edgeLerp = lerp(finalColor.rgb, edgeTint, edgeMask);
				half3 edgeLerpMul = lerp(finalColor.rgb, edgeTint * finalColor.rgb, edgeMask);
				finalColor.rgb = _DissolveColorMode > 1 ? edgeLerpMul : (_DissolveColorMode > 0 ? edgeLerp : edgeAdd);
				finalColor.a *= dissAlpha * secAlpha;
				if (_AlphaClip > 0) clip(finalColor.a - _Cutoff);

				// 近平面渐隐
				half viewDistance = distance(_WorldSpaceCameraPos.xyz, input.positionWS);
				half nearStart = clamp(_NearFadeStar, 0, HALF_MAX);
				half nearRange = clamp(_NearFadeRange, 0, HALF_MAX);
				finalColor.a *= lerp(1, smoothstep(nearStart, nearStart + nearRange, viewDistance), _CameraDepth);

				finalColor.a = lerp(finalColor.a, smoothstep(_AlphaRangeMin, _AlphaRangeMax, finalColor.a), _AlphaRangeON);
				finalColor.a = saturate(finalColor.a) * _GlobalAlpha * _AlphaMultiplyer;

				return finalColor;
			}

			// 特效 Bloom（原项目 MRT 第二张图）：颜色 × _BloomTint × _BloomOn；场景开了 SceneFXBloom 时再乘全局强度
			float _GlobalFXBloomOn;
			float _GlobalFXBloomIntensity;
			half3 BloomMultiplier() { return _GlobalFXBloomOn > 0 ? _BloomTint.rgb * _GlobalFXBloomIntensity : _BloomTint.rgb; }

			half4 frag(Varyings input) : SV_Target
			{
				half4 c = FragCore(input);
				return half4(TO_LINEAR(c.rgb), GAMMA_ALPHA(c.a));
			}

			half4 fragBloom(Varyings input) : SV_Target
			{
				half4 c = FragCore(input);
				return half4(c.rgb * BloomMultiplier() * _BloomOn, c.a);
			}

		ENDHLSL

		Pass
		{
			Name "ForwardFX"
			Tags { "LightMode" = "UniversalForward" }

			ZWrite [_ZWrite]
			ZTest LEqual
			Cull [_Cull]
			Blend [_SrcBlend] [_DstBlend]
			ColorMask RGB

			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex vert
			#pragma fragment frag
			#pragma shader_feature_local_fragment _MASK_ON
			#pragma shader_feature_local_fragment _SEC_DISSOLVE_ON

			ENDHLSL
		}

		// 特效 Bloom 图，由 PortedFXBloom 单独绘制
		Pass
		{
			Name "PortedFXBloom"
			Tags { "LightMode" = "PortedFXBloom" }

			Cull [_Cull]
			ZTest LEqual
			ZWrite Off
			Blend [_SrcBlend] [_DstBlend]
			ColorMask RGB

			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex vert
			#pragma fragment fragBloom
			#pragma shader_feature_local_fragment _MASK_ON
			#pragma shader_feature_local_fragment _SEC_DISSOLVE_ON

			ENDHLSL
		}
	}

	FallBack "Hidden/Universal Render Pipeline/FallbackError"
}

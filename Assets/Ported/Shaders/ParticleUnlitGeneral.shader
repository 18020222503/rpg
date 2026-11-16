// qq13 特效通用 shader（XinYuan/FX/Particles/UnlitGeneral）的 URP 移植版。
// 属性名、关键字、计算顺序都和原版一致，原材质只换 shader 引用即可直接用。
// 没有移植的部分：GPU 粒子 Instancing、深度淡出、贴花模式、Bloom MRT 输出、全局反相效果、雾。
Shader "Ported/FX/ParticleUnlitGeneral"
{
	Properties
	{
		[MainTexture]_BaseMap("主贴图", 2D) = "white" {}
		[HDR][MainColor]_BaseColor("Main_Color", Color) = (1, 1, 1, 1)
		[Toggle]_BaseColorByCutomData2 ("主颜色By Custom Data2", Float) = 0.0
		[Toggle]_AnimSheetOn ("开启AnimSheet", Float) = 0
		_BaseWrapMode ("主贴图UV Wrap Mode", Float) = 0.0
		_BaseUVMoveMode ("主贴图UV Move Mode", Float) = 0.0
		[Toggle] _BaseScreenUV("全部贴图屏幕UV坐标",Float) = 0.0
		_BaseUSpeed ("U速度", Float) = 0.0
		_BaseVSpeed ("V速度", Float) = 0.0
		_BaseRadialScale ("极坐标Radial", Float) = 1.0
		_BaseLengthScale ("极坐标Length", Float) = 1.0
		_BaseRotAngle("旋转角度", Float) = 0.0
		_HSV("HSV X(色相) Y(饱和度) Z(亮度)", Vector) = (0, 1, 1, 0)

		_DetailMapOn("开启细节贴图", Float) = 0
		_DetailMap("细节贴图", 2D) = "white" {}
		[HDR]_DetailColor("Detail_Color", Color) = (1, 1, 1, 1)
		_DetailWrapMode ("细节贴图UV Wrap Mode", Float) = 0.0
		_DetailUVMoveMode ("细节贴图UV Move Mode", Float) = 0.0
		_DetailUSpeed ("U速度", Float) = 0.0
		_DetailVSpeed ("V速度", Float) = 0.0
		_DetailRadialScale ("Radial", Float) = 0.0
		_DetailLengthScale ("Length", Float) = 0.0
		_DetailStren("细节强度", Range(0, 1)) = 1

		_DoubleFaceOn("Double Face(双面)", Float) = 0
		[HDR] _BackFaceColor("背面颜色", Color) = (0, 0, 0, 1)

		_MaskOn ("Mask(遮罩)", Float) = 0.0
		_MaskMap("遮罩贴图", 2D) = "white" {}
		_MaskMapChannel("遮罩贴图通道", Float) = 0
		_MaskMapWrapMode ("遮罩贴图UV Wrap Mode", Float) = 0.0
		_MaskMapUVMoveMode ("遮罩贴图 UV Move Mode", Float) = 0.0
		_MaskUSpeed ("U速度", Float) = 0.0
		_MaskVSpeed ("V速度", Float) = 0.0
		_MaskRotAngle ("旋转角度", Float) = 0.0
		_MaskAddOn("Mask Add On", Float) = 0.0
		_MaskAlphaStrength("Mask Alpha Strength", Float) = 0.0
		_AlphaOn("Alpha On ", Float) = 0
		_AlphaAddOn("Alpha Add On ", Float) = 0.0
		_AlphaStrength("Alpha Strength", Float) = 0.0

		_DistortionOn ("Shape Distortion(形变扭曲)", Float) = 0.0
		_ShpDistMap("变形主贴图(RG)", 2D) = "gray" {}
		_ShpDistMapWrapMode ("变形贴图UV Wrap Mode", Float) = 0.0
		_ShpDistMapUVMoveMode ("变形贴图 UV Move Mode", Float) = 0.0
		_ShpDistUSpeed ("U速度", Float) = 0.0
		_ShpDistVSpeed ("V速度", Float) = 0.0
		_ShpDistRadialScale ("变形贴图极坐标Radial Scale", Float) = 1
		_ShpDistLengthScale ("变形贴图极坐标Radial Scale", Float) = 1
		_DistStrengthMaskOn("使用遮罩控制扭曲强度", Float) = 0.0
		_InvertDistMask("反转扭曲强度控制Mask", Float) = 0.0
		_DistStrengthMaskPower ("变形遮罩Mask Power", Float) = 1
		_ShpDistStrengthControlMask("变形强度控制贴图", 2D) = "black" {}
		_ShpDistStrengthControlMaskChannel("变形强度控制贴图通道", Float) = 0
		_ShpDetailDistMap("变形细节贴图(RG)", 2D) = "white" {}
		_ShpDetailDistMapWrapMode ("细节贴图UV Wrap Mode", Float) = 0.0
		_ShpDetailDistMapUVMoveMode ("细节贴图 UV Move Mode", Float) = 0.0
		_ShpDetailDistUSpeed ("U速度", Float) = 0.0
		_ShpDetailDistVSpeed ("V速度", Float) = 0.0
		_ShpDetailDistRadialScale ("Radial", Float) = 0.0
		_ShpDetailDistLengthScale ("Length", Float) = 0.0
		_ShpDistStrenByCustomDataY("变形强度By CustomData1 Y", Float) = 0.0
		_ShpDistStren("变形强度", Range(0, 2)) = 0.5
		_ShpDetailDistStrenOn("开启独立细节变形强度", Float) = 0
		_ShpDetailDistStren("细节变形强度", Range(0, 2)) = 0.5

		_DissolveOn ("Dissolve(溶解)", Float) = 0.0
		_DissolveMap("溶解贴图(R)", 2D) = "white" {}
		_InvertDissolveMap ("反向溶解贴图", Float) = 0
		_FollowShapeDistortionOn ("跟随扭曲进行溶解", Float) = 0
		_DissolveMapWrapMode ("溶解贴图UV Wrap Mode", Float) = 0.0
		_DissolveUVMoveMode ("溶解贴图 UV Move Mode", Float) = 0.0
		_DissolveUSpeed ("U速度", Float) = 0.0
		_DissolveVSpped ("V速度", Float) = 0.0
		_DissolveRadialScale ("Radial", Float) = 0.0
		_DissolveLengthScale ("Length", Float) = 0.0
		_DissolveRotAngle ("旋转角度", Float) = 0.0
		_DissolveByCustomDataX("溶解进度By CustomData1 X", Range(0, 1)) = 0
		_Dissolve("溶解进度", Range(0, 1)) = 0
		_EdgeRange("溶解边缘范围", Range(0, 1)) = 0.01
		_EdgeSmoothness ("边缘柔和度", Range(0, 1)) = 0.5
		_EdgeColorMode ("边缘颜色模式", Float) = 0
		[HDR]_EdgeColor("边缘颜色", Color) = (1, 1, 1, 0)

		_FresnelOn("Fresnel(菲尼尔)", Float) = 0.0
		_FresnelMode("菲尼尔模式", Float) = 0
		_FresnelColorMode("菲尼尔颜色模式", Float) = 0
		[HDR]_FresnelColor("菲尼尔颜色r", Color) = (1, 1, 1, 1)
		_FresnelPow("菲尼尔Pow", Float) = 1.0
		_FresnelStrength("菲尼尔强度", Float) = 1
		_InverFresnel("反向菲尼尔", Float) = 0

		_NearCameraFadeOn("Near Camera Fade(近平面渐隐)", Float) = 0.0
		_NearFadeStar ("Near Fade Star", Float) = 5
		_NearFadeRange ("Near Fade Range", Float) = 10

		_VertexOffsetOn("Vertex Animation(模型顶点偏移)", Float) = 0.0
		_VertexOffsetMainTexOn("主贴图影响顶点偏移", Float) = 1
		_VertexOffsetTexParams("XY(贴图平铺次数) ZW(贴图偏移量)", Vector) = (2, 2, 0, 0)
		_VertexOffsetMainTexColorOn("主贴图是否作为颜色贴图" ,Float) = 1
		_VertexOffsetMaskMap("Mask贴图", 2D) = "white" {}
		_VertexOffsetMaskMapChannelMask("Mask贴图通道", Float) = 0
		_VertexOffsetMaskUSpeed("U Speed", Float) = 0
		_VertexOffsetMaskVSpeed("V Speed", Float) = 0
		_VertexMaskMapWrapMode("Mask贴图UV Wrap Mode", Float) = 0.0
		_VertexRandomByCutomData2w("顶点偏移偏移随机值ByCustomData2w", Float) = 0.0
		_VertexOffsetIntensityByCutomData2X("顶点偏移强度ByCustomData2X", Float) = 0.0
		_VertexOffsetIntensity("偏移强度", Float) = 0.0

		_AlphaRemapping("范围", Vector) = (0, 1, 0, 0)
		_AlphaMultiplyer ("GamePlay Alpha 相乘系数", Range(0, 1)) = 1
		_Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

		[HideInInspector] _Surface("__surface", Float) = 1.0
		[HideInInspector] _Blend("__blend", Float) = 1.0
		[Toggle]_BloomOn("开启Bloom", Float) = 1
		[HDR]_BloomTint("Bloom颜色", Color) = (1, 1, 1, 1)

		[HideInInspector] _SrcBlend("__src", Float) = 1.0
		[HideInInspector] _DstBlend("__dst", Float) = 0.0
		[HideInInspector] _ZWrite("__ZWrite", Float) = 0.0
		[HideInInspector] _Cull("__Cull", Float) = 1.0
		[HideInInspector] _StencilRef("__StencilRef", Float) = 0
		[HideInInspector] _StencilReadMask("__StencilReadMask", Float) = 255
		[HideInInspector] _StencilWriteMask("__StencilWriteMask", Float) = 255
		[HideInInspector] _StencilComp("__Stencil Comp", Float) = 0
		[HideInInspector] _StencilPassOp("__StencilPassOp", Float) = 0
		[HideInInspector] _StencilZFailOp("__StencilZFailOp", Float) = 0
		[HideInInspector] _StencilFailOp("__StencilFailOp", Float) = 0
		_ZOffsetViewSpace("Z Offset ViewSpace", Float) = 0
	}

	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent" "RenderPipeline"="UniversalPipeline" "IgnoreProjector"="True" "PreviewType"="Plane" }

		HLSLINCLUDE
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "PortedFXCommon.hlsl"

			TEXTURE2D(_BaseMap);
			TEXTURE2D(_DetailMap);
			TEXTURE2D(_MaskMap);
			TEXTURE2D(_DissolveMap);
			TEXTURE2D(_ShpDistMap);
			TEXTURE2D(_ShpDetailDistMap);
			TEXTURE2D(_VertexOffsetMaskMap);
			TEXTURE2D(_ShpDistStrengthControlMask);

			CBUFFER_START(UnityPerMaterial)
			float4 _BaseMap_ST;
			half4 _BaseColor;
			half4 _HSV;
			half _BaseColorByCutomData2;
			half _AnimSheetOn;
			half _BaseWrapMode;
			half _BaseUVMoveMode;
			half _BaseScreenUV;
			half _BaseUSpeed;
			half _BaseVSpeed;
			half _BaseRotAngle;
			half _BaseRadialScale;
			half _BaseLengthScale;

			float4 _DetailMap_ST;
			half4 _DetailColor;
			half _DetailWrapMode;
			half _DetailUVMoveMode;
			half _DetailUSpeed;
			half _DetailVSpeed;
			half _DetailRadialScale;
			half _DetailLengthScale;
			half _DetailStren;

			half4 _BackFaceColor;

			float4 _MaskMap_ST;
			half _MaskOn;
			half _MaskMapChannel;
			half _MaskMapWrapMode;
			half _MaskMapUVMoveMode;
			half _MaskUSpeed;
			half _MaskVSpeed;
			half _MaskRotAngle;
			half _MaskAddOn;
			half _MaskAlphaStrength;
			half _AlphaOn;
			half _AlphaAddOn;
			half _AlphaStrength;

			float4 _ShpDistMap_ST;
			float4 _ShpDetailDistMap_ST;
			half _ShpDistMapWrapMode;
			half _ShpDistMapUVMoveMode;
			half _ShpDistUSpeed;
			half _ShpDistVSpeed;
			half _ShpDetailDistMapWrapMode;
			half _ShpDetailDistMapUVMoveMode;
			half _ShpDetailDistUSpeed;
			half _ShpDetailDistVSpeed;
			half _ShpDetailDistRadialScale;
			half _ShpDetailDistLengthScale;
			half _ShpDetailDistStrenOn;
			half _ShpDetailDistStren;
			half _ShpDistStrenByCustomDataY;
			half _ShpDistStren;
			half _ShpDistRadialScale;
			half _ShpDistLengthScale;
			half _DistStrengthMaskPower;
			half _InvertDistMask;
			half _ShpDistStrengthControlMaskChannel;

			float4 _DissolveMap_ST;
			half _DissolveOn;
			half _InvertDissolveMap;
			half _DissolveMapWrapMode;
			half _DissolveUVMoveMode;
			half _DissolveUSpeed;
			half _DissolveVSpped;
			half _DissolveRadialScale;
			half _DissolveLengthScale;
			half _DissolveRotAngle;
			half _DissolveByCustomDataX;
			half _Dissolve;
			half _EdgeRange;
			half _EdgeSmoothness;
			half _EdgeColorMode;
			half4 _EdgeColor;

			half4 _FresnelColor;
			half _FresnelMode;
			half _FresnelColorMode;
			half _FresnelPow;
			half _FresnelStrength;
			half _InverFresnel;

			half _NearFadeStar;
			half _NearFadeRange;

			half _VertexOffsetMainTexOn;
			half _VertexOffsetMainTexColorOn;
			half _VertexMaskMapWrapMode;
			half _VertexOffsetIntensity;
			half4 _VertexOffsetMaskMap_ST;
			half4 _VertexOffsetTexParams;
			half _VertexOffsetMaskUSpeed;
			half _VertexOffsetMaskVSpeed;
			half _VertexRandomByCutomData2w;
			half _VertexOffsetIntensityByCutomData2X;
			half _VertexOffsetMaskMapChannelMask;

			half _AlphaMultiplyer;
			half _BloomOn;
			half4 _BloomTint;
			half _Cutoff;
			half _Cull;
			half4 _AlphaRemapping;
			half _ZOffsetViewSpace;
			CBUFFER_END

			// ---------- 原 UVHelper / Math / ColorAdjustment 里用到的函数 ----------

			float2 RotateUV(float2 uv, float angleDeg)
			{
				float a = angleDeg / 57.3;
				float s = sin(a);
				float c = cos(a);
				return mul(float2x2(c, -s, s, c), uv);
			}

			bool IsUVMoveOn(half mode) { return mode > 0; }
			bool IsUVMoveByCustomData(half mode) { return (uint)mode == 2; }
			bool IsPolarUV(half mode) { return (uint)mode == 3; }

			float2 TransformUV(float2 uv, float4 st, float2 speed, float2 customZW, float rotAngle, half moveMode)
			{
				uv = abs(rotAngle) > 0 ? RotateUV(uv, rotAngle) : uv;
				float2 moved = IsUVMoveByCustomData(moveMode) ? customZW : st.zw + frac(speed * _Time.y);
				float2 offset = IsUVMoveOn(moveMode) ? moved : st.zw;
				return uv * st.xy + offset;
			}

			float2 TransformUVPolar(float2 uv, float2 speed, float radialScale, float lengthScale)
			{
				float2 d = uv - 0.5;
				float2 polar = float2(length(d) * radialScale * 2.0, atan2(d.x, d.y) * INV_TWO_PI * lengthScale);
				return polar + frac(_Time.y * speed);
			}

			half4 ChannelMask(int channel)
			{
				return half4(channel == 0 ? 1 : 0, channel == 1 ? 1 : 0, channel == 2 ? 1 : 0, channel == 3 ? 1 : 0);
			}

			half PercentInRange(half c, half minV, half maxV)
			{
				return saturate((c - minV) / (maxV - minV));
			}

			half SafePowH(half b, half p)
			{
				return pow(max(abs(b), HALF_EPS), p);
			}

			// ---------- 顶点 ----------

			struct Attributes
			{
				float3 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 tangentOS : TANGENT;
				float4 color : COLOR;
				float4 texcoord : TEXCOORD0;
				float4 customData : TEXCOORD1;
				float4 customData2 : TEXCOORD2;
			#if defined(_FLIPBOOKBLENDING_ON)
				float4 animSheetFrameAndBlend : TEXCOORD3;
			#endif
			};

			struct Varyings
			{
				float4 positionCS : SV_POSITION;
				half4 color : COLOR;
				float4 uv : TEXCOORD0;
				float3 positionWS : TEXCOORD1;
				float4 screenPos : TEXCOORD2;
				half4 customData : TEXCOORD3;
				half4 customData2 : TEXCOORD4;
			#if defined(_FLIPBOOKBLENDING_ON)
				float3 animSheetUVAndBlend : TEXCOORD5;
			#endif
			#if defined(_FRESNEL_ON)
				half3 normalWS : TEXCOORD6;
				half3 viewDirWS : TEXCOORD7;
			#endif
			};

			Varyings vert(Attributes i)
			{
				Varyings o = (Varyings)0;
				o.color = i.color;
				o.customData = i.customData;
				o.customData2 = i.customData2;

				float2 texcoord = i.texcoord.xy;
			#if defined(_FLIPBOOKBLENDING_ON)
				o.animSheetUVAndBlend = float3(i.texcoord.zw, i.animSheetFrameAndBlend.y);
			#endif

			#if defined(_VERTEXOFFSET_ON)
				half base = 1;
				half rnd = 0;
				if (_VertexOffsetMainTexOn > 0)
				{
					float2 uvBase = TransformUV(texcoord, _VertexOffsetTexParams, float2(_BaseUSpeed, _BaseVSpeed), o.customData.zw, _BaseRotAngle, _BaseUVMoveMode);
					base = SAMPLE_WRAP_LOD(_BaseMap, uvBase, _BaseWrapMode).r;
				}
				if (_VertexRandomByCutomData2w > 0) rnd = o.customData2.w;
				float2 uvMask = TransformUV(texcoord, _VertexOffsetMaskMap_ST, float2(_VertexOffsetMaskUSpeed, _VertexOffsetMaskVSpeed), 0, 0, 1);
				half4 maskSample = SAMPLE_WRAP_DATA_LOD(_VertexOffsetMaskMap, uvMask + rnd, _BaseWrapMode);
				half vmask = dot(maskSample, ChannelMask((int)_VertexOffsetMaskMapChannelMask));
				half intensity = lerp(_VertexOffsetIntensity, o.customData2.x, _VertexOffsetIntensityByCutomData2X);
				i.positionOS += ((base * 2.0) - 1.0) * vmask * intensity * i.normalOS;
			#endif

				VertexPositionInputs vpi = GetVertexPositionInputs(i.positionOS);
				o.positionCS = vpi.positionCS;
			#if defined(_DEPTH_OFFSET_ON)
				float eps = 5.960464478e-8;
				float vz = -max(_ProjectionParams.y + eps, abs(o.positionCS.w) - _ZOffsetViewSpace);
				float cz = vz * UNITY_MATRIX_P[2].z + UNITY_MATRIX_P[2].w;
				o.positionCS.z = cz * o.positionCS.w / -vz;
			#endif
				o.positionWS = vpi.positionWS;
				o.screenPos = ComputeScreenPos(vpi.positionCS);
				o.uv.zw = lerp(texcoord, o.screenPos.xy / o.screenPos.w, _BaseScreenUV);

			#if defined(_FRESNEL_ON)
				o.normalWS = TransformObjectToWorldNormal(i.normalOS);
				o.viewDirWS = SafeNormalize(GetCameraPositionWS() - vpi.positionWS);
			#endif
				return o;
			}

			// ---------- 片元 ----------

			// 返回 Gamma 空间的结果（和原 shader 输出一致），由下面两个入口分别处理
			half4 FragCore(Varyings i, FRONT_FACE_TYPE frontFacing)
			{
				float2 baseUVIn = i.uv.zw;

			#if defined(_DISTORTION_ON)
				float2 distUV = IsPolarUV(_ShpDistMapUVMoveMode)
					? TransformUVPolar(i.uv.zw, float2(_ShpDistUSpeed, _ShpDistVSpeed), _ShpDistRadialScale, _ShpDistLengthScale)
					: TransformUV(i.uv.zw, _ShpDistMap_ST, float2(_ShpDistUSpeed, _ShpDistVSpeed), 0, 0, _ShpDistMapUVMoveMode);
				distUV = SAMPLE_WRAP_DATA(_ShpDistMap, distUV, _ShpDistMapWrapMode).rg * 2 - 1;
				half distStrength = lerp(_ShpDistStren, clamp(i.customData.y, 0, 2), _ShpDistStrenByCustomDataY);
				half2 distUVNoMask = distUV * distStrength;
				#if defined(_DISTSTRENGTHMASK_ON)
					half distMask = dot(SAMPLE_WRAP_DATA(_ShpDistStrengthControlMask, i.uv.zw, _ShpDistMapWrapMode), ChannelMask((int)_ShpDistStrengthControlMaskChannel));
					distMask = lerp(distMask, 1 - distMask, _InvertDistMask);
					distMask = SafePowH(distMask, _DistStrengthMaskPower);
					distUV *= lerp(0, distStrength, distMask);
				#else
					distUV = distUVNoMask;
				#endif

				float2 detailDistUV = IsPolarUV(_ShpDetailDistMapUVMoveMode)
					? TransformUVPolar(i.uv.zw, float2(_ShpDistUSpeed, _ShpDistVSpeed), _ShpDetailDistRadialScale, _ShpDetailDistLengthScale)
					: TransformUV(i.uv.zw, _ShpDetailDistMap_ST, float2(_ShpDetailDistUSpeed, _ShpDetailDistVSpeed), 0, 0, _ShpDetailDistMapUVMoveMode);
				detailDistUV = SAMPLE_WRAP_DATA(_ShpDetailDistMap, detailDistUV, _ShpDetailDistMapWrapMode).rg * 2 - 1;
				half detailStren = lerp(distStrength, _ShpDetailDistStren, _ShpDetailDistStrenOn);
				#if defined(_DISTSTRENGTHMASK_ON)
					detailDistUV *= detailStren * distMask;
				#else
					detailDistUV *= detailStren;
				#endif
				distUV *= detailDistUV;
				#if defined(_FLIPBOOKBLENDING_ON)
					i.animSheetUVAndBlend.xy += distUV;
				#endif
				baseUVIn = distUV + i.uv.zw;
			#endif

				float2 baseUV = IsPolarUV(_BaseUVMoveMode)
					? TransformUVPolar(baseUVIn, float2(_BaseUSpeed, _BaseVSpeed), _BaseRadialScale, _BaseLengthScale)
					: TransformUV(baseUVIn, _BaseMap_ST, float2(_BaseUSpeed, _BaseVSpeed), i.customData.zw, _BaseRotAngle, _BaseUVMoveMode);
				half4 baseColor = GammaColor(SAMPLE_WRAP(_BaseMap, baseUV, _BaseWrapMode));

			#if defined(_VERTEXOFFSET_ON)
				if (_VertexOffsetMainTexColorOn < 1) baseColor = half4(1, 1, 1, 1);
			#endif

			#if defined(_FLIPBOOKBLENDING_ON)
				float2 nextUV = IsPolarUV(_BaseUVMoveMode)
					? TransformUVPolar(i.animSheetUVAndBlend.xy, float2(_BaseUSpeed, _BaseVSpeed), _BaseRadialScale, _BaseLengthScale)
					: TransformUV(i.animSheetUVAndBlend.xy, _BaseMap_ST, float2(_BaseUSpeed, _BaseVSpeed), i.customData.zw, _BaseRotAngle, _BaseUVMoveMode);
				baseColor = lerp(baseColor, GammaColor(SAMPLE_WRAP(_BaseMap, nextUV, _BaseWrapMode)), i.animSheetUVAndBlend.z);
			#endif

				// 粒子颜色和材质颜色在 Linear 下被 Unity 转成了线性值，转回来；Custom Data 不会被转换，原样使用
				half4 color = baseColor * GammaColor(i.color);
				half4 tint = _BaseColorByCutomData2 > 0 ? i.customData2 : GammaColor(_BaseColor);
			#if defined(_DDUBLE_FACE_ON)
				tint = IS_FRONT_VFACE(frontFacing, true, false) ? tint : GammaColor(_BackFaceColor);
			#endif
				color *= tint;

			#if defined(_BASE_DETAIL_MAP_ON)
				float2 detailUV = IsPolarUV(_DetailUVMoveMode)
					? TransformUVPolar(i.uv.zw, float2(_DetailUSpeed, _DetailVSpeed), _DetailRadialScale, _DetailLengthScale)
					: TransformUV(i.uv.zw, _DetailMap_ST, float2(_DetailUSpeed, _DetailVSpeed), i.customData2.zw, 0, _DetailUVMoveMode);
				half4 detail = GammaColor(SAMPLE_WRAP(_DetailMap, detailUV, _DetailWrapMode)) * GammaColor(_DetailColor);
				color = lerp(color, color * detail, _DetailStren);
			#endif

				color.rgb = DoHSV(color.rgb, _HSV.xyz);

				UNITY_BRANCH
				if (_DissolveOn > 0)
				{
					half progress = lerp(_Dissolve, i.customData.x, _DissolveByCustomDataX);
					progress += step(0.99h, progress) * 0.01h;
					float2 dissUV = IsPolarUV(_DissolveUVMoveMode)
						? TransformUVPolar(i.uv.zw, float2(_DissolveUSpeed, _DissolveVSpped), _DissolveRadialScale, _DissolveLengthScale)
						: TransformUV(i.uv.zw, _DissolveMap_ST, float2(_DissolveUSpeed, _DissolveVSpped), 0, _DissolveRotAngle, _DissolveUVMoveMode);
				#if defined(_DISTORTION_ON) && defined(_FOLLOWSHAPEDISTORTION_ON)
					half diss = SAMPLE_WRAP_DATA(_DissolveMap, (distUVNoMask + dissUV) * _DissolveMap_ST.xy + _DissolveMap_ST.zw, _DissolveMapWrapMode).r;
				#else
					half diss = SAMPLE_WRAP_DATA(_DissolveMap, dissUV, _DissolveMapWrapMode).r;
				#endif
					diss = _InvertDissolveMap > 0 ? 1 - diss : diss;

					half edgeRange = lerp(_EdgeRange * diss, _EdgeRange, progress);
					half inEdge = step(diss, progress + edgeRange) * step(0.01h, progress);
					half3 edgeTint = TO_GAMMA(_EdgeColor.rgb);
					half3 gradient = lerp(color.rgb, edgeTint, 1 - PercentInRange(diss, progress, progress + edgeRange));
					half3 edgeColor = (int)_EdgeColorMode == 0 ? color.rgb : ((int)_EdgeColorMode == 1 ? edgeTint : gradient);
					color.rgb = lerp(color.rgb, edgeColor, inEdge);

					half dissolveTexR = 1 - diss;
					progress *= (1 + _EdgeRange);
					half hardness = 2.0 - (1 - _EdgeSmoothness);
					half d2 = (progress - _EdgeRange) * hardness + dissolveTexR;
					d2 = PercentInRange(2.0 - d2, 1 - _EdgeSmoothness, 1.0);
					color.a *= d2;
				}

			#if defined(_NEAR_CAMERA_FADE_ON)
				half viewDistance = distance(_WorldSpaceCameraPos.xyz, i.positionWS);
				half nearStart = clamp(_NearFadeStar, 0, HALF_MAX);
				half nearRange = clamp(_NearFadeRange, 0, HALF_MAX);
				color.a *= smoothstep(nearStart, nearStart + nearRange, viewDistance);
			#endif

			#if defined(_FRESNEL_ON)
				half ndv = saturate(dot(normalize(i.normalWS), i.viewDirWS));
				half fresnel = saturate(pow(1 - ndv, _FresnelPow));
				half invFresnel = saturate(pow(ndv, _FresnelPow));
				fresnel = lerp(fresnel, invFresnel, _InverFresnel) * _FresnelStrength;
				half3 fresnelTint = TO_GAMMA(_FresnelColor.rgb);
				half3 fc1 = color.rgb * fresnelTint * fresnel;
				half3 fc2 = color.rgb + fresnelTint * fresnel;
				half3 fcol = lerp(fc1, fc2, _FresnelColorMode);
				half falpha = color.a * _FresnelColor.a * fresnel;
				color.rgb = (_FresnelMode == 0 || _FresnelMode == 2) ? fcol : color.rgb;
				color.a = saturate((_FresnelMode == 1 || _FresnelMode == 2) ? falpha : color.a);
			#endif

				half a = color.a;
				UNITY_BRANCH
				if (_MaskOn > 0)
				{
					float2 maskUV = TransformUV(i.uv.zw, _MaskMap_ST, float2(_MaskUSpeed, _MaskVSpeed), 0, _MaskRotAngle, _MaskMapUVMoveMode);
					half4 maskSample = SAMPLE_WRAP_DATA(_MaskMap, maskUV, _MaskMapWrapMode);
					half alphaMask = dot(maskSample, ChannelMask((int)_MaskMapChannel));
					alphaMask = lerp(alphaMask, pow(clamp(alphaMask, 0.0001, 1), _MaskAlphaStrength), _MaskAddOn);
					a = lerp(a, color.r * _BaseColor.a * i.color.a, _AlphaOn) * alphaMask;
					a *= lerp(1.0, pow(clamp(a, 0.0001, 1), _AlphaStrength), _AlphaAddOn);
					a = saturate(a);
				}

			#if defined(_ALPHATEST_ON)
				clip(a - _Cutoff);
			#endif

				a = lerp(a, smoothstep(_AlphaRemapping.x, _AlphaRemapping.y, a), _AlphaRemapping.w);
				a *= _AlphaMultiplyer;

				return half4(max(color.rgb, (half3)0), saturate(a));
			}

			// 特效 Bloom（原项目 MRT 第二张图）：颜色 × _BloomTint × _BloomOn；场景开了 SceneFXBloom 时再乘全局强度
			float _GlobalFXBloomOn;
			float _GlobalFXBloomIntensity;
			half3 BloomMultiplier() { return _GlobalFXBloomOn > 0 ? _BloomTint.rgb * _GlobalFXBloomIntensity : _BloomTint.rgb; }

			half4 frag(Varyings i, FRONT_FACE_TYPE frontFacing : FRONT_FACE_SEMANTIC) : SV_Target
			{
				half4 c = FragCore(i, frontFacing);
				return half4(TO_LINEAR(c.rgb), GAMMA_ALPHA(c.a));
			}

			half4 fragBloom(Varyings i, FRONT_FACE_TYPE frontFacing : FRONT_FACE_SEMANTIC) : SV_Target
			{
				half4 c = FragCore(i, frontFacing);
				return half4(c.rgb * BloomMultiplier() * _BloomOn, c.a);
			}

		ENDHLSL

		Pass
		{
			Name "ForwardFX"
			Tags { "LightMode" = "UniversalForward" }

			Cull [_Cull]
			ZTest LEqual
			ZWrite [_ZWrite]
			Blend [_SrcBlend] [_DstBlend]
			ColorMask RGB
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
			#pragma target 3.5
			#pragma vertex vert
			#pragma fragment frag

			#pragma shader_feature_local_fragment _BASE_DETAIL_MAP_ON
			#pragma shader_feature_local_fragment _DDUBLE_FACE_ON
			#pragma shader_feature_local_fragment _DISTORTION_ON
			#pragma shader_feature_local_fragment _NEAR_CAMERA_FADE_ON
			#pragma shader_feature_local _FLIPBOOKBLENDING_ON
			#pragma shader_feature_local _ALPHATEST_ON
			#pragma shader_feature_local _FRESNEL_ON
			#pragma shader_feature_local _VERTEXOFFSET_ON
			#pragma shader_feature_local _FOLLOWSHAPEDISTORTION_ON
			#pragma shader_feature_local _DISTSTRENGTHMASK_ON
			#pragma shader_feature_local _DEPTH_OFFSET_ON

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

			#pragma shader_feature_local_fragment _BASE_DETAIL_MAP_ON
			#pragma shader_feature_local_fragment _DDUBLE_FACE_ON
			#pragma shader_feature_local_fragment _DISTORTION_ON
			#pragma shader_feature_local_fragment _NEAR_CAMERA_FADE_ON
			#pragma shader_feature_local _FLIPBOOKBLENDING_ON
			#pragma shader_feature_local _ALPHATEST_ON
			#pragma shader_feature_local _FRESNEL_ON
			#pragma shader_feature_local _VERTEXOFFSET_ON
			#pragma shader_feature_local _FOLLOWSHAPEDISTORTION_ON
			#pragma shader_feature_local _DISTSTRENGTHMASK_ON
			#pragma shader_feature_local _DEPTH_OFFSET_ON

			ENDHLSL
		}
	}

	FallBack "Hidden/Universal Render Pipeline/FallbackError"
}

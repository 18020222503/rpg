#ifndef PORTED_FX_COMMON_INCLUDED
#define PORTED_FX_COMMON_INCLUDED

// 移植特效 shader 共用的部分：Gamma 计算模拟、贴图采样、HSV 调整。

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

// ---------- Gamma 计算模拟 ----------
// 原项目是 Gamma 色彩空间，特效都是在 Gamma 下调的：贴图和颜色按原值参与计算，HDR 颜色（比如 2.5）不会被放大，
// 半透明按 Gamma 值混合。本项目是 Linear，Unity 会把 sRGB 贴图、材质颜色、粒子颜色先转成线性值（HDR 颜色 2.5 会变成约 7），
// 混合也在线性空间进行，结果就是颜色发白、半透明边缘变实。
// 这里把输入转回 Gamma 值，按原 shader 的方式计算，最后再转回线性输出；透明度做 a^2.2 补偿，近似 Gamma 下的混合效果。
#if defined(UNITY_COLORSPACE_GAMMA)
	#define TO_GAMMA(c) (c)
	#define TO_LINEAR(c) (c)
	#define GAMMA_ALPHA(a) (a)
#else
	#define TO_GAMMA(c) LinearToSRGB(max((c), (half3)0))
	#define TO_LINEAR(c) SRGBToLinear(max((c), (half3)0))
	#define GAMMA_ALPHA(a) pow(saturate(a), 2.2)
#endif

half4 GammaColor(half4 c) { return half4(TO_GAMMA(c.rgb), c.a); }

// ---------- 采样 ----------
SAMPLER(sampler_linear_repeat);
SAMPLER(sampler_linear_clamp);

// 原版 Clamp 模式是先把 uv 夹到 0..1 再用 Repeat 采样
half4 SampleWrap(TEXTURE2D_PARAM(tex, unusedSampler), float2 uv, half wrapMode)
{
	uv = wrapMode > 0.5 ? saturate(uv) : uv;
	return SAMPLE_TEXTURE2D(tex, sampler_linear_repeat, uv);
}

half4 SampleWrapLod(TEXTURE2D_PARAM(tex, unusedSampler), float2 uv, half wrapMode)
{
	return wrapMode > 0.5
		? SAMPLE_TEXTURE2D_LOD(tex, sampler_linear_clamp, uv, 0)
		: SAMPLE_TEXTURE2D_LOD(tex, sampler_linear_repeat, uv, 0);
}

#define SAMPLE_WRAP(tex, uv, mode) SampleWrap(TEXTURE2D_ARGS(tex, sampler_linear_repeat), uv, mode)
#define SAMPLE_WRAP_LOD(tex, uv, mode) SampleWrapLod(TEXTURE2D_ARGS(tex, sampler_linear_repeat), uv, mode)
// 按 Gamma 值采样：原项目在 Gamma 下采样拿到的是贴图原值
#define SAMPLE_WRAP_GAMMA(tex, uv, mode) GammaColor(SAMPLE_WRAP(tex, uv, mode))

// 遮罩/溶解/扭曲这类数据贴图：原 shader 用 FX_FAST_SRGB_TO_LINEAR 读，Gamma 工程里会做一次 sRGB→线性，
// Linear 工程里贴图本身已被转成线性，不再处理。两种工程下结果一致
#if defined(UNITY_COLORSPACE_GAMMA)
	#define FX_DATA(c) FastSRGBToLinear(c)
#else
	#define FX_DATA(c) (c)
#endif
#define SAMPLE_WRAP_DATA(tex, uv, mode) FX_DATA(SAMPLE_WRAP(tex, uv, mode))
#define SAMPLE_WRAP_DATA_LOD(tex, uv, mode) FX_DATA(SAMPLE_WRAP_LOD(tex, uv, mode))

// ---------- 颜色 ----------
half3 DoHSV(half3 rgb, half3 hsv)
{
	half3 col = RgbToHsv(rgb);
	col.x = RotateHue(col.x + hsv.x * 0.1, 0, 1);
	col = HsvToRgb(col);
	col = max(Desaturate(col, clamp(hsv.y, 0, 10)), (half3)0);
	col *= clamp(hsv.z, 0, 10);
	return col;
}

#endif

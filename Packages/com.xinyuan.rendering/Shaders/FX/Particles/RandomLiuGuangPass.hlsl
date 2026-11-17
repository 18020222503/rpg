#ifndef RANDOM_LIU_GUANG_PASS_INCLUDED
#define RANDOM_LIU_GUANG_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/Util.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/UVHelper.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/ColorAdjustment.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/FX/FXDebug.hlsl"

//#define TIME fmod(_Time.y, HALF_MAX)
			
struct Attributes
{
	float3 positionOS				: POSITION;
	float3 normalOS					: NORMAL;
	float2 baseUV					: TEXCOORD0;
	float4 customData 				: TEXCOORD1;
	float4 customData2				: TEXCOORD2;
	half4 vertexColor				: COLOR;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
	float4 positionCS				: SV_POSITION;
	float4 noiseAndDissloveUV		: TEXCOORD0;
	float4 maskUV					: TEXCOORD1;
	float4 customData2				: TEXCOORD2;
	//float4 ScreenPosition			: TEXCOORD3;
	float4 baseUV                   : TEXCOORD4;
	half4 vertexColor				: COLOR;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct MRTOutput
{
	half4 fragColor		: SV_TARGET0;
	half4 bloomColor	: SV_TARGET1;
};

Varyings vert (Attributes i)
{
	Varyings o = (Varyings)0;
	UNITY_SETUP_INSTANCE_ID(i);
    UNITY_TRANSFER_INSTANCE_ID(i, o);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
	
	o.positionCS = TransformObjectToHClip(i.positionOS);

	float eps = 5.960464478e-8;
	float modifiedPositionVS_Z = -max(_ProjectionParams.y + eps, abs(o.positionCS.w) - _ZOffsetViewSpace);
	float modifiedPositionCS_Z = modifiedPositionVS_Z * UNITY_MATRIX_P[2].z + UNITY_MATRIX_P[2].w;
	o.positionCS.z = _DepthOffsetOn > 0 ? modifiedPositionCS_Z *  o.positionCS.w / -(modifiedPositionVS_Z) : o.positionCS.z ;
	//o.ScreenPosition = ComputeScreenPos(o.positionCS);
	float2 NoiseUV = UVHelper_TransformUV(i.baseUV.xy, _NoiseTex_ST, _NoiseTexSpeed.xy, half2(0,0), 0, 1, 0);
	NoiseUV = lerp(NoiseUV,  NoiseUV + i.customData.z, _OpenRandomNoiseUV);
	o.noiseAndDissloveUV.xy = NoiseUV;
	float2 DissolveUV = UVHelper_TransformUV(i.baseUV.xy, _DissolveTex_ST, _DissolveSpeed, half2(0,0), 0, 1, 0);
	DissolveUV = lerp(DissolveUV, DissolveUV + i.customData.w, _OpenRandomDissolveUV);
	o.noiseAndDissloveUV.zw = DissolveUV;
	float2 Base1UV = UVHelper_TransformUV(i.baseUV.xy, _BaseTex1_ST, _BaseTexUVSpeed.xy, half2(0,0), 0, 1, 0);
	Base1UV = lerp(Base1UV,  Base1UV + i.customData.x, _OpenRandomTex1UV);
	float2 Base2UV = UVHelper_TransformUV(i.baseUV.xy, _BaseTex2_ST, _BaseTexUVSpeed.zw, half2(0,0), 0, 1, 0);
	Base2UV = lerp(Base2UV, Base2UV + i.customData.y, _OpenRandomTex2UV);
	o.baseUV.xy = Base1UV;
	o.baseUV.zw = Base2UV;
	
	float2 Mask1UV = i.baseUV.xy * _MaskTex1_ST.xy + _MaskTex1_ST.zw;	
	Mask1UV= float2(Mask1UV.x + lerp((0).x, i.customData2.z,  _OpenUDirMask), Mask1UV.y + lerp((0).x,i.customData2.w,  _OpenVDirMask));
	o.maskUV.xy = Mask1UV;
	float2 MaskTex2UV = i.baseUV.xy * _MaskTex2_ST.xy + _MaskTex2_ST.zw;
	o.maskUV.zw = MaskTex2UV;
	//o.customData = i.customData;
	o.customData2 = i.customData2;
	o.vertexColor = i.vertexColor;
	return o;
}

half4 ColorFrag(Varyings i)
{
    UNITY_SETUP_INSTANCE_ID(i);
	
	//float4 customData = i.customData;
	//customData.xy = i.customData.xy;
	//float VarX = customData.x;
	//float VarY = customData.y;
	//float VarZ = customData.z;
	//float VarW = customData.w;

	float4 customData2 = i.customData2;
	customData2.xy = i.customData2.xy + float2( 0.5,0.5 );
	float VarRongJie = customData2.x;
	//float VarMaskU = customData2.z;
	//float VarMaskV = customData2.w;
	
	// 扰动贴图 一定是Repeat
	half4 NoiseColor =  1;
	UNITY_BRANCH
    if (_NoiseIntensity1 >0 || _NoiseIntensity2 >0 || _OpenRandomTex1UV > 0 || _OpenRandomTex2UV>0||
    	_OpenRandomNoiseUV > 0 ||_OpenRandomDissolveUV>0 )
    {
    	NoiseColor = SAMPLE_TEXTURE2D_WARP(_NoiseTex, i.noiseAndDissloveUV.xy,0);
    }
	
	// 基础贴图1
	half4 BaseColor1 = SAMPLE_TEXTURE2D_WARP(_BaseTex1, i.baseUV.xy + (NoiseColor * _NoiseIntensity1).rg ,_BaseTex1UVWrapMode);
	half GrayColor1 = dot(BaseColor1.rgb, float3(0.299, 0.587, 0.114));
	half3 TempColor1 = lerp(BaseColor1, GrayColor1.xxx, _Desature1);
	half4 _BaseColor1 = lerp(half4(TempColor1, 1), half4(TempColor1, BaseColor1.a), _AlpahCaleOn);

	// 基础贴图2
	half4 BaseColor2 = SAMPLE_TEXTURE2D_WARP(_BaseTex2, i.baseUV.zw + (NoiseColor * _NoiseIntensity2).rg, _BaseTex2UVWrapMode);
	half GrayColor2 = dot(BaseColor2, float3(0.299, 0.587, 0.114));
	half3 TempColor2 = lerp(BaseColor2, GrayColor2.xxx, _Desature2); 
	half4 _BaseColor2 = lerp(half4(TempColor2, 1), half4(TempColor2, BaseColor2.a), _AlpahCaleOn);
	
	half4 TempColor3 = pow(_BaseColor1 * _BaseColor2, (_BaseTex12PM.x).xxxx) * _BaseTex12PM.y;
	half4 TempColor4 = pow(_BaseColor1 + _BaseColor2, (_BaseTex12PM.z).xxxx) * _BaseTex12PM.w;
	
	half4 LerpColorMulResult = lerp(_Color1 * TempColor3, _Color2 * TempColor4, _ColorLerp);
	half4 lerpResult = lerp( TempColor3 , TempColor4 , _ColorLerp);
	
	half4 DissolveColor = 1;
	UNITY_BRANCH
    if (_OpenDissolve> 0)
    {
    	i.noiseAndDissloveUV.zw += (NoiseColor * _DissolveNoiseIntensity).rg ;
    	half4 TempDissolveColor = SAMPLE_TEXTURE2D_WARP(_DissolveTex, i.noiseAndDissloveUV.zw,_DissolveTexUVWrapMode);
    	half TempValue2 = lerp(_Dissolve, VarRongJie , _DissolveByCustomData);
    	TempDissolveColor = smoothstep((TempValue2).xxxx, (TempValue2 + _DissolveEdge).xxxx, TempDissolveColor);
    	DissolveColor = lerp((1.0).xxxx, TempDissolveColor, _OpenDissolve);  
    }
	
	// Mask1贴图
	half TempValue= 1;
	half Mask2Color = 1;
	#if defined(_MASK_MAP_ON)
	i.maskUV.xy += NoiseColor.rg * _Mask1NoiseIntensity;
	//half4 Mask1Color = SAMPLE_TEXTURE2D(_MaskTex1, sampler_MaskTex1, AppendUV);
	half4 Mask1Color = SAMPLE_TEXTURE2D_WARP( _MaskTex1 ,i.maskUV.xy ,_MaskTex1UVWrapMode);
	TempValue = lerp(Mask1Color.r, Mask1Color.r * Mask1Color.a, _Mask1AlphaMultiply);
	Mask2Color = SAMPLE_TEXTURE2D_WARP( _MaskTex2 ,i.maskUV.zw ,_MaskTex2UVWrapMode).r;
	#endif

	// Mask2贴图 
	//half4 Mask2Color = SAMPLE_TEXTURE2D(_MaskTex2, sampler_MaskTex2, MaskTex2UV);
	
	half4 DissolveMaskMultColor = lerpResult * DissolveColor * TempValue * Mask2Color.r;
	
	half4 smoothResult1 = smoothstep((_AlphaMin).xxxx, (_AlphaMin + _AlphaEdge).xxxx, (i.vertexColor.a * DissolveMaskMultColor));
	half4 smoothResult2 = smoothstep((_AlphaMin).xxxx, (_AlphaMin + _AlphaEdge).xxxx, DissolveMaskMultColor);
	half4 tempAlphaColor = lerp(smoothResult1, i.vertexColor.a * smoothResult2, _VertexAlphaOrderChange) * lerpResult.a * saturate(_TotalAlpha);
	
	half4 FragColor = half4((LerpColorMulResult * i.vertexColor).rgb, tempAlphaColor.r);
	clip(FragColor.a - _Cutoff);
	return OutputFXFinalColor(FragColor);
}

	MRTOutput MRTFrag(Varyings i)
	{
		MRTOutput mrtOutput = (MRTOutput)0;
		half4 bloomMultiplyer = _GlobalFXBloomOn > 0 ? _BloomTint * _GlobalFXBloomIntensity : _BloomTint;
		mrtOutput.fragColor = ColorFrag(i);
		mrtOutput.bloomColor = half4(mrtOutput.fragColor.rgb * bloomMultiplyer.rgb * _BloomOn, mrtOutput.fragColor.a);
		return mrtOutput;
	}

#endif


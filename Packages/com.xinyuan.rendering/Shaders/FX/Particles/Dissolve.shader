Shader "XinYuan/FX/Particles/Dissolve"
{
    Properties
    {
	    [BlendMode]_BlendMode("混合模式", Float) = 1
    	[Enum(UnityEngine.Rendering.CullMode)]_Cull("背面剔除", Float) = 0
	    [Toggle] _ZWrite("开启深度写入", Float) = 0.0
	    [Toggle] _FogOn("开启雾效", Float) = 0
        [Toggle] _DepthOffsetOn("开启深度偏移", Float) = 0
    	[Toggle] _AlphaClip("Alpha Clipping", Float) = 0.0
    	_Cutoff("Threshold", Range(0.0, 1.0)) = 0.5
        _ZOffsetViewSpace("Z Offset ViewSpace", Float) = 0
    
	    [Header(Global Alpha)]
    	_GlobalAlpha("总体透明度", Range(0, 1)) = 1
    		
    	// Main Texture
    	[Main(_MAIN_TEX_GRP)]_MAIN_TEX_GRP("主贴图设置", Float) = 0
    	[Sub(_MAIN_TEX_GRP)]_MainTex("主贴图", 2D) = "white" {}
    	[SubEnum(_MAIN_TEX_GRP, Repeat, 0, Clamp, 1)]_MainUVWrapMode("UV Wrap 模式", Float) = 0
        [SubEnum(_MAIN_TEX_GRP, RGB, 0, Channel, 1)]_MainColorChannel("颜色模式", Float) = 0
        [RGBAChannelMaskToVec4(_MAIN_TEX_GRP)]_MainChannel("    Channel通道", Vector) = (0, 0, 0, 1) 
    	[RGBAChannelMaskToVec4(_MAIN_TEX_GRP)]_MainAlphaChannel("Alpha通道", Vector) = (0, 0, 0, 1) 
    	[Sub(_MAIN_TEX_GRP)][HDR]_MainColor("主颜色", Color) = (1,1,1,1)
        [SubNumToggle(_MAIN_TEX_GRP)]_IsGradient("是否用渐变色", Float) = 0
        [Sub(_MAIN_TEX_GRP)][HDR]_GradientColor1("渐变色A", Color) = (1,1,1,1)
        [Sub(_MAIN_TEX_GRP)][HDR]_GradientColor2("渐变色B", Color) = (1,1,1,1)
        [Sub(_MAIN_TEX_GRP)]_GradientRotateParams("渐变旋转中心(XY) 角度(Z)", Vector) = (0.5, 0.5, 0, 0)
        [Sub(_MAIN_TEX_GRP)]_GradientTillingParams("渐变Tilling和Offset", Vector) = (1,1, 0, 0)
    	[Sub(_MAIN_TEX_GRP)]_MainUVFlowSpeed("UV流动速度(XY)", Vector) = (0, 0, 0, 0)
    	[Sub(_MAIN_TEX_GRP)]_MainTexRotateParams("旋转中心(XY) 角度(Z)", Vector) = (0.5, 0.5, 0, 0)
		[SubEnum(_MAIN_TEX_GRP, Off, 0, Const, 1, ParCustom1W, 2)]_MainTexDistortMode("UV扭曲模式", Float) = 0
	    [Sub(_MAIN_TEX_GRP)]_MainTexUVDistortIntensity("UV扭曲强度", Range(0, 1)) = 0.5
    	[Sub(_MAIN_TEX_GRP)]_MainHSV("HSV X(色相) Y(饱和度) Z(亮度)", Vector) = (0, 1, 1, 0)

	    // Detail Texture
    	[Main(_DETAIL_TEX_GRP)]_DETAIL_TEX_GRP("细节贴图设置(和主贴图相乘)", Float) = 0
    	[Sub(_DETAIL_TEX_GRP)]_DetailTex("细节贴图", 2D) = "white" {}
    	[SubEnum(_DETAIL_TEX_GRP, Repeat, 0, Clamp, 1)]_DetailUVWrapMode("UV Wrap 模式", Float) = 0
    	[RGBAChannelMaskToVec4(_DETAIL_TEX_GRP)]_DetailAlphaChannel("Alpha通道", Vector) = (0, 0, 0, 1) 
	    [Sub(_DETAIL_TEX_GRP)]_DetailUVFlowSpeed("UV流动速度(XY)", Vector) = (0, 0, 0, 0)
    	//[Sub(_DETAIL_TEX_GRP)]_DetailTexRotateParams("旋转中心(XY) 角度(Z)", Vector) = (0.5, 0.5, 0, 0)
	    [SubEnum(_DETAIL_TEX_GRP, Off, 0, Const, 1)]_DetailTexDistortMode("UV扭曲模式", Float) = 0
	    [Sub(_DETAIL_TEX_GRP)]_DetailTexUVDistortIntensity("UV扭曲强度", Range(0, 1)) = 0.5
	    
    	// Distortion
    	[Main(_DISTORTION_GRP)]_DISTORTION_GRP("扭曲设置", Float) = 0
    	[Sub(_DISTORTION_GRP)]_DistortionTex("扭曲贴图(RG)", 2D) = "black" {}
    	[SubEnum(_DISTORTION_GRP, Off, 0, parCustom2XY, 1)]_DistortionUVRandMode("UV随机模式", Float) = 0
    	[Sub(_DISTORTION_GRP)]_DistortionUVSpeed("UV流动速度(XY)", Vector) = (0, 0, 0, 0)
        [SubNumToggle(_DISTORTION_GRP)]_IsDistortionMask("是否用Mask.B作为遮罩", Float) = 0
	    
    	// Dissolve
    	[Main(_DISSOLVE_GRP)]_DISSOLVE_GRP("溶解设置", Float) = 0
		[Sub(_DISSOLVE_GRP)]_DissolveTex("溶解贴图(R)", 2D) = "white" {}
    	[SubEnum(_DISSOLVE_GRP, Repeat, 0, Clamp, 1)]_DissolveUVWrapMode("UV Wrap 模式", Float) = 0
    	[RGBAChannelMaskToVec4(_DISSOLVE_GRP)]_DissolveChannel("溶解通道", Vector) = (1, 0, 0, 0)
    	[SubEnum(_DISSOLVE_GRP, Off,0, Const,1, ParCustom2ZW,2)]_DissolveUVRandMode("溶解UV随机模式", Float) = 0
        [Sub(_DISSOLVE_GRP)]_DissolveUVFlowSpeed("UV流动速度(XY)", Vector) = (0, 0, 0, 0)
    	[Sub(_DISSOLVE_GRP)]_DissolveRotateParams("旋转中心(XY) 角度(Z)", Vector) = (0.5, 0.5, 0, 0)
    	[SubEnum(_DISSOLVE_GRP, Off, 0, Const, 1, ParCustom1Z, 2)]_DissolveUVDistortMode("溶解UV扭曲模式", Float) = 0
    	[Sub(_DISSOLVE_GRP)]_DissolveUVDistortIntensity("溶解UV扭曲强度", Range(0, 1)) = 0.5
	    [SubEnum(_DISSOLVE_GRP, Const, 0, ParCustom1X, 1)]_DissolveMode("溶解模式", Float) = 0
    	[Sub(_DISSOLVE_GRP)]_DissolveIntensity("溶解强度", Range(0, 1)) = 0
    	[SubEnum(_DISSOLVE_GRP, Add, 0, Lerp, 1, LerpMultiply, 2)]_DissolveColorMode("溶解颜色模式", Float) = 0
    	[Sub(_DISSOLVE_GRP)][HDR]_DissolveEdgeColor("溶解边颜色", Color) = (1, 1, 1, 1)
	    [Sub(_DISSOLVE_GRP)]_DissolveEdgeWidth("溶解边宽度", Range(0, 1)) = 0
    	[Sub(_DISSOLVE_GRP)]_DissolveEdgeInnerSoftness("溶解边内羽化", Range(0, 1)) = 0
    	[SubEnum(_DISSOLVE_GRP, Const, 0, ParCustom1Y, 1)] _DissolveEdgeOutterSoftnessMode("溶解边外羽化模式", Float) = 0
    	[Sub(_DISSOLVE_GRP)]_DissolveEdgeOutterSoftness("溶解边外羽化", Range(0, 1)) = 0    	
	    
    	// Secondary Dissolve
    	[Main(_SEC_DISSOLVE_GRP, _SEC_DISSOLVE_ON)]_SEC_DISSOLVE_GRP("二级溶解设置", Float) = 0
    	[Sub(_SEC_DISSOLVE_GRP)]_SecDissolveTex("溶解贴图(R)", 2D) = "white" {}
    	[SubEnum(_SEC_DISSOLVE_GRP, Repeat, 0, Clamp, 1)]_SecDissolveUVWrapMode("UV Wrap 模式", Float) = 0
    	[RGBAChannelMaskToVec4(_SEC_DISSOLVE_GRP)]_SecDissolveChannel("溶解通道", Vector) = (1, 0, 0, 0)
	    [Sub(_SEC_DISSOLVE_GRP)]_SecDissolveUVFlowSpeed("UV流动速度(XY)", Vector) = (0, 0, 0, 0)
    	//[Sub(_SEC_DISSOLVE_GRP)]_SecDissolveRotateParams("旋转中心(XY) 角度(Z)", Vector) = (0.5, 0.5, 0, 0)
	    [SubEnum(_SEC_DISSOLVE_GRP, Const, 0, ColorOverLifeTime(A), 1)]_SecDissolveMode("溶解模式", Float) = 0
    	[Sub(_SEC_DISSOLVE_GRP)]_SecDissolveIntensity("溶解强度", Range(0, 1)) = 0
//    	[SubEnum(_SEC_DISSOLVE_GRP, Add, 0, Lerp, 1, LerpMultiply, 2)]_SecDissolveColorMode("溶解颜色模式", Float) = 0
//    	[Sub(_SEC_DISSOLVE_GRP)][HDR]_SecDissolveEdgeColor("溶解边颜色", Color) = (1, 1, 1, 1)
//	    [Sub(_SEC_DISSOLVE_GRP)]_SecDissolveEdgeWidth("溶解边宽度", Range(0, 1)) = 0
    	[Sub(_SEC_DISSOLVE_GRP)]_SecDissolveEdgeInnerSoftness("溶解边内羽化", Range(0, 1)) = 0
//	    [Sub(_SEC_DISSOLVE_GRP)]_SecDissolveEdgeOutterSoftness("溶解边外羽化", Range(0, 1)) = 0   
    	
    	// Mask
    	[Main(_MASK_GRP, _MASK_ON)]_MASK_GRP("开启遮罩", Float) = 0
    	[Sub(_MASK_GRP)]_MaskTex("遮罩贴图", 2D) = "white" {}
    	[SubEnum(_MASK_GRP, Repeat, 0, Clamp, 1)]_MaskUVWrapMode("UV Wrap 模式", Float) = 0
    	[Sub(_MASK_GRP)]_MaskRotateParams("旋转中心(XY) 角度(Z)", Vector) = (0.5, 0.5, 0, 0)
    	[SubEnum(_MASK_GRP, R, 0, RxA, 1)]_MaskChannel("遮罩通道", Float) = 0
        [SubEnum(_MASK_GRP, Off, 0, Const, 1)]_MaskDistortMode("UV扭曲模式", Float) = 0
	    [Sub(_MASK_GRP)]_MaskUVDistortIntensity("UV扭曲强度", Range(0, 1)) = 0.5

    	//VAT
    	[Main(_VAT_GRP,_VAT_ON)]_VATOn("开启VAT",Float) = 0
    	[Sub(_VAT_GRP)]_VatTexture("VAT图片",2D) = "black"{}
	    [Sub(_VAT_GRP)]_XboundingMax("X包围盒最大值",Float) = 1
	    [Sub(_VAT_GRP)]_XboundingMin("X包围盒最小值",Float) = 0 
	    [Sub(_VAT_GRP)]_YboundingMax("Y包围盒最大值",Float) = 1
	    [Sub(_VAT_GRP)]_YboundingMin("Y包围盒最小值",Float) = 0 
	    [Sub(_VAT_GRP)]_ZboundingMax("Z包围盒最大值",Float) = 1
	    [Sub(_VAT_GRP)]_ZboundingMin("Z包围盒最小值",Float) = 0 
	    [Sub(_VAT_GRP)]_numOfFrames("动画帧数" ,Float) = 1
    	[Sub(_VAT_GRP)]_VertexUVRows("顶点行数",Float) = 1
	    [Sub(_VAT_GRP)]_VatAnimspeed("动画播放速度",Float) = 1
    	
        // Depth Fade
		[Main(_DEPTH_GRP,_DEPTH_FADE_ON)] _DEPTH_GRP ("软化插边", Float) = 0
		[Sub(_DEPTH_GRP)] _DepthFadeRange("软化范围", Float) = 0.1
		[Sub(_DEPTH_GRP)] _DepthFadePow("软化强度", Range(0, 10)) = 1
		
    	[Main(_CAMERADEPTH_GRP,_NEAR_CAMERA_FADE_ON)] _CameraDepth("近平面渐隐", Float) = 0
		[Sub(_CAMERADEPTH_GRP)] _NearFadeStar ("Near Fade Star", Float) = 5
		[Sub(_CAMERADEPTH_GRP)] _NearFadeRange ("Near Fade Range", Float) = 10
    	
	    // Bloom
	    [Main(_BLOOM_GRP, TransparentFXBloom)] _BloomOn("开启Bloom", Float) = 0        
		[Sub(_BLOOM_GRP)][HDR]_BloomTint("Bloom颜色", Color) = (1, 1, 1, 1)
    	
    	
	    [Main(_ALPHA_GRP, _DUMMY_KW)] _AlphaRangeON("开启Alpha范围调整", Float) = 0
    	[MinMaxSlider(_ALPHA_GRP, _AlphaRangeMin, _AlphaRangeMax)]_AlphaRange("Alhpa范围", Range(0, 2)) = 0
    	[HideInInspector]_AlphaRangeMin("Min", Float) = 0
    	[HideInInspector]_AlphaRangeMax("Max", Float) = 1

	    // Blending state
	    [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0
	    [HideInInspector] _Cull("__Cull", Float) = 0.0

        [HideInInspector] _QueueOffset("Queue offset", Float) = 0
    }
    SubShader
    {
        Tags { 
                "RenderType" = "Transparent" 
                "Queue" = "Transparent"
                "RenderPipeline" = "UniversalPipeline"
                "UniversalMaterialType" = "Unlit"
                "IgnoreProjector" = "True" 
            }

    	
    	HLSLINCLUDE

		#ifndef FOLDOUT
		#define FOLDOUT 1
    	#endif

    	
    	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    	#include "Packages/com.xinyuan.rendering/ShaderLibrary/FX/FXCommonGlobalVar.hlsl"
		#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/UVTransform.hlsl"
    	#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/Dissolve.hlsl"
    	#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/ColorAdjustment.hlsl"
    	#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/UVHelper.hlsl"

    	TEXTURE2D(_MainTex);					//SAMPLER(sampler_MainTex);
    	TEXTURE2D(_DetailTex);					//SAMPLER(sampler_DetailTex);
    	TEXTURE2D(_DistortionTex);				//SAMPLER(sampler_DistortionTex);
		TEXTURE2D(_DissolveTex);				//SAMPLER(sampler_DissolveTex);
    	
    	#if defined(_SEC_DISSOLVE_ON)
    	TEXTURE2D(_SecDissolveTex);				//SAMPLER(sampler_SecDissolveTex);
		#endif
    	
        #if defined(_MASK_ON)
    	TEXTURE2D(_MaskTex);					//SAMPLER(sampler_MaskTex);
        #endif
        #if defined(_DEPTH_FADE_ON)
    	TEXTURE2D(_CameraDepthTexture);			SAMPLER(sampler_CameraDepthTexture);
        #endif
    	#if defined(_VAT_ON)
    	TEXTURE2D(_VatTexture);					//SAMPLER(sampler_VatTexture);
    	#endif

		#if  DEBUG_DISPLAY
		CBUFFER_START(PerDebugMaterial)
		half _Blend;
		CBUFFER_END
		#endif

		#include "Packages/com.xinyuan.rendering/ShaderLibrary/FX/FXDebug.hlsl"
    	
    	CBUFFER_START(UnityPerMaterial)
    	#if FOLDOUT
        //depth Offset
        half _DepthOffsetOn;
        half _ZOffsetViewSpace;
		half _Cutoff;
    	half _AlphaClip;
    	// Distortion
    	half4 _DistortionTex_ST;
		half2 _DistortionUVSpeed;
    	half _DistortionUVRandMode;
        half _IsDistortionMask;

    	// Main Texture
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
        
    	
    	// Detail Texture
    	half4 _DetailTex_ST;
		//half4 _DetailTexRotateParams;
    	half4 _DetailAlphaChannel;
    	half4 _DetailUVFlowSpeed;
		half _DetailTexDistortMode;
    	half _DetailTexUVDistortIntensity;
		half _DetailUVWrapMode;
    	
    	// Dissolve

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

  		// Secondary Dissolve
  		half4 _SecDissolveTex_ST;
  		half4 _SecDissolveChannel;
		half4 _SecDissolveUVFlowSpeed;
  //   	half4 _SecDissolveRotateParams;
  //   	half4 _SecDissolveEdgeColor;
    	half _SecDissolveUVWrapMode;
	   	half _SecDissolveIntensity;
  //   	half _SecDissolveColorMode;
	 //    half _SecDissolveEdgeWidth;
	   	half _SecDissolveEdgeInnerSoftness;
	 //    half _SecDissolveEdgeOutterSoftness;   
		half _SecDissolveMode;
  //   	
		// Mask
    	half4 _MaskTex_ST;
    	half4 _MaskRotateParams;
    	half _MaskUVWrapMode;
    	half _MaskChannel;      
        half _MaskDistortMode ;
        half _MaskUVDistortIntensity;

        // Depth Fade       
        half _DepthFadeRange;
		half _DepthFadePow;

        // Near Camera Fade  
        half _CameraDepth;
        half _NearFadeStar;
        half _NearFadeRange;
       
		
		// Alpha Control
    	half _AlphaRangeON;
    	half _AlphaRangeMin;
    	half _AlphaRangeMax;
    	half _GlobalAlpha;

    	half _BloomOn;
    	half4 _BloomTint;

    	//VAT
    	float _XboundingMax;
    	float _XboundingMin;
    	float _YboundingMax;
    	float _YboundingMin;
    	float _ZboundingMax;
    	float _ZboundingMin;
    	half _numOfFrames;
    	half _VertexUVRows;
    	half _VatAnimspeed;
    	half _VATOn;
    	#endif // FOLDOUT
    	CBUFFER_END
    	
	    struct Attributes
	    {
		    float3 positionOS		: POSITION;
    		float2 uv				: TEXCOORD0;
    		half4  color			: COLOR;
    		float4 customData1		: TEXCOORD1; // X: 溶解强度 Y:溶解外羽化 Z: 溶解扭曲强度  W: 主贴图扭曲强度
    		float4 customData2		: TEXCOORD2; // XY: 扭曲贴图UV随机 ZW: 溶解贴图UV随机
    		#if defined(_VAT_ON)
    		float4 texcoord3         : TEXCOORD3;
    		float2 texcoord4		 : TEXCOORD4;
    		#endif
    		
	    };


	    struct Varings
	    {
		    float4 positionCS		: SV_POSITION;
	    	half4 color				: COLOR;
	    	float4 uv				: TEXCOORD0;
	    	float4 uv1				: TEXCOORD1;
			float4 uv2				: TEXCOORD2;
	    	float4 customData1		: TEXCOORD3;
	    	float4 customData2		: TEXCOORD4;
            float3 positionWS       : TEXCOORD5;
            float4 ScreenPosition   : TEXCOORD6;
	    	
	    };

        struct MRTOutput
        {
	        half4 fragColor		: SV_TARGET0;
	        half4 bloomColor	: SV_TARGET1;
        };

    	Varings vert(Attributes input)
    	{
    		Varings output = (Varings)0;
    		
    		///////////////////////////////////////////////////////////////////////////////////////////////////
    		/// VAT
    		///////////////////////////////////////////////////////////////////////////////////////////////
    		//#if FOLDOUT
    		#if _VAT_ON
    		float timeInFrames = ((ceil(frac(-_Time.y * _VatAnimspeed) * _numOfFrames))/_numOfFrames);
			float4 texturePos =  (SAMPLE_TEXTURE2D_WARP_LOD(_VatTexture, float2((input.texcoord3.x), (timeInFrames * _VertexUVRows + input.texcoord3.y)),0));
			float3 expand = float3(_XboundingMax - _XboundingMin ,_YboundingMax - _YboundingMin ,_ZboundingMax - _ZboundingMin) * float3(input.texcoord3.z , input.texcoord3.w , input.texcoord4.x);
			texturePos.xyz *= expand;
			texturePos.xyz +=float3( _XboundingMin  ,_YboundingMin  ,_ZboundingMin) * float3(input.texcoord3.z , input.texcoord3.w , input.texcoord4.x);
    		input.positionOS.xyz += texturePos.xyz  ;
			#endif
    		//#endif
    		
            output.positionWS = TransformObjectToWorld(input.positionOS) ;
    		output.positionCS = TransformObjectToHClip(input.positionOS);

	        float eps = 5.960464478e-8;
	        float modifiedPositionVS_Z = -max(_ProjectionParams.y + eps, abs(output.positionCS.w) - _ZOffsetViewSpace);
	        float modifiedPositionCS_Z = modifiedPositionVS_Z * UNITY_MATRIX_P[2].z + UNITY_MATRIX_P[2].w;
	        output.positionCS.z =_DepthOffsetOn > 0 ? modifiedPositionCS_Z *  output.positionCS.w / -(modifiedPositionVS_Z) :output.positionCS.z ;	
            
            output.ScreenPosition = ComputeScreenPos(output.positionCS);
    		output.color = input.color;

    		output.uv.xy = input.uv * _MainTex_ST.xy + _MainTex_ST.zw + _MainUVFlowSpeed.xy * _Time.x;
    		output.uv.zw = input.uv * _DissolveTex_ST.xy + _DissolveTex_ST.zw ;

    		output.uv1.xy = input.uv * _DetailTex_ST.xy + _DetailTex_ST.zw + _DetailUVFlowSpeed.xy * _Time.x;
    		output.uv1.zw = input.uv * _DistortionTex_ST.xy + _DistortionTex_ST.zw;

    		output.uv2.xy = input.uv * _MaskTex_ST.xy + _MaskTex_ST.zw;
    		output.uv2.zw = input.uv ;
			output.customData1 = input.customData1;
    		output.customData2 = input.customData2;
    		
    		return output;
    	}


    	half4 ColorFrag(Varings input, FRONT_FACE_TYPE frontFacing)
    	{
            ///////////////////////////////////////////////////////////////////////////////////////////////////
    		/// Mask
    		///////////////////////////////////////////////////////////////////////////////////////////////
    		#if FOLDOUT
            half dissolvemask = 1 ;
    		#if _MASK_ON
    		float2 dissovlemaskUV = input.uv2.xy;
    		UNITY_BRANCH
    		if (_IsDistortionMask > 0)
    			dissolvemask = SAMPLE_TEXTURE2D_WARP(_MaskTex, dissovlemaskUV,_MaskUVWrapMode).b;           
			#endif
    		#endif
    		

    		///////////////////////////////////////////////////////////////////////////////////////////////
    		/// Distotrion
    		//////////////////////////////////////////////////////////////////////////////////////////////
    		#if FOLDOUT
    		float2 uvDistorted = 0;
    		float2 distortUV = input.uv1.zw;
    		distortUV += _DistortionUVRandMode > 0 ? input.customData2.xy : 0;
    		distortUV = FlowUV(distortUV, _DistortionUVSpeed, _TimeParameters.x);
    		uvDistorted = SAMPLE_TEXTURE2D_WARP(_DistortionTex, distortUV,0).rg * dissolvemask.xx;
            uvDistorted = uvDistorted *2 -1 ;
    		#endif


    		///////////////////////////////////////////////////////////////////////////////////////////
    		/// Main Texture
    		////////////////////////////////////////////////////////////////////////////////////////////
    		#if FOLDOUT
			float2 mainTexUVDistorted = uvDistorted * lerp(_MainTexUVDistortIntensity, input.customData1.w, saturate( _MainTexDistortMode - 1))
    									* step(0.1, _MainTexDistortMode);
    		float2 mainTexUV = input.uv.xy + mainTexUVDistorted;
    		UNITY_BRANCH
            if (_MainTexRotateParams.z != 0)
            {
	            mainTexUV = RotateUV(mainTexUV, _MainTexRotateParams.xy, _MainTexRotateParams.z, true);
            }
    		//mainTexUV = lerp(mainTexUV, saturate(mainTexUV), _MainUVWrapMode);
    		half4 mainTexSample = SAMPLE_TEXTURE2D_WARP( _MainTex ,mainTexUV ,_MainUVWrapMode);
            half Alpha = dot(mainTexSample, _MainAlphaChannel);
            half Channel = dot(mainTexSample, _MainChannel);
            mainTexSample.rgb = lerp(mainTexSample.rgb ,Channel.xxx ,_MainColorChannel);
    		mainTexSample.rgb = DoHSV(mainTexSample.rgb, _MainHSV);
            half Lerpmask = RotateUV(input.uv2.zw * _GradientTillingParams.xy + _GradientTillingParams.zw,_GradientRotateParams.xy, _GradientRotateParams.z, true).x ;
            half3 Lerpcolor = lerp(_GradientColor1.rgb, _GradientColor2.rgb , Lerpmask);
            Lerpcolor = lerp(1,Lerpcolor ,_IsGradient);
            mainTexSample.rgb *= Lerpcolor ;
    		mainTexSample.a = Alpha ;
    		#endif
    		
    		//////////////////////////////////////////////////////////////////////////////////////////////
    		/// Detail Texture
    		//////////////////////////////////////////////////////////////////////////////////////////////
    		#if FOLDOUT
			float2 detailUV = input.uv1.xy;
    		detailUV += _DetailTexDistortMode > 0 ? uvDistorted * _DetailTexUVDistortIntensity : 0;
    		//detailUV = RotateUV(detailUV, _DetailTexRotateParams.xy, _DetailTexRotateParams.z, true);
			//detailUV = lerp(detailUV, saturate(detailUV), _DetailUVWrapMode);
    		half4 detailTexSample = SAMPLE_TEXTURE2D_WARP(_DetailTex, detailUV,_DetailUVWrapMode);
    		detailTexSample.a = dot(detailTexSample, _DetailAlphaChannel);
    		#endif


    		////////////////////////////////////////////////////////////////////////////////////////////////
    		/// Dissolve
    		//////////////////////////////////////////////////////////////////////////////////////////////
			#if FOLDOUT
			float2 dissUV = input.uv.zw;   		
            dissUV += lerp( _DissolveUVFlowSpeed.xy * _Time.y * saturate(_DissolveUVRandMode) , input.customData2.zw  , saturate( _DissolveUVRandMode -1) );
    		UNITY_BRANCH
            if (_DissolveRotateParams.z != 0)
            {
	            dissUV = RotateUV(dissUV, _DissolveRotateParams.xy, _DissolveRotateParams.z, true);
            }
            
    		dissUV += lerp(_DissolveUVDistortIntensity, input.customData1.z, saturate(_DissolveUVDistortMode - 1)) * uvDistorted
    					* step(0.1, _DissolveUVDistortMode);
			half dissVal = dot(SAMPLE_TEXTURE2D_WARP(_DissolveTex, dissUV ,_DissolveUVWrapMode), _DissolveChannel);
			half dissIntensity = lerp(_DissolveIntensity, input.customData1.x, step(0.1, _DissolveMode));
			half dissEdgeMask = 0;
    		half dissAlpha = 1;
    		Dissolve(dissVal,
    				dissIntensity,
    				_DissolveEdgeWidth,
    				_DissolveEdgeInnerSoftness,
    				lerp(_DissolveEdgeOutterSoftness, input.customData1.y, step(0.1, _DissolveEdgeOutterSoftnessMode)),
    				dissEdgeMask,
    				dissAlpha);
    		

    		#endif

    		///////////////////////////////////////////////////////////////////////////////////////////////// 
    		/// Secondary Dissovle
    		/////////////////////////////////////////////////////////////////////////////////////////////////
    		//half secDissEdgeMask = 0;
    		half secDissAlpha = 1;
			#if _SEC_DISSOLVE_ON
    		float2 secDissUV = input.uv2.zw*_SecDissolveTex_ST.xy + _SecDissolveTex_ST.zw + _SecDissolveUVFlowSpeed.xy * _Time.x;
    		half secDissVal = dot(SAMPLE_TEXTURE2D_WARP(_SecDissolveTex, secDissUV,_SecDissolveUVWrapMode), _SecDissolveChannel);
    		half secDissIntensity = lerp(_SecDissolveIntensity, input.color.a, _SecDissolveMode);
    		UNITY_BRANCH
    		if (_SecDissolveMode> 0)
    		{
    			input.color.a = 1;
    		}
			secDissAlpha = smoothstep( secDissIntensity,secDissIntensity + _SecDissolveEdgeInnerSoftness,secDissVal);
    		// Dissolve(secDissVal,
    		// 		lerp(_SecDissolveIntensity, input.color.a, _SecDissolveMode),
    		// 		_SecDissolveEdgeWidth,
    		// 		_SecDissolveEdgeInnerSoftness,
    		// 		_SecDissolveEdgeOutterSoftness,
    		// 		secDissEdgeMask,
    		// 		secDissAlpha);
    		#endif
    		
            ///////////////////////////////////////////////////////////////////////////////////////////////////
    		/// Mask
    		///////////////////////////////////////////////////////////////////////////////////////////////
    		#if FOLDOUT
			half mask = 1;
    		#if _MASK_ON
    		float2 maskUV = input.uv2.xy;
            maskUV += _MaskDistortMode > 0 ? uvDistorted * _MaskUVDistortIntensity : 0;
    		UNITY_BRANCH
    		if (_MaskRotateParams.z != 0)
			{
			  maskUV = RotateUV(maskUV, _MaskRotateParams.xy, _MaskRotateParams.z, true);
			}
			
    		half4 maskSample = SAMPLE_TEXTURE2D_WARP(_MaskTex, maskUV ,_MaskUVWrapMode);         
    		mask = lerp(maskSample.r, maskSample.r * maskSample.a, step(0.1, _MaskChannel));
			#endif
    		#endif

    		
    		
    		//////////////////////////////////////////////////////////////////////////////////
    		/// Compose
    		///////////////////////////////////////////////////////////////////////////////
    		half4 vertColor = half4(input.color.rgb,input.color.a);
    		half4 finalColor = mainTexSample * detailTexSample *  _MainColor * vertColor;
    		finalColor.a *= mask;
    		
			half3 edgeAdd = finalColor.rgb + _DissolveEdgeColor.rgb * dissEdgeMask;
    		half3 edgeLerp = lerp(finalColor.rgb, _DissolveEdgeColor.rgb,  dissEdgeMask);
    		half3 edgeLerpMul = lerp(finalColor.rgb, _DissolveEdgeColor.rgb * finalColor.rgb,  dissEdgeMask);
			finalColor.rgb = _DissolveColorMode > 1 ? edgeLerpMul : (_DissolveColorMode > 0 ? edgeLerp : edgeAdd);
			finalColor.a *= dissAlpha;
    		finalColor.a *= secDissAlpha;
            if (_AlphaClip>0)
				clip(finalColor.a - _Cutoff);
    		// #if _SEC_DISSOLVE_ON
    		// edgeAdd = finalColor.rgb + _SecDissolveEdgeColor.rgb * secDissEdgeMask;
    		// edgeLerp = lerp(finalColor.rgb, _SecDissolveEdgeColor, secDissEdgeMask);
    		// edgeLerpMul = lerp(finalColor.rgb, _SecDissolveEdgeColor * finalColor.rgb,  secDissEdgeMask);
    		// finalColor.rgb = _SecDissolveColorMode > 1 ? edgeLerpMul : (_SecDissolveColorMode > 0 ? edgeLerp : edgeAdd);
    		// finalColor.a *= secDissAlpha;
      //       #endif
    		
    		///////////////////////////////////////////////////////////////////////////////////////////////////
    		/// DEPTH
    		///////////////////////////////////////////////////////////////////////////////////////////////
    		#if FOLDOUT
	        #if _DEPTH_FADE_ON
                half rawDepth = SAMPLE_DEPTH_TEXTURE_LOD(_CameraDepthTexture, sampler_CameraDepthTexture, input.ScreenPosition.xy / input.ScreenPosition.w, 0);
	            half sceneZ = LinearEyeDepth(rawDepth, _ZBufferParams);
		        half selfZ = LinearEyeDepth(input.positionCS.z, _ZBufferParams);
		        finalColor.a *= pow(saturate( abs(sceneZ - selfZ) / max(_DepthFadeRange, 0.001h)), _DepthFadePow);
	        #endif
            #endif


            #if FOLDOUT         
	            half viewDistance = distance(_WorldSpaceCameraPos.xyz, input.positionWS.xyz);
	            half nearFadeStar = clamp(_NearFadeStar, 0, HALF_MAX);
	            half nearFadeRange = clamp(_NearFadeRange, 0, HALF_MAX);
	            finalColor.a *=lerp(1, smoothstep(nearFadeStar, nearFadeStar+nearFadeRange, viewDistance) ,_CameraDepth);   
            #endif

    		finalColor.a = lerp(finalColor.a, smoothstep(_AlphaRangeMin, _AlphaRangeMax, finalColor.a), _AlphaRangeON);
    		finalColor.a = saturate(finalColor.a) * _GlobalAlpha;
    		return OutputFXFinalColor(finalColor);
    	}
    	

    	ENDHLSL


        Pass
        {
            Tags { "LightMode" = "TransparentFX" }
            ZWrite [_ZWrite]
			ZTest LEqual
            Cull [_Cull]
        	 Blend [_SrcBlend] [_DstBlend]
			ColorMask RGB
            
			HLSLPROGRAM
            
            #pragma target 3.5
            #pragma vertex vert
            #pragma fragment MRTFrag

			#pragma shader_feature_local_fragment _MASK_ON
            #pragma shader_feature_local_fragment _DEPTH_FADE_ON
			#pragma shader_feature_local_fragment _SEC_DISSOLVE_ON
			#pragma shader_feature_local_vertex _VAT_ON
            #pragma multi_compile_fog
			#pragma multi_compile_fragment _ DEBUG_DISPLAY

			MRTOutput MRTFrag(Varings input, FRONT_FACE_TYPE frontFacing : FRONT_FACE_SEMANTIC)
            {
	            MRTOutput mrtOutput = (MRTOutput)0;
	            half4 bloomMutiplyer = _GlobalFXBloomOn > 0 ? _BloomTint * _GlobalFXBloomIntensity : _BloomTint;
	            mrtOutput.fragColor =  ColorFrag(input, frontFacing);
	            mrtOutput.bloomColor = half4(mrtOutput.fragColor.rgb * bloomMutiplyer.rgb * _BloomOn, mrtOutput.fragColor.a);
	
	            return mrtOutput;
            }
			
           
            ENDHLSL
        }

    }
    
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "XYRendering.Editor.DissolveGUI" 
}
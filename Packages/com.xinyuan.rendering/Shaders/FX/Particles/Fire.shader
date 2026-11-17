Shader "XinYuan/FX/Particles/Fire"
{
    Properties
    {
        // Main 
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
	    [ToggleOff]_FresnelMaskOn("开启Fresnel遮罩模拟", Float) = 0
    	_FresnelMaskMul("Fresnel遮罩范围", Range(0, 5)) = 1
    	_FresnelMaskPow("Fresnel遮罩过渡", Range(0, 100)) = 1
    	_RemapNewMin("RemapNewMin", Float) = 0
    	_RemapNewMax("RemapNewMax", Float) = 1
        
        // Noise
        //_NoiseType("噪声类型", Float) = 0
        _NoiseTex("噪声贴图", 2D) = "black" {}
    	_NoiseTexUVWrapMode("UV Wrap模式", Float) = 0
        [ToggleOff] _InvertNoise("反向Noise", Float) = 0  
        //_NoiseScale("噪声Scale", Float) = 1
        //_NoiseAngle("噪声Angle", Float) = 0
        //_NoiseDensity("噪声密度", Float) = 1
        [ToggleOff] _NoiseStrenByCustomData("噪声强度 By Customdata", Float) = 0
        _NoiseStren("噪声强度", Float) = 1
        _NoiseUSpeed("Noise U Speed", Float) = 0
        _NoiseVSpeed("Noise V Speed", Float) = 0
    	
    	 // Noise2
        //_Noise2Type("噪声2类型", Float) = 0
        _Noise2Tex("噪声2贴图", 2D) = "black" {}
    	_Noise2TexUVWrapMode("UV Wrap模式", Float) = 0
        [ToggleOff] _InvertNoise2("反向Noise2", Float) = 0  
        //_Noise2Scale("噪声2Scale", Float) = 1
        //_Noise2Angle("噪声2Angle", Float) = 0
        //_Noise2Density("噪声2密度", Float) = 1
        [ToggleOff] _Noise2StrenByCustomData("噪声2强度 By Customdata", Float) = 0
        _Noise2Stren("噪声2强度", Float) = 1
        _Noise2USpeed("Noise2 U Speed", Float) = 0
        _Noise2VSpeed("Noise2 V Speed", Float) = 0
    	
        
        // distortion Mask
        _MaskType("遮罩类型", Float) = 0 // 0-UV 1-贴图
        _NoiseMask("遮罩贴图(R)", 2D) = "white" {}
        //_NoiseMaskRot("遮罩旋转", Float) = 0
        _NoiseMaskPow("遮罩Power", Float) = 1
        [ToggleOff] _InvertMask("反向Mask", Float) = 0
        
        
        // Dispalcement
        [ToggleOff] _DisplacementOn ("开启顶点置换", Float) = 0
        _DisplaceMap("置换图（R）", 2D) = "black" {}
        [ToggleOff]_InvertDisplaceMap("反向置换图", Float) = 0
        _DisplaceUVWrapMode("置换UV Wrap模式", Float) = 0
        _DisplaceUVMoveMode("置换UV流动模式", Float) = 0
        _DisplaceUSpeed("置换U速度", Float) = 0
        _DisplaceVSpeed("置换V速度", Float) = 0     
        [ToggleOff] _DisplaceStrenByCustomData("置换强度 By Customdata", Float) = 0    
        _DisplaceStren("置换强度", Float) = 0.5

        // Dissolve
        [ToggleOff] _DissovleOn("开启溶解", Float) = 0
        _DissMap ("溶解图（R）", 2D) = "white" {}
        [ToggleOff]_InvertDissMap("反向溶解图", Float) = 0
        _DissUVWrapMode("溶解UV Wrap模式", Float) = 0
        _DissUVMoveMode("溶解UV流动模式", Float) = 0
        _DissUSpeed("溶解U速度", Float) = 0
        _DissVSpeed("溶解V速度", Float) = 0
        [ToggleOff] _DissStrenByCustomData("溶解强度 By Customdata", Float) = 0
        _DissStren ("溶解强度", Range(0, 1)) = 1
        _DissSmooth("溶解平滑度", Range(0, 1)) = 0.25
		[ToggleOff] _DissovleRandomOn("开启随机溶解", Float) = 0
    	
        // visible Mask
        [ToggleOff] _AlphaMaskOn("开启AlphaMask", Float) = 0  
    	_AlphaMaskUVWrapMode("UV Wrap模式", Float) = 0       
        _AlphaMaskTex("遮罩贴图(R)", 2D) = "white" {}
        //_AlphaMaskRot("遮罩旋转", Float) = 0
        _AlphaMaskStren("遮罩强度", Range(0, 1)) = 1
    	_AlphaMaskDistort("遮罩扰乱强度", Float) = 0
        [ToggleOff] _InvertAlphaMask("反向Mask", Float) = 0
        
        [ToggleOff]_TransparentZWrite("深度写入", Float) = 0
        [ToggleOff]_FogOn("开启雾效", Float) = 0

    	[ToggleOff]_AlphaSimulateOn("开启透明度模拟火焰形态", Float) = 0
    	
        _Cutoff("Alpha Cutoff", Range(0,1)) = 0.5

		// Bloom
		[Toggle]_BloomOn("开启Bloom", Float) = 1        
		[HDR]_BloomTint("Bloom颜色", Color) = (1, 1, 1, 1)

		// Gameplay Control
		_AlphaMultiplyer ("GamePlay Alpha 相乘系数", Range(0, 1)) = 1
    	
        // Blending state
		[HideInInspector] _Surface("__surface", Float) = 1.0
		[HideInInspector] _Blend("__blend", Float) = 1.0
        [HideInInspector] _AlphaClip("__clip", Float) = 0.0
        [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0
        [HideInInspector] _ZWrite("__ZWrite", Float) = 0.0
		[HideInInspector] _Cull("__Cull", Float) = 0.0

        [HideInInspector] _QueueOffset("Queue offset", Float) = 0
    	
        [Toggle] _DepthOffsetOn("开启深度偏移", Float) = 0
        _ZOffsetViewSpace("Z Offset ViewSpace", Float) = 0
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
        
        LOD 150

        Pass
        {
            Tags { "LightMode" = "TransparentFX" }
            ZWrite [_ZWrite]
        	Cull [_Cull]
        	ZTest LEqual
            Blend [_SrcBlend] [_DstBlend]
			ColorMask RGB
            
			HLSLPROGRAM
            
            #pragma target 4.5
            #pragma vertex vert
            #pragma fragment MRTFrag

			//#pragma shader_feature_local _ _DISSOVLE_ON
			#define _DISSOVLE_ON_BRANCH
			
            //#pragma shader_feature_local _ _ALPHAMASK_ON
			#define _ALPHAMASK_ON_BRANCH

			#define _ALPHASIMULATE_ON_BRANCH
			
            #pragma shader_feature_local _DISPLACEMENT_ON
            #pragma shader_feature_local_fragment _TEXTURE_MASK_ON
            #pragma shader_feature_local_fragment _ALPHATEST_ON

			#pragma shader_feature_local _ALPHA_SIMULATE_ON
			
            #pragma multi_compile_fog
            #pragma multi_compile_instancing

			#pragma multi_compile_fragment _ DEBUG_DISPLAY

            #include "Packages/com.xinyuan.rendering/Shaders/FX/Particles/FireInput.hlsl"            
            #include "Packages/com.xinyuan.rendering/Shaders/FX/Particles/FirePass.hlsl"

            ENDHLSL
        }


//        Pass
//        {
//            Tags { "LightMode" = "TransparentFXBloom" }
//            
//            ZWrite Off
//			ZTest LEqual
//            Cull [_Cull]
//            Blend [_SrcBlend] [_DstBlend]
//			//ColorMask RGB
//            
//			HLSLPROGRAM
//            
//            #pragma target 3.5
//            #pragma vertex vert
//            #pragma fragment BloomFrag
//            
//            #pragma shader_feature_local _ _ALPHAMASK_ON
//            #pragma shader_feature_local _ _DISPLACEMENT_ON
//            #pragma shader_feature_local _ _DISSOVLE_ON
//            #pragma shader_feature_local_fragment _ TEXTURE_MASK_ON
//            #pragma shader_feature_local_fragment _ALPHATEST_ON
//            
//            #pragma multi_compile_fog
//            #pragma multi_compile_instancing   
//
//            #include "Packages/com.xinyuan.rendering/Shaders/FX/Particles/FireInput.hlsl"            
//            #include "Packages/com.xinyuan.rendering/Shaders/FX/Particles/FirePass.hlsl"
//
//            ENDHLSL
//        }

    }
    
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "XYRendering.Editor.FireGUI"

}
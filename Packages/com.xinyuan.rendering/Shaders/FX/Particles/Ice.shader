Shader "XinYuan/FX/Particles/Ice"
{
    Properties
    {
        // Main Texture
		[MainTexture]_BaseMap("主贴图", 2D) = "white" {}
        _BaseWrapMode ("UV Wrap模式", Float) = 0.0
		_BaseUVMoveMode ("UV运动模式", Float) = 0.0	// 0-Off 1-OffsetAnimated 2-CustomData_ZW
		_BaseUSpeed ("U速度", Float) = 0.0
		_BaseVSpeed ("V速度", Float) = 0.0
		_BaseRotAngle("UV旋转角度", Float) = 0.0

        // Ramp Texture
		_RampTex("Ramp贴图(R)", 2D) = "white" {}
		[Toggle]_InvertRampTex("反向Ramp贴图", Float) = 0
		[HDR]_RampColor1("渐变色A", Color) = (1,1,1,1)
		[HDR]_RampColor2("渐变色B", Color) = (0, 0, 0, 1)
        _RampValueCtrl("X(乘)Y(加)Z(Pow)", Vector) = (1,0,1,0)
		
		// Bloom
		[Toggle]_BloomOn("开启Bloom", Float) = 1        
		[HDR]_BloomTint("Bloom颜色", Color) = (1, 1, 1, 1)

		// Normal Map
		_NormalMap("法线贴图", 2D) = "bump" {}
		_NormalScale("法线Scale", Float) = 1
        
		// Volumetric Control
		_VolUVOffsetStren("体积感UV偏移强度", Float) = 1
		[Toggle]_VolUVOffsetNoiseON("UV偏移by Noise", Float) = 0
	    _VolNoiseType("噪声类型", Float) = 0
        _VolNoiseTex("噪声贴图", 2D) = "white" {}
        _VolNoiseScale("噪声Scale", Float) = 1
        _VolNoiseAngle("噪声Angle", Float) = 0
        _VolNoiseDensity("噪声密度", Float) = 1
        [Toggle]_InvertVolNoise("反向Noise", Float) = 0
        _VolUVNoiseStren("体积感UV噪声强度", Float) = 1  
	     
		// Distortion
		[Toggle]_ClearnessOn("开启通透性", Float) = 0
		_Clearness("通透性", Range(0, 1)) = 0
	    _DistortionStren("扭曲强度", Float) = 0.25
		[Toggle]_RampClearnessOn("通透关联Ramp", Float) = 0
		[Toggle]_FresnelClearnessOn("通透关联Fresnel", Float) = 0
        _FresnelClearnessPow("Fresnel Pow", Float) = 1

		// Rim Light
		[Toggle]_FresnelOn("开启边缘光", Float) = 0
		_FresnelColor("Fresnel颜色", Color) = (1, 1, 1, 1)
		_FresnelPow("Fresnel Pow", Float) = 1

		// Specular Light
		[Toggle]_SpecLightOn("开启高光", Float) = 0
        _SpecLightDir("Specular光方向", Vector) = (1, -0.5, 0.5, 0)
	    _SpecColor("Specular颜色", Color) = (1,1,1,1)
		_Shininess("光滑度", Float) = 2
        
        // Dissolve
		[Toggle]_DissolveOn("开启溶解", Float) = 0
		_DissTex("溶解贴图（R）", 2D) = "white" {}
        _DissNoiseType("溶解Noise类型", Float) = 0
		_DissNoiseScale("Noise Scale", Float) = 1
        _DissNoiseAngleOffset("Noise角度偏移", Float) = 0
        _DissNoiseCellDensity("Noise Cell密度", Float) = 1
		[Toggle]_InvertDissNoise("反向Noise", Float) = 0
		_DissParams("Noise强度(X) 阈值偏移(YZ) 溶解进度(W)", Vector) = (1, 0, 0, 0)
		[Toggle]_DissAmoutByCustomData1X("溶解进度by CustomData1.X", Float) = 0
		_DissEdgeColor("Edge颜色", Color) = (1, 1, 1, 1)
		_DissEdgeWidth("Edge宽度", Range(0, 1)) = 0.1       

        [Toggle]_AlphaClip("Alpha_clip", Float) = 0.0
		_Cutoff("Alpha Cutoff", Range(0,1)) = 0.5
        
		_Cull("__Cull", Float) = 0.0

		[Toggle]_ZWrite("深度写入", Float) = 0
        [Toggle]_FogOn("开启雾效", Float) = 0
        
        _QueueOffset("Queue offset", Float) = 0
        
    }
    SubShader
    {
        Tags 
		{ 
                "RenderType" = "Transparent" 
                "Queue" = "Transparent+1950"
                "RenderPipeline" = "UniversalPipeline"
                "UniversalMaterialType" = "Unlit"
                "IgnoreProjector" = "True" 
		}

        Pass
        {
            Tags { "LightMode" = "ExtractTransparentFX" }
            
	        Cull [_Cull]
            ZWrite [_ZWrite]
			ColorMask RGB

            HLSLPROGRAM
            
            #pragma target 3.5
            #pragma vertex vert
            #pragma fragment MRTFrag

            //#pragma shader_feature_local_fragment _ _CLEARNESS_DISTORTION_ON
			#define _CLEARNESS_DISTORTION_ON_BRANCH

            //#pragma shader_feature_local_fragment _ _RIM_LIGHT_ON
            #define _RIM_LIGHT_ON_BRANCH

            //#pragma shader_feature_local_fragment _ _VOLUMETRIC_NOISE_UV_ON
            #define _VOLUMETRIC_NOISE_UV_BRANCH
            
			#pragma shader_feature_local_fragment _ _SPECULAR_LIGHT_ON            
			#pragma shader_feature_local_fragment _ _DISSOLVE_ON			

            #pragma multi_compile_fragment _ DEBUG_DISPLAY
            
            #pragma multi_compile_fog
            #pragma multi_compile_instancing   

            #include "Packages/com.xinyuan.rendering/Shaders/FX/Particles/IceInput.hlsl"            
            #include "Packages/com.xinyuan.rendering/Shaders/FX/Particles/IcePass.hlsl"

            ENDHLSL
        }


//        Pass
//        {
//            Tags { "LightMode" = "TransparentFXBloom" }
//            
//	        Cull [_Cull]
//            ZTest LEqual
//			ZWrite Off
//			Blend One One
//			//ColorMask RGB
//            
//			HLSLPROGRAM
//            
//            #pragma target 3.5
//            #pragma vertex vert
//            #pragma fragment BloomFrag
//			
//			#pragma shader_feature_local_fragment _ _VOLUMETRIC_NOISE_UV_ON
//			#pragma shader_feature_local_fragment _ _CLEARNESS_DISTORTION_ON
//			#pragma shader_feature_local_fragment _ _RIM_LIGHT_ON
//			#pragma shader_feature_local_fragment _ _SPECULAR_LIGHT_ON            
//			#pragma shader_feature_local_fragment _ _DISSOLVE_ON			
//
//            #pragma multi_compile_fog
//            #pragma multi_compile_instancing   
//
//            #include "Packages/com.xinyuan.rendering/Shaders/FX/Particles/IceInput.hlsl"            
//            #include "Packages/com.xinyuan.rendering/Shaders/FX/Particles/IcePass.hlsl"
//
//            ENDHLSL
//        }

    }
    
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "XYRendering.Editor.IceGUI"

}
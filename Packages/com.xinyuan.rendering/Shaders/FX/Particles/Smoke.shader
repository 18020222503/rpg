Shader  "XinYuan/FX/Particles/Smoke" 
{
    Properties
    {
        // Base Map
		[MainTexture]_BaseMap("主贴图", 2D) = "white" {}
		[HDR][MainColor]_BaseColor("Main_Color", Color) = (1, 1, 1, 1)
		[Toggle]_BaseColorByCutomData2 ("主颜色By Custom Data2", Float) = 0.0
		[Toggle]_AnimSheetOn ("开启AnimSheet", Float) = 0
		_BaseWrapMode ("主贴图UV Wrap Mode", Float) = 0.0
		_BaseUVMoveMode ("主贴图UV Move Mode", Float) = 0.0	// 0-Off 1-OffsetAnimated 2-CustomData_ZW
		_BaseUSpeed ("U速度/角速度", Float) = 0.0
		_BaseVSpeed ("V速度/线速度", Float) = 0.0
		_BaseRadialScale ("极坐标Radial", Float) = 1.0
		_BaseLengthScale ("极坐标Length", Float) = 1.0
		_BaseRotAngle("旋转角度", Float) = 0.0
		[Toggle]_BaseMapDistStrenAByCustomData1("形变A强度ByCustomData1", Float) = 0.0
		_BaseMapDistStrenAChannel("形变A CustomData来源", int) = 0
    	_BaseMapDistortionStrength_A("形变A强度", range(0, 2)) =  0.0
    	_BaseMapDistortionStrength_B("形变B强度", range(0, 2)) =  0.0
    	[Toggle]_BaseMapDistStrenBByCustomData1("形变B强度ByCustomData1", Float) = 0.0
		_BaseMapDistStrenBChannel("形变B CustomData来源", int) = 0
    	_DistStrengthMaskPower ("变形遮罩Mask Power", Float) = 1
    	[Toggle(_DISTSTRENGTHMASK_ON)] _DistStrengthMaskOn("使用遮罩控制形变A强度", Float) = 0.0
		[Toggle] _InvertDistMask("反转扭曲强度控制Mask", Float) = 0.0
    	_DistMaskPower("形变强度遮罩power", Float) = 1
		_DistStrengthControlMask("变形强度A控制贴图(R)", 2D) = "black" {}
        _Horizontal("水平Filp", Range(0, 1)) = 0
		_Vertical("垂直Filp", Range(0, 1)) = 0
		_HSV("HSV X(色相) Y(饱和度) Z(亮度)", Vector) = (0, 1, 1, 0)

		// Base Detail Map
		_DetailMapOn("开启细节贴图", Float) = 0
		_DetailMap("细节贴图", 2D) = "white" {}
		[HDR]_DetailColor("Detail_Color", Color) = (1, 1, 1, 1)
		_DetailWrapMode ("细节贴图UV Wrap Mode", Float) = 0.0
		_DetailUVMoveMode ("细节贴图UV Move Mode", Float) = 0.0	// 0-Off 1-OffsetAnimated 2-CustomData_ZW
		_DetailUSpeed ("U速度/角速度", Float) = 0.0
		_DetailVSpeed ("V速度/线速度", Float) = 0.0
		_DetailRadialScale ("Radial", Float) = 0.0
		_DetailLengthScale ("Length", Float) = 0.0
		_DetailRotAngle("旋转角度", Float) = 0.0
		_DetailStren("细节强度", Range(0, 1)) = 1

		// Double Face
		[Space(5)]
		[ToggleOff] _DoubleFaceOn("Double Face(双面)", Float) = 0
		[HDR] _BackFaceColor("背面颜色", Color) = (0, 0, 0, 1)
		_BackFaceHSV("HSV X(色相) Y(饱和度) Z(亮度)", Vector) = (0, 1, 1, 0)

		// Mask
		[Space(5)]
		[Toggle(_MASK_ON)] _MaskOn ("Mask(遮罩)", Float) = 0.0
		_MaskMap("遮罩贴图(R)", 2D) = "white" {}
		_MaskMapWrapMode ("遮罩贴图UV Wrap Mode", Float) = 0.0
		_MaskMapUVMoveMode ("遮罩贴图 UV Move Mode", Float) = 0.0
		_MaskLengthScale ("遮罩贴图极坐标Length Scale", Float) = 0.0
		_MaskRadialScale ("遮罩贴图极坐标Radial Scale", Float) = 0.0
		_MaskUSpeed ("U速度", Float) = 0.0
		_MaskVSpeed ("V速度", Float) = 0.0
		_MaskRotAngle ("旋转角度", Float) = 0.0		
		
		_MaskAddOn("Mask Add On", Float) = 0.0
		_MaskAlphaStrength("Mask Alpha Strength", Float) = 0.0
		
		_AlphaOn("Alpha On ", Float) = 0
		_AlphaAddOn("Alpha Add On ", Float) = 0.0
        _AlphaStrength("Alpha Strength", Float) = 0.0
		
		// Distortion
		[Space(5)]
		[Toggle(_DISTORTION_ON)] _DistortionOn ("Shape Distortion(形变扭曲)", Float) = 0.0
		_DistMap("变形贴图 A(RG)", 2D) = "black" {}
		_DistMapWrapMode ("变形贴图UV Wrap Mode", Float) = 0.0
		_DistMapUVMoveMode ("变形贴图 UV Move Mode", Float) = 0.0
		_DistUSpeed ("U速度/角速度", Float) = 0.0
		_DistVSpeed ("U速度/角速度", Float) = 0.0
		_DistRotAngle ("旋转角度", Float) = 0.0
		_DistRadialScale ("变形贴图极坐标Radial Scale", Float) = 1
		_DistLengthScale ("变形贴图极坐标Radial Scale", Float) = 1
    
		
		_DetailDistMap("变形贴图 B(RG)", 2D) = "white" {}
		_DetailDistMapWrapMode ("细节贴图UV Wrap Mode", Float) = 0.0
		_DetailDistMapUVMoveMode ("细节贴图 UV Move Mode", Float) = 0.0
		_DetailDistUSpeed ("U速度/角速度", Float) = 0.0
		_DetailDistVSpeed ("U速度/角速度", Float) = 0.0
		_DetailDistRadialScale ("Radial", Float) = 0.0
		_DetailDistLengthScale ("Length", Float) = 0.0
		_DetailDistRotAngle ("旋转角度", Float) = 0.0
    	
    	[Toggle(_SECONDARYDISTMAP_ON)] _SecondaryDistMapOn("开启二级形变扭曲", Float) = 0
		_SecondaryDistMap("二级变形贴图(RG)", 2D) = "white" {}
    	_SecondaryDistMapWrapMode ("细节贴图UV Wrap Mode", Float) = 0.0
    	_SecondaryDistMapDistortionSource("二级形变扰动来源", int) = 0
    	_SecondaryDistDistortionStrength("二级形变强度", Range(0, 2)) = 0
		
		_DistStren("变形强度B", Range(0, 2)) = 0.5
    	
    // Dissolve
		[Space(5)]
		[Toggle(_DISSOLVE_ON)] _DissolveOn ("Dissolve(溶解)", Float) = 0.0
		_DissolveMap("溶解贴图(R)", 2D) = "white" {}
		[Toggle] _InvertDissolveMap ("反向溶解贴图", Float) = 0
		[Toggle(_FOLLOWSHAPEDISTORTION_ON)] _FollowShapeDistortionOn ("应用形变扭曲", Float) = 0
    	_DissolveDistortionSource("溶解的扭曲来源", int) = 0
    	_DissolveDistortionStrength("溶解的形变扭曲强度", Range(0, 2)) = 0
		_DissolveMapWrapMode ("溶解贴图UV Wrap Mode", Float) = 0.0 
		_DissolveUVMoveMode ("溶解贴图 UV Move Mode", Float) = 0.0
		_DissolveUSpeed ("U速度", Float) = 0.0
		_DissolveVSpped ("V速度", Float) = 0.0
		_DissolveRadialScale ("Radial", Float) = 0.0
		_DissolveLengthScale ("Length", Float) = 0.0
		_DissolveRotAngle ("旋转角度", Float) = 0.0
		[Toggle]_DissolveByCustomData1("溶解进度By CustomData1", Range(0, 1)) = 0
		_DissolveCustomDataChannel("溶解进度CustomData1 来源", int) = 0
		_Dissolve("溶解进度", Range(0, 1)) = 0
		_EdgeRange("溶解边缘范围", Range(0, 1)) = 0.01
		_EdgeSmoothness ("边缘柔和度", Range(0, 1)) = 0.5
		_EdgeColorMode ("边缘颜色模式", Float) = 0 // 0-Off 1-Solid 2-Gradient
		[HDR]_EdgeColor("边缘颜色", Color) = (1, 1, 1, 0)
    	
    	[Toggle(_NEAR_CAMERA_FADE_ON)] _NearCameraFadeOn("Near Camera Fade(近平面渐隐)", Float) = 0.0
		_NearFadeStar ("Near Fade Star", Float) = 5
		_NearFadeRange ("Near Fade Range", Float) = 10
    	
    	// Depth Fade
		[Toggle(_DEPTH_FADE_ON)] _DepthFadeOn ("Depth Fade(软化插边)", Float) = 0.0
		_DepthFadeRange("Depth Fade Range", Float) = 0.1
    	
    	// Blending state
		[HideInInspector] _Surface("__surface", Float) = 1.0
		[HideInInspector] _Blend("__blend", Float) = 1.0
        [HideInInspector] _AlphaClip("__clip", Float) = 0.0
        [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0
        [HideInInspector] _ZWrite("__ZWrite", Float) = 0.0
		[HideInInspector] _Cull("__Cull", Float) = 0.0
    	
		// Bloom
		[Toggle]_BloomOn("开启Bloom", Float) = 1        
		[HDR]_BloomTint("Bloom颜色", Color) = (1, 1, 1, 1)
    	
    	_Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
    	[ToggleOff]_TransparentZWrite("深度写入", Float) = 0
        [ToggleOff]_FogOn("开启雾效", Float) = 0
    	
        [Toggle(_DEPTH_OFFSET_ON)] _DepthOffsetOn("开启深度偏移", Float) = 0
	    _ZOffset("深度偏移", Float) = 0
    	// Gameplay Control
		_AlphaMultiplyer ("GamePlay Alpha 相乘系数", Range(0, 1)) = 1


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
            Blend [_SrcBlend] [_DstBlend]
			ColorMask RGB
            
			HLSLPROGRAM
            
            #pragma target 3.5
            #pragma vertex vert
            #pragma fragment MRTFrag            
            
            #pragma multi_compile_fog
            #pragma multi_compile_instancing

			//#pragma shader_feature_local_fragment _DISTORTION_ON
			#define _DISTORTION_BRANCH 

			//#pragma shader_feature_local_fragment _FOLLOWSHAPEDISTORTION_ON
			#define _FOLLOWSHAPEDISTORTION_BRANCH

			//#pragma shader_feature_local _DISTSTRENGTHMASK_ON
			#define _DISTSTRENGTHMASK_BRANCH

			//#pragma shader_feature_local_fragment _DEPTH_FADE_ON
			#define _DEPTH_FADE_BRANCH

			//#pragma shader_feature_local _DISSOLVE_ON					
			#define _DISSOLVE_BRANCH
			
            #pragma shader_feature_local_fragment _BASE_DETAIL_MAP_ON
			#pragma shader_feature_local_fragment _DDUBLE_FACE_ON
			
			#pragma shader_feature_local_fragment _NEAR_CAMERA_FADE_ON
		
			#pragma shader_feature_local_fragment _SECONDARYDISTMAP_ON
			
			#pragma shader_feature_local _MASK_ON
	
			#pragma shader_feature_local _DEPTH_OFFSET_ON

			#pragma multi_compile_fragment _ DEBUG_DISPLAY

            #include "Packages/com.xinyuan.rendering/Shaders/FX/Particles/SmokeInput.hlsl"            
            #include "Packages/com.xinyuan.rendering/Shaders/FX/Particles/SmokePass.hlsl"

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
//            #pragma multi_compile_fog
//            #pragma multi_compile_instancing
//
//            #pragma shader_feature_local_fragment _BASE_DETAIL_MAP_ON
//			#pragma shader_feature_local_fragment _DDUBLE_FACE_ON
//			#pragma shader_feature_local_fragment _DISTORTION_ON
//			#pragma shader_feature_local_fragment _NEAR_CAMERA_FADE_ON
//			#pragma shader_feature_local_fragment _FOLLOWSHAPEDISTORTION_ON
//			#pragma shader_feature_local_fragment _SECONDARYDISTMAP_ON
//			#pragma shader_feature_local_fragment _DEPTH_FADE_ON
//			
//			#pragma shader_feature_local _DISSOLVE_ON
//			#pragma shader_feature_local _MASK_ON
//			#pragma shader_feature_local _DISTSTRENGTHMASK_ON
//			#pragma shader_feature_local _DEPTH_OFFSET_ON
//
//            #include "Packages/com.xinyuan.rendering/Shaders/FX/Particles/SmokeInput.hlsl"            
//            #include "Packages/com.xinyuan.rendering/Shaders/FX/Particles/SmokePass.hlsl"
//
//            ENDHLSL
//        }

    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "XYRendering.Editor.SmokeGUI"
}
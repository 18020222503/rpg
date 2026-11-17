Shader "XinYuan/FX/Particles/UnlitGeneral" 
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
		[Toggle] _BaseScreenUV("全部贴图屏幕UV坐标",Float) = 0.0
		_BaseUSpeed ("U速度", Float) = 0.0
		_BaseVSpeed ("V速度", Float) = 0.0
		_BaseRadialScale ("极坐标Radial", Float) = 1.0
		_BaseLengthScale ("极坐标Length", Float) = 1.0
		_BaseRotAngle("旋转角度", Float) = 0.0
		//_Horizontal("水平Filp", Range(0, 1)) = 0
		//_Vertical("垂直Filp", Range(0, 1)) = 0
		_HSV("HSV X(色相) Y(饱和度) Z(亮度)", Vector) = (0, 1, 1, 0)

		// Base Detail Map
		_DetailMapOn("开启细节贴图", Float) = 0
		_DetailMap("细节贴图", 2D) = "white" {}
		[HDR]_DetailColor("Detail_Color", Color) = (1, 1, 1, 1)
		_DetailWrapMode ("细节贴图UV Wrap Mode", Float) = 0.0
		_DetailUVMoveMode ("细节贴图UV Move Mode", Float) = 0.0	// 0-Off 1-OffsetAnimated 2-CustomData_ZW
		_DetailUSpeed ("U速度", Float) = 0.0
		_DetailVSpeed ("V速度", Float) = 0.0
		_DetailRadialScale ("Radial", Float) = 0.0
		_DetailLengthScale ("Length", Float) = 0.0
		//_DetailRotAngle("旋转角度", Float) = 0.0
		_DetailStren("细节强度", Range(0, 1)) = 1

		// Double Face
		[Space(5)]
		[ToggleOff] _DoubleFaceOn("Double Face(双面)", Float) = 0
		[HDR] _BackFaceColor("背面颜色", Color) = (0, 0, 0, 1)
		//_BackFaceHSV("HSV X(色相) Y(饱和度) Z(亮度)", Vector) = (0, 1, 1, 0)

		// Mask
		[Space(5)]
		[Toggle(_MASK_ON)] _MaskOn ("Mask(遮罩)", Float) = 0.0
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
		
		// Shape Distortion
		[Space(5)]
		[Toggle(_DISTORTION_ON)] _DistortionOn ("Shape Distortion(形变扭曲)", Float) = 0.0
		_ShpDistMap("变形主贴图(RG)", 2D) = "gray" {}
		_ShpDistMapWrapMode ("变形贴图UV Wrap Mode", Float) = 0.0
		_ShpDistMapUVMoveMode ("变形贴图 UV Move Mode", Float) = 0.0
		_ShpDistUSpeed ("U速度", Float) = 0.0
		_ShpDistVSpeed ("V速度", Float) = 0.0
		//_ShpDistRotAngle ("旋转角度", Float) = 0.0
		_ShpDistRadialScale ("变形贴图极坐标Radial Scale", Float) = 1
		_ShpDistLengthScale ("变形贴图极坐标Radial Scale", Float) = 1
		[Toggle(_DISTSTRENGTHMASK_ON)] _DistStrengthMaskOn("使用遮罩控制扭曲强度", Float) = 0.0
		[Toggle] _InvertDistMask("反转扭曲强度控制Mask", Float) = 0.0
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
		//_ShpDetailDistRotAngle ("旋转角度", Float) = 0.0
		
		_ShpDistStrenByCustomDataY("变形强度By CustomData1 Y", Float) = 0.0
		_ShpDistStren("变形强度", Range(0, 2)) = 0.5
		
		_ShpDetailDistStrenOn("开启独立细节变形强度", Float) = 0
		_ShpDetailDistStren("细节变形强度", Range(0, 2)) = 0.5

		// Refract Distortion
//		[Space(5)]
//		[Toggle(_REFRACT_DISTORTION_ON)] _RfrDistOn ("Refract Distortion(折射扭曲)", Float) = 0.0
//		_RfrDistMap ("Distortion Map(RG)", 2D) = "gray" {}
//		_RfrDistMapWrapMode ("Distor Wrap Mode", Float) = 0.0
//		_RfrDistUVMoveMode ("Distortion UV Move Mode", Float) = 0.0  // 0-Off 1-OffsetAnimated 2-CustomData_ZW
//		_RfrDistUSpeed ("Distortion U Speed", Float) = 0.0
//		_RfrDistVSpeed ("Distortion V Speed", Float) = 0.0
//		_RfrDistRotAngle ("Distortion Rotate Angle", Float) = 0.0
//		_RfrDistStrenByCustomData2X ("Distortion Stren By CumstomData2 X", Float) = 0.0		
//		_RfrDistStren("Distortion Stren", Range(0, 1)) = 0.5
//		_RfrDistBlendByCustomData2Y ("Distortion Blend By CustomData2 Y", Float) = 0.0
//		_RfrDistBlend("Distortion Blend", Range(0, 1)) = 0.5
		

		// Dissolve
		[Space(5)]
		[Toggle(_DISSOLVE_ON)] _DissolveOn ("Dissolve(溶解)", Float) = 0.0
		_DissolveMap("溶解贴图(R)", 2D) = "white" {}
		[Toggle] _InvertDissolveMap ("反向溶解贴图", Float) = 0
		[Toggle(_FOLLOWSHAPEDISTORTION_ON)] _FollowShapeDistortionOn ("跟随扭曲进行溶解", Float) = 0
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
		_EdgeColorMode ("边缘颜色模式", Float) = 0 // 0-Off 1-Solid 2-Gradient
		[HDR]_EdgeColor("边缘颜色", Color) = (1, 1, 1, 0)
		
		// Fresnel
		[Space(5)]
		[Toggle(_FRESNEL_ON)] _FresnelOn("Fresnel(菲尼尔)", Float) = 0.0
		_FresnelMode("菲尼尔模式", Float) = 0
		_FresnelColorMode("菲尼尔颜色模式", Float) = 0
		[HDR]_FresnelColor("菲尼尔颜色r", Color) = (1, 1, 1, 1)
		_FresnelPow("菲尼尔Pow", Float) = 1.0
		_FresnelStrength("菲尼尔强度", Float) = 1
		_InverFresnel("反向菲尼尔", Float) = 0
		
//		// Soft Particle
//		[Toggle(_SOFTPARTICLES_ON)] _SoftParticleOn ("Soft Particle(软粒子)", Float) = 0.0
//		_SoftRange("Soft Range", Float) = 10
		
		// Depth Fade
		[Toggle(_DEPTH_FADE_ON)] _DepthFadeOn ("Depth Fade(软化插边)", Float) = 0.0
		_DepthFadeRange("虚化范围", Float) = 0.1
		_DepthFadePow("虚化强度", Range(0, 10)) = 1
		[Enum(Back,0,Both,1)] _DepthFadeMode("Affect Mode", Float) = 1

		[Toggle(_NEAR_CAMERA_FADE_ON)] _NearCameraFadeOn("Near Camera Fade(近平面渐隐)", Float) = 0.0
		_NearFadeStar ("Near Fade Star", Float) = 5
		_NearFadeRange ("Near Fade Range", Float) = 10

		
		// Vertex Offset
		[Space(5)]
		[Toggle(_VERTEXOFFSET_ON)] _VertexOffsetOn("Vertex Animation(模型顶点偏移)", Float) = 0.0
		_VertexOffsetMainTexOn("主贴图影响顶点偏移", Float) = 1
		_VertexOffsetTexParams("XY(贴图平铺次数) ZW(贴图偏移量)", Vector) = (2, 2, 0, 0)
		[Toggle]_VertexOffsetMainTexColorOn("主贴图是否作为颜色贴图" ,Float) = 1
		_VertexOffsetMaskMap("Mask贴图", 2D) = "white" {}
		_VertexOffsetMaskMapChannelMask("Mask贴图通道", Float) = 0
		_VertexOffsetMaskUSpeed("U Speed", Float) = 0
		_VertexOffsetMaskVSpeed("V Speed", Float) = 0
		_VertexMaskMapWrapMode("Mask贴图UV Wrap Mode", Float) = 0.0
		//_VertexOffsetMaskRotAngle("Mask贴图旋转角度", Float) = 0.0
		[Toggle] _VertexRandomByCutomData2w("顶点偏移偏移随机值ByCustomData2w", Float) = 0.0
		[Toggle] _VertexOffsetIntensityByCutomData2X("顶点偏移强度ByCustomData2X", Float) = 0.0
		_VertexOffsetIntensity("偏移强度", Float) = 0.0
		
		// FlowMap
//		[Space(5)]
//		[Toggle(_FLOWMAP_ON)] _FlowMapOn("FlowMatcap", Float) = 0.0
//		_FlowNormalMap("流动法线图/法线图", 2D) = "" {}
//		_FlowMap("法线图扰动贴图", 2D) = "" {}
//		_FlowOffsetSpeed("法线扰动 X(U强度) Y(V强度) Z(流动速度)", Vector) = (0,0,0,0)
//		[KeywordEnum(TriNormal, UV)] _FlowNormalMapSampleMode("Matcap流动采样方式", Float) = 0
//		_FlowTiling("FlowTiliing", Vector) = (1,1,1,1)
//		_FlowSpeed("三平面流速 X(YOZ平面) Y(XOZ) Z(XOY)", Vector) = (0,0,0,0)
//		_FlowMapSpeed("FlowMap流动速度", Vector) = (0,0,0,0)
//		
//		_MatcapMap("Matcap贴图", 2D) = "" {}
//		_MatcapPower("MatcapPower", Float) = 1.0
//		[KeywordEnum(Additive, Multiply)]_MatcapColorBlendMode("Matcap叠加方式", Float) = 0.0 

		// Bloom
		[Toggle]_BloomOn("开启Bloom", Float) = 1        
		[HDR]_BloomTint("Bloom颜色", Color) = (1, 1, 1, 1)
		
		// Addtional Alpha Control
		_AlphaRemapping("范围", Vector) = (0, 1, 0, 0) // x- Min Alpha y- Alpha Range z-null w-On/Off
		
		// Gameplay Control
		_AlphaMultiplyer ("GamePlay Alpha 相乘系数", Range(0, 1)) = 1		
		
		_Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
		[Toggle] _FogOn ("Fog On", Float) = 0.0
		[Toggle] _TransparentZWrite ("Z Write", Float) = 0.0
		[Toggle] _IgnoreNegativeEffect("忽略反相效果", Float) = 0.0
		
		// For Laser End
//		[HideInInspector] _HitPositionWS("Hit Postion WS", Vector) = (0,0,0,0)
//		[HideInInspector] _LaserDirWS("Laser Direction WS", Vector) = (0,0,0,0)
//		[Toggle(_LASEREND_ON)] _LaserEndOn("开启激光终止", Float) = 0
		
		// Decal Mode
		[Toggle(_DECAL_ON)]_DecalModeOn("开启贴花模式", Float) = 0
		_DecalRootRotation("贴花父节点旋转", Vector) = (0, 0, 0, 1)
		
		 // Blending state
		[HideInInspector] _Surface("__surface", Float) = 1.0
		[HideInInspector] _Blend("__blend", Float) = 1.0
        [HideInInspector] _AlphaClip("__clip", Float) = 0.0
        [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0
        [HideInInspector] _ZWrite("__ZWrite", Float) = 0.0
		[HideInInspector] _Cull("__Cull", Float) = 1.0
		
		[HideInInspector][ToggleOff] _StencilOn("__Stencil On", Float) = 0
        [HideInInspector] _StencilRef("__StencilRef", Float) = 0
        [HideInInspector] _StencilReadMask("__StencilReadMask", Float) = 255
        [HideInInspector] _StencilWriteMask("__StencilWriteMask", Float) = 255
        [HideInInspector] _StencilComp("__Stencil Comp", Float) = 0
        [HideInInspector] _StencilPassOp("__StencilPassOp", Float) = 0
        [HideInInspector] _StencilZFailOp("__StencilZFailOp", Float) = 0
        [HideInInspector] _StencilFailOp("__StencilFailOp", Float) = 0

        [HideInInspector] _QueueOffset("Queue offset", Float) = 0
		
		// 视觉空间的深度偏移, 用于特效遮挡的调整
		[Toggle(_DEPTH_OFFSET_ON)] _DepthOffsetOn("开启深度偏移", Float) = 0
        _ZOffsetViewSpace("Z Offset ViewSpace", Float) = 0
		

	}

	SubShader 
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent" "RenderPipeline"="UniversalPipeline" "IgnoreProjector"="True" "PreviewType"="Plane" "PerformanceChecks"="False" }

		Pass 
		{

            Name "TransparentFX"
            Tags{"LightMode" = "TransparentFX"}
			
			Cull [_Cull]
			ZTest LEqual
			ZWrite [_ZWrite]
			Blend[_SrcBlend][_DstBlend]
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
			//#pragma prefer_hlslcc gles
            //#pragma exclude_renderers d3d11_9x
            #pragma target 4.5

			#pragma vertex vert
			#pragma fragment MRTFrag

			//#pragma shader_feature_local _DISSOLVE_ON
			#define _DISSOLVE_ON_BRANCH

			//#pragma shader_feature_local _MASK_ON
			#define _MASK_ON_BRANCH

			// #pragma shader_feature_local_fragment _DEPTH_FADE_ON
			#define _DEPTH_FADE_BRANCH

			#pragma shader_feature_local_fragment _BASE_DETAIL_MAP_ON
			
			#pragma shader_feature_local_fragment _DDUBLE_FACE_ON
			//#pragma shader_feature_local_fragment _SOFTPARTICLES_ON
			#pragma shader_feature_local_fragment _DISTORTION_ON
			//#pragma shader_feature_local_fragment _REFRACT_DISTORTION_ON
			#pragma shader_feature_local_fragment _NEAR_CAMERA_FADE_ON
			
			//屏蔽FlipBook分支	
			#pragma shader_feature_local _FLIPBOOKBLENDING_ON 
			
			#pragma shader_feature_local _ALPHATEST_ON
			#pragma shader_feature_local _FRESNEL_ON
			#pragma shader_feature_local _VERTEXOFFSET_ON
			#pragma shader_feature_local _DECAL_ON


			//#pragma shader_feature_local _FLOWMAP_ON
			#pragma shader_feature_local _FOLLOWSHAPEDISTORTION_ON
			#pragma shader_feature_local _DISTSTRENGTHMASK_ON
			//#pragma shader_feature_local _LASEREND_ON
			#pragma shader_feature_local _DEPTH_OFFSET_ON

			// #pragma multi_compile_fragment _ DEBUG_DISPLAY
			
			#pragma multi_compile _  _GOOGLE_DEVICE
			
			// #pragma multi_compile_fog
			#define FOG_LINEAR 1
            // #pragma multi_compile_instancing
			//#pragma instancing_options procedural:ParticleInstancingSetup
			
			//声明开启GPU Instancing Per particle needed data
			#define DEC_PARTICLE_GENERAL_INSTANCING_DATA 
			
			#include "Packages/com.xinyuan.rendering/Shaders/FX/Particles/ParticleUnlitGeneralInput.hlsl"
			#include "Packages/com.xinyuan.rendering/Shaders/FX/Particles/ParticleUnlitGeneralPass.hlsl"
			
			ENDHLSL
		}


//		Pass 
//		{
//
//            Tags{"LightMode" = "TransparentFXBloom"}
//			
//			Cull [_Cull]
//			ZTest LEqual
//			ZWrite Off
//			Blend[_SrcBlend][_DstBlend]
//			//ColorMask RGB
//			
//
//			HLSLPROGRAM
//			//#pragma prefer_hlslcc gles
//            //#pragma exclude_renderers d3d11_9x
//            #pragma target 3.5
//
//			#pragma vertex vert
//			#pragma fragment BloomFrag
//			
//			#pragma shader_feature_local_fragment _BASE_DETAIL_MAP_ON
//			#pragma shader_feature_local_fragment _DDUBLE_FACE_ON
//			#pragma shader_feature_local_fragment _SOFTPARTICLES_ON
//			#pragma shader_feature_local_fragment _DEPTH_FADE_ON
//			#pragma shader_feature_local_fragment _DISTORTION_ON
//			#pragma shader_feature_local_fragment _REFRACT_DISTORTION_ON
//			#pragma shader_feature_local_fragment _NEAR_CAMERA_FADE_ON
//			
//			#pragma shader_feature_local _FLIPBOOKBLENDING_ON
//			#pragma shader_feature_local _ALPHATEST_ON
//			#pragma shader_feature_local _FRESNEL_ON
//			#pragma shader_feature_local _VERTEXOFFSET_ON
//			#pragma shader_feature_local _DISSOLVE_ON
//			#pragma shader_feature_local _MASK_ON
//			#pragma shader_feature_local _FLOWMAP_ON
//			#pragma shader_feature_local _FOLLOWSHAPEDISTORTION_ON
//			#pragma shader_feature_local _DISTSTRENGTHMASK_ON
//			#pragma shader_feature_local _LASEREND_ON
//			#pragma shader_feature_local _DEPTH_OFFSET_ON
//
//			#pragma multi_compile_fog
//            #pragma multi_compile_instancing
//			#pragma instancing_options procedural:ParticleInstancingSetup
//			
//			//声明开启GPU Instancing Per particle needed data
//			#define DEC_PARTICLE_GENERAL_INSTANCING_DATA 
//			
//			#include "Packages/com.xinyuan.rendering/Shaders/FX/Particles/ParticleUnlitGeneralInput.hlsl"
//			#include "Packages/com.xinyuan.rendering/Shaders/FX/Particles/ParticleUnlitGeneralPass.hlsl"
//			
//			ENDHLSL
//		}

	}

	FallBack "Hidden/Universal Render Pipeline/FallbackError"
	CustomEditor "XYRendering.Editor.ParticleUnlitGeneralGUI"
}

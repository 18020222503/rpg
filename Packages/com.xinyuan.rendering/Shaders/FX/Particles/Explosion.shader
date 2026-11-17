Shader  "XinYuan/FX/Particles/Explosion" 
{
    Properties
    {
        [HDR]_HighTempCol("高温度层颜色", Color) = (1, 0.4209617, 0, 1)
        [HDR]_MidTempCol("中温度层颜色", Color) = (1, 0.7958018, 0.5801887, 1)
        [HDR]_LowTempCol("低温度层颜色", Color) = (0, 0, 0, 1)
        
        _MidTempRange("中温度层范围", Range(0,1)) = 0.25
        _LowTempRange("低温层范围", Range(0, 1)) = 0.5
        _MidTempEdgeSmooth("中温度边平滑", Range(0, 1)) = 0
        _LowTempEdgeSmooth("低温度边平滑", Range(0, 1)) = 0
        
        _DisplaceMap("置换图（R）", 2D) = "white" {}
        [ToggleOff]_InvertDisplaceMap("反向置换图", Float) = 0
        _DisplaceUVWrapMode("置换UV Wrap模式", Float) = 0
        _DisplaceUVMoveMode("置换UV流动模式", Float) = 0
        _DisplaceUSpeed("置换U速度", Float) = 0
        _DisplaceVSpeed("置换V速度", Float) = 0     
        _DisplaceStren("置换强度", Float) = 0.5
    
        _DissMap ("溶解图（R）", 2D) = "white" {}
        [ToggleOff]_InvertDissMap("反向溶解图", Float) = 0
        _DissUVWrapMode("溶解UV Wrap模式", Float) = 0
        _DissUVMoveMode("溶解UV流动模式", Float) = 0
        _DissUSpeed("溶解U速度", Float) = 0
        _DissVSpeed("溶解V速度", Float) = 0
        _DissStren ("溶解强度", Float) = 1
        _DissSmooth("溶解平滑度", Range(0, 1)) = 0.25

		// Bloom
		[Toggle]_BloomOn("开启Bloom", Float) = 1        
		[HDR]_BloomTint("Bloom颜色", Color) = (1, 1, 1, 1)

		// Gameplay Control
		_AlphaMultiplyer ("GamePlay Alpha 相乘系数", Range(0, 1)) = 1
    
        [ToggleOff]_TransparentZWrite("深度写入", Float) = 0
        [ToggleOff]_FogOn("开启雾效", Float) = 0

        [HideInInspector] _Cutoff("Alpha Cutoff", Range(0,1)) = 0.5

		 // Blending state
		[HideInInspector] _Surface("__surface", Float) = 1.0
		[HideInInspector] _Blend("__blend", Float) = 1.0
        [HideInInspector] _AlphaClip("__clip", Float) = 0.0
        [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0
        [HideInInspector] _ZWrite("__ZWrite", Float) = 0.0
		[HideInInspector] _Cull("__Cull", Float) = 0.0
        
        // Laser end
		//[HideInInspector] _LaserEndOn("_LaserEndOn", Float) = 0.0

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

            //#pragma shader_feature_local _LASEREND_ON

            #pragma multi_compile_fragment _ DEBUG_DISPLAY

            #include "Packages/com.xinyuan.rendering/Shaders/FX/Particles/ExplosionInput.hlsl"            
            #include "Packages/com.xinyuan.rendering/Shaders/FX/Particles/ExplosionPass.hlsl"

            ENDHLSL
        }

//        Pass
//        {
//            Tags { "LightMode" = "TransparentFXBloom" }
//            
//            ZTest LEqual
//			ZWrite Off
//            Cull [_Cull]
//            Blend [_SrcBlend] [_DstBlend]
//			//ColorMask RGB
//
//            HLSLPROGRAM
//            
//            #pragma target 3.5
//            #pragma vertex vert
//            #pragma fragment BloomFrag            
//            
//            #pragma multi_compile_fog
//            #pragma multi_compile_instancing
//
//            #pragma shader_feature_local _LASEREND_ON
//
//            #include "Packages/com.xinyuan.rendering/Shaders/FX/Particles/ExplosionInput.hlsl"            
//            #include "Packages/com.xinyuan.rendering/Shaders/FX/Particles/ExplosionPass.hlsl"
//
//            ENDHLSL
//        }

    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "XYRendering.Editor.ExplosionGUI"
}
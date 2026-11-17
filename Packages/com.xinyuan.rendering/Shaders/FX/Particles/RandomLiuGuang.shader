Shader "XinYuan/FX/Particles/RandomLiuGuang"
{
    Properties
    {
        [Toggle] _ZWrite("开启深度写入", Float) = 0.0
        [Toggle] _DepthOffsetOn("开启深度偏移", Float) = 0
        _ZOffsetViewSpace("Z Offset ViewSpace", Float) = 0
        [Toggle] _BloomOn("开启Bloom", Float) = 0
        [HDR]_BloomTint("Bloom颜色", Color) = (1, 1, 1, 1)
        [Toggle] _AlpahCaleOn("开启纹理1纹理2 Alpha计算", Float) = 0
        
        _BaseTex1("基础纹理1", 2D) = "white" {}
        _BaseTex1UVWrapMode("UV Wrap 模式", Float) = 0
        _Desature1("基础纹理1去色", Range(0, 1)) = 0
        _BaseTex2("基础纹理2", 2D) = "white" {}
        _BaseTex2UVWrapMode("UV Wrap 模式", Float) = 0
        _Desature2("基础纹理2去色", Range(0, 1)) = 0
        _BaseTexUVSpeed("基础纹理UV速度", Vector) = (0, 0, 0, 0)
        _BaseTex12PM("纹理12power和multiply", Vector) = (1,1,1,1)
        [HDR] _Color1("Color 1", Color) = (1,1,1,1)
        [HDR] _Color2("Color 2", Color) = (1,1,1,1)
        _ColorLerp("纹理1纹理2颜色融合值", Range(0, 1)) = 0
        _NoiseIntensity1("基础纹理1噪声强度", Float) = 0
        _NoiseIntensity2("基础纹理2噪声强度", Float) = 0
        
        _NoiseTex("噪声贴图", 2D) = "white" {}
        _NoiseTexSpeed("扰动速度", Vector) = (0, 0, 0, 0)
        
        _MaskTexOn("开启Mask贴图", Float) = 1
        _MaskTex1("Mask贴图1", 2D) = "white" {}
        _MaskTex1UVWrapMode("UV Wrap 模式", Float) = 0
        _Mask1NoiseIntensity("Mask1噪声强度", Float) = 0
        [Toggle]_Mask1AlphaMultiply("启用Mask1透明度相乘", Float) = 0
        
        _MaskTex2("Mask贴图2", 2D) = "white" {}
        _MaskTex2UVWrapMode("UV Wrap 模式", Float) = 0
        [Toggle]_OpenRandomTex1UV("启用纹理1随机UV",Float) = 0
        [Toggle]_OpenRandomTex2UV("启用纹理2随机UV", Float) = 0
        [Toggle]_OpenRandomNoiseUV("启用扰动随机UV", Float) = 0
        [Toggle]_OpenRandomDissolveUV("启用溶解随机UV", Float) = 0
        
        [Toggle]_OpenUDirMask("启动U方向条带", Float) = 0
        [Toggle]_OpenVDirMask("启动V方向条带", Float) = 0
        
        [Toggle]_VertexAlphaOrderChange("顶点色计算顺序切换", Float) = 0
        _AlphaMin("Alpha Min", Float) = 0
        _AlphaEdge("Alpha边缘", Float) = 1
        
        [Toggle]_OpenDissolve("启动溶解", Float) = 0
        [Toggle]_DissolveByCustomData("Custom控制溶解", Float) = 0
        _DissolveTex("溶解贴图", 2D) = "white" {}
        _DissolveTexUVWrapMode("UV Wrap 模式", Float) = 0
        _DissolveNoiseIntensity("溶解扭曲强度", Float) = 0
        _Dissolve("溶解", Range(0, 1)) = 0
        _DissolveEdge("溶解边缘", Float) = 0
        
        _TotalAlpha("整体透明度控制", Float) = 1
        
        [HideInInspector] _Surface("__surface", Float) = 1.0
        [HideInInspector] _Blend("__blend", Float) = 1.0       
        [HideInInspector] _AlphaClip("__clip", Float) = 0.0
        [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0
        [HideInInspector] _ZWrite("__ZWrite", Float) = 0.0
        [HideInInspector] _Cull("__Cull", Float) = 0.0
        [HideInInspector] _Cutoff("Alpha Cutoff", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags { 
            "RenderType"="Transparent"
            "Queue" = "Transparent"
        }
        LOD 100
        //ZWrite Off
        //ZTest LEqual

       
        
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
            
            #pragma multi_compile_fragment _ DEBUG_DISPLAY
            #pragma shader_feature_local_fragment _MASK_MAP_ON
            #include "Packages/com.xinyuan.rendering/Shaders/FX/Particles/RandomLiuGuangInput.hlsl"
            #include "Packages/com.xinyuan.rendering/Shaders/FX/Particles/RandomLiuGuangPass.hlsl"

            ENDHLSL
        }
    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "XYRendering.Editor.RandomLiuGuangGUI"
}

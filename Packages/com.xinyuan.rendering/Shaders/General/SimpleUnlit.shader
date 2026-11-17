Shader "XinYuan/Scene/General/SimpleUnlit"
{
    Properties
    {
    	[Enum(UnityEngine.Rendering.CullMode)]_Cull("背面剔除", Float) = 0
        [MainTexture]_BaseMap ("BaseMap", 2D) = "white" {}
        [HDR]_BaseColor("Base Color", color) = (1,1,1,1)
        [Toggle] _BloomOff("bloom分离时强制关闭Bloom", float) = 0
	    [Toggle] _SRGBOff("关闭快速线性到SRGB", float) = 0
    	[Toggle] _fogOff("关闭雾效", float) = 0
    	_CullOff("Cull Off" , Float) = 0
    	[Main(_FogOffset_Group,_DISTANCE_FOG_OFFSET_ON)] _FogOffset("是否开启距离雾偏移", Float) = 0
    	[Sub(_FogOffset_Group)][NoScaleOffset]_FogOffsetMap ("雾效偏移灰度图", 2D) = "black" {}
    	[Sub(_FogOffset_Group)]_FogOffsetIntenisty("雾效偏移强度",Range(0,1)) = 0.2
    	
    	[Main(_ZOffset_Group,_DEPTH_OFFSET_ON)] _ZOffset("是否开启深度偏移", Float) = 0
        [Sub(_ZOffset_Group)] _ZOffsetViewSpace("深度偏移距离",float) = 0
    }
    SubShader
    {
       Tags{"RenderType" = "TransparentCutout" "IgnoreProjector" = "True" "ShaderModel"="4.5"}

    	HLSLINCLUDE
    	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		TEXTURE2D(_BaseMap);    SAMPLER(sampler_BaseMap);
        TEXTURE2D(_FogOffsetMap);    
        CBUFFER_START(UnityPerMaterial)
        half4 _BaseColor;
    	half4 _BaseMap_ST;
        half _BloomOff;
        half _CullOff;
        half _SRGBOff;
        half _fogOff;
        half _FogOffsetIntenisty;
        half _ZOffsetViewSpace;
		CBUFFER_END
    	ENDHLSL
    	
        Pass
        {
        	Tags{ "LightMode" = "UniversalForward"  }
        	Name "ForwardLit"
        	Cull [_Cull]
            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fragment _ DEBUG_DISPLAY
			#pragma multi_compile_fog
            #pragma skip_variants FOG_EXP FOG_EXP2
            #pragma shader_feature FOG_HEIGHT_PASS_APPLY
            #pragma shader_feature_local_vertex _DISTANCE_FOG_OFFSET_ON
            #pragma shader_feature_local_vertex _DEPTH_OFFSET_ON
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/ColorAdjustment.hlsl"
			#include "Packages/com.xinyuan.rendering/ShaderLibrary/Scene/FogLib.hlsl"
            #include "Packages/com.xinyuan.rendering/ShaderLibrary/Scene/ScenesCommon.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            
	        struct Attributes
	        {
	            float4 positionOS : POSITION;
	            half2 texcoord : TEXCOORD0;
    			half4 normalOS     : NORMAL;
	        };

	        struct Varyings
	        {
	            float4 positionHCS : SV_POSITION;
	            float2 uv : TEXCOORD0;
	            float4 positionWS  : TEXCOORD1;
	        };

	      
            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.texcoord;
            	OUT.positionWS.xyz = TransformObjectToWorld(IN.positionOS.xyz);
				half fogFactor = ComputeFogFactor(OUT.positionHCS.z);
				#ifdef _DISTANCE_FOG_OFFSET_ON
				half fogOffset = SAMPLE_TEXTURE2D_LOD(_FogOffsetMap, sampler_LinearClamp, OUT.uv,0).r;
				fogOffset *= _FogOffsetIntenisty;
				fogFactor -= fogOffset;
				fogFactor = clamp(fogFactor,0,1);
				#endif
				OUT.positionWS.w = fogFactor ;
				#if defined(_DEPTH_OFFSET_ON)
					float eps = 5.960464478e-8;
					float modifiedPositionVS_Z = -max(_ProjectionParams.y + eps, abs(OUT.positionHCS.w) - _ZOffsetViewSpace);
					float modifiedPositionCS_Z = modifiedPositionVS_Z * UNITY_MATRIX_P[2].z + UNITY_MATRIX_P[2].w;
					OUT.positionHCS.z = modifiedPositionCS_Z *  OUT.positionHCS.w / -(modifiedPositionVS_Z);
				#endif
                return OUT;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv) * _BaseColor;
				color.rgb =  SCENE_FAST_SRGB_TO_LINEAR(color.rgb) ;
            	
            	[branch]
                if (_CullOff > 0)
                {
					clip(color.a - _CullOff);
                }
            	//debugOverDraw
            	#if DEBUG_DISPLAY
			    half4 debugColor = half4(0, 0, 0, color.a);
			    InputData inputData = (InputData)0;
			    SurfaceData surfaceData = (SurfaceData)0;
			    surfaceData.albedo = color.rgb;
			    surfaceData.alpha = color.a;
			    if (CanDebugOverrideOutputColor(inputData, surfaceData, debugColor))
			    {
			        return debugColor;
			    }
				#endif
            	
                [branch]
            	if (_fogOff < 1.0f)
                {
	                float height = i.positionWS.y - _FogPosition;
					MixFogWithHeightAndDistance(color.rgb, height, i.positionWS.w);
                }
            	
            	
			    //TODO : 尝试把这个效果迁移到LUT中
			    GreyNegativeWithTint(_NegativeBrightScene, _NegativeStrengthScene, color, _NegativeTintScene, _LumThreshholdScene);
            	

            	
			    // 场景单独Lut, _Apply_SceneLut在ColorGradingLut被赋值
			    color.rgb = lerp(color.rgb, ApplyColorGrading(color.rgb, _Scene_Lut_Params.w, TEXTURE2D_ARGS(_ScenesLut, sampler_LinearClamp), _Scene_Lut_Params.xyz), _Apply_SceneLut);
			    // DoSceneColorChange(color.rgb, _ColorChangeProgress);
			    half a = GetBloomPrefilter(color.rgb, _SceneBloomThreshold) * _SceneBloomIntensity; 
			    SCENE_BLOOM_MUL(a);
            	color.rgb = _SRGBOff > 0? color.rgb : SCENE_FAST_LINEAR_TO_SRGB(color.rgb);
                return half4(color.rgb, lerp(a, 0, _BloomOff));
            }
            ENDHLSL
        }

    	 Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            ColorMask 0
			Cull[_Cull]
        	
            HLSLPROGRAM
            #pragma target 4.5
            
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            
            #pragma vertex ShadowPassVertexUnlit
            #pragma fragment ShadowPassFragmentUnlit
            
            struct Attributes
	        {
	            float4 positionOS : POSITION;
	            half2 texcoord : TEXCOORD0;
    			half4 normalOS     : NORMAL;
	        };

	        struct Varyings
	        {
	            float4 positionHCS : SV_POSITION;
	            float2 uv : TEXCOORD0;
	        };
            
            float3 _LightDirection;
            
			float4 GetShadowPositionHClip(Attributes input)
			{
			    float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
			    float3 normalWS = TransformObjectToWorldNormal(input.normalOS.xyz);
				
			    float3 lightDirectionWS = _LightDirection;

			    float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));

			#if UNITY_REVERSED_Z
			    positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
			#else
			    positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
			#endif

			    return positionCS;
				
			}
            
            Varyings ShadowPassVertexUnlit(Attributes input)
			{
			    Varyings output;
			    UNITY_SETUP_INSTANCE_ID(input);

			    output.uv = input.texcoord;
			    output.positionHCS = GetShadowPositionHClip(input);
			    return output;
			}
             half4 ShadowPassFragmentUnlit(Varyings i) : SV_TARGET
			{
				half Alpha = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv).a;
				[branch]
                if (_CullOff > 0)
                {
					clip(Alpha - _CullOff);
                }
				
				return 0;
			}
            ENDHLSL
        	
        }
    	 Pass
        {
            Name "Meta"
            Tags{"LightMode" = "Meta"}

            Cull Off

            HLSLPROGRAM
            #pragma target 4.5

            #pragma vertex UniversalVertexMeta
            #pragma fragment UniversalFragmentMetaUnlit
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UniversalMetaPass.hlsl"
            
            half4 UniversalFragmentMetaUnlit(Varyings input) : SV_Target
			{
				MetaInput metaInput = (MetaInput)0;
				
				return UniversalFragmentMeta(input, metaInput);
			}
            ENDHLSL
        }
    }
	
	FallBack "Hidden/Universal Render Pipeline/FallbackError"
	CustomEditor "XYRendering.Editor.XYRendingBaseGUI"
	
}
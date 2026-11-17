Shader "XinYuan/FX/Common/EFBloomOutline"
{
    Properties
    {
		[Toggle]_isSmoothNormal("是否开始平滑法线",float)=1
        _VertexOffest("顶点偏移强度",float) = 1   
    	_Alpha("总体透明度",Range(0,1)) = 1    
    	_BaseColor("基础颜色", Color) = (1,1,1,1)
    	[HDR]_BloomColor("发光颜色", Color) = (1,1,1,1)
    	_BloomOffest("发光遮罩强度[顶点色R]" ,Range(0,10)) = 0
	    [IntRange(0, 255)] _Ref ("Ref", Range(0, 255)) = 5
    	[IntRange(0, 255)]_ReadMask ("ReadMask", Range(0, 255)) = 255
    	[IntRange(0, 255)] _WriteMask ("WriteMask", Range(0, 255)) = 255
    	[KeywordEnum(None, Never, Less, Equal, LEqua, Greate, NotEqual, GEqual, Always)] _StencilComp ("StencilComp", float) = 7.0 //defalut always
    	[KeywordEnum(Keep, Zero, Replace, IncrSat, DecrSat, Invert, IncrWrap, DecrWrap)] _StencilPassOp ("StencilPassOp", float) = 7.0 //defalut Replace
    	[KeywordEnum(Keep, Zero, Replace, IncrSat, DecrSat, Invert, IncrWrap, DecrWrap)] _StencilFailOp ("StencilFailOp", float) = 7.0 //defalut Replace
    	[KeywordEnum(Keep, Zero, Replace, IncrSat, DecrSat, Invert, IncrWrap, DecrWrap)] _StencilZFailOp ("StencilZFailOp", float) = 7.0 //defalut Replace
    	
    }
    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 0

        Pass
        {
        	Tags{"LightMode" = "TransparentFX"}
        	Name "EFOutline"
		
			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite Off
			ZTest LEqual
            Cull Back
        	ColorMask RGB
        	Stencil
		{
			Ref [_Ref]
			ReadMask [_ReadMask]
			WriteMask [_WriteMask]
			Comp [_StencilComp]
            Pass [_StencilPassOp]
			Fail [_StencilFailOp]
			ZFail [_StencilZFailOp]
			
		}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                //float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
                float2 uv3 : TEXCOORD2;
                float4 tangent : TANGENT;
            	float4 vertexColor : COLOR;
            };

            struct v2f
            {
                float4 positionCS : SV_POSITION;
            	//float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 mask   : TEXCOORD2;
				half4 vertexColor : TEXCOORD3;
    
            };

            
            struct MRTOutput
            {
	            half4 fragColor		: SV_TARGET0;
	            half4 bloomColor	: SV_TARGET1;
            };
			
           
            
            CBUFFER_START(UnityPerMaterial)

            half4 _BaseColor;
            half4 _BloomColor;
            half _VertexOffest ;
            half _isSmoothNormal ;
            half _BloomOffest;
            half _Alpha;
            CBUFFER_END
			


            v2f vert (appdata v)
            {
                v2f o;
            	o.vertexColor = v.vertexColor;
                float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
                float3 normalWS = TransformObjectToWorldNormal(v.normalOS.xyz);
                float3 tangentWS = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
                float3 bitangentWS = normalize(cross(normalWS, tangentWS) * v.tangent.w);
                float3x3 tangentTransform = float3x3( tangentWS, bitangentWS, normalWS);

                float3 normal = float3(v.uv3, 0);
		        normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));
                float3 normalWSSmooth = normalize(mul(normal, tangentTransform));
				normalWS = lerp(normalWS , normalWSSmooth , _isSmoothNormal); 
               
                positionWS += normalWS.xyz * _VertexOffest * 0.01;
				float4 positionCS = TransformWorldToHClip( positionWS );
                o.positionWS = positionWS ;
                o.positionCS = positionCS;
            	
                return o;
            }
            

            
            MRTOutput frag (v2f i) 
            {
                MRTOutput mrtOutput = (MRTOutput)0;
            	half colorMask = lerp(-_BloomOffest,0,i.vertexColor.r);
                mrtOutput.fragColor = half4(_BaseColor.rgb * i.vertexColor.r , i.vertexColor.r *  _BaseColor.a * _Alpha);
                mrtOutput.bloomColor = half4( _BloomColor.rgb * i.vertexColor.r + colorMask,i.vertexColor.r *  _BloomColor.a * _Alpha);
                return mrtOutput;
				
            }
            ENDHLSL
        }
    }
}

Shader "XinYuan/Scene/SphereShadow/ShadowGenerator"
{
	Properties
	{
         _Shadowtex("椭圆阴影",2D) = "black"{}
	}

	HLSLINCLUDE  
	   #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 pos : SV_POSITION;
			};

	
			TEXTURE2D(_Shadowtex);                   
			
            CBUFFER_START(UnityPerMaterial)
			half4 _Shadowtex_ST;
		    CBUFFER_END

			v2f vert (appdata v)
			{
				v2f o;
				o.pos = TransformObjectToHClip(v.vertex);				
				o.uv =TRANSFORM_TEX(v.uv, _Shadowtex);
				return o;
			}
     ENDHLSL
	SubShader
	{
		Tags {  "RenderType"="Transparent" 
                "Queue" = "Transparent" }
		LOD 300
		Pass 
		{
		    Name "ShadowGenerator"
            Tags { "LightMode"= "ShadowGenerator" }
			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite Off

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
					
			half4 frag (v2f i) : SV_Target
			{				
				
				half4 stepCol = SAMPLE_TEXTURE2D(_Shadowtex,sampler_LinearClamp , i.uv);			
				half4 col = half4(1,1,1,stepCol.r);
				return col;
			}
			ENDHLSL
		}
		
		
	}
}

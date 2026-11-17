#ifndef UNIVERSAL_STANDARD_SLIME_INPUT_INCLUDED
#define UNIVERSAL_STANDARD_SLIME_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

CBUFFER_START(UnityPerMaterial)

		half _DitherFadeoutAmount;
        half _FlowNoiseIntensity;          
        half _Flowspeed;
        half _FlowIntensity;
        half _FlowIntensity2 ;
        half _FlowNoiseIntensity2;          
        half _Flowspeed2;
        half _IsuseFlow;

        half _BaseNoiseIntensity;
        half _BaseNoiseIntensity2;

        //alpha
        half _AlphaPower2;           
        half _AlphaIntensity2;
        half _AlphaPower;           
        half _AlphaIntensity;
        half _IsuseAlpha;

        half _DiffuseOn;
        half _DiffuseIntensity;

        half _EFEdgeSmooth;
        half _EFEdgeThreshold;
        half _EFSize;

        half _OutlineWidth ;
        half _isSmoothNormal;
        

        //FrenselRim
        half _FXFresnelRim_ON;

        //frensel
        half _IsuseNormal;
        half _IsuseNormal2;
        half _FrenselPower;
        half _FrenselIntensity;  
        half _FrenselPower2;
        half _FrenselIntensity2;

		//normal
		half _NormalIntensity ;
		half _NormalSpeed ;
		half _NormalIntensity2 ;
		half _NormalSpeed2 ;

		//顶点动画
		half _VertexanimIntensity;
		half _VertexFrequency; 
		half _VertexDirecitonFrequency;
		half _IsuseNoise;
		half _IsuseVertexDir;

		//透明扰动
		half _DistortionIntensity;
		half _DistortionSpeed;
		half _DistortionMaskIntensity;
		half _DistortionMaskPower;

		//MatCap
		half _MatIntensity ;
		half _MatNoise;
		half _MatIntensity2 ;
		half _MatNoise2;

		half3 _FXFresnelRimParams;

		float4 _DistortionMap_ST;

		half4 _VertexDireciton;
		half4 _VertexwindScale ;

		float4 _NormalMap_ST;
  
        half4 _FXFresnelRimColor;
        half4 _OutlineColor;
        half4 _FrenselColor;
        float4 _Flowmap_ST;

CBUFFER_END

        SAMPLER (sampler_Flowmap);                      TEXTURE2D(_Flowmap);
        SAMPLER (sampler_BaseMap);                      TEXTURE2D(_BaseMap);

        #ifdef _NORMAL_ON
        SAMPLER (sampler_NormalMap);                    TEXTURE2D(_NormalMap);
        #endif
        #ifdef _DISTORTION_ON
        SAMPLER(sampler_DistortionMap);                 TEXTURE2D(_DistortionMap);
        #endif
        #ifdef _MATMAP_ON
        SAMPLER(sampler_Mat);                           TEXTURE2D(_Mat);
        #endif

		half3 PlanarNormal(half3 posworld ,half3 pos_pivot ,TEXTURE2D( _VertexAnim ),SAMPLER( sampler_VertexAnim) , half4 _VertexAnim_ST,half _VertexSpeed)
        {
            half3 pos_world = pow(abs(posworld) , 5);
            pos_world = pos_world / (pos_world.x + pos_world.y + pos_world.z);
            half2 normal_xy =pos_pivot.xy ;
            half2 normal_zy =pos_pivot.zy ;
            half2 normal_xz =pos_pivot.xz ; 
            half flow_vertex = _Time.y * _VertexSpeed  ;
            half2 world_xy = normal_xy * _VertexAnim_ST.xy + _VertexAnim_ST.zw * flow_vertex ;
            half2 world_zy = normal_zy * _VertexAnim_ST.xy + _VertexAnim_ST.zw * flow_vertex;
            half2 world_xz = normal_xz * _VertexAnim_ST.xy + _VertexAnim_ST.zw * flow_vertex;           
            half3 vertexanim = UnpackNormal(SAMPLE_TEXTURE2D(_VertexAnim , sampler_VertexAnim , half2(world_xy.x , world_xy.y)))* pos_world.z;
            vertexanim += UnpackNormal(SAMPLE_TEXTURE2D(_VertexAnim , sampler_VertexAnim , half2(world_zy.x , world_zy.y)))* pos_world.x;
            vertexanim += UnpackNormal(SAMPLE_TEXTURE2D(_VertexAnim , sampler_VertexAnim , half2(world_xz.x , world_xz.y)))* pos_world.y;
            return vertexanim ;
        }
            
		float mysin(float x)
		{
            float B = 1.2732395447; // 4/pi
            float C = -0.4052847346; // -4/(pi^2)
            float y = 0;

            //always wrap input angle to -PI..PI
            if (x < -3.14159265)
                x += 6.28318531;
            else if (x > 3.14159265)
                x -= 6.28318531;
 
            if(x > 0)
                y = B*x + C*x*x;
            else
                y = B*x - C*x*x;
    
            return y; 

		}

        float2 randomVec(float2 uv)
		{
            float vec = dot(uv, float2(127.1, 311.7));
            return -1.0 + 2.0 * frac(mysin(vec) * 43758.5453123);
        }

        float perlinNoise(float2 uv )
		{
		    
						
            float2 pi = floor(uv);
            float2 pf = uv - pi;
            float2 w = pf * pf * (3.0 - 2.0 *  pf);

            float lerp1 = lerp(
	            dot(randomVec(pi + float2(0.0, 0.0)), pf - float2(0.0, 0.0)),
	            dot(randomVec(pi + float2(1.0, 0.0)), pf - float2(1.0, 0.0)), w.x);
            
            float lerp2 = lerp(
	            dot(randomVec(pi + float2(0.0, 1.0)), pf - float2(0.0, 1.0)),
	            dot(randomVec(pi + float2(1.0, 1.0)), pf - float2(1.0, 1.0)), w.x);
	
            return lerp(lerp1, lerp2, w.y);
        }

        half3 VertexAnim(half2 uv ,  half mask , half3 normalWS)
		{
			//vertexdirection
			half vertexwindspeed = _Time.y * _VertexDirecitonFrequency ;
			half vertexwind = sin(vertexwindspeed * 3.14h ) * _VertexDireciton.w;
			half vertexwindanim = vertexwind ;
			half3 vertexdirection = _VertexDireciton.xyz * vertexwindanim * mask ;              
			vertexdirection = vertexdirection;             
			vertexdirection = lerp(half3(0,0,0),vertexdirection , _IsuseVertexDir);
			//noisevalue
			half2 noiseTimeuv = (uv.x * _VertexwindScale.xy * ( _VertexwindScale.z * 100)  + _Time.y  ) ;
			half noiseAnim = perlinNoise(noiseTimeuv) *  _VertexwindScale.w *2 ;
			half3 noisevalue = float3(0.1h,0.1h,0.1h) * noiseAnim  * mask ;
			noisevalue = lerp(half3(0,0,0),noisevalue , _IsuseNoise);
			//vertexanim
			half2 vertexanim = (uv * ( _VertexFrequency *100)  + _Time.y  ) ;
			half vertexnoise = perlinNoise(vertexanim) *2 -1 ;
			if(_IsuseNoise > 0 || _IsuseVertexDir > 0)
			{
				vertexnoise = lerp(vertexnoise , 0 , mask);
			}
			half3 vertexAinmposition = vertexnoise * 0.02 * _VertexanimIntensity * normalWS  + noisevalue  + vertexdirection  ;
			return  vertexAinmposition;
		}

#endif 

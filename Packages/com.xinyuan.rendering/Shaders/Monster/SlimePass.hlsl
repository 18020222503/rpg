#ifndef UNIVERSAL_STANDARD_SLIME_PASS_INCLUDED
#define UNIVERSAL_STANDARD_SLIME_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/ColorAdjustment.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Scene/ScenesCommon.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Scene/FogLib.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/DitherFadeoutClipUtil.hlsl"

    struct appdata
    {
        float4 vertex : POSITION;
        float2 texcoord : TEXCOORD0;
        float3 normal:NORMAL;
        float4 tangent : TANGENT;
        float4 color : COLOR;
        float2 uv3 : TEXCOORD2;
    };

    struct v2f
    {
        float4 pos : SV_POSITION;
        float2 uv : TEXCOORD0;
        float3 viewuvandfogFactor : TEXCOORD1;
        float4 normal_dir : TEXCOORD2;                                     
        float2 matuv : TEXCOORD3;            
        float4 vertexcolor : TEXCOORD4;
        float4 tangent : TEXCOORD5;
        float4 binormal : TEXCOORD6;
        float4 pos_pivot : TEXCOORD08;
    };

    v2f vert (appdata v)
    {
        v2f o;
       
        VertexPositionInputs vertexPositionInputs = GetVertexPositionInputs(v.vertex.xyz);
        half3 pos_world = vertexPositionInputs.positionWS;
        half3 pivot_world = mul(UNITY_MATRIX_M , float4( float3( 0,0,0 ), 1 )).xyz;
        o.pos_pivot.w = pos_world.y;
        o.pos_pivot.xyz = pos_world  - pivot_world ;
        o.vertexcolor = v.color.rgba;
        VertexNormalInputs vertexNormalInputs = GetVertexNormalInputs(v.normal.xyz , v.tangent.xyzw);
        o.normal_dir.xyz = vertexNormalInputs.normalWS;       
        o.tangent.xyz = vertexNormalInputs.tangentWS;
        o.binormal.xyz = vertexNormalInputs.bitangentWS;
                               
      #ifdef _VERTEXANIM_ON
        UNITY_BRANCH
        if (_VertexanimIntensity > 0 )
        {
            half3 vertexAinmposition = VertexAnim(v.vertex.xy , o.vertexcolor.r , o.normal_dir.xyz);
            v.vertex.xyz += vertexAinmposition;
        
            o.pos = TransformObjectToHClip(v.vertex.xyz) ;   
            pos_world = TransformObjectToWorld(v.vertex.xyz);
        }
      #else
        o.pos = TransformObjectToHClip(v.vertex.xyz) ;                 
      #endif
        half3 viewdir = normalize( _WorldSpaceCameraPos - pos_world );    
        o.normal_dir = float4(o.normal_dir.xyz , viewdir.x) ;     
        o.tangent =float4(o.tangent.xyz , viewdir.y) ; 
        o.binormal =float4(o.binormal.xyz , viewdir.z) ; 
        o.uv = v.texcoord;  
        half3 pos_view = TransformWorldToView(pos_world);                             
        half3 pivot_view = TransformWorldToView(mul(UNITY_MATRIX_M , float4( float3( 0,0,0 ), 1 )).xyz);
        o.viewuvandfogFactor.xy = pos_view.xy - pivot_view.xy ;
        o.matuv =  TransformWorldToViewDir(o.normal_dir.xyz).xy; 
        // Fog
        o.viewuvandfogFactor.z = ComputeFogFactor(o.pos.z);
        
        return o;
    }

    v2f vertoutline (appdata v)
    {
        v2f o;
        
        o.vertexcolor = v.color.rgba;
        VertexNormalInputs vertexNormalInputs = GetVertexNormalInputs(v.normal.xyz , v.tangent.xyzw);
        o.normal_dir.xyz = vertexNormalInputs.normalWS;
        float3 tangentWS = vertexNormalInputs.tangentWS;
        float3 bitangentWS = vertexNormalInputs.bitangentWS;
        float3x3 tangentTransform = float3x3( tangentWS, bitangentWS, o.normal_dir.xyz);
        
        //SmoothNormal
        if(_isSmoothNormal > 0)
        {
            float3 normal = float3(v.uv3, 0);
		    normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));
            float3 normalWSSmooth = normalize(mul(normal, tangentTransform));
			o.normal_dir.xyz = normalWSSmooth;
        }
    
      #ifdef _VERTEXANIM_ON
        UNITY_BRANCH
        if (_VertexanimIntensity > 0 )
        {
            half3 vertexAinmposition = VertexAnim(v.vertex.xy , o.vertexcolor.r , o.normal_dir.xyz);
            v.vertex.xyz += vertexAinmposition;
        }
      #endif
        
        VertexPositionInputs vertexPositionInputs = GetVertexPositionInputs(v.vertex.xyz);
        half3 posview = vertexPositionInputs.positionVS; 
            
        half3 outline_dir = TransformWorldToViewDir(o.normal_dir.xyz);
        posview += outline_dir * _OutlineWidth * 0.01 * o.vertexcolor.a  ;
        
        o.pos = mul(GetViewToHClipMatrix(), float4(posview, 1.0)); ;  
        o.uv = v.texcoord;
        
        VertexPositionInputs vertexPositionInput = GetVertexPositionInputs(v.vertex.xyz);
        half3 pos_world = vertexPositionInput.positionWS;
        o.pos_pivot = float4(0,0,0,pos_world.y);
        // Fog
        o.viewuvandfogFactor =float3(0,0, ComputeFogFactor(TransformObjectToHClip(v.vertex.xyz).z));
        return o;
    }

    half4 fragoutline (v2f i ) : SV_Target
    {   
        
        #if defined(_DITHER_FADEOUT)
        DoDitherFadeoutClip(i.pos, 1-_DitherFadeoutAmount);
        #endif
        
        half4 baseColor = SAMPLE_TEXTURE2D(_BaseMap , sampler_BaseMap , i.uv );   
        half maxComponent = max(max(baseColor.r, baseColor.g), baseColor.b) - 0.004;
        half3 saturatedColor = step(maxComponent.rrr, baseColor.rgb) * baseColor.rgb;
        saturatedColor = lerp(baseColor.rgb, saturatedColor, 0.1);
        saturatedColor *= 0.8 * _OutlineColor.rgb * _OutlineColor.a;
        float height = i.pos_pivot.w - _FogPosition;
        MixFogWithHeightAndDistance(saturatedColor.rgb, height, i.viewuvandfogFactor.z);
        return half4(saturatedColor,1) ;
  
    }

    half4 backFrag (v2f i ,half face : VFACE) : SV_Target
    {

        #if defined(_DITHER_FADEOUT)
        DoDitherFadeoutClip(i.pos, 1-_DitherFadeoutAmount);
        #endif
        half3 normal_dir =  i.normal_dir.xyz ;               
        half3 view = half3(i.normal_dir.w,i.tangent.w , i.binormal.w);
        half matcap = 0 ;
        half3 Matnoise = normal_dir;
        
        // 三平面映射 normal   
      #ifdef _NORMAL_ON
        UNITY_BRANCH
        if (_NormalIntensity > 0)
        {
            half3 normalmap = PlanarNormal(normal_dir, i.pos_pivot.xyz,_NormalMap ,sampler_NormalMap ,_NormalMap_ST,_NormalSpeed * 0.1);
            float3x3 TBN = float3x3(i.tangent.xyz  , i.binormal.xyz, normal_dir) ;
            float3 normal = normalize( mul(normalmap  * half3(_NormalIntensity.xx ,1), TBN) ) ;  
            #ifdef _MATMAP_ON
                Matnoise = lerp( i.normal_dir.xyz , normal ,_MatNoise);
            #endif
                normal_dir = normal ;  
        }
       
      #endif

      //Diffuse
        Light mainLight = GetMainLight();  
        half3 Light = mainLight.direction ;
        half diffusecolor = dot( i.normal_dir.xyz , Light) * 0.5 + 0.5 ;
        diffusecolor =  step( 0.35, diffusecolor );
        diffusecolor = lerp(1 , diffusecolor , _DiffuseOn);

      //MatCap
      #ifdef _MATMAP_ON
        UNITY_BRANCH
        if (_MatIntensity > 0)
        {
            half3 matuv =  TransformWorldToViewDir(Matnoise) * 0.5 + 0.5;   
            matcap = SAMPLE_TEXTURE2D(_Mat , sampler_Mat ,matuv.xy ).r * _MatIntensity;  
        }
       
      #endif
        half BaseMask = i.vertexcolor.g ;              
        half2 noiseuv = lerp(0 , normal_dir.xy * 0.1,_BaseNoiseIntensity);
        half4 Basecolor = SAMPLE_TEXTURE2D(_BaseMap , sampler_BaseMap , i.uv + noiseuv * BaseMask);  

        half Flowcolor = SAMPLE_TEXTURE2D(_Flowmap , sampler_Flowmap , i.viewuvandfogFactor.xy *_Flowmap_ST.xy + _Flowmap_ST.zw * _Time.y * _Flowspeed * 0.1 + normal_dir.xy * _FlowNoiseIntensity * 0.1 ).r * _FlowIntensity;                
        half4 Flow = lerp(Basecolor * 0.92 , Basecolor + Basecolor *Flowcolor * _FlowIntensity,Flowcolor);
        Basecolor = lerp(Basecolor , Flow  ,_IsuseFlow) ;
        Flowcolor = lerp(0 , Flowcolor ,_IsuseFlow);
        Basecolor =  saturate( Basecolor +  matcap  );
        Basecolor.rgb = lerp(Basecolor.rgb * saturate(1 - _DiffuseIntensity) , Basecolor.rgb , diffusecolor);
        i.normal_dir.xyz = (face > 0) ? normalize( i.normal_dir.xyz ) : normalize( - i.normal_dir.xyz) ;
        
        half3 frenselnormal = lerp(i.normal_dir.xyz , normal_dir , _IsuseNormal);
        half frensel =saturate(1-  max(0.01,dot(frenselnormal , normalize(view))) );            
        half basealpha = Basecolor.a;
        half alphamask =saturate(1-  max(0.01,dot(i.normal_dir.xyz ,normalize( view))) ); 
        half alpha =saturate((pow(alphamask , _AlphaPower) * _AlphaIntensity) + matcap) ;
        alpha = saturate( Flowcolor + alpha);   
        alpha = lerp(alpha , alpha* basealpha , _IsuseAlpha);
        half frenselcolor = saturate( pow( frensel , _FrenselPower) * _FrenselIntensity) * _FrenselColor.a * Basecolor.a;
        half4 finalcolor =lerp(Basecolor , _FrenselColor * Basecolor ,saturate( frenselcolor )) ; 
      
        // //FrenselRim
        // half fresnelNdotV = 1-alphamask ;
        // half3 rimColor = ((1 - smoothstep(_FXFresnelRimParams.x, _FXFresnelRimParams.x+ _FXFresnelRimParams.y, fresnelNdotV))) * _FXFresnelRimParams.z * _FXFresnelRimColor * _FXFresnelRim_ON;
        //
        // finalcolor.rgb += rimColor;
        
        float height = i.pos_pivot.w - _FogPosition;
        MixFogWithHeightAndDistance(finalcolor.rgb, height, i.viewuvandfogFactor.z);
        return half4(finalcolor.rgb ,alpha);
  
    }

    half4 frontFrag (v2f i) : SV_Target
    {
        #if defined(_DITHER_FADEOUT)
        DoDitherFadeoutClip(i.pos, 1-_DitherFadeoutAmount);
        #endif
            
        half3 normal_dir =  i.normal_dir.xyz ;               
        half3 view = half3(i.normal_dir.w,i.tangent.w , i.binormal.w);
        half matcap = 0 ;
        half3 Matnoise = normal_dir;
        
        // 三平面映射 normal   
      #ifdef _NORMAL_ON
        UNITY_BRANCH
        if (_NormalIntensity > 0)
        {
            half3 normalmap = PlanarNormal(normal_dir, i.pos_pivot.xyz,_NormalMap ,sampler_NormalMap ,_NormalMap_ST,_NormalSpeed * 0.1);          
            float3x3 TBN = float3x3(i.tangent.xyz  , i.binormal.xyz, i.normal_dir.xyz) ;
            half3 normal = normalize( mul(normalmap  * half3(_NormalIntensity2.xx ,1), TBN) ) ;  
            #ifdef _MATMAP_ON
                Matnoise = lerp(i.normal_dir.xyz , normal ,_MatNoise2);
            #endif
                normal_dir = normal ;
        }
      #endif

      //Diffuse
        Light mainLight = GetMainLight();  
        half3 Light = mainLight.direction ;
        half diffusecolor = dot(i.normal_dir.xyz  , Light) * 0.5 + 0.5 ;
        diffusecolor =  step( 0.35, diffusecolor );
        diffusecolor = lerp(1 , diffusecolor , _DiffuseOn);

      //MatCap
      #ifdef _MATMAP_ON
        UNITY_BRANCH
        if (_MatIntensity2 > 0)
        {
            half3 matuv =  TransformWorldToViewDir(Matnoise) * 0.5 + 0.5;   
            matcap = SAMPLE_TEXTURE2D(_Mat , sampler_Mat ,matuv.xy ).r * _MatIntensity2;
        }
      #endif

        half BaseMask = i.vertexcolor.g ;    
        half2 noiseuv = lerp(0 , normal_dir.xy * 0.1,_BaseNoiseIntensity2);
        half4 Basecolor = SAMPLE_TEXTURE2D(_BaseMap , sampler_BaseMap , i.uv + noiseuv * BaseMask);  

        half Flowcolor = SAMPLE_TEXTURE2D(_Flowmap , sampler_Flowmap , i.viewuvandfogFactor.xy *_Flowmap_ST.xy + _Flowmap_ST.zw * _Time.y * _Flowspeed2 * 0.1+ normal_dir.xy * _FlowNoiseIntensity2  * 0.1).r * _FlowIntensity2;                
        half4 Flow = lerp(Basecolor * 0.9 , Basecolor + Basecolor *Flowcolor * _FlowIntensity2,Flowcolor);
        Basecolor = lerp(Basecolor , Flow  ,_IsuseFlow) ;
        Flowcolor = lerp(0 , Flowcolor ,_IsuseFlow);
        Basecolor =  saturate( Basecolor +  matcap  );
        Basecolor.rgb = lerp(Basecolor.rgb * saturate(1 - _DiffuseIntensity) ,Basecolor.rgb, diffusecolor);
        half3 frenselnormal = lerp(i.normal_dir.xyz , normal_dir , _IsuseNormal2);
        half frensel =saturate(1-  max(0.01,dot(frenselnormal , normalize(view))) ); 
        half basealpha = Basecolor.a;
        half alphamask =saturate(1-  max(0.01,dot(i.normal_dir.xyz ,normalize( view))) ); 
        half alpha =saturate(pow(alphamask , _AlphaPower2) * _AlphaIntensity2) + matcap ;
        alpha = saturate( Flowcolor + alpha)  ;
        alpha = lerp(alpha , alpha* basealpha , _IsuseAlpha);
        half frenselcolor = clamp( pow( frensel , _FrenselPower2) * _FrenselIntensity2, 0 , 1) * _FrenselColor.a * Basecolor.a;
        half4 finalcolor =lerp(Basecolor , _FrenselColor * Basecolor ,saturate( frenselcolor )) ;    
        
        
        //FrenselRim
        half fresnelNdotV = 1-alphamask ;
        half3 rimColor = ((1 - smoothstep(_FXFresnelRimParams.x, _FXFresnelRimParams.x+ _FXFresnelRimParams.y, fresnelNdotV))) * _FXFresnelRimParams.z * _FXFresnelRimColor * _FXFresnelRim_ON;

        finalcolor.rgb += rimColor;
        float height = i.pos_pivot.w - _FogPosition;
        MixFogWithHeightAndDistance(finalcolor.rgb, height, i.viewuvandfogFactor.z);
        return half4(finalcolor.rgb ,alpha);
  
    }

#endif

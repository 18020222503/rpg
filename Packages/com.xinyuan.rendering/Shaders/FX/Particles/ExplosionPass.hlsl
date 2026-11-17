#ifndef FX_PARTICLE_EXPLOSION_PASS_INCLUDED
#define FX_PARTICLE_EXPLOSION_PASS_INCLUDED


#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/UVHelper.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/ColorAdjustment.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/FX/FXDebug.hlsl"

struct Attributes
{
    float3 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 color : COLOR;
    float4 uv : TEXCOORD0;
    float4 customData1 : TEXCOORD1;
    float4 customData2 : TEXCOORD2;
    
    UNITY_VERTEX_INPUT_INSTANCE_ID
};


struct Varyings
{
    float4 positionCS : SV_POSITION;
    float4 uv : TEXCOORD0;
    float4 vertexColor : TEXCOORD1;
    float4 customData : TEXCOORD2;
    float fogFactor : TEXCOORD3;
    float3 positionWS : TEXCOORD4;
    
    UNITY_VERTEX_INPUT_INSTANCE_ID
};


struct MRTOutput
{
    half4 fragColor		: SV_TARGET0;
    half4 bloomColor	: SV_TARGET1;
};



Varyings vert(Attributes attrs)
{
    Varyings vars = (Varyings)0;
    UNITY_SETUP_INSTANCE_ID(attrs);
    UNITY_TRANSFER_INSTANCE_ID(attrs, vars);

    float2 uv = UVHelper_TransformUV(attrs.uv.xy, _DisplaceMap_ST,  float2(_DisplaceUSpeed, _DisplaceVSpeed), attrs.customData2.xy, 0, _DisplaceUVMoveMode, _DisplaceUVWrapMode);
    half displaceAmout = SAMPLE_TEXTURE2D_LOD(_DisplaceMap, sampler_DisplaceMap, uv, 0).r;
    displaceAmout = lerp(displaceAmout, 1-displaceAmout, _InvertDisplaceMap);
    displaceAmout *= _DisplaceStren;
    attrs.positionOS += attrs.normalOS * displaceAmout * attrs.customData1.w;    
    
    vars.positionCS = TransformObjectToHClip(attrs.positionOS);
    vars.uv.xy = uv;
    vars.uv.zw = UVHelper_TransformUV(attrs.uv.xy, _DissMap_ST,  float2(_DissUSpeed, _DissVSpeed), attrs.customData2.zw, 0, _DissUVMoveMode, _DissUVWrapMode);;
    vars.vertexColor = attrs.color;
    
    vars.customData = attrs.customData1;
    
    vars.fogFactor = ComputeFogFactor(vars.positionCS.z);

    vars.positionWS = TransformObjectToWorld(attrs.positionOS);

    return vars;
}


half4 ColorFrag(Varyings vars) : SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(vars);

    // Laser Hit End
    // #if defined(_LASEREND_ON)
    // half3 positionFromHitPoint = vars.positionWS - _HitPositionWS;
    // half HDotLaser = dot(positionFromHitPoint, _LaserDirWS);
    // clip(-HDotLaser);
    // #endif

    half alpha = vars.vertexColor.a;
    half cutoff = saturate(1 - vars.customData.x);
    half diss = SAMPLE_TEXTURE2D(_DissMap, sampler_DissMap, vars.uv.zw).r;;
    diss = lerp(diss, 1-diss, _InvertDissMap);
    diss = saturate(diss * _DissStren);    

    clip(diss - cutoff);

    half distance = saturate(diss - cutoff);
    half inEdge = step(distance, _DissSmooth)  * step(0.01, cutoff);
    alpha = lerp(alpha, saturate(alpha * distance / _DissSmooth), inEdge); 

    half displaceAmout = SAMPLE_TEXTURE2D(_DisplaceMap, sampler_DisplaceMap, vars.uv.xy).r;
    displaceAmout = lerp(displaceAmout, 1-displaceAmout, _InvertDisplaceMap);
    displaceAmout *= _DisplaceStren;
    half3 col = lerp(_HighTempCol.rgb, _MidTempCol.rgb, smoothstep(vars.customData.z-_MidTempEdgeSmooth*2, vars.customData.z+_MidTempEdgeSmooth*2, (displaceAmout+_MidTempRange) * vars.customData.y));
    col = lerp(col, _LowTempCol.rgb, smoothstep(vars.customData.z-_LowTempEdgeSmooth*2, vars.customData.z +_LowTempEdgeSmooth*2, (displaceAmout+_LowTempRange) * vars.customData.y));

    col = lerp(col, MixFog(col, vars.fogFactor), _FogOn);
    alpha *= _AlphaMultiplyer;    

    GreyNegativeWithTint(_NegativeBrightFX, _NegativeStrengthFX, col, _NegativeTintFX,_LumThreshholdFX);
    alpha = saturate(alpha);

    return OutputFXFinalColor(half4(col, alpha));
}


half4 ForwardFrag(Varyings vars) : SV_TARGET
{
    return ColorFrag(vars);
}


half4 BloomFrag(Varyings vars) : SV_TARGET
{
    half4 bloomMutiplyer = _GlobalFXBloomOn > 0 ? _BloomTint * _GlobalFXBloomIntensity : _BloomTint;
    half4 fragColor = ColorFrag(vars);
    return half4(fragColor.rgb * bloomMutiplyer.rgb, fragColor.a);
}


MRTOutput MRTFrag(Varyings i)
{
    MRTOutput mrtOutput = (MRTOutput)0;
    half4 bloomMutiplyer = _GlobalFXBloomOn > 0 ? _BloomTint * _GlobalFXBloomIntensity : _BloomTint;
    mrtOutput.fragColor =  ColorFrag(i);
    mrtOutput.bloomColor = half4(mrtOutput.fragColor.rgb * bloomMutiplyer.rgb * _BloomOn, mrtOutput.fragColor.a);

    return mrtOutput;
}



#endif 
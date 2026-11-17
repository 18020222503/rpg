#ifndef SHADER_LIBRARY_UTILITIES_INCLUDE
#define SHADER_LIBRARY_UTILITIES_INCLUDE

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/ColorSpace.hlsl"

// 2d旋转
float2x2 Rotate2d(half angle)
{
    return half2x2(cos(angle), -sin(angle),
                sin(angle), cos(angle));
}

half2 rotateUV(half2 uv, half angle, half2 center = half2(0,0))
{
    uv -= center;
    angle /= 57.3;
    half2x2 rot = Rotate2d(angle);
    uv = mul(rot, uv);
    uv += center;

    return  uv;
}


// Triplanar Mapping
#define SAMPLE_TEXTURE2D_TRIPLANAR(texName, samplerName, tileOffset, posWs, normalWS) SampleTex2DTriplanar(TEXTURE2D_ARGS(texName, samplerName), tileOffset, posWs, normalWS)

half4 SampleTex2DTriplanar(TEXTURE2D_PARAM(texName, samplerName), float4 tileOffset,half3 posWS, half3 normalWS)
{
    half4 sampleX = SAMPLE_TEXTURE2D(texName, samplerName, posWS.yz * tileOffset.xy + tileOffset.zw);
    half4 sampleY = SAMPLE_TEXTURE2D(texName, samplerName, posWS.xz * tileOffset.xy + tileOffset.zw);
    half4 sampleZ = SAMPLE_TEXTURE2D(texName, samplerName, posWS.xy * tileOffset.xy + tileOffset.zw);
    
    half3 weights = normalize(max(abs(normalWS), 0.001h));
    weights /= dot(weights, half3(1, 1, 1));
    
    return sampleX * weights.x + sampleY * weights.y + sampleZ * weights.z;
}

float3 TriplanarSampling(TEXTURE2D_PARAM(texName, samplerName), float3 positionWS, float3 normalWS, float falloff, float2 tiling = float2(1,1), float3 normalScale = 1, float3 index = 0 )
{
    float3 projNormal = pow(abs(normalWS), falloff);
    projNormal /= (projNormal.x + projNormal.y + projNormal.z) + 0.00001;
    float3 nsign = sign(normalWS);
    half4 xNorm, yNorm, zNorm;
    xNorm = FAST_SRGB_TO_LINEAR(SAMPLE_TEXTURE2D(texName, samplerName, tiling * positionWS.zy * float2(  nsign.x, 1.0 ) ));
    yNorm = FAST_SRGB_TO_LINEAR(SAMPLE_TEXTURE2D(texName, samplerName, tiling * positionWS.xz * float2(  nsign.y, 1.0 ) ));
    zNorm = FAST_SRGB_TO_LINEAR(SAMPLE_TEXTURE2D(texName, samplerName, tiling * positionWS.xy * float2( -nsign.z, 1.0 ) ));
    xNorm.xyz  = half3(UnpackNormal(xNorm).xy * float2(nsign.x, 1.0) + normalWS.zy, normalWS.x).zyx;
    yNorm.xyz  = half3(UnpackNormal(yNorm).xy * float2(nsign.y, 1.0) + normalWS.xz, normalWS.y).xzy;
    zNorm.xyz  = half3(UnpackNormal(zNorm).xy * float2(-nsign.z, 1.0) + normalWS.xy, normalWS.z).xyz;
    return normalize(xNorm.xyz * projNormal.x + yNorm.xyz * projNormal.y + zNorm.xyz * projNormal.z);
}

half2 MatcapUVCompute(half3 viewVS, half3 normalVS, bool flipped = false)
{
    
    /* Quick creation of an orthonormal basis */
    half a = 1.0 / (1.0 + viewVS.z);
    half b = -viewVS.x * viewVS.y * a;
    half3 b1 = half3(1.0 - viewVS.x * viewVS.x * a, b, -viewVS.x);
    half3 b2 = half3(b, 1.0 - viewVS.y * viewVS.y * a, -viewVS.y);
    half2 matcap_uv = half2(dot(b1, normalVS), dot(b2, normalVS));
    //TODO
    if (flipped) {
        matcap_uv.x = -matcap_uv.x;
    }
    return matcap_uv * 0.496 + 0.5;
}

half2 MatcapUVSimpleCompute(half2 normalVS)
{
    half2 uv = normalVS * 0.5 + 0.5;
    return half2(uv.x, (1-uv.y));
}

half2 PolarCoordinates(half2 uv, half2 center = half2(0.5, 0.5), half radialScale = 0, half lengthScale = 0)
{
    // https://cyangamedev.wordpress.com/2019/05/13/polar-coordinates/
    half2 delta = uv - center;
    return half2((length(delta) * radialScale * 2.0), (atan2(delta.x, delta.y) * INV_TWO_PI * lengthScale));
}



#endif
#ifndef XY_PIPELINE_TYPES_INCLUDED
#define XY_PIPELINE_TYPES_INCLUDED

// xinyuan 管线（URP 12 fork）在 Input.hlsl / SurfaceData.hlsl / Core.hlsl 里加的类型和变量，
// URP 17 没有，场景 Lit / SimpleLit 需要

#ifndef BUMP_SCALE_NOT_SUPPORTED
    #define BUMP_SCALE_NOT_SUPPORTED !SHADER_HINT_NICE_QUALITY
#endif

// 实时阴影与 shadowmask 重叠区域的额外 AO，全局变量，没设置时为 0（不影响）
half _RealTimeShadowAreaOcclusion;

struct XYInputData
{
    float3  positionWS;
    float4  positionCS;
    half3   normalWS;
    half3   viewDirectionWS;
    float4  shadowCoord;
    half    fogCoord;
    half3   vertexLighting;
    half3   bakedGI;
    half4   shadowMask;
    half3x3 tangentToWorld;
};

// 金属工作流，没有 specular 和清漆
struct XYSurfaceData
{
    half3 albedo;
    half  metallic;
    half  smoothness;
    half3 normalTS;
    half3 emission;
    half  occlusion;
    half  alpha;
};

#endif

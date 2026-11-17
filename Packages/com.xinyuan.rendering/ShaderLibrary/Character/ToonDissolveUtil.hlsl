#ifndef __ToonDissolveModule__
#define __ToonDissolveModule__
#if _DISSOLVE && _DISSOLVE_BRANCH
#define DISSOLVE_ON(dissolve)      half  dissolve
#define DISSOLVE_START(dissolve) STATIC_BRANCH_START(dissolve)
#define DISSOLVE_END(dissolve)   STATIC_BRANCH_END(dissolve) 
#else
#define DISSOLVE_ON(dissolve)
#define DISSOLVE_START(dissolve)
#define DISSOLVE_END(dissolve)
#endif
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/Math.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/ProceduralNoise.hlsl"

float3 mod3D289( float3 x ) { return x - floor( x / 289.0 ) * 289.0; }
			float4 mod3D289( float4 x ) { return x - floor( x / 289.0 ) * 289.0; }
			float4 permute( float4 x ) { return mod3D289( ( x * 34.0 + 1.0 ) * x ); }
			float4 taylorInvSqrt( float4 r ) { return 1.79284291400159 - r * 0.85373472095314; }
			float snoise( float3 v )
			{
				const float2 C = float2( 1.0 / 6.0, 1.0 / 3.0 );
				float3 i = floor( v + dot( v, C.yyy ) );
				float3 x0 = v - i + dot( i, C.xxx );
				float3 g = step( x0.yzx, x0.xyz );
				float3 l = 1.0 - g;
				float3 i1 = min( g.xyz, l.zxy );
				float3 i2 = max( g.xyz, l.zxy );
				float3 x1 = x0 - i1 + C.xxx;
				float3 x2 = x0 - i2 + C.yyy;
				float3 x3 = x0 - 0.5;
				i = mod3D289( i);
				float4 p = permute( permute( permute( i.z + float4( 0.0, i1.z, i2.z, 1.0 ) ) + i.y + float4( 0.0, i1.y, i2.y, 1.0 ) ) + i.x + float4( 0.0, i1.x, i2.x, 1.0 ) );
				float4 j = p - 49.0 * floor( p / 49.0 );  // mod(p,7*7)
				float4 x_ = floor( j / 7.0 );
				float4 y_ = floor( j - 7.0 * x_ );  // mod(j,N)
				float4 x = ( x_ * 2.0 + 0.5 ) / 7.0 - 1.0;
				float4 y = ( y_ * 2.0 + 0.5 ) / 7.0 - 1.0;
				float4 h = 1.0 - abs( x ) - abs( y );
				float4 b0 = float4( x.xy, y.xy );
				float4 b1 = float4( x.zw, y.zw );
				float4 s0 = floor( b0 ) * 2.0 + 1.0;
				float4 s1 = floor( b1 ) * 2.0 + 1.0;
				float4 sh = -step( h, 0.0 );
				float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
				float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
				float3 g0 = float3( a0.xy, h.x );
				float3 g1 = float3( a0.zw, h.y );
				float3 g2 = float3( a1.xy, h.z );
				float3 g3 = float3( a1.zw, h.w );
				float4 norm = taylorInvSqrt( float4( dot( g0, g0 ), dot( g1, g1 ), dot( g2, g2 ), dot( g3, g3 ) ) );
				g0 *= norm.x;
				g1 *= norm.y;
				g2 *= norm.z;
				g3 *= norm.w;
				float4 m = max( 0.6 - float4( dot( x0, x0 ), dot( x1, x1 ), dot( x2, x2 ), dot( x3, x3 ) ), 0.0 );
				m = m* m;
				m = m* m;
				float4 px = float4( dot( x0, g0 ), dot( x1, g1 ), dot( x2, g2 ), dot( x3, g3 ) );
				return (42.0 * dot( m, px)) ;
			}

half3 TransformnRhToLhSpace(half3 positionOS)
{
    return half3(-positionOS.z, -positionOS.x, positionOS.y);
}
 half3 TransformnLhToRhSpace(half3 positionOS)
{
    return half3(-positionOS.y, positionOS.z, -positionOS.x);
}

void ApplyShadowDissolve(float2 uv, half3 position)
{
#if _DISSOLVE
	DISSOLVE_START(_DISSOLVE_ON)
	//分离阶段
	half firstStageProgress = saturate(XYRemap(_DissProgress, half2(0, _DissFirstStageEnd), half2(0,1)));
	half secondStageProgress = (XYRemap(_DissProgress, half2(_DissSecondStageStart, 1), half2(0,1)));

	//溶解贴图
	half2 noiseuv = uv;//lerp(lightingData.uv, lightingData.fulluv, step(0, _DissNoiseUV));
	half2 noiseUV = lerp(noiseuv, position.xy, step(1,_DissNoiseUV)) * _DissCustomTex_ST.xy + _DissCustomTex_ST.zw + _DissSpeed * _Time.x;
	
	half dissProceNoise = saturate(snoise(position * _DissNoiseScalex) * 0.5 + 0.5);
	half dissCustomTex  = SAMPLE_TEXTURE2D(_DissCustomTex, sampler_DissCustomTex, noiseUV);
	half dissNoise = lerp(dissProceNoise, dissCustomTex, step(1,_DissNoiseSelect)) * 0.99;

	//二阶段clip
	clip(dissNoise - secondStageProgress);
	DISSOLVE_END(_DISSOLVE_ON)
#endif
}

void ApplyTwoStageDissolveFrag(inout half3 color, ToonLightingData lightingData, half3 position, inout half bloom)
{
#if _DISSOLVE
	DISSOLVE_START(_DISSOLVE_ON)
	
    //分离阶段
    half firstStageProgress = saturate(XYRemap(_DissProgress, half2(0, _DissFirstStageEnd), half2(0,1)));
    half secondStageProgress = (XYRemap(_DissProgress, half2(_DissSecondStageStart, 1), half2(0,1)));

    //溶解贴图
	half2 noiseuv = lerp(lightingData.uv.xy, lightingData.uv.zw, step(0, _DissNoiseUV));
    half2 noiseUV = lerp(noiseuv, position.xy, step(1,_DissNoiseUV)) * _DissCustomTex_ST.xy + _DissCustomTex_ST.zw + _DissSpeed * _Time.x;
	
    half dissProceNoise = saturate(snoise(position * _DissNoiseScalex) * 0.5 + 0.5);
	half dissCustomTex  = SAMPLE_TEXTURE2D(_DissCustomTex, sampler_DissCustomTex, noiseUV);
	half dissNoise = lerp(dissProceNoise, dissCustomTex, step(1,_DissNoiseSelect)) * 0.99;

	//一阶段lerp
    half firstStageLerp = step(firstStageProgress, dissNoise);
    
    //一阶段边缘颜色
    half startMask = 1-step(_DissProgress,0);	
    half edgeProgress = XYRemap(_DissProgress, half2(0, _DissFirstStageEnd), half2(0,1));
    //half firstStageDissEdge = step(edgeProgress + _DissEdgeWidthx * startMask, dissNoise);
	half edgeWidth = edgeProgress + _DissEdgeWidthx * startMask;
	half firstStageDissEdge = smoothstep(edgeWidth - _DissEdgeSmooth,  edgeWidth + _DissEdgeSmooth, dissNoise);
	
	//一阶段输出颜色
	half3 edgeColor = lerp(_DissEdgeColor, color, firstStageDissEdge);
    color = lerp(0, edgeColor, firstStageLerp);
	
	//bloom
	half bloomMask = saturate(firstStageLerp - firstStageDissEdge) * startMask;
	bloom += lerp( 0, BloomMaskRGB(_DissEdgeColor, _DissEdgeBloomSten), bloomMask);
	

    //二阶段clip
    clip(dissNoise - secondStageProgress);	
	DISSOLVE_END(_DISSOLVE_ON)
#endif
}


#endif

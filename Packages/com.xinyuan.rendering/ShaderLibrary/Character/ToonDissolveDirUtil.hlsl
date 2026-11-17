#ifndef __ToonDissolveDirModule__
#define __ToonDissolveDirModule__
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/Math.hlsl"
#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/ProceduralNoise.hlsl"

// #if _DISSOLVE && _DISSOLVE_BRANCH
// #define DISSOLVE_ON(dissolve)      half  dissolve
// #define DISSOLVE_START(dissolve) STATIC_BRANCH_START(dissolve)
// #define DISSOLVE_END(dissolve)   STATIC_BRANCH_END(dissolve) 
// #else
// #define DISSOLVE_ON(dissolve)
// #define DISSOLVE_START(dissolve)
// #define DISSOLVE_END(dissolve)
// #endif
#define Y_DISSOLVE_UP half3(0, 1, 0)
#define Z_DISSOLVE_UP half3(0, -1, 0)
#define X_DISSOLVE_UP half3(0, 0, 1)
half GetNormalizeHeight(float3 positionOS, half height, bool invertUp) // Model Space
{
    half normalizeY = saturate((dot(positionOS, Y_DISSOLVE_UP) + height * 0.5) / height);
    return lerp(normalizeY, 1 - normalizeY, invertUp);
}


half GetNormalizeHeight(float3 posWS, float3 povitPosWS, half height, bool inverUp) // World Space
{
    float3 relPos = posWS - povitPosWS;
    half normalizeY = saturate(relPos.y / max(height, 0.01));
    return inverUp ? 1 - normalizeY : normalizeY;
    
}

half GetNormalizeWidth(float3 positionOS, half width, bool invertUp) // World Space
{
    half normalizeY = saturate((dot(positionOS, Z_DISSOLVE_UP) + width * 0.5) / width);
    return lerp(normalizeY, 1 - normalizeY, invertUp);
}

half GetNormalizeLength(float3 positionOS, half length, bool invertUp) // World Space
{
    half normalizeY = saturate((dot(positionOS, X_DISSOLVE_UP) + length * 0.5) / length);
    return lerp(normalizeY, 1 - normalizeY, invertUp);
}
float GetVertexAnimProgress(half dissProgress, half dissDelay, half edgeSmooth, half dissSmooth, half normalizeY)
{
    half halfEdgeSm = edgeSmooth / 2;
    half halfDissSm = dissSmooth / 2;
    float progress = XYRemap(1-dissProgress, float2(0,1), float2(-halfEdgeSm - dissDelay, 1 + halfEdgeSm));
    progress += dissDelay;
    progress = smoothstep(progress - halfDissSm, progress + halfDissSm, normalizeY);
    
    return progress;
}   

half GetEdgeDissolveProgress(half dissProgress, half dissDelay, half edgeSmooth, half normalizeY)
{
    half halfEdgeSm = edgeSmooth / 2;
    float progress = XYRemap(1-dissProgress, float2(0,1), float2(-halfEdgeSm - dissDelay, 1 + halfEdgeSm));
    progress = smoothstep(progress - halfEdgeSm, progress + halfEdgeSm, normalizeY);
    
    return progress;
}

half GetDissolveValue(float2 uv, float noiseScale)
{
    return SimpleNoise(uv, noiseScale);
}


half GetDissolveClipValue(half dissProgress, half edgePhaseClip,  half edgeSmooth, float dissDelay, half dissSmooth, float normalizeY)
{
    half animProgress = GetVertexAnimProgress(dissProgress, dissDelay, edgeSmooth, dissSmooth, normalizeY);
    half edgeProgress = GetEdgeDissolveProgress(dissProgress, dissDelay, edgeSmooth, normalizeY);
    edgeProgress = XYRemap(edgeProgress, float2(0,1), float2(0, edgePhaseClip));
    
    return edgeProgress + animProgress;
}


float3 DoHeightDissolveVertexAnim(float3 position, float3 normal, half normalAnimStren, half animSpeed, bool invertUp, half dissVal, half clipVal, half vertAnimProgress) 
{
    half3 upDir = lerp(Y_DISSOLVE_UP, -1 * Y_DISSOLVE_UP, invertUp);
    half3 animDir = normalize(upDir + normal * normalAnimStren);
    half dissDetalNor = 1 -  saturate((dissVal - clipVal) / max(dissVal, 0.01h));

    return position + animDir * animSpeed * dissDetalNor * vertAnimProgress;
}

float3 DoWidthDissolveVertexAnim(float3 position, float3 normal, half normalAnimStren, half animSpeed, bool invertUp, half dissVal, half clipVal, half vertAnimProgress) 
{
    half3 upDir = lerp(Z_DISSOLVE_UP, -1 * Z_DISSOLVE_UP, invertUp);
    half3 animDir = normalize(upDir + normal * normalAnimStren);
    half dissDetalNor = 1 -  saturate((dissVal - clipVal) / max(dissVal, 0.01h));
    return position + animDir * animSpeed * dissDetalNor * vertAnimProgress;
}
float3 DoLengthDissolveVertexAnim(float3 position, float3 normal, half normalAnimStren, half animSpeed, bool invertUp, half dissVal, half clipVal, half vertAnimProgress) 
{
    half3 upDir = lerp(X_DISSOLVE_UP, -1 * X_DISSOLVE_UP, invertUp);
    half3 animDir = normalize(upDir + normal * normalAnimStren);
    half dissDetalNor = 1 -  saturate((dissVal - clipVal) / max(dissVal, 0.01h));

    return position + animDir * animSpeed * dissDetalNor * vertAnimProgress;
}
void DoHeightDissolveFragmentClip(half dissProgress, half dissVal, half dissDelay, half dissSmooth,  half edgePhaseClip,  half edgeSmooth, half normalizeY)
{
    half clipVal = GetDissolveClipValue(dissProgress, edgePhaseClip, edgeSmooth, dissDelay, dissSmooth, normalizeY);
    clip(dissVal - clipVal);
}


//方向渐变
half GetDirOSGradient(half dirSwitch,half3 positionOS, half offset, half width, half smooth, half invert, half noise)
{
    half positionValue = 0;
	if(dirSwitch == 1)
		positionValue = -positionOS.x;
    if(dirSwitch == 2)
        positionValue = -positionOS.y;
    if(dirSwitch == 3)
        positionValue = -positionOS.z;
    
	positionValue = lerp(positionValue, -positionValue, invert);
    half gradient = saturate((positionValue - offset) / width);
    half gradientPow = saturate(pow(gradient, smooth));
    
    half gradientNoise = frac(1-frac(gradientPow)) * noise;
    return saturate(gradientPow - gradientNoise);
}
//边缘溶解
half GetNonDirEdgeMask(half edgeWidth, half edgeSmooth, half noiseAlpha)
{
    half alpha = 1-saturate(noiseAlpha - edgeWidth);
    return alpha;
}
            
half3 GetNoiseUVScaleOffset(half3 position, half scale, half offsetSpeed, half dirSwitch, half invert)
{
    half3 noiseUV = position;
    half speed = lerp(-offsetSpeed, offsetSpeed, invert);
    //return noiseUV;
    if(dirSwitch == 1)
    {
        noiseUV.y *= scale;
        noiseUV.y  += speed * _TimeParameters.x;
    }
    if(dirSwitch == 2 || dirSwitch == 0)
    {
        noiseUV.x *= scale; 
        noiseUV.x  += speed * _TimeParameters.x;
    }
    if(dirSwitch == 3)
    {
         noiseUV.y *= scale;
         noiseUV.y  += speed * _TimeParameters.x;
    }
    return noiseUV;
}

half3 GetNoiseUVScaleOffset2(half3 position, half scale, half offsetSpeed, half dirSwitch, half invert)
{
    half3 noiseUV = position * scale;
    half speed = lerp(-offsetSpeed, offsetSpeed, invert);

    //return noiseUV;	
    if(dirSwitch == 1)
    {
        noiseUV.x  += speed * _TimeParameters.x;
    }
	if(dirSwitch == 2 || dirSwitch == 0)
    {
        noiseUV.y  += speed * _TimeParameters.x;
    }
    if(dirSwitch == 3)
    {
         noiseUV.z  += speed * _TimeParameters.x;
    }
    return noiseUV;
}

void ApplyVertAnimDir(half dirSwitch, half invert, inout half3 position, half vertAnimStren)
{
    if(dirSwitch == 1)
    {
        position.x += lerp(-vertAnimStren, vertAnimStren, invert);
         //return position;
    }
         
    if(dirSwitch == 2 || dirSwitch == 0)
    {
        position.y += lerp(vertAnimStren, -vertAnimStren, invert);
         //return position;
    }
    if(dirSwitch == 3)		
    {
        position.z += lerp(-vertAnimStren, vertAnimStren, invert);
         //return position;
    }
}

void ApplyDissolveVertex(inout Attributes attrubute, half3 positionWSPovotPosSpace, half3 normalWS, half3 positionOS, half3 positionWS)
{
    //noise
    half3 noiseUV1 = GetNoiseUVScaleOffset(positionWSPovotPosSpace, _DissNoiseScale1 * 5, _DissSpeed1, _DissDirect, _DissDirectInvert);
    half3 noiseUV2 = GetNoiseUVScaleOffset2(positionWSPovotPosSpace, _DissNoiseScale2 * 10, _DissSpeed2, _DissDirect, _DissDirectInvert);
    half noise1 = saturate((snoise(noiseUV1) *0.5 + 0.5) );
    half noise2 = saturate((snoise(noiseUV2) *0.5 + 0.5) );
    half noise = saturate(noise1 * noise2 * 1.5);

    //progress
    half dissProgress = XYRemap(_DissDirProgress, half2(0,1), half2(-1-_DissClipRemapMin, _DissClipRemapMax));
				
    //dirmask
    half dirGradientAnim = 1-GetDirOSGradient(_DissDirect, positionWSPovotPosSpace, dissProgress , _DissClipWidth - _DissAnimDelay,_DissAnimPow, _DissDirectInvert, noise1);
    dirGradientAnim *= (1-step(_DissDirProgress, 0));

    //nonDirMask
    half nonDirAnimMask = saturate(XYRemap(_DissDirProgress, half2(_DissAnimDelay,1), half2(0, 1)));
    
    half3 normalOS = TransformObjectToWorldNormal(attrubute.normalOS);
    half3 nonDirAnimValue = normalize(normalOS) * _DissAnimNormalStren  + half3(0, _DissAnimStren * 5, 0);


    half3 normalAnimValue = normalize(normalWS) * _DissAnimNormalStren * noise;
    half stepDir = step( _DissDirect,0);
    half dissAnim = lerp(nonDirAnimValue, _DissAnimStren * noise, 1-stepDir);

    if(stepDir)
    {
        //positionOS += nonDirAnimValue * nonDirAnimMask * noise;
        //positionWS += nonDirAnimValue * nonDirAnimMask * noise;
        //positionOS = TransformnLhToRhSpace(positionOS);
        positionOS = TransformWorldToObject(positionWS);    
    }
    else
    {
        ApplyVertAnimDir(_DissDirect, _DissDirectInvert,  positionOS, _DissAnimStren * dirGradientAnim);
        positionOS.xyz += normalAnimValue * dirGradientAnim;
        positionOS = TransformnLhToRhSpace(positionOS);
    }
   
    attrubute.positionOS.xyz = positionOS;
}

void ApplyDissolveFragment(inout half3 color, half3 positionWSPovotPosSpace)
{
    DISSOLVE_START(_DISSOLVE_ON)
    half3 noiseUV1 = GetNoiseUVScaleOffset(positionWSPovotPosSpace, _DissNoiseScale1, _DissSpeed1, _DissDirect, _DissDirectInvert);
    half3 noiseUV2 = GetNoiseUVScaleOffset2(positionWSPovotPosSpace, _DissNoiseScale2, _DissSpeed2, _DissDirect, _DissDirectInvert);
    half noise1 = saturate((snoise(noiseUV1) *0.5 + 0.5)  );
    half noise2 = saturate((snoise(noiseUV2) *0.5 + 0.5)  );
    half noise = saturate(noise1 * noise2 * 2);
    //dir
    half dissProgress = XYRemap(_DissDirProgress, half2(0,1), half2(-1-_DissClipRemapMin, _DissClipRemapMax));
    half dirGradient = GetDirOSGradient(_DissDirect, positionWSPovotPosSpace, dissProgress, _DissClipWidth, 1.5, _DissDirectInvert, noise);
    half stepProgress = (1-step(_DissDirProgress, 0));
    half dirGradientEdge = 1-GetDirOSGradient(_DissDirect, positionWSPovotPosSpace, dissProgress , _DissClipWidth,1, _DissDirectInvert,noise1);
    dirGradientEdge = pow(smoothstep(0.1, 1.5, dirGradientEdge),2) * stepProgress;    

    //nonDir    
    //half dissprogress =step(_DissDirProgress, 0.7);
    //half diss = saturate(XYRemap(_DissDirProgress, half2(0.6,1), half2(0,1)));
    half nonDirClipMask = saturate(noise - _DissDirProgress);
    //half dissEdge = XYRemap(_DissEdgeWidth, half2(0,1), half2(1,0));
    half nonDirEdge = smoothstep(0.9, 0.98, 1-(saturate(noise - _DissDirProgress))) * stepProgress;// + (diss * 0.5);//GetNonDirEdgeMask(_DissEdgeWidth, _DissEdgePow, noise) * stepProgress;
    //nonDirEdge = smoothstep(0.8, 1, nonDirEdge);  
    //color = nonDirEdge;
    // color = smoothstep(0.8, 1, 1-(saturate(noise - _DissEdgeWidth)));
    half stepDir = step( _DissDirect,0);
    half clipMask = saturate(lerp( dirGradient, nonDirClipMask, stepDir));
    half edgeMask = saturate(lerp( dirGradientEdge, nonDirEdge, stepDir));
        	
    clip(clipMask - 0.01);  
    
    color = lerp(color, _DissDirEdgeColor, edgeMask);
    DISSOLVE_END(_DISSOLVE_ON)
}



#endif

#ifndef SHADER_LIBRARY_PROCEDURAL_NOISE_HELPER_INCLUDED
#define SHADER_LIBRARY_PROCEDURAL_NOISE_HELPER_INCLUDED

#include "Packages/com.xinyuan.rendering/ShaderLibrary/Utilities/ProceduralNoise.hlsl"

/* C# definition
public enum NoiseType
{
    Texture,
    Simple,
    Gradient,
    Voroni,
}

*/

inline bool ProceduralNoiseHelper_IsProceduralNoise(real noiseType)
{
    return noiseType > 0;
}


real ProceduralNoiseHelper_GenerateNoise(real noiseType, real2 uv, real noiseScale, real angleOffset, real cellDensity)
{
    real noise = 0;
    if ((uint)noiseType == 1) // simple noise
    {
        noise = SimpleNoise(uv, noiseScale);
    }
    else if ((uint)noiseType == 2) // gradient noise
    {
        noise = GradientNoise(uv, noiseScale);
    }
    else if ((uint)noiseType == 3) // voroni noise
    {
        real cell = 0;
        VoronoiNoise(uv, angleOffset, cellDensity, noise, cell);
    }
    
    return noise;
} 



#endif
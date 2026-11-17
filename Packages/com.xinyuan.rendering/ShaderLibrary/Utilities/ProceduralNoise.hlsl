#ifndef _SHADER_LIBRARY_UTILITIES_PROCEDURAL_NOISE_INCLUDE
#define _SHADER_LIBRARY_UTILITIES_PROCEDURAL_NOISE_INCLUDE


//
// Simple Noise
//

inline real SimpleNoise_RandomValue(real2 uv)
{
    return frac(sin(dot(uv, real2(12.9898, 78.233)))*43758.5453);
}

inline real SimpleNoise_ValueNoise(real2 uv)
{
    real2 i = floor(uv);
    real2 f = frac(uv);
    f = f * f * (3.0 - 2.0 * f);

    uv = abs(frac(uv) - 0.5);
    real2 c0 = i + real2(0.0, 0.0);
    real2 c1 = i + real2(1.0, 0.0);
    real2 c2 = i + real2(0.0, 1.0);
    real2 c3 = i + real2(1.0, 1.0);
    real r0 = SimpleNoise_RandomValue(c0);
    real r1 = SimpleNoise_RandomValue(c1);
    real r2 = SimpleNoise_RandomValue(c2);
    real r3 = SimpleNoise_RandomValue(c3);

    real bottomOfGrid = lerp(r0, r1, f.x);
    real topOfGrid = lerp(r2, r3, f.x);
    real t = lerp(bottomOfGrid, topOfGrid, f.y);
   
     return t;
}


real SimpleNoise(real2 UV, real Scale)
{
    real t = 0.0;

    real freq = pow(2.0, real(0));
    real amp = pow(0.5, real(3-0));
    t += SimpleNoise_ValueNoise(real2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

    freq = pow(2.0, real(1));
    amp = pow(0.5, real(3-1));
    t += SimpleNoise_ValueNoise(real2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

    freq = pow(2.0, real(2));
    amp = pow(0.5, real(3-2));
    t += SimpleNoise_ValueNoise(real2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

    return t;
}


//
// Gradient Noise
//

inline float2 GradientNoise_Dir(float2 p)
{
    // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
    p = p % 289;
    // need full precision, otherwise half overflows when p > 1
    float x = float(34 * p.x + 1) * p.x % 289 + p.y;
    x = (34 * x + 1) * x % 289;
    x = frac(x / 41) * 2 - 1;
    return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
}


float GradientNoise(float2 UV, float Scale)
{
    // p需要全精度 否则噪声会不连续
    float2 p = UV * Scale;
    float2 ip = floor(p);
    float2 fp = frac(p);
    half d00 = dot(GradientNoise_Dir(ip), fp);
    half d01 = dot(GradientNoise_Dir(ip + real2(0, 1)), fp - real2(0, 1));
    half d10 = dot(GradientNoise_Dir(ip + real2(1, 0)), fp - real2(1, 0));
    half d11 = dot(GradientNoise_Dir(ip + real2(1, 1)), fp - real2(1, 1));
    fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
    real result = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;

    return result;
}


//
// Voronoi Noise
//

inline real2 Voronoi_RandomVector(real2 UV, real offset)
{
    real2x2 m = real2x2(15.27, 47.63, 99.41, 89.98);
    UV = frac(sin(mul(UV, m)));
    return real2(sin(UV.y*+offset)*0.5+0.5, cos(UV.x*offset)*0.5+0.5);
}

void VoronoiNoise(real2 UV, real AngleOffset, real CellDensity, out real Out, out real Cells)
{
    real2 g = floor(UV * CellDensity);
    real2 f = frac(UV * CellDensity);
    real t = 8.0;
    real3 res = real3(8.0, 0.0, 0.0);

    for(int y=-1; y<=1; y++)
    {
        for(int x=-1; x<=1; x++)
        {
            real2 lattice = real2(x,y);
            real2 offset = Voronoi_RandomVector(lattice + g, AngleOffset);
            real d = distance(lattice + offset, f);

            if(d < res.x)
            {
                res = real3(d, offset.x, offset.y);
                Out = res.x;
                Cells = res.y;
            }
        }
    }
}

#endif
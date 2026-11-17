#ifndef _SHADER_LIBRARY_DitherFadeoutClipUtil
#define _SHADER_LIBRARY_DitherFadeoutClipUtil


static const half DITHER_THRESHOLDS[16] =
{
    1.0h / 17.0h,  9.0h / 17.0h,  3.0h / 17.0h, 11.0h / 17.0h,
    13.0h / 17.0h,  5.0h / 17.0h, 15.0h / 17.0h,  7.0h / 17.0h,
    4.0h / 17.0h, 12.0h / 17.0h,  2.0h / 17.0h, 10.0h / 17.0h,
    16.0h / 17.0h,  8.0h / 17.0h, 14.0h / 17.0h,  6.0h / 17.0h
};

void DoDitherFadeoutClip(float2 SV_POSITIONxy, half ditherOpacity)
{
    // copy from https://docs.unity3d.com/Packages/com.unity.shadergraph@10.3/manual/Dither-Node.html?q=dither
    
    uint index = (uint(SV_POSITIONxy.x) % 4) * 4 + uint(SV_POSITIONxy.y) % 4;
    clip(ditherOpacity - DITHER_THRESHOLDS[index]);
}

#endif


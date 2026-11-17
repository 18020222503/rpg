
#ifndef VERTEXDECODE_INCLUDED
#define VERTEXDECODE_INCLUDED


//  用于解压压缩成 qTangent的法线和切线
//QTangent解压方法

// 两个方法公用的
#define _wz fyOne.y
#define _zz fyTwo.y


// QTangentToTangent 
#define _wx fyOne.x
#define _xx fyOne.z
#define _zy fyOne.w
#define _yz fyTwo.x

// QTangentToNormal
#define _wy fyOne.x
#define _xy fyOne.z
#define _xz fyOne.w
#define _yy fyTwo.x




// 通过qTangent 将 normal和Tangent压缩到 half4中
// https://zhuanlan.zhihu.com/p/376264983
float3 qTangentToNormal(float4 qTangent)
{
    float3 _xyz = float3(0, 2.0 * qTangent.yz);

    float4 fyOne = _xyz.yzyz * qTangent.wwxx;
    float2 fyTwo = _xyz.yz * qTangent.yz;
    return float3(1.0 - (_yy + _zz),_xy + _wz,_xz - _wy);
}

float3 qTangentToTangent(float4 qTangent)
{
    float3 _xyz = 2.0f * qTangent.xyz;

    float4 fyOne = _xyz.xzxy * qTangent.wwxx;
    float2 fyTwo = _xyz.zz * qTangent.yz;
    return float3(_xy - _wz, 1.0 - (_xx + _zz),_yz + _wx);
}



#endif

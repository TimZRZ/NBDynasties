﻿#ifndef WATER_UTILITIES
#define WATER_UTILITIES

#define PI (3.1415926536)

// Pans the input uv in the given direction and speed.
float2 Panner(float2 uv, float2 direction, float speed)
{
    return uv + normalize(direction)*speed*_Time.y;
}

float3 MotionFourWayChaos(sampler2D tex, float2 uv, float speed, bool unpackNormal)
{
	float2 uv1 = Panner(uv + float2(0.000, 0.000), float2( 0.1,  0.1), speed);
	float2 uv2 = Panner(uv + float2(0.418, 0.355), float2(-0.1, -0.1), speed);
	float2 uv3 = Panner(uv + float2(0.865, 0.148), float2(-0.1,  0.1), speed);
	float2 uv4 = Panner(uv + float2(0.651, 0.752), float2( 0.1, -0.1), speed);

	float3 sample1;
	float3 sample2;
	float3 sample3;
	float3 sample4;

	if (unpackNormal)
	{
		sample1 = UnpackNormal(tex2D(tex, uv1)).rgb;
		sample2 = UnpackNormal(tex2D(tex, uv2)).rgb;
		sample3 = UnpackNormal(tex2D(tex, uv3)).rgb;
		sample4 = UnpackNormal(tex2D(tex, uv4)).rgb;

		return normalize(sample1 + sample2 + sample3 + sample4);
	}
	else
	{
		sample1 = tex2D(tex, uv1).rgb;
		sample2 = tex2D(tex, uv2).rgb;
		sample3 = tex2D(tex, uv3).rgb;
		sample4 = tex2D(tex, uv4).rgb;

		return (sample1 + sample2 + sample3 + sample4) / 4.0;
	}
}

#endif  // WATER_UTILITIES
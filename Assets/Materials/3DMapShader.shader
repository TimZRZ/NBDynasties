// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/3DMapShader"
{
    Properties
	{
		_MainTex("Texture", 2D) = "white"{}
		_RemapTex ("Texture", 2D) = "white" {}
        _PaletteTex ("Texture", 2D) = "white" {}
		_HeightMapTex ("Height Map", 2D) = "white" {}
		_TerrainMapTex ("Terrain Map", 2D) = "white" {}
		_NormalMap("Normal Map", 2D) = "bump" {}
		_Color("Main Color", Color) = (1, 1, 1, 1)
		_SeaColor("Sea Color", Color) = (1, 1, 1, 1)
		_RiverColor("River Color", Color) = (1, 1, 1, 1)

		[Header(Waves)]
        _ShallowWaterColor ("Shallow Color", Color) = (0.44, 0.95, 0.36, 1.0)
		_DeepWaterColor ("Deep Color", Color) = (0.0, 0.05, 0.19, 1.0)
		_FarWaterColor ("Far Color", Color) = (0.04, 0.27, 0.75, 1.0)
		_WaterDepthDensity ("Water Depth", Range(0.0, 1.0)) = 0.5
		_DistanceDensity ("Distance", Range(0.0, 1.0)) = 0.01
		// Foam
		_FoamContribution ("Contribution", Range(0.0, 1.0)) = 1.0
		[NoScaleOffset]
		_FoamTexture ("Texture", 2D) = "black"{}
        _FoamScale ("Scale", float) = 1.0
        _FoamSpeed ("Speed", float) = 1.0
        _FoamNoiseScale ("Noise Contribution", Range(0.0, 1.0)) = 0.5
		// Normal
		[NoScaleOffset]
		_WaveNormalMap ("Wave Normal Map", 2D) = "bump"{}
        _WaveNormalScale ("Wave Normal Scale", float) = 10.0
        _WaveNormalSpeed ("Wave Normal sSpeed", float) = 1.0
	}


    SubShader
    {
		Tags{ "RenderType" = "Opaque" }
		Tags{ "LightingMode" = "ForwardBase" }
		LOD 200

		GrabPass
        {
            "_GrabTexture"
        }

		Pass
		{
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#pragma glsl

			#include "UnityCG.cginc"
			#include "WaterUtilities.cginc"

			// Struct for Vertex
			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float3 tangent : TANGENT;
				float2 uv : TEXCOORD0;
			};

			// Struct for Pixel
			struct v2f
			{
				float4 position : SV_POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;

				float3 T : TEXCOORD1;
				float3 B : TEXCOORD2;
				float3 N : TEXCOORD3;

				float3 worldPosition : TEXCOORD4;
				float4 grabPosition : TEXCOORD5;
			};

			//------
			// VARS
			//------
			float4 _LightColor0;
			float4 _Color;
			float4 _SeaColor;
			float4 _RiverColor;
			sampler2D _MainTex;
			sampler2D _RemapTex;
            sampler2D _PaletteTex;
			sampler2D _HeightMapTex;
			sampler2D _TerrainMapTex;
			sampler2D _NormalMap;
			int _ShowTerrain;

			// Depth and color buffers.
            sampler2D _GrabTexture;
            sampler2D _CameraDepthTexture;

			// Water Related Variable
			float _WaterDepthDensity;
			float _DistanceDensity;
			float3 _ShallowWaterColor;
			float3 _DeepWaterColor;
			float3 _FarWaterColor;
			// Foam.
            sampler2D _FoamTexture;
            float _FoamScale;
            float _FoamNoiseScale;
            float _FoamSpeed;
            float _FoamContribution;
			// Wave Normal Map.
            sampler2D _WaveNormalMap;
            float _WaveNormalScale;
            float _WaveNormalSpeed;

			//------
			// VERT
			//------
			v2f vert(appdata input)
			{
				v2f output;

				fixed4 col = tex2Dlod(_HeightMapTex, float4(input.uv.xy,0,0));
				input.vertex.z -= col.b * 10;

				// Project from 3D space to 2D screen
				output.position = UnityObjectToClipPos(input.vertex);

				// Output UV is the same as input
				output.uv = input.uv;

				// Get normal in world space
				output.normal = mul(float4(input.normal, 0.0), unity_WorldToObject).xyz;

				float3 worldNormal = mul((float3x3)unity_ObjectToWorld, input.normal);
				float3 worldTangent = mul((float3x3)unity_ObjectToWorld, input.tangent);
				
				float3 binormal = cross(input.normal, input.tangent.xyz); // *input.tangent.w;
				float3 worldBinormal = mul((float3x3)unity_ObjectToWorld, binormal);

				output.N = normalize(worldNormal);
				output.T = normalize(worldTangent);
				output.B = normalize(worldBinormal);

				// For Water Effect
				output.worldPosition = mul(unity_ObjectToWorld, input.vertex).xyz;
				output.grabPosition = ComputeGrabScreenPos(output.position);

				return output;
			}

			//-----
			// FRAG
			//-----
			fixed4 frag(v2f input) : COLOR
			{
				// sample the texture
                fixed4 col = tex2D(_MainTex, input.uv);

                fixed4 c1 = tex2D(_MainTex, input.uv + float2(0.0005, 0));
                fixed4 c2 = tex2D(_MainTex, input.uv - float2(0.0005, 0));
                fixed4 c3 = tex2D(_MainTex, input.uv + float2(0, 0.0005));
                fixed4 c4 = tex2D(_MainTex, input.uv - float2(0, 0.0005));

				float diffRiver =
					min(distance(_RiverColor, col),
						min(distance(_RiverColor, c1),
							min(distance(_RiverColor, c2),
								min(distance(_RiverColor, c3), distance(_RiverColor, c4)))));

				float diffSea =
					min(distance(_SeaColor, col),
						min(distance(_SeaColor, c1),
							min(distance(_SeaColor, c2),
								min(distance(_SeaColor, c3), distance(_SeaColor, c4)))));

                if (diffRiver > 0.01 &&  diffSea > 0.01 && (any(c1 != col) || any(c2 != col) || any(c3 != col) || any(c4 != col)))
                {
                    return fixed4(0, 0, 0, 1);
                }

				if (diffSea < 0.01 || diffRiver < 0.01)
				{
					float2 screenCoord = input.grabPosition.xy / input.grabPosition.w;

					// Sample the grab-pass and depth textures based on the screen coordinate
					// to get the frag color and depth of the fragment behind this one.
					float3 fragColor = tex2D(_GrabTexture, screenCoord.xy).rgb;
					float fragDepth = tex2D(_CameraDepthTexture, screenCoord.xy).x;

					// Calculate the distance the viewing ray travels underwater,
					// as well as the transmittance for that distance.
					float opticalDepth = abs(LinearEyeDepth(fragDepth) - LinearEyeDepth(input.position.z));
					float transmittance = exp(-_WaterDepthDensity * opticalDepth);

					// Also calculate how far away the fragment is from the camera.
					float distanceMask = exp(-_DistanceDensity * length(input.worldPosition - _WorldSpaceCameraPos));

					float3 baseWaterColor = fragColor * _ShallowWaterColor;
					baseWaterColor = lerp(_DeepWaterColor, baseWaterColor, transmittance);
					baseWaterColor = lerp(_FarWaterColor, baseWaterColor, distanceMask);

					// ----------
					// FOAM COLOR
					// ----------

					// Distort the world space uv coordinates by the normal map.
					float2 foamUV = (input.worldPosition.xy / _FoamScale);

					// Sample the foam texture and modulate the result by the distance mask and shadow mask.
					float3 foamColor = MotionFourWayChaos(_FoamTexture, foamUV, _FoamSpeed, false);
					foamColor = foamColor * distanceMask;
					foamColor = foamColor * _FoamContribution;

					return float4(baseWaterColor + foamColor, 1);
				}

				fixed4 index = tex2D(_RemapTex, input.uv);
				fixed4 terrainColor = tex2D(_TerrainMapTex, input.uv);
				float4 texColor = tex2D(_PaletteTex, index.xy * 255.0 / 256.0);

				if (_ShowTerrain)
				{
					if (all(texColor == float4(1, 1, 1, 1)))
					{
						texColor = tex2D(_PaletteTex, index.xy * 255.0 / 256.0) * 0.1 + terrainColor;
					}
					else
					{
						texColor = tex2D(_PaletteTex, index.xy * 255.0 / 256.0) * 0.5 + terrainColor;
					}	
				}

				// Calculate normal
				float3 tangentNormal = tex2D(_NormalMap, input.uv).xyz;
				tangentNormal = normalize(tangentNormal * 2 - 1);
				float3x3 TBN = float3x3(normalize(input.T), normalize(input.B), normalize(input.N));
				TBN = transpose(TBN);
				float3 worldNormal = mul(TBN, tangentNormal);

				float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);

				// Diffuse = LightColor * MainColor * max(0,dot(N,L))
				float3 diffuse = _LightColor0.rgb * _Color.rgb * max(0.0, dot(worldNormal, lightDirection));

				float4 DiffuseAmbient = float4(diffuse, 1.0) + UNITY_LIGHTMODEL_AMBIENT;

				return DiffuseAmbient* texColor;
			}

			ENDCG
		}
    }
}

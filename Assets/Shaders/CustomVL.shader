Shader "Unlit/CustomVL"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		CGINCLUDE

		#include "UnityCG.cginc"
		#include "UnityDeferredLibrary.cginc"

		struct appdata
		{
			float4 vertex : POSITION;
		};

		struct v2f
		{
			float4 vertex : SV_POSITION;
			float4 screenPos : TEXCOORD0;
			float4 worldPos : TEXCOORD1;
		};

		float4x4 _WorldViewProj;
		float4 _VLightParams;
		float4 _VLightPos;
		float4 _CameraForward;

		float4 _Params;
		float4 _MieG;

		float4 _VolumetricLight;

		sampler2D _DitherTexture;

		float MieScattering(float cosAngle, float4 g)
		{
            return g.w * (g.x / (pow(g.y - g.z * cosAngle, 1.5)));			
		}

		fixed3 RayMarch(float2 screenPos, float3 rayStart, float3 rayDir, float rayLength)
		{
			float2 interleavedPos = (fmod(floor(screenPos.xy), 4.0));
			float offset = tex2D(_DitherTexture, interleavedPos / 4.0 + float2(0.5 / 4.0, 0.5 / 4.0)).w;

			int sampleCount = _Params.x;
			
			float stepSize = rayLength / sampleCount;
			float3 step = rayDir * stepSize;

			float3 curPos = rayStart + offset * step;

			float lightSum = 0;

			curPos += step * 2;

			for(int i = 0; i < sampleCount; i++)
			{
				float3 toLight = _VLightPos - curPos;
				float3 toLightDir = normalize(toLight);
				
				float atten = 1 - dot(toLight, toLight) * _VLightParams.z;
				
				float density = UnityDeferredComputeShadow(-toLight, 0, float2(0, 0));

				float cosAngle = dot(toLightDir, rayDir);

				float light = atten * density * stepSize * MieScattering(cosAngle, _MieG) * _Params.y;

				lightSum += light;

				curPos += step;
			}

			return lightSum;
		}

		float GetLightAttenuation_1(float3 wpos)
		{
			float atten = 0;
			float3 tolight = wpos - _VLightPos.xyz;
			half3 lightDir = -normalize(tolight);

			return UnityDeferredComputeShadow(tolight, 0, float2(0, 0));
		}

		v2f vert (appdata v)
		{
			v2f o;
			o.vertex = mul(_WorldViewProj, v.vertex);
			o.worldPos = mul(unity_ObjectToWorld, v.vertex);
			o.screenPos = ComputeScreenPos(o.vertex);
			return o;
		}

		ENDCG

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#pragma shader_feature SHADOWS_CUBE
			#pragma shader_feature POINT

						
			fixed4 frag (v2f i) : SV_Target
			{
				float3 rayStart = _WorldSpaceCameraPos.xyz;
				float3 rayEnd = i.worldPos.xyz;

				float3 rayDir = normalize(rayEnd - rayStart);
				
				float3 toLight = _VLightPos.xyz - _WorldSpaceCameraPos.xyz;
				
				float projectLight = dot(toLight, rayDir);

				float d = sqrt(_VLightParams.y + projectLight * projectLight - dot(toLight, toLight));
				
				float start = projectLight - d;
				float end = projectLight + d;

				rayStart = rayStart + start * rayDir;

				float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.screenPos.xy / i.screenPos.w);
				float linearDepth = LinearEyeDepth(depth);
				float projectedDepth = linearDepth / dot(_CameraForward, rayDir);
				float rayLength = min(end, projectedDepth) - start;

				// float3 vtoLight = rayStart - _VLightPos;
				return fixed4(RayMarch(i.vertex.xy, rayStart, rayDir, rayLength), 1);

			}
			ENDCG
		}
	}
}

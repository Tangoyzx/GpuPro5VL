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

		sampler2D _MainTex;
		sampler2D _FallOffTex;

		float4 _VLightParams;
		float4 _MieG;
		float4 _VLightPos;
		float3 _CameraForward;
		fixed4 _VLightColor;

		float GetAtten(float3 worldPos) {
			float3 toLight = _VLightPos - worldPos;
			float atten = dot(toLight, toLight) * _VLightParams.z;
			atten *= tex2D(_FallOffTex, atten.rr).r;
			return atten;
		}

		float MieScattering(float cosAngle, float4 g) {
			return g.w * (g.x / pow(g.y - g.z * cosAngle, 1.5));
		}

		inline fixed4 RayMarch(float3 rayStart, float3 rayDir, float rayLength)
		{
			int stepCount = _VLightParams.w;

			float stepSize = rayLength / stepCount;
			float3 step = rayDir * stepSize;

			float3 curPos = rayStart;

			float lightSum = 0;
			for(int i = 1; i < stepCount; i++)
			{
				float atten = GetAtten(curPos);
				lightSum += stepSize * atten * 0.5;
				curPos += step;
			}

			return _VLightColor * lightSum;
		}

		ENDCG

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.screenPos = ComputeScreenPos(o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float3 rayStart = _WorldSpaceCameraPos.xyz;
				float3 rayEnd = i.worldPos.xyz;

				float3 rayDir = normalize(rayEnd - rayStart);
				
				
				float3 toLight = _VLightPos - _WorldSpaceCameraPos.xyz;
				
				float projectLight = dot(toLight, rayDir);

				float d = sqrt(_VLightParams.y + projectLight * projectLight - dot(toLight, toLight));
				
				float start = projectLight - d;
				float end = projectLight + d;

				rayStart = rayStart + start * rayDir;
				float rayLength = end - start;


				float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.screenPos.xy / i.screenPos.w);
				float linearDepth = LinearEyeDepth(depth);
				float projectedDepth = linearDepth / dot(_CameraForward, rayDir);
				rayLength = min(end, projectedDepth);
				// return fixed4(debugUV, 0, 1);
				

				// return RayMarch(rayStart, rayDir, rayLength);

			}
			ENDCG
		}
	}
}

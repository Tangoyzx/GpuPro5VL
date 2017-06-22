Shader "Hidden/CustomBlur"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		CGINCLUDE

		static const half GaussWeight[7] = {0.0205, 0.0855, 0.232, 0.324, 0.232, 0.0855, 0.0205};
		sampler2D _MainTex;
		float4 _MainTex_TexelSize;

		fixed4 GaussianBlur(float2 uv, float2 dir)
		{
			fixed4 totalColor = fixed4(0, 0, 0, 0);
			for(int i = 0; i < 7; i++)
			{
				float weight = GaussWeight[i];
				float2 sampleUV = uv + dir * (i - 3) * _MainTex_TexelSize.xy;
				totalColor += tex2D(_MainTex, sampleUV) * weight;
			}
			return totalColor;
		}

		#include "UnityCG.cginc"

		struct appdata
		{
			float4 vertex : POSITION;
			float2 uv : TEXCOORD0;
		};

		struct v2f
		{
			float2 uv : TEXCOORD0;
			float4 vertex : SV_POSITION;
		};

		v2f vert (appdata v)
		{
			v2f o;
			o.vertex = UnityObjectToClipPos(v.vertex);
			o.uv = v.uv;
			return o;
		}

		ENDCG

		// Pass 0, Horizontal
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			fixed4 frag (v2f i) : SV_Target
			{
				return GaussianBlur(i.uv, float2(1, 0));
			}
			ENDCG
		}

		// Pass 1, Vertical
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			fixed4 frag (v2f i) : SV_Target
			{
				return GaussianBlur(i.uv, float2(0, 1));
			}
			ENDCG
		}
	}
}

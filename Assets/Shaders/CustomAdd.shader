Shader "Hidden/CustomAdd"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
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
			
			sampler2D _MainTex;
			sampler2D _SecTex;

			fixed4 frag (v2f i) : SV_Target
			{
				// return fixed4(i.uv, 0, 1);
				// return tex2D(_SecTex, i.uv);
				// return tex2D(_MainTex, i.uv);
				return tex2D(_MainTex, i.uv) + tex2D(_SecTex, i.uv);
			}
			ENDCG
		}
	}
}

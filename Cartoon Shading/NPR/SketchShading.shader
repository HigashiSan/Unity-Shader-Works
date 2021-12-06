// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/SketchShading"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
		_TileFactor ("Tile Factor", Float) = 1
		_Outline ("Outline", Range(0, 1)) = 0.1
		_Hatch0 ("Hatch 0", 2D) = "white" {}
		_Hatch1 ("Hatch 1", 2D) = "white" {}
		_Hatch2 ("Hatch 2", 2D) = "white" {}
		_Hatch3 ("Hatch 3", 2D) = "white" {}
		_Hatch4 ("Hatch 4", 2D) = "white" {}
		_Hatch5 ("Hatch 5", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry"}

        UsePass "Unlit/ToonShading/OUTLINE"

        Pass
        {
            Tags {"LightMode" = "ForwardBase"}

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "UnityShaderVariables.cginc"

			fixed4 _Color;
			float _TileFactor;
			sampler2D _Hatch0;
			sampler2D _Hatch1;
			sampler2D _Hatch2;
			sampler2D _Hatch3;
			sampler2D _Hatch4;
			sampler2D _Hatch5;

            struct inputData{
                float4 vertex : POSITION;
				float4 tangent : TANGENT; 
				float3 normal : NORMAL; 
				float2 texcoord : TEXCOORD0; 
            };

            struct vertexOutput{
                float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				fixed3 hatchWeights0 : TEXCOORD1;
				fixed3 hatchWeights1 : TEXCOORD2;
				float3 worldPos : TEXCOORD3;
				SHADOW_COORDS(4)
            };

            vertexOutput vert(inputData IN) {
				vertexOutput vo;
				
				vo.pos = UnityObjectToClipPos(IN.vertex);
				
				vo.uv = IN.texcoord.xy * _TileFactor;
				
				fixed3 worldLightDir = normalize(WorldSpaceLightDir(IN.vertex));
				fixed3 worldNormal = UnityObjectToWorldNormal(IN.normal);
				fixed diff = max(0, dot(worldLightDir, worldNormal));
				
				vo.hatchWeights0 = fixed3(0, 0, 0);
				vo.hatchWeights1 = fixed3(0, 0, 0);
				
				float hatchFactor = diff * 7.0;
				
				if (hatchFactor > 6.0) {

				} else if (hatchFactor > 5.0) {
					vo.hatchWeights0.x = hatchFactor - 5.0;
				} else if (hatchFactor > 4.0) {
					vo.hatchWeights0.x = hatchFactor - 4.0;
					vo.hatchWeights0.y = 1.0 - vo.hatchWeights0.x;
				} else if (hatchFactor > 3.0) {
					vo.hatchWeights0.y = hatchFactor - 3.0;
					vo.hatchWeights0.z = 1.0 - vo.hatchWeights0.y;
				} else if (hatchFactor > 2.0) {
					vo.hatchWeights0.z = hatchFactor - 2.0;
					vo.hatchWeights1.x = 1.0 - vo.hatchWeights0.z;
				} else if (hatchFactor > 1.0) {
					vo.hatchWeights1.x = hatchFactor - 1.0;
					vo.hatchWeights1.y = 1.0 - vo.hatchWeights1.x;
				} else {
					vo.hatchWeights1.y = hatchFactor;
					vo.hatchWeights1.z = 1.0 - vo.hatchWeights1.y;
				}
				
				vo.worldPos = mul(unity_ObjectToWorld, IN.vertex).xyz;
				
				TRANSFER_SHADOW(vo);
				
				return vo; 
			}

			fixed4 frag(vertexOutput v) : SV_Target {			
				fixed4 hatchTex0 = tex2D(_Hatch0, v.uv) * v.hatchWeights0.x;
				fixed4 hatchTex1 = tex2D(_Hatch1, v.uv) * v.hatchWeights0.y;
				fixed4 hatchTex2 = tex2D(_Hatch2, v.uv) * v.hatchWeights0.z;
				fixed4 hatchTex3 = tex2D(_Hatch3, v.uv) * v.hatchWeights1.x;
				fixed4 hatchTex4 = tex2D(_Hatch4, v.uv) * v.hatchWeights1.y;
				fixed4 hatchTex5 = tex2D(_Hatch5, v.uv) * v.hatchWeights1.z;
				fixed4 whiteColor = fixed4(1, 1, 1, 1) * (1 - v.hatchWeights0.x - v.hatchWeights0.y - v.hatchWeights0.z - 
							v.hatchWeights1.x - v.hatchWeights1.y - v.hatchWeights1.z);
				
				fixed4 hatchColor = hatchTex0 + hatchTex1 + hatchTex2 + hatchTex3 + hatchTex4 + hatchTex5 + whiteColor;
				
				UNITY_LIGHT_ATTENUATION(atten, v, v.worldPos);
								
				return fixed4(hatchColor.rgb * _Color.rgb * atten, 1.0);
			}
            ENDCG
        }
    }
	FallBack "Diffuse"
}

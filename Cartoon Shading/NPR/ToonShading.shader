// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/ToonShading"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
		_MainTex ("Main Tex", 2D) = "white" {}
		_Ramp ("Ramp Texture", 2D) = "white" {}
		_Outline ("Outline", Range(0, 1)) = 0.1
		_OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
		_Specular ("Specular", Color) = (1, 1, 1, 1)
		_SpecularScale ("Specular Scale", Range(0, 0.1)) = 0.01
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry"}

        Pass{
            NAME "OUTLINE"
            Cull Front

            CGPROGRAM
             
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct inputData{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct vertexOutput{
                float4 pos : SV_POSITION;
            };

            float _Outline;
            fixed4 _OutlineColor;

            vertexOutput vert(inputData IN){
                vertexOutput vo;

                float4 pos = mul(UNITY_MATRIX_MV, IN.vertex);
                float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV, IN.normal);
                pos = pos + float4(normalize(normal), 0) * _Outline;
                vo.pos = mul(UNITY_MATRIX_P, pos);

                return vo;
            }

            float4 frag(vertexOutput v) : SV_TARGET{
                return float4(_OutlineColor.rgb, 1);
            }
            ENDCG
        }

        Pass{
            Tags{"LightMode" = "ForwardBase"}
            Cull Back

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "UnityShaderVariables.cginc"

            fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _Ramp;
			fixed4 _Specular;
			fixed _SpecularScale;

            struct inputData {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
				float4 tangent : TANGENT;
			}; 

            struct vertexOutput {
				float4 pos : POSITION;
				float2 uv : TEXCOORD0;
				float3 worldNormal : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				SHADOW_COORDS(3)
			};
			
			vertexOutput vert (inputData IN) {
				vertexOutput vo;
				
				vo.pos = UnityObjectToClipPos(IN.vertex);
				vo.uv = TRANSFORM_TEX (IN.texcoord, _MainTex);
				vo.worldNormal  = UnityObjectToWorldNormal(IN.normal);
				vo.worldPos = mul(unity_ObjectToWorld, IN.vertex).xyz;
				
				TRANSFER_SHADOW(vo);
				
				return vo;
			}

            float4 frag(vertexOutput v) : SV_Target { 
				fixed3 worldNormal = normalize(v.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(v.worldPos));
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(v.worldPos));
				fixed3 worldHalfDir = normalize(worldLightDir + worldViewDir);
				
				fixed4 c = tex2D (_MainTex, v.uv);
				fixed3 albedo = c.rgb * _Color.rgb;
				
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				
				UNITY_LIGHT_ATTENUATION(atten, v, v.worldPos);
				
				fixed diff =  dot(worldNormal, worldLightDir);
				diff = (diff * 0.5 + 0.5) * atten;
				
				fixed3 diffuse = _LightColor0.rgb * albedo * tex2D(_Ramp, float2(diff, diff)).rgb;
				
				fixed spec = dot(worldNormal, worldHalfDir);
				fixed w = fwidth(spec) * 2.0;
				fixed3 specular = _Specular.rgb * lerp(0, 1, smoothstep(-w, w, spec + _SpecularScale - 1)) * step(0.0001, _SpecularScale);
				
				return fixed4(ambient + diffuse + specular, 1.0);
			}
            ENDCG
        }
    }
}

Shader "Unlit/DissolveShading"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _BumpTex ("Bump Texture", 2D) = "white" {}
        _BurnTex ("Burn Texture", 2D) = "white" {}
        _BurnAmount ("Burn Amount", Range(0.0,1.0)) = 0.0
        _LineWidth ("Burn Line Width", Range(0.0,0.2)) = 0.1
        _BurnFirstColor ("Burn First Color",Color) = (1,0,0,1)
        _BurnSecondColor ("Burn Second Color",Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry"}
        Pass
        {
            Tags {"LightMode" = "ForwardBase"}
            Cull Off
            CGPROGRAM

            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #pragma multi_compile_fwdbase
            #pragma vertex vert
            #pragma fragment frag

            struct inputData{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;
            };

            struct vertexOutput{
                float4 pos : SV_POSITION;
                float2 uvMain : TEXCOORD0;
                float2 uvBump : TEXCOORD1;
                float2 uvBurn : TEXCOORD2;
                float3 lightDir : TEXCOORD3;
                float3 worldPos : TEXCOORD4; 
                SHADOW_COORDS(5)
            };
            
            sampler2D _MainTex;
            sampler2D _BumpTex;
            sampler2D _BurnTex;
            float _BurnAmount;
            float _LineWidth;
            fixed4 _BurnFirstColor;
            fixed4 _BurnSecondColor;

            float4 _MainTex_ST;
            float4 _BumpTex_ST;
            float4 _BurnTex_ST;

            vertexOutput vert(inputData v){
                
                vertexOutput vo;
                vo.pos = UnityObjectToClipPos(v.vertex);

                vo.uvMain = TRANSFORM_TEX(v.texcoord, _MainTex);
                vo.uvBump = TRANSFORM_TEX(v.texcoord, _BumpTex);
                vo.uvBurn = TRANSFORM_TEX(v.texcoord, _BurnTex);

                TANGENT_SPACE_ROTATION;
                vo.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;

                vo.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                TRANSFER_SHADOW(vo);
                
                return vo;
            }

            fixed4 frag(vertexOutput v) : SV_TARGET{

                fixed3 burn = tex2D(_BurnTex, v.uvBurn);
                clip(burn.r - _BurnAmount);

                float3 tangentLightDir = normalize(v.lightDir);
                float3 tangentNormal = UnpackNormal(tex2D(_BumpTex, v.uvBump));

                fixed3 basicColor = tex2D(_MainTex, v.uvMain);

                fixed3 ambientColor = UNITY_LIGHTMODEL_AMBIENT.xyz * basicColor;
                fixed3 diffuseColor = _LightColor0.rgb * basicColor * max(0,dot(tangentLightDir, tangentNormal));
                
                //Calculate burn color
                fixed mixIndex = 1 - smoothstep(0.0, _LineWidth, burn.r - _BurnAmount);
                fixed3 burnColor  = lerp(_BurnFirstColor, _BurnSecondColor, mixIndex);

                UNITY_LIGHT_ATTENUATION(atten, v, v.worldPos);
                fixed3 finalColor = lerp(ambientColor + diffuseColor * atten, burnColor, mixIndex * step(0.001, _BurnAmount));

                return fixed4(finalColor, 1.0);
            }
            ENDCG
        }

        Pass {
			Tags { "LightMode" = "ShadowCaster" }
			
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#pragma multi_compile_shadowcaster
			
			#include "UnityCG.cginc"
			
			fixed _BurnAmount;
			sampler2D _BurnMap;
			float4 _BurnMap_ST;
			
			struct v2f {
				V2F_SHADOW_CASTER;
				float2 uvBurnMap : TEXCOORD1;
			};
			
			v2f vert(appdata_base v) {
				v2f o;
				
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				
				o.uvBurnMap = TRANSFORM_TEX(v.texcoord, _BurnMap);
				
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				fixed3 burn = tex2D(_BurnMap, i.uvBurnMap).rgb;
				
				clip(burn.r - _BurnAmount);
				
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}
    }
}

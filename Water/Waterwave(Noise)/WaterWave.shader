// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/WaterWave"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color",Color) = (0,0.15,0.115,1)
        _WaveMap ("Wave Map", 2D) = "bump" {}
        _CubeMap ("Enviroment CubeMap", Cube) = "_Skybox" {}
        _WaveXSpeed ("Wave Horizontal Speed", Range(-0.2,0.2)) = 0.01
        _WaveYSpeed ("Wave Vertical Speed",Range(-0.2,0.2)) = 0.01
        _Distortion ("Distortion", Range(0,200)) = 50
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType"="Opaque" }

        GrabPass {"_RefractionTex"}

        Pass
        {
            Tags {"LightMode" = "ForwardBase"}

            CGPROGRAM
            #include "UnityCG.cginc"
			#include "Lighting.cginc"
			#pragma multi_compile_fwdbase
			#pragma vertex vert
			#pragma fragment frag

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _WaveMap;
            float4 _WaveMap_ST;
            samplerCUBE _CubeMap;
            fixed _WaveXSpeed;
            fixed _WaveYSpeed;
            sampler2D _RefractionTex;
            float4 _RefractionTex_TexelSize;
            float _Distortion;

            struct inputData{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;
            };

            struct vertexOutput{
                float4 pos : SV_POSITION;
                float4 grabPos : TEXCOORD0;
                float2 uvMainTex : TEXCOORD1;
                float2 uvWaveMap : TEXCOORD2;
                float3 TtoW0 : TEXCOORD3;
                float3 TtoW1 : TEXCOORD4;
                float3 TtoW2 : TEXCOORD5;
                float3 worldPos: TEXCOORD6;
            };
            
            vertexOutput vert(inputData IN){
                vertexOutput vo;

                vo.pos = UnityObjectToClipPos(IN.vertex);
                vo.worldPos = mul(unity_ObjectToWorld, IN.vertex).xyz;
                vo.grabPos = ComputeGrabScreenPos(vo.pos);
                vo.uvMainTex = TRANSFORM_TEX(IN.texcoord, _MainTex);
                vo.uvWaveMap = TRANSFORM_TEX(IN.texcoord, _WaveMap);
                
                float3 worldPos = mul(unity_ObjectToWorld, IN.vertex);
                fixed3 worldNormal = UnityObjectToWorldNormal(IN.normal);
                fixed3 worldTangent = UnityObjectToWorldDir(IN.tangent);
                fixed3 biNormal = cross(worldNormal, worldTangent);

                //xyz -- tangent binormal normal
                vo.TtoW0 = float3(worldTangent.x,biNormal.x,worldNormal.x);
                vo.TtoW1 = float3(worldTangent.y,biNormal.y,worldNormal.y);
                vo.TtoW2 = float3(worldTangent.z,biNormal.z,worldNormal.z);

                return vo;
            }

            fixed4 frag(vertexOutput v) : SV_TARGET{
                
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(v.worldPos));
                float2 waveSpeed = _Time.y * float2(_WaveXSpeed, _WaveYSpeed);

                float3 bump1 = UnpackNormal(tex2D(_WaveMap, v.uvWaveMap + waveSpeed)).rgb;
                float3 bump2 = UnpackNormal(tex2D(_WaveMap, v.uvWaveMap - waveSpeed)).rgb;
                float3 bumpNormal = normalize(bump1 + bump2);

                float2 offset = bumpNormal.xy * _Distortion * _RefractionTex_TexelSize.xy;
                v.grabPos.xy = offset * v.grabPos.z + v.grabPos.xy;
                fixed3 refractColor = tex2D(_RefractionTex, v.grabPos.xy/v.grabPos.w).rgb;

                bumpNormal = float3(dot(v.TtoW0, bumpNormal), dot(v.TtoW1, bumpNormal), dot(v.TtoW2, bumpNormal));

                fixed4 mainColor = tex2D(_MainTex, v.uvMainTex + waveSpeed);

                fixed3 reflectDir = reflect(-viewDir, bumpNormal);
                fixed3 reflectColor = texCUBE(_CubeMap, reflectDir).rgb * mainColor.rgb * _Color.rgb;

                fixed fresnel = pow(1 - saturate(dot(viewDir, bumpNormal)), 4);
                fixed3 finalColor = reflectColor * fresnel + refractColor * (1 - fresnel);

                return fixed4(finalColor, 1.0);
            }
            ENDCG
        }
    }
}

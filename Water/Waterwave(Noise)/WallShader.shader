// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/WallShader"
{
    Properties
    {
        _Color ("Color",Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _BumpTex ("Texture", 2D) = "white" {}
        _BumpScale ("Bump Scale", float) = 1.0
        _Specular ("Specular", Color) = (1,1,1,1)
        _Gloss ("Gloss", Range(4,512)) = 8
    }
    SubShader
    {
        Pass
        {
            Tags {"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpTex;
            float4 _BumpTex_ST;
            float _BumpScale;
            fixed4 _Specular;
            float _Gloss;

            struct inputData{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;
            };

            struct vertexOutput{
                float4 pos : POSITION;
                float3 worldPos : TEXCOORD0;
                float2 uvMainTex : TEXCOORD1;
                float2 uvBumpTex : TEXCOORD2;
                float3 TtoW0 : TEXCOORD3;
                float3 TtoW1 : TEXCOORD4;
                float3 TtoW2 : TEXCOORD5;
            };

            vertexOutput vert(inputData IN){
                vertexOutput vo;

                vo.pos = UnityObjectToClipPos(IN.vertex);
                vo.worldPos = mul(unity_ObjectToWorld, IN.vertex);
                vo.uvMainTex = TRANSFORM_TEX(IN.texcoord, _MainTex);
                vo.uvBumpTex = TRANSFORM_TEX(IN.texcoord, _BumpTex);
                
                fixed3 worldNormal = UnityObjectToWorldNormal(IN.normal);
                fixed3 worldTangent = UnityObjectToWorldDir(IN.tangent);
                fixed3 biNormal = cross(worldNormal, worldTangent) * IN.tangent.w;

                vo.TtoW0 = float3(worldTangent.x, biNormal.x, worldNormal.x);
                vo.TtoW1 = float3(worldTangent.y, biNormal.y, worldNormal.y);
                vo.TtoW2 = float3(worldTangent.z, biNormal.z, worldNormal.z);

                return vo;
            }

            fixed4 frag(vertexOutput v) : SV_TARGET{
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(v.worldPos));
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(v.worldPos));

                fixed3 bumpNormal = UnpackNormal(tex2D(_BumpTex, v.uvBumpTex));
                bumpNormal.xy *= _BumpScale;
                bumpNormal.z = sqrt(1 - saturate(dot(bumpNormal.xy, bumpNormal.xy)));

                fixed3 worldNormal = normalize(half3(dot(v.TtoW0, bumpNormal), dot(v.TtoW1, bumpNormal), dot(v.TtoW2, bumpNormal)));

                fixed3 basicColor = tex2D(_MainTex, v.uvMainTex) * _Color.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * basicColor;
                fixed3 diffuse = _LightColor0.rgb * basicColor * max(0, dot(worldNormal, lightDir));

                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0,dot(worldNormal, normalize(lightDir + viewDir))),_Gloss);

                return fixed4(ambient + diffuse + specular,1.0);
            }
            ENDCG
        }
    }
}

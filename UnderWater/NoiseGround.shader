Shader "Custom/NoiseGround"
{
    Properties
    {
        _Tess ("Tesselation", Range(1,8)) = 4
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _NormalMap ("Normal Map", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _NoiseScale ("Noise Scale", Range(0,5)) = 1
        _NoiseFrequency ("Noise Frequency", Range(0,5)) = 2
        _NoiseOffset ("Noise Offset",Vector) = (0,0,0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows tessellate:tess vertex:vert
        #pragma target 4.6
        #include "noiseSimplex.cginc"

        sampler2D _MainTex;
        sampler2D _NormalMap;
        float _Tess;
        float _NoiseScale;
        float _NoiseFrequency;
        float4 _NoiseOffset;

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        struct appdata{
            float4 vertex : POSITION0;
            float3 normal : NORMAL; 
            float4 tangent : TANGENT;
            float3 texcoord : TEXCOORD0;
        };

        struct Input
        {
            float2 uv_MainTex;
        };

        float4 tess(){
            return _Tess;
        }

        void vert(inout appdata v){
            float3 vPos = v.vertex.xyz;
            float3 biTangent = cross(v.tangent.xyz, v.normal);
            float3 noiseNormal = vPos + (v.tangent.xyz * 0.01);
            float3 noiseTangent = vPos + (biTangent * 0.01);

            float noise1 = _NoiseScale * snoise(float3(vPos.x + _NoiseOffset.x, vPos.y + _NoiseOffset.y, vPos.z + _NoiseOffset.z) * _NoiseFrequency);
            vPos += ((noise1 + 1) / 2) * v.normal;

            float noise2 = _NoiseScale * snoise(float3(noiseNormal.x + _NoiseOffset.x, noiseNormal.y + _NoiseOffset.y, noiseNormal.z + _NoiseOffset.z) * _NoiseFrequency);
            noiseNormal += ((noise2 + 1 ) / 2) * v.normal;

            float noise3 = _NoiseScale * snoise(float3(noiseTangent.x + _NoiseOffset.x, noiseTangent.y + _NoiseOffset.y, noiseTangent.z + _NoiseOffset.z) * _NoiseFrequency);
            noiseTangent += ((noise3 + 1) / 2) * v.normal;

            float3 finalNormal = cross(noiseNormal  - vPos, noiseTangent - vPos) * v.tangent.w;
            v.normal = normalize(finalNormal);
            v.vertex.xyz = vPos;
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Normal = UnpackNormal(tex2D(_NormalMap, IN.uv_MainTex));
        }
        ENDCG
    }
    FallBack "Diffuse"
}

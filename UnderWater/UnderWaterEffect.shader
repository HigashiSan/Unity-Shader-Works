Shader "Hidden/UnderWaterEffect"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NoiseScale ("Noise Scale", Range(0,10)) = 2
        _NoiseSpeed ("Noise Speed", Range(0,30)) = 1
        _NoiseAmount ("Noise Amount", Range(0,300)) = 1
        _OffsetScale ("Offset Scale", Range(0, 0.003)) = 0.001
        _WaterWaveStart ("WaterWave Start", float) = 1
        _WaveDistance ("WaterWave Distance", float) = 1
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
            #include "noiseSimplex.cginc"
            #define Pi 3.1415926535

            sampler2D _MainTex;
            float _NoiseScale;
            float _NoiseSpeed;
            float _NoiseAmount;
            float _OffsetScale;
            float _WaterWaveDistance;
            float _WaterWaveStart;
            sampler2D _CameraDepthTexture;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 grabPos : TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.grabPos = ComputeScreenPos(o.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : COLOR
            {
                float depthValue = Linear01Depth(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.grabPos)).r) * _ProjectionParams.z;
                depthValue = 1 - saturate((depthValue - _WaterWaveStart) / _WaterWaveDistance);

                float3 pos = float3(i.grabPos.x, i.grabPos.y, 0) * _NoiseAmount;
                pos.z = _Time.x * _NoiseSpeed;
                float noise = ((snoise(pos.xyz) + 1) / 2) * _NoiseScale;
                float4 noiseTrans = float4(sin(noise * Pi * 2), cos(noise * Pi * 2),0,0);
                fixed4 color = tex2Dproj(_MainTex, i.grabPos + noiseTrans * _OffsetScale * depthValue);

                return color;
            }
            ENDCG
        }
    }
}

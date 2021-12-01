Shader "Unlit/Window"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _GridNum ("DropNum", float) = 1
        _T ("Time", float) = 1
        _Distortion ("Distortion", Range(-10,10)) = 0.5
        _Blur ("Blur", Range(0,1)) = 1
        _RainLayers ("RainLayers", Range(1,10)) = 1
        _SampleNum ("SampleNum", Range(1,128)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Transparent"}
        LOD 100

        GrabPass {"_GrabTexture"}

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
                float4 grab_uv : TEXCOORD1;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _GrabTexture;
            float4 _MainTex_ST;
            float _GridNum;
            float _T;
            float _Distortion;
            float _Blur;
            float _RainLayers;
            float _SampleNum;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.grab_uv = UNITY_PROJ_COORD(ComputeGrabScreenPos(o.vertex));
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float GetRandom(float2 p)
            {
                p = frac(p * float2(123.33, 233.233));
                p += dot(p, p + 34.33);
                return frac(p.x * p.y);
            }

            float3 DrawDrop(float2 UV, float t)
            {
                float2 aspect = float2(2,1);
                float2 uv = UV * _GridNum * aspect;
                uv.y += t * 0.25;
                float2 grid_uv = frac(uv) - 0.5;
                float2 grid_id = floor(uv);

                float gridValue = GetRandom(grid_id);
                t += gridValue * 6.28;

                float w = UV.y * 10;
                float x = (gridValue - 0.5) * 0.8;
                x += (0.4 - abs(x)) * sin(3 * w) * pow(sin(w), 6) * 0.45;
                float y = -sin(t + sin(t + sin(t) * .5)) * 0.45;
                y -= (grid_uv.x - x) * (grid_uv.x - x);

                float2 dropPos = (grid_uv - float2(x, y)) / aspect;
                float drop = smoothstep(0.05, 0.03, length(dropPos));

                float2 trailPos = (grid_uv - float2(x, t * 0.25)) / aspect;
                trailPos.y = (frac(trailPos.y * 8) - 0.5) / 8;
                float trail = smoothstep(0.03, 0.01, length(trailPos));

                float fogTrail = dropPos.y > 0 ? 1 : 0;
                fogTrail *= smoothstep(0.5, y, grid_uv.y);
                trail *= fogTrail;
                fogTrail *= smoothstep(0.05, 0.04, abs(dropPos.x));

                float2 offsets = drop * dropPos + trail * trailPos;

                return float3(offsets, fogTrail);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float t = fmod(_Time.y + _T, 7200);
                float4 col = 0;

                float3 drops = DrawDrop(i.uv, t);
                for(int k = 1; k <= _RainLayers; k++)
                {
                    drops += DrawDrop(i.uv * (1.13 + 0.012 * k) + 0.98 * k, t);
                }

                float fade = 1 - saturate(fwidth(i.uv) * 60);
                
                float blur = _Blur * 7 * (1 - drops.z * fade);

                float2 proj_uv = i.grab_uv.xy / i.grab_uv.w;
                proj_uv += drops.xy * _Distortion * fade;

                float a = GetRandom(i.uv) * 6.283;
                for(float j = 0; j < _SampleNum; j++)
                {
                    float2 sampleOffset = float2(sin(a),cos(a)) * blur * 0.01;
                    float d = sqrt(frac(sin((j + 1) * 546.) * 5489.));
                    col += tex2D(_GrabTexture, proj_uv + sampleOffset * d);
                    a++;
                }
                col /= _SampleNum; 

                return col;
            }
            ENDCG
        }
    }
}

Shader "Hidden/NightVision"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
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
                float4 screenPos : TEXCOORD1;
            };

            sampler2D _MainTex;
            half _Distortion;
            half _Scale;

            fixed _Brightness;
            fixed _Saturation;
            fixed _Contrast;

            fixed4 _VisionColor;

            fixed _VignetteFalloff;
            fixed _VignetteIntensity;

            sampler2D _NoiseMap;
            half _NoiseAmount;
            half _RandomValue;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.screenPos = ComputeScreenPos(o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //Distortion
                fixed2 center = i.uv - 0.5;
                half radius = pow(center.x, 2) + (center.y, 2);
                half distortion = 1 + sqrt(radius) * radius * _Distortion;
                float2 uvScreen = center * distortion * _Scale + 0.5;
                fixed4 screen = tex2D(_MainTex, uvScreen);

                //Contrast Saturation
                screen *= _Brightness;
                fixed4 luminance = Luminance(screen.rgb);
                screen = lerp(luminance, screen, _Saturation);

                fixed4 grey = fixed4(0.5,0.5,0.5,1);
                screen = lerp(grey, screen, _Contrast);

                screen *= _VisionColor;

                //Border
                half circle = distance(i.screenPos.xy, fixed2(0.5, 0.5));
                fixed vignette = 1 - saturate(pow(circle, _VignetteFalloff));
                screen *= pow(vignette, _VignetteIntensity);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    

                //Noise
                float2 uvNoise = i.uv * _NoiseAmount;
                uvNoise.x -= sin(_RandomValue);
                uvNoise.y += sin(_RandomValue + 1);

                fixed noise = tex2D(_NoiseMap, uvNoise).r;
                screen *= noise;

                return screen;            
            }
            ENDCG
        }
    }
}

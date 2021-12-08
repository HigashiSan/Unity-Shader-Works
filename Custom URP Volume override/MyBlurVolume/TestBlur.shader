Shader "PostEffect/TestBlur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" { }
    }

    SubShader
    {
        Cull Off ZWrite Off ZTest Always
        Tags { "RenderPipeline" = "UniversalPipeline" }
        Pass
        {
            CGPROGRAM

            #pragma vertex Vert
            #pragma fragment Frag

            sampler2D _MainTex;
            float2 _FocusScreenPosition;
            float _FocusPower;

            struct appdata
            {
                float4 vertex: POSITION;
                float2 uv: TEXCOORD0;
            };

            struct v2f
            {
                float2 uv: TEXCOORD0;
                float4 vertex: SV_POSITION;
            };

            v2f Vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 Frag(v2f i): SV_Target
            {
                float2 uv = i.uv;

                half2 uv1 = uv + half2(_FocusPower / _ScreenParams.x, _FocusPower / _ScreenParams.y) * half2(1, 0) * - 2.0;
                half2 uv2 = uv + half2(_FocusPower / _ScreenParams.x, _FocusPower / _ScreenParams.y) * half2(1, 0) * - 1.0;
                half2 uv3 = uv + half2(_FocusPower / _ScreenParams.x, _FocusPower / _ScreenParams.y) * half2(1, 0) * 0.0;
                half2 uv4 = uv + half2(_FocusPower / _ScreenParams.x, _FocusPower / _ScreenParams.y) * half2(1, 0) * 1.0;
                half2 uv5 = uv + half2(_FocusPower / _ScreenParams.x, _FocusPower / _ScreenParams.y) * half2(1, 0) * 2.0;
                half4 s = 0;

                s += tex2D(_MainTex, uv1) * 0.0545;
                s += tex2D(_MainTex, uv2) * 0.2442;
                s += tex2D(_MainTex, uv3) * 0.4026;
                s += tex2D(_MainTex, uv4) * 0.2442;
                s += tex2D(_MainTex, uv5) * 0.0545;

                return s;
            }
            ENDCG

        }
        
        Pass
        {
            CGPROGRAM

            #pragma vertex Vert
            #pragma fragment Frag

            sampler2D _MainTex;
            float2 _FocusScreenPosition;
            float _FocusPower;

            struct appdata
            {
                float4 vertex: POSITION;
                float2 uv: TEXCOORD0;
            };

            struct v2f
            {
                float2 uv: TEXCOORD0;
                float4 vertex: SV_POSITION;
            };

            v2f Vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 Frag(v2f i): SV_Target
            {
                float2 uv = i.uv;

                half2 uv1 = uv + half2(_FocusPower / _ScreenParams.x, _FocusPower / _ScreenParams.y) * half2(0, 1) * - 2.0;
                half2 uv2 = uv + half2(_FocusPower / _ScreenParams.x, _FocusPower / _ScreenParams.y) * half2(0, 1) * - 1.0;
                half2 uv3 = uv + half2(_FocusPower / _ScreenParams.x, _FocusPower / _ScreenParams.y) * half2(0, 1) * 0.0;
                half2 uv4 = uv + half2(_FocusPower / _ScreenParams.x, _FocusPower / _ScreenParams.y) * half2(0, 1) * 1.0;
                half2 uv5 = uv + half2(_FocusPower / _ScreenParams.x, _FocusPower / _ScreenParams.y) * half2(0, 1) * 2.0;
                half4 s = 0;

                s += tex2D(_MainTex, uv1) * 0.0545;
                s += tex2D(_MainTex, uv2) * 0.2442;
                s += tex2D(_MainTex, uv3) * 0.4026;
                s += tex2D(_MainTex, uv4) * 0.2442;
                s += tex2D(_MainTex, uv5) * 0.0545;

                return s;
            }
            ENDCG
        }
    }
}
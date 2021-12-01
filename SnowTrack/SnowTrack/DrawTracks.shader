Shader "Unlit/DrawTracks"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Coordinate ("Coordinate",Vector) = (0,0,0,0)
        _Color ("Draw Color",Color) = (1,0,0,0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Coordinate,_Color;
            float _TrackWidth;
            float _TrackWeight;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);

                float draw = pow(saturate(1 - distance(i.uv, _Coordinate.xy)), 500 / _TrackWidth);
                fixed4 drawcol = _Color * (draw * _TrackWeight);

                return saturate(col + drawcol);
            }
            ENDCG
        }
    }
}
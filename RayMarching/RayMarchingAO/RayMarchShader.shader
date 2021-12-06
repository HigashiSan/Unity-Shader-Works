Shader "cdcRayMarching/RayMarchShader"
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
            #pragma target 5.0

            #include "UnityCG.cginc"
            #include "DistanceFunctions.cginc"
            #include "Lighting.cginc"

            sampler2D _MainTex;
            uniform sampler2D _CameraDepthTexture;
            uniform float4x4 _CamFrustum, _CamToWorldMatrix;
            uniform float _maxDst;

            uniform float4 _Sphere1,_Sphere2,_Box1;
            uniform float _Box1round, _BoxSphereSmooth, _SphereIntersectSmooth;
            uniform float3 _LightDir, _LightCol;
            uniform float4 _LightPos;
            uniform float _LightIntensity;
            uniform fixed4 _MainColor;
            uniform float2 _ShadowDst;
            uniform float _ShadowIntensity;
            uniform float _ShadowSoft;
            uniform int _MaxIterations;
            uniform float _Accuracy;
            uniform float _AoStepSize;
            uniform int _AoIterations;
            uniform float _AoIntensity;
            uniform float3 _BoxSize;
            uniform float3 _BoxPos;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 ray : TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;
                v.vertex.z = 0;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;

                int index = 0;
                if(o.uv.x < 0.5 && o.uv.y < 0.5)
                {
                    index = 3;
                }
                else if(o.uv.x > 0.5 && o.uv.y < 0.5)
                {
                    index = 2;
                }
                else if(o.uv.x > 0.5 && o.uv.y > 0.5)
                {
                    index = 1;
                }
                else if(o.uv.x < 0.5 && o.uv.y > 0.5)
                {
                    index = 0;
                }

                o.ray = _CamFrustum[index].xyz;
                
                o.ray = mul(_CamToWorldMatrix, o.ray);

                return o;
            }

            float BoxSphere(float3 p)
            {
                float sphere1 = sdSphere(p - _Sphere1.xyz, _Sphere1.w);
                float box1 = sdRoundBox(p - _Box1.xyz, _Box1.www, _Box1round);
                float combine1 = opSS(sphere1, box1, _BoxSphereSmooth);

                float sphere2 = sdSphere(p - _Sphere2.xyz, _Sphere2.w);
                float combine2 = opIS(sphere2, combine1, _SphereIntersectSmooth);

                return combine2;
            }

            float DstField(float3 p)
            {
                float ground = sdPlane(p, float4(0,1,0,0));

                float box = sdBox(p - _BoxPos, _BoxSize);

                float groundBox = opU(ground, box);

                float BoxSphere1 = BoxSphere(p);

                return opU(groundBox, BoxSphere1);
            }

            //Use Gradient to get normals
            float3 GetNormal(float3 p)
            {
                const float offset = 0.0001;
                float3 normal = float3(
                    DstField(float3(p.x + offset, p.y, p.z)) - DstField(float3(p.x - offset, p.y, p.z)),
                    DstField(float3(p.x, p.y + offset, p.z)) - DstField(float3(p.x, p.y - offset, p.z)),
                    DstField(float3(p.x, p.y, p.z + offset)) - DstField(float3(p.x, p.y, p.z - offset)));

                return normalize(normal);
            }

            float SoftShadow(float3 ro, float3 rd, float mint, float maxt, float k)
            {
                float result = 1.0;
                for(float t = mint; t < maxt; )
                {
                    float h = DstField(ro + rd * t);
                    if(h < 0.001)
                    {
                        return 0.0;
                    }
                    result = min(result, k * h / t);
                    t += h;
                }
                return result;
            }

            float SoftShadowImprove(float3 ro, float3 rd, float mint, float maxt, float k)
            {
                float result = 1.0;
                float lastDst = 1e20;

                for(float t = mint; t< maxt; )
                {
                    float h = DstField(ro + rd * t);
                    
                    if(h < 0.001)
                    {
                        return 0.0;
                    }
                    float y = h * h / (2.0 * lastDst);
                    float d = sqrt( h * h - y * y);
                    result = min( result, k * d / max(0.0,t-y));
                    lastDst = h;
                    t += h;
                }
                return result;
            }

            float AmbientOcclusion(float3 p, float3 n)
            {
                float step = _AoStepSize;
                float ao = 0.0;
                float dist;

                for(int i=1; i <= _AoIterations; i++ )
                {
                    dist = step * i;
                    ao += max(0.0, (dist - DstField(p + n * dist)) / dist);
                }
                return (1.0 - ao * _AoIntensity);
            }

            float3 Shading(float3 p, float3 n)
            {
                float3 result;

                float3 color = _MainColor.rgb;
                float3 light = (_LightCol * dot(-_LightDir, n) * 0.5 + 0.5) * _LightIntensity;

                float shadow = SoftShadow(p, -_LightDir, _ShadowDst.x, _ShadowDst.y, _ShadowSoft) * 0.5 + 0.5;
                shadow = max(0.0, pow(shadow, _ShadowIntensity));

                float ao = AmbientOcclusion(p, n);

                result = color * light * shadow * ao;
                return result;
            }

            fixed4 RayMarching(float3 ro, float3 rd, float depth)
            {
                fixed4 result = fixed4(1,1,1,1);

                const int maxIteration = _MaxIterations;
                float t = 0;

                for(int i = 0; i < maxIteration; i++)
                {
                    if(t > _maxDst || t >= depth)
                    {
                        result = fixed4(0,0,0,0);
                        break;
                    }

                    float3 p = ro + rd * t;
                    float d = DstField(p);
                    if(d < _Accuracy)
                    {
                        float3 n = GetNormal(p);
                        float3 s = Shading(p, n);

                        result = fixed4(s,1);
                        break;
                    }
                    t += d;
                }
                return result;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float depth = LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv).r);
                depth *= length(i.ray);

                fixed3 col = tex2D(_MainTex, i.uv);
                float3 rayDir = normalize(i.ray.xyz);
                float3 rayOrigin = _WorldSpaceCameraPos;
                fixed4 result = RayMarching(rayOrigin, rayDir, depth);

                return fixed4(col * (1.0 - result.w) + result.xyz * result.w, 1.0);
            }
            ENDCG
        }
    }
}

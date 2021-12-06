Shader "Hidden/RaymarchTest"
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
                float4 pos : SV_POSITION;
                float3 viewVector : TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                float3 viewVector = mul(unity_CameraInvProjection, float4(v.uv * 2 - 1, 0, -1));
                o.viewVector = mul(unity_CameraToWorld, float4(viewVector,0));
                return o;
            }

            Texture3D<float4> ShapeNoise;
            Texture2D<float4> BlueNoise;

            SamplerState samplerShapeNoise;
            SamplerState samplerBlueNoise;

            sampler2D _MainTex, _CameraDepthTexture;

            float3 BoundsMin, BoundsMax;

            //Shape Settings
            float CloudScale;
            float CloudOffset;
            float DensityThreshold;
            float DensityMultiplier;
            int NumSteps;
            float4 phaseParams = (0.83f,0.3f,0.8f,0.15f);

            //Light march settings
            int numStepsLight;
            float rayOffsetStrength;

            //Light Settings
            float lightAbsorptionTowardSun;
            float lightAbsorptionThroughCloud;
            float darknessThreshold;
            float4 _LightColor0;
            //float4 colA;
            //float4 colB;

            float2 rayBoxDst(float3 boundsMin, float3 boundsMax, float3 rayOrigin, float3 rayDir) {
                float3 t0 = (boundsMin - rayOrigin) / rayDir;
                float3 t1 = (boundsMax - rayOrigin) / rayDir;
                float3 tmin = min(t0, t1);
                float3 tmax = max(t0, t1);
                
                float dstA = max(max(tmin.x, tmin.y), tmin.z);
                float dstB = min(tmax.x, min(tmax.y, tmax.z));

                float dstToBox = max(0, dstA);
                float dstInsideBox = max(0, dstB - dstToBox);
                return float2(dstToBox, dstInsideBox);
            }

            float sampleDensity(float3 position) {
                float3 uvw = position * CloudScale * 0.001 + CloudOffset * 0.01;
                float4 shape = ShapeNoise.SampleLevel(samplerShapeNoise, uvw, 0);
                float density = max(0, shape.r - DensityThreshold) * DensityMultiplier;
                return density;
            }

            float lightmarch(float3 position)
            {
                float3 dirToLight = _WorldSpaceLightPos0.xyz;
                float dstInsideBox = rayBoxDst(BoundsMin, BoundsMax, position, 1/dirToLight).y;

                float stepSize = dstInsideBox / numStepsLight;
                float totalDensity = 0;

                for(int step = 0; step < numStepsLight; step ++)
                {
                    position += dirToLight * stepSize;
                    totalDensity += max(0, sampleDensity(position) * stepSize);
                }

                float transmittance = exp(-totalDensity * lightAbsorptionTowardSun);
                return darknessThreshold + transmittance * (1 - darknessThreshold);
            }

            //Henyey-Greenstein
            float hg(float a, float g)
            {
                return (1 - g * g) / (4 * 3.1415 * pow(1 + g * g - 2 * g * (a), 1.5));
            }

            float phase(float a)
            {
                float blend = 0.5;
                float hgBlend = hg(a, phaseParams.x) * (1 - blend) + hg(a, -phaseParams.y) * blend;
                return phaseParams.z + hgBlend * phaseParams.w;
            }

            float2 squareUV(float2 uv) {
                float width = _ScreenParams.x;
                float height =_ScreenParams.y;
                float scale = 1000;
                float x = uv.x * width;
                float y = uv.y * height;
                return float2 (x/scale, y/scale);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //Not modify
                fixed4 col = tex2D(_MainTex, i.uv);
                
                float3 rayOrigin = _WorldSpaceCameraPos;
                float3 rayDir = normalize(i.viewVector);

                float nonLinearDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
                float depth = LinearEyeDepth(nonLinearDepth) * length(i.viewVector);
                
                float2 rayBoxInfo = rayBoxDst(BoundsMin, BoundsMax, rayOrigin, rayDir);
                float dstToBox = rayBoxInfo.x;
                float dstInsideBox = rayBoxInfo.y;

                float dstTravelled = 0;
                float stepSize = dstInsideBox / NumSteps;
                float dstLimit = min(depth - dstToBox, dstInsideBox);

                float totalDensity = 0;
                while (dstTravelled < dstLimit) {
                    float3 rayPos = rayOrigin + rayDir * (dstToBox + dstTravelled);
                    totalDensity += sampleDensity(rayPos) * stepSize;
                    dstTravelled += stepSize;
                }
                float transmittance = exp(-totalDensity);
                return col * transmittance + (1-transmittance);

                //float3 rayPos = _WorldSpaceCameraPos;
                //float viewLength = length(i.viewVector);
                //float3 rayDir = i.viewVector / viewLength;

                //float screenDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
                //float depth = LinearEyeDepth(screenDepth) * viewLength;
                //float2 rayToContainerInfo = rayBoxDst(BoundsMin,BoundsMax,rayPos, 1/rayDir);
                //float dstToBox = rayToContainerInfo.x;
                //float dstInsideBox = rayToContainerInfo.y;

                //float3 rayHitPoint = rayPos + rayDir * dstToBox;

                //float randomOffset = BlueNoise.SampleLevel(samplerBlueNoise, squareUV(i.uv*3), 0);
                //randomOffset *= rayOffsetStrength;

                //float cosAngle = dot(rayDir, _WorldSpaceLightPos0.xyz);
                //float phaseVal =  phase(cosAngle);

                //float dstTravelled = randomOffset;
                //float dstLimit = min(depth - dstToBox, dstInsideBox);

                //const float stepSize = 11;

                //float transmittance = 1;
                //float3 lightEnergy = 0;

                //while (dstTravelled < dstLimit) {
                //    rayPos = rayHitPoint + rayDir * dstTravelled;
                //    float density = sampleDensity(rayPos);
                    
                //    if (density > 0) {
                //        float lightTransmittance = lightmarch(rayPos);
                //        lightEnergy += density * stepSize * transmittance * lightTransmittance * phaseVal;
                //        transmittance *= exp(-density * stepSize * lightAbsorptionThroughCloud);
                    
                //        if (transmittance < 0.01) {
                //            break;
                //        }
                //    }
                //    dstTravelled += stepSize;
                //}

                //float3 backgroundCol = tex2D(_MainTex,i.uv);
                //float3 cloudCol = lightEnergy * _LightColor0;
                //float3 col = backgroundCol * transmittance + cloudCol;
                //return float4(col,0);
            }
            ENDCG
        }
    }
}

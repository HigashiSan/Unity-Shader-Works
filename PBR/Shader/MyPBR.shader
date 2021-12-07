Shader "Unlit/MyPBR"
{
    Properties
    {
        _Color("Color",color) = (1,1,1,1)	
		_MainTex("Albedo",2D) = "white"{}	
		_MetallicGlossMap("Metallic",2D) = "white"{} 
		_BumpMap("Normal Map",2D) = "bump"{}
		_OcclusionMap("Occlusion",2D) = "white"{}
		_MetallicStrength("MetallicStrength",Range(0,1)) = 1 
		_GlossStrength("Smoothness",Range(0,1)) = 0.5 
		_BumpScale("Normal Scale",float) = 1 
        _EmissionColor("Color",color) = (0,0,0) 
		_EmissionMap("Emission Map",2D) = "white"{}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
			#pragma multi_compile_fog
         
            #include "UnityCG.cginc"
		    #include "Lighting.cginc"
		    #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent :TANGENT;
                float2 texcoord : TEXCOORD0;
                float2 texcoord1 : TEXCOORD1;
	            float2 texcoord2 : TEXCOORD2;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
                half4 ambientOrLightmapUV : TEXCOORD1;
				float4 TtoW0 : TEXCOORD2;
				float4 TtoW1 : TEXCOORD3;
				float4 TtoW2 : TEXCOORD4;
				SHADOW_COORDS(5)
				UNITY_FOG_COORDS(6)
            };

            half4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _MetallicGlossMap;
			sampler2D _BumpMap;
			sampler2D _OcclusionMap;
			half _MetallicStrength;
			half _GlossStrength;
			float _BumpScale;
			half4 _EmissionColor;
			sampler2D _EmissionMap;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                float3 worldPos = mul(unity_ObjectToWorld,v.vertex);
				float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				float3 worldTangent = UnityObjectToWorldDir(v.tangent);
				float3 worldBinormal = cross(worldNormal,worldTangent) * v.tangent.w;

                o.TtoW0 = float4(worldTangent.x,worldBinormal.x,worldNormal.x,worldPos.x);
				o.TtoW1 = float4(worldTangent.y,worldBinormal.y,worldNormal.y,worldPos.y);
				o.TtoW2 = float4(worldTangent.z,worldBinormal.z,worldNormal.z,worldPos.z);

				TRANSFER_SHADOW(o);
				UNITY_TRANSFER_FOG(o,o.pos);
                
                return o;
            }

            float3 ComputeDisneyDiffuseTerm(float nv,float nl,float lh,float roughness,float3 baseColor)
		    {
			    float Fd90 = 0.5f + 2 * roughness * lh * lh;
			    return baseColor * UNITY_INV_PI * (1 + (Fd90 - 1) * pow(1-nl,5)) * (1 + (Fd90 - 1) * pow(1-nv,5));
		    }

            //Geometry function
            float SmithJointGGX(half nl, half nv, half roughness)
            {
                half ag = roughness * roughness;
			    half lambdaV = nl * (nv * (1 - ag) + ag);
			    half lambdaL = nv * (nl * (1 - ag) + ag);
			
			    return 0.5f/(lambdaV + lambdaL + 1e-5f);
            }

            //Normal Distribution Function
            float NormalDistribution(half nh,half roughness)
            {
                float a = roughness * roughness;
			    float a2 = a * a;
			    float d = (a2 - 1.0f) * nh * nh + 1.0f;
			    return a2 * UNITY_INV_PI / (d * d + 1e-5f);
            }

            //Fresnel effect
            float3 ComputeFresnelTerm(half3 F0,half cosA)
            {
                return F0 + (1 - F0) * pow(1 - cosA, 5);
            }

			float3 fresnelSchlickRoughness(float cosTheta, float3 F0, float roughness)
			{
				return F0 + (max(float3(1 ,1, 1) * (1 - roughness), F0) - F0) * pow(1.0 - cosTheta, 5.0);
			}

			float CubeMapMip(float _Roughness)
			{
				float mip_roughness = _Roughness * (1.7 - 0.7 * _Roughness);
				half mip = mip_roughness * UNITY_SPECCUBE_LOD_STEPS; 
				return mip;
			}

            fixed4 frag (v2f i) : SV_Target
            {
                float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
				float3 albedo = tex2D(_MainTex,i.uv).rgb * _Color.rgb;
				float2 metallicGloss = tex2D(_MetallicGlossMap,i.uv).ra;
				float metallic = metallicGloss.x * _MetallicStrength;
				float roughness = 1 - metallicGloss.y * _GlossStrength;
				float occlusion = tex2D(_OcclusionMap,i.uv).g;
				float3 emission = tex2D(_EmissionMap,i.uv).rgb * _EmissionColor;

                float3 normalTangent = UnpackNormal(tex2D(_BumpMap,i.uv));
				normalTangent.xy *= _BumpScale;
				normalTangent.z = sqrt(1.0 - saturate(dot(normalTangent.xy,normalTangent.xy)));
				float3 worldNormal = normalize(half3(dot(i.TtoW0.xyz,normalTangent),dot(i.TtoW1.xyz,normalTangent),dot(i.TtoW2.xyz,normalTangent)));
                float3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				float3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				float3 refDir = reflect(-viewDir,worldNormal);

				UNITY_LIGHT_ATTENUATION(atten,i,worldPos);

                float3 halfDir = normalize(lightDir + viewDir);
				float nv = saturate(dot(worldNormal,viewDir));
				float nl = saturate(dot(worldNormal,lightDir));
				float nh = saturate(dot(worldNormal,halfDir));
				float lv = saturate(dot(lightDir,viewDir));
				float lh = saturate(dot(lightDir,halfDir));
                float vh = saturate(dot(viewDir,halfDir));

				float3 specColor = lerp(unity_ColorSpaceDielectricSpec.rgb,albedo,metallic);
				float oneMinusReflectivity = (1- metallic) * unity_ColorSpaceDielectricSpec.a;
				float3 diffColor = albedo * oneMinusReflectivity;

				//DirectLight
                float G = SmithJointGGX(nl,nv,roughness);
				float D = NormalDistribution(nh,roughness);
				float3 F = ComputeFresnelTerm(specColor,lh);
                float3 specularTerm = G * D * F;
                float3 diffuseTerm = ComputeDisneyDiffuseTerm(nv,nl,lh,roughness,diffColor);
				
				//Indirect Light
				float mipLevel = CubeMapMip(roughness);
				float4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, refDir, mipLevel);
				float3 IBLspecular = DecodeHDR(rgbm, unity_SpecCube0_HDR);
				
				float3 IBLdiffuse = ShadeSH9(float4(worldNormal,1));
				float3 Flast = fresnelSchlickRoughness(max(nv, 0.0), specColor, roughness);
                float kdLast = (1 - Flast) * (1 - metallic);                   

                float3 iblDiffuseResult = IBLdiffuse * kdLast * albedo;


				float3 color = UNITY_PI * (diffuseTerm + specularTerm) * _LightColor0.rgb * nl * atten + emission
								+ IBLspecular + iblDiffuseResult;

				UNITY_APPLY_FOG(i.fogCoord, color.rgb);
                return float4(color, 1.0);
            }
            ENDCG
        }
    }
}

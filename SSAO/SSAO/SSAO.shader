Shader "SS/SSAO"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }

    CGINCLUDE

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
		float3 viewVec : TEXCOORD1;
    };

    #define MAXTIMES 64
    sampler2D _CameraDepthNormalsTexture;
    sampler2D _NoiseTex;
    float4 _SampleArray[MAXTIMES];
    float _SampleTimes;
    float _HalfSphereRadius;
    float _AOStrength;
    float _GenAoDistance;
    float _DepthOffset;

    v2f AOvert (appdata v)
    {
        v2f o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.uv = v.uv;
        float4 screenPos = ComputeScreenPos(o.vertex);
        float4 ndcPos = (screenPos / screenPos.w) * 2.0 - 1.0;
        float3 clipVec = float3(ndcPos.x, ndcPos.y, 1.0) * _ProjectionParams.z;
        o.viewVec = mul(unity_CameraInvProjection, clipVec.xyzz).xyz;
        return o;
    }

    fixed4 AOfrag (v2f i) : SV_Target
    {
		float3 viewNormal;
        float centerPosDepth;
        float4 depthAndNormal = tex2D(_CameraDepthNormalsTexture, i.uv);
        DecodeDepthNormal(depthAndNormal, centerPosDepth, viewNormal);

        float3 viewPos = centerPosDepth * i.viewVec;
        viewNormal = normalize(viewNormal) * float3(1,1,-1);

		float2 noiseScale = _ScreenParams.xy / 4.0;
        float2 noiseUV = i.uv * noiseScale;
        float3 randomVec = tex2D(_NoiseTex, noiseUV).xyz;
        float3 tangent = normalize(randomVec - viewNormal * dot(randomVec, viewNormal));
        float3 bitangent = cross(viewNormal, tangent);
        float3x3 TBN = float3x3(tangent, bitangent, viewNormal);

		float aoValue = 0;
		int sampleTimes = _SampleTimes;
		for(int i=0;i<sampleTimes;i++){
			float3 randomSampleVec = mul(_SampleArray[i].xyz, TBN);
            float weight = smoothstep(0,0.1,length(randomSampleVec.xy));

            float4 randomSamplePos = float4(viewPos + randomSampleVec * _HalfSphereRadius, 1.0);
            float4 clipPos = mul(unity_CameraProjection, randomSamplePos);
            float2 screenPos = (clipPos.xy / clipPos.w) * 0.5 + 0.5;

            float samplePosDepth;
            float3 samplePosNormal;
            float4 samplePosDepthAndNormal = tex2D(_CameraDepthNormalsTexture, screenPos);
            DecodeDepthNormal(samplePosDepthAndNormal, samplePosDepth, samplePosNormal);

            float AoDst = abs(samplePosDepth - centerPosDepth) > _GenAoDistance ? 0.0 : 1.0;
			float selfCheck = samplePosDepth + _DepthOffset < centerPosDepth ? 1.0 : 0.0;

			aoValue += AoDst * selfCheck * weight;
		}
		aoValue /= sampleTimes;
        aoValue = max(0.0, 1.0 - aoValue * _AOStrength);
        return float4(aoValue, aoValue, aoValue, 1.0);
    }

    sampler2D _MainTex;
    float4 _MainTex_TexelSize;
    float2 _BlurRadius;
    float _BlurTensity;
    float _BilaterFilterFactor;
   
    float3 GetNormal(float2 uv)
	{
		float4 cdn = tex2D(_CameraDepthNormalsTexture, uv);	
		return DecodeViewNormalStereo(cdn);
	}

	half CompareNormal(float3 nor1,float3 nor2)
	{
		return smoothstep(_BilaterFilterFactor,1.0,dot(nor1,nor2));
	}
	
	fixed4 Blurfrag (v2f i) : SV_Target
	{	
		float2 delta = _MainTex_TexelSize.xy * _BlurRadius.xy;
		
		float2 uv = i.uv;
		float2 uv0a = i.uv - delta;
		float2 uv0b = i.uv + delta;	
		float2 uv1a = i.uv - 2.0 * delta;
		float2 uv1b = i.uv + 2.0 * delta;
		float2 uv2a = i.uv - 3.0 * delta;
		float2 uv2b = i.uv + 3.0 * delta;
		
		float3 normal = GetNormal(uv);
		float3 normal0a = GetNormal(uv0a);
		float3 normal0b = GetNormal(uv0b);
		float3 normal1a = GetNormal(uv1a);
		float3 normal1b = GetNormal(uv1b);
		float3 normal2a = GetNormal(uv2a);
		float3 normal2b = GetNormal(uv2b);
		
		fixed4 col = tex2D(_MainTex, uv);
		fixed4 col0a = tex2D(_MainTex, uv0a);
		fixed4 col0b = tex2D(_MainTex, uv0b);
		fixed4 col1a = tex2D(_MainTex, uv1a);
		fixed4 col1b = tex2D(_MainTex, uv1b);
		fixed4 col2a = tex2D(_MainTex, uv2a);
		fixed4 col2b = tex2D(_MainTex, uv2b);
		
		half w = 0.37004405286;
		half w0a = CompareNormal(normal, normal0a) * 0.31718061674;
		half w0b = CompareNormal(normal, normal0b) * 0.31718061674;
		half w1a = CompareNormal(normal, normal1a) * 0.19823788546;
		half w1b = CompareNormal(normal, normal1b) * 0.19823788546;
		half w2a = CompareNormal(normal, normal2a) * 0.11453744493;
		half w2b = CompareNormal(normal, normal2b) * 0.11453744493;
		
		half3 result;
		result = w * col.rgb;
		result += w0a * col0a.rgb;
		result += w0b * col0b.rgb;
		result += w1a * col1a.rgb;
		result += w1b * col1b.rgb;
		result += w2a * col2a.rgb;
		result += w2b * col2b.rgb;
		
		result /= w + w0a + w0b + w1a + w1b + w2a + w2b;
		return fixed4(result, 1.0);
	}

    sampler2D _AoTexture;

    fixed4 Combinefrag(v2f i) : SV_Target
    {
        fixed4 col = tex2D(_MainTex, i.uv);
        fixed4 ao = tex2D(_AoTexture, i.uv);

        col.rgb *= ao.r;
        return col;
    }

    ENDCG

    SubShader
    {
        Cull Off ZWrite Off ZTest Always

        //AO Pass
        Pass
        {
            CGPROGRAM
            #pragma vertex AOvert
            #pragma fragment AOfrag
            
            ENDCG
        }

        //Blur Pass
        Pass
        {
            CGPROGRAM
            #pragma vertex AOvert
            #pragma fragment Blurfrag
            ENDCG
        }

        //Combine Pass
        Pass
        {
            CGPROGRAM
            #pragma vertex AOvert
            #pragma fragment Combinefrag
            ENDCG
        }
    }
}

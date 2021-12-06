Shader "Test/Tessellation Test"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_TessellationUniform ("Tessellation Uniform", Range(1, 64)) = 1
	}
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#pragma hull hull
			#pragma domain custom_domain

			#pragma geometry geo

			#pragma target 4.6
			
			#include "UnityCG.cginc"

			struct vertexInput
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
			};

			struct vertexOutput
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float2 uv : TEXCOORD0;
			};

			struct TessellationFactors 
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			struct geometryOutput
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			vertexInput vert(vertexInput v)
			{
				return v;
			}

			vertexOutput tessVertTransformed(vertexInput v)
			{
				vertexOutput o;
				o.vertex = v.vertex;
				o.normal = v.normal;
				o.tangent = v.tangent;
				o.uv = v.uv;
				return o;
			}

			float _TessellationUniform;

			TessellationFactors patchConstantFunction (InputPatch<vertexInput, 3> patch)
			{
				TessellationFactors f;
				f.edge[0] = _TessellationUniform;
				f.edge[1] = _TessellationUniform;
				f.edge[2] = _TessellationUniform;
				f.inside = _TessellationUniform;
				return f;
			}
			
			[UNITY_domain("tri")]
			[UNITY_outputcontrolpoints(3)]
			[UNITY_outputtopology("triangle_cw")]
			[UNITY_partitioning("integer")]
			[UNITY_patchconstantfunc("patchConstantFunction")]
			vertexInput hull (InputPatch<vertexInput, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[UNITY_domain("tri")]
			vertexOutput custom_domain(TessellationFactors factors, OutputPatch<vertexInput, 3> patch, float3 barycentricCoordinates : SV_DomainLocation)
			{
				vertexInput v;

				#define MY_DOMAIN_PROGRAM_INTERPOLATE(fieldName) v.fieldName = \
					patch[0].fieldName * barycentricCoordinates.x + \
					patch[1].fieldName * barycentricCoordinates.y + \
					patch[2].fieldName * barycentricCoordinates.z;

				MY_DOMAIN_PROGRAM_INTERPOLATE(vertex)
				MY_DOMAIN_PROGRAM_INTERPOLATE(normal)
				MY_DOMAIN_PROGRAM_INTERPOLATE(tangent)

				return tessVertTransformed(v);
			}

			[maxvertexcount(3)]
			void geo(triangle vertexOutput IN[3] , inout TriangleStream<geometryOutput> triStream)
			{
				geometryOutput o;

				for(int i=0; i<3; i++)
				{
					o.vertex = UnityObjectToClipPos(IN[i].vertex);
					o.uv = IN[i].uv;
					triStream.Append(o);
				}
			}

			float4 _Color;
			
			float4 frag (vertexOutput i) : SV_Target
			{
				return _Color;
			}
			ENDCG
		}
	}
}

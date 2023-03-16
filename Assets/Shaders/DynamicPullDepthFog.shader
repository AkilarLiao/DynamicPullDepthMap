Shader "CustomURP/DynamicPullDepthCloudSea"
{
    Properties
    {
        _FogDepth("FogDepth", Range(0.0, 5.0)) = 1.5
        _FogDepthPow("FogDepthPow", Range(1.0, 10.0)) = 2
        _FogPlaneOffestHeight("FogPlaneOffestHeight", Range(0.0, 10.0)) = 1
        _FogColor("FogColor", Color) = (1, 1, 1, 1)
        _PerlinWorldScale("PerlinWorldScale", Range(0.1, 10.0)) = 1.0
        _PerlinNoiseSpeed("PerlinNoiseSpeed", Range(0.0, 10.0)) = 0.5
        _PerlinRnageRatio("PerlinRnageRatio", Range(0.1, 100.0)) = 20.0
        _DepthVisibility("DepthVisibility", Range(0.0, 1.0)) = 0.0
    }
    SubShader
    {
        Tags 
        {            
           "RenderType" = "Transparent"
           "Queue" = "Transparent"
        }
        Pass
        {            
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            HLSLPROGRAM
            #pragma vertex VertexProgram
            #pragma fragment FragmentProgram
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "UtilityFunctions.hlsl"
            
            struct VertexInput
            {
                float4 positionOS : POSITION; 
                float2 texcoordOS : TEXCOORD0;
            };

            struct VertexOutput
            {
                float4 positionCS : SV_POSITION;
                float3 worldPosition : TEXCOORD0;
                float4 screenPosition : TEXCOORD1;
            };
            
            CBUFFER_START(UnityPerMaterial)
            float _FogDepth;
            float _FogDepthPow;
            float _FogPlaneOffestHeight;
            float _PerlinWorldScale;
            float _PerlinNoiseSpeed;
            float _PerlinRnageRatio;            
            half3 _FogColor;
            half _DepthVisibility;
            CBUFFER_END

            half ProcessDepthRatio(float2 screenUV, float waterSurfaceHeight)
            {   
                float3 groundPosition = GetDepthToWorldPosition(screenUV);
                float sourceHeight = min(groundPosition.y, waterSurfaceHeight);
                float depthRatio = saturate((waterSurfaceHeight - groundPosition.y) / _FogDepth);
                depthRatio = 1.0 - pow(1.0 - depthRatio, _FogDepthPow);
                return depthRatio;
            }

            VertexOutput VertexProgram(VertexInput input)
            {
                VertexOutput output;
                output.worldPosition = TransformObjectToWorld(input.positionOS.xyz);
                output.positionCS = TransformWorldToHClip(output.worldPosition);
                output.screenPosition = ComputeScreenPos(output.positionCS);
                return output;
            }

            half4 FragmentProgram(VertexOutput input) : SV_Target
            {
                real2 screenUV = input.screenPosition.xy / input.screenPosition.w;
                float origionHeight = input.worldPosition.y;                
                float3 worldPosition = input.worldPosition;
                float2 offestPosition = worldPosition.xz * _PerlinWorldScale + _Time.y * _PerlinNoiseSpeed;
                worldPosition.y += snoise(offestPosition) * _PerlinRnageRatio - _FogPlaneOffestHeight;
                float depthRatio = ProcessDepthRatio(screenUV, worldPosition.y);
                half3 resultColor = _FogColor;

                return lerp(half4(_FogColor, depthRatio),
                    half4(depthRatio, 0.0, 0.0, 1.0), _DepthVisibility);
            }
            ENDHLSL
        }
    }
}

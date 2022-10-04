Shader "Unlit/CardUnlitShader"
{
    Properties
    {
        _BackgroundTex ("Background Texture", 2D) = "black" {}
        _SubjectTex ("Subject Texture", 2D) = "black" {}
        _SineTex ("Sine Texture", 2D) = "black" {}
        _SineAmplitude ("Amplitude", float) = 0
        _SineSpeed ("Speed", float) = 1
        _ScrollingTex ("Scrolling Texture", 2D) = "black" {}
        _DistortedTex ("Distorted Texture", 2D) = "black" {}
        _DistortionMap ("Distortion Map", 2D) = "black" {}
        _DistortionMask ("Distortion Mask", 2D) = "black" {}
        _DistortionStrength("Distortion Strength", Vector) = (1, 1, 0, 0)
        _DistortionSpeed("Distortion Speed", Vector) = (0, 0, 0, 0)

    }
    SubShader
    {
        Tags { "RenderType"="Transparent" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _BackgroundTex;
            float4 _BackgroundTex_ST;
            sampler2D _SubjectTex;
            sampler2D _SineTex;
            sampler2D _ScrollingTex;
            sampler2D _DistortedTex;
            sampler2D _DistortionMap;
            sampler2D _DistortionMask;
            float4 _DistortionMap_ST;
            float2 _DistortionStrength, _DistortionSpeed;

            float _SineAmplitude;
            float _SineSpeed;

            float2 FlowUV (float2 uv, float2 flowVector, float time) {
                float progress = frac(time);
	            return uv - flowVector * progress;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _BackgroundTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 bg = tex2D(_BackgroundTex, i.uv);
                fixed4 subject = tex2D(_SubjectTex, i.uv);
                float2 offset = (0, sin(_Time * _SineSpeed) * _SineAmplitude);
                fixed4 sine = tex2D(_SineTex, i.uv + offset);
                fixed4 scrolling = tex2D(_ScrollingTex, i.uv);

                float distortionMask = 1 - tex2D(_DistortionMask, i.uv).a;
                float2 distortionOffset = float2(_DistortionSpeed.x * _Time.x, _DistortionSpeed.y * _Time.x);
                float2 distortedUVs = tex2D(_DistortionMap, i.uv + distortionOffset) * _DistortionStrength * distortionMask;
                fixed4 distorted = tex2D(_DistortedTex, distortedUVs + i.uv);

                fixed4 combined2 = bg * (1 - saturate(subject.a + sine.a + scrolling.a + distorted.a))
                                + subject * (subject.a * (1 - saturate(sine.a + scrolling.a + distorted.a)))
                                + sine * (sine.a * (1 - saturate(scrolling.a + distorted.a)))
                                + scrolling * (scrolling.a * (1 - distorted.a))
                                + distorted * distorted.a;
                
                
                // apply fog
                // UNITY_APPLY_FOG(i.fogCoord, col);
                return combined2;
            }
            ENDCG
        }
    }
}

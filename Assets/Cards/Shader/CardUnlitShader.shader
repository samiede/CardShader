Shader "Unlit/CardUnlitShader"
{
    Properties
    {
        _ImageAspectRatio("Image Aspect Ratio", float) = 1.5
        _ModelAspectRatio("Model Aspect Ratio", float) = 1.5
        _BackgroundTex ("Background Texture", 2D) = "black" {}
        [NoScaleOffset]_SubjectTex ("Subject Texture", 2D) = "black" {}
        _SubjectParallax("Subject Parallax", float) = 0
        [NoScaleOffset]_SineTex ("Sine Texture", 2D) = "black" {}
        [NoScaleOffset]_SineOffsetTex ("Sine Offset Texture", 2D) = "black" {}
        [MaterialToggle] _SubjectMasksSine("Subject Masks SineTex", Float) = 0
        _SineParallax("Sine Parallax", float) = 0
        _SineAmplitude ("Amplitude", float) = 0
        _SineSpeed ("Speed", float) = 1
        [MaterialToggle] _OffsetSineByMask("Offset Sine by Mask", Float) = 0
        [NoScaleOffset]_ScrollingTex ("Scrolling Texture", 2D) = "black" {}
        _ScrollingSpeed("Scrolling Speed", Vector) = (0, 0, 0, 0)
        [MaterialToggle] _SubjectMasksScrolling("Subject Masks ScrollingTex", Float) = 0
        _ScrollingParallax("Scrolling Parallax", float) = 0
        [NoScaleOffset]_DistortedTex ("Distorted Texture", 2D) = "black" {}
        [MaterialToggle] _SubjectMasksDistorted("Subject Masks Distorted", Float) = 0
        [MaterialToggle] _OffsetDistortedWithSine("Offset Distorted with Sine", Float) = 0
        [MaterialToggle] _UseFlowMapForDistortion("Use Flow Map For Distortion", Float) = 0
        _DistortedParallax("Distorted Parallax", float) = 0
        [NoScaleOffset]_DistortionMap ("Distortion Map", 2D) = "black" {}
        [NoScaleOffset]_DistortionMask ("Distortion Mask", 2D) = "black" {}
        _DistortionStrength("Distortion Strength", Vector) = (1, 1, 0, 0)
        _DistortionSpeed("Distortion Speed", Vector) = (0, 0, 0, 0)
        [NoScaleOffset] _FlowmapTex ("Flowmap Texture", 2D) = "black" {}
        _UJump ("U jump per phase", Range(-0.25, 0.25)) = 0.25
		_VJump ("V jump per phase", Range(-0.25, 0.25)) = 0.25
        _FlowMapTiling ("Flow Map Tiling", Float) = 1
        _FlowMapSpeed("Flowmap Speed", float) = 0
        _FlowMapStrength("Flowmap Strength", float) = 0
        _FlowOffset ("Flow Offset", Float) = 0


        [MaterialToggle] _parallaxWithTranslation("Parallax with Translation", Float) = 0

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
                float3 normal: NORMAL;
                float4 tangent: TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float2 viewDir : TEXCOORD1;
            };

            float _ImageAspectRatio, _ModelAspectRatio;

            sampler2D _BackgroundTex;
            float4 _BackgroundTex_ST;
            sampler2D _SubjectTex;
            sampler2D _SineTex;
            sampler2D _SineOffsetTex;
            float _SubjectMasksSine;
            sampler2D _ScrollingTex;
            float _SubjectMasksScrolling;
            sampler2D _DistortedTex;
            float _SubjectMasksDistorted;
            sampler2D _DistortionMap;
            sampler2D _DistortionMask;
            float4 _DistortionMap_ST;
            float2 _DistortionStrength, _DistortionSpeed;
            sampler2D _FlowmapTex;
            float _UJump, _VJump, _FlowMapTiling;
            float _FlowMapStrength, _FlowMapSpeed, _FlowOffset;

            float _SineAmplitude;
            float _SineSpeed;
            float _SineOffsetByMask;
            float _SubjectParallax, _SineParallax, _ScrollingParallax, _DistortedParallax, _parallaxWithTranslation;

            float2 _ScrollingSpeed;
            float _OffsetDistortedWithSine, _UseFlowMapForDistortion;


            float2 toPolar(float2 cartesian){
                
	            float distance = length(cartesian);
	            float angle = atan2(cartesian.y, cartesian.x);
	            return float2(angle / UNITY_TWO_PI, distance);
            }

            float2 toCartesian(float2 polar){
                float2 cartesian;
                sincos(polar.x * UNITY_TWO_PI, cartesian.y, cartesian.x);
                return cartesian * polar.y;
            }

            float3 FlowUVW (float2 uv, float2 flowVector, float2 jump, float flowOffset, float tiling, float time, bool flowB) {
	            float phaseOffset = flowB ? 0.5 : 0;
	            float progress = frac(time + phaseOffset);
	            float3 uvw;
	            uvw.xy = uv - flowVector * (progress + flowOffset);
                uvw.xy *= tiling;
	            uvw.xy += phaseOffset;
                uvw.xy += (time - progress) * jump;
                uvw.z = 1 - abs(1 - 2 * progress);
                return uvw;
            }
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                float4 objCam = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1.0));
                float3 viewDir = objCam.xyz;
                float tangentSign = v.tangent.w * unity_WorldTransformParams.w;
                float3 bitangent = cross(v.normal.xyz, v.tangent.xyz) * tangentSign;
                float3 viewDirTangent = float3(
                    dot(viewDir, v.tangent.xyz),
                    dot(viewDir, bitangent.xyz),
                    dot(viewDir, v.normal.xyz)
                );
                
                float3 cameraForward =  -UNITY_MATRIX_I_V._m02_m12_m22;
                cameraForward = mul(unity_WorldToObject, cameraForward);
                o.viewDir = lerp(cameraForward.xy, viewDirTangent, _parallaxWithTranslation);
                float ratio = _ModelAspectRatio/_ImageAspectRatio;
                v.uv = v.uv * float2(1, ratio);
                o.uv = TRANSFORM_TEX(v.uv, _BackgroundTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 bg = tex2D(_BackgroundTex, i.uv);
                const float2 subjectParallaxOffset =  -i.viewDir * _SubjectParallax;
                fixed4 subject = tex2D(_SubjectTex, i.uv + subjectParallaxOffset);

                const float2 sineParallaxOffset = -i.viewDir * _SineParallax;
                // TODO make sine also oscillate in x direction 
                float2 sineOffset = (0, sin(_Time * _SineSpeed + step(0.5, _SineOffsetByMask) * tex2D(_SineOffsetTex, i.uv).a * 7) * _SineAmplitude);
                fixed4 sine = tex2D(_SineTex, i.uv + sineOffset + sineParallaxOffset);

                const float2 scrollingParallaxOffset = -i.viewDir * _ScrollingParallax;
                const float2 scrollingTimeOffset =  - _ScrollingSpeed * _Time.x;
                fixed4 scrolling = tex2D(_ScrollingTex, i.uv + scrollingParallaxOffset + scrollingTimeOffset);

                const float2 distortedParallaxOffset = -i.viewDir * _DistortedParallax;

                fixed4 distorted;
                if (_UseFlowMapForDistortion)
                {
                    float3 flowVectorAndAlpha = tex2D(_FlowmapTex, i.uv + distortedParallaxOffset).rga;
                    float2 flowVector = flowVectorAndAlpha.xy * 2 - 1;
                    flowVector *= _FlowMapStrength;
                    float time = _Time.y * _FlowMapSpeed;

                    float2 jump = float2(_UJump, _VJump);

			        float3 uvwA = FlowUVW(i.uv, flowVector, jump, _FlowOffset, _FlowMapTiling, time, false);
			        float3 uvwB = FlowUVW(i.uv, flowVector, jump, _FlowOffset, _FlowMapTiling, time, true);

			        fixed4 texA = tex2D(_DistortedTex, uvwA.xy) * uvwA.z;
			        fixed4 texB = tex2D(_DistortedTex, uvwB.xy) * uvwB.z;
                    
                    distorted = texA + texB;
                } else
                {
                    float distortionMask = 1 - tex2D(_DistortionMask, i.uv + distortedParallaxOffset).a;
                    float2 distortionOffset = float2(_DistortionSpeed.x * _Time.x, _DistortionSpeed.y * _Time.x);
                
                    float2 distortedUVs = tex2D(_DistortionMap, i.uv + distortionOffset) * _DistortionStrength * distortionMask;
                    distorted = tex2D(_DistortedTex, distortedUVs + i.uv + distortedParallaxOffset + step(0.5, _OffsetDistortedWithSine) * sineOffset);
                }

                
                fixed4 combined2 = bg * (1 - saturate(subject.a + sine.a + scrolling.a + distorted.a))
                                + subject * (subject.a * (1 - saturate(
                                    lerp(0, sine.a, 1 - _SubjectMasksSine) +
                                    lerp(0, scrolling.a, 1 - _SubjectMasksScrolling) +
                                    lerp(0, distorted.a, 1 - _SubjectMasksDistorted))))
                                + sine * (sine.a * (1 - saturate(lerp(0, subject.a, _SubjectMasksSine) + scrolling.a + distorted.a)))
                                + scrolling * (scrolling.a * (1 - saturate(lerp(0, subject.a, _SubjectMasksScrolling) + distorted.a)))
                                + distorted * distorted.a * (1 - lerp(0, subject.a, _SubjectMasksDistorted));
                
                
                // apply fog
                // UNITY_APPLY_FOG(i.fogCoord, col);
                return combined2;
            }
            ENDCG
        }
    }
}

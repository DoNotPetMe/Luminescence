// =====================================================================
//  Luminescence  —  a high-quality PBR shader for VRChat avatars
//  Reflections · Wetness · Sweat · Emissive glow · Rim · Matcap · SSS
//
//  Render pipeline : Built-in (the pipeline VRChat uses)
//  Editor UI       : Editor/LuminescenceGUI.cs
// =====================================================================
Shader "Luminescence/Avatar"
{
    Properties
    {
        [Header(Base)]
        _MainTex            ("Albedo", 2D) = "white" {}
        _Color              ("Tint", Color) = (1,1,1,1)
        _Saturation         ("Saturation", Range(0,2)) = 1
        _Brightness         ("Albedo Brightness", Range(0,2)) = 1
        [Toggle(_ALPHATEST_ON)] _AlphaTest ("Alpha Cutout", Float) = 0
        _Cutoff             ("Cutout Threshold", Range(0,1)) = 0.5

        [Header(Normal and Detail)]
        [Toggle(_NORMALMAP)] _NormalToggle ("Enable Normal Map", Float) = 0
        [Normal] _BumpMap   ("Normal Map", 2D) = "bump" {}
        _BumpScale          ("Normal Strength", Range(0,4)) = 1
        [Toggle(_DETAIL_MAP)] _DetailToggle ("Enable Detail", Float) = 0
        _DetailAlbedoMap    ("Detail Albedo (x2)", 2D) = "grey" {}
        [Normal] _DetailNormalMap ("Detail Normal", 2D) = "bump" {}
        _DetailNormalMapScale ("Detail Normal Strength", Range(0,4)) = 1
        _DetailMask         ("Detail Mask (A)", 2D) = "white" {}

        [Header(Surface PBR)]
        [Toggle(_METALLICGLOSSMAP)] _MetalToggle ("Enable Metallic Map", Float) = 0
        _MetallicGlossMap   ("Metallic (R) Smoothness (A)", 2D) = "white" {}
        _Metallic           ("Metallic", Range(0,1)) = 0
        _Glossiness         ("Smoothness", Range(0,1)) = 0.5
        _GlossMapScale      ("Smoothness (map) Scale", Range(0,1)) = 1
        _SpecularTint       ("Specular Tint by Albedo", Range(0,1)) = 0
        [Toggle(_OCCLUSIONMAP)] _OcclToggle ("Enable Occlusion", Float) = 0
        _OcclusionMap       ("Occlusion (G)", 2D) = "white" {}
        _OcclusionStrength  ("Occlusion Strength", Range(0,1)) = 1

        [Header(Reflections)]
        [Toggle(_GLOSSYREFLECTIONS_OFF)] _NoReflections ("Disable Reflections", Float) = 0
        _ReflectionStrength ("Reflection Strength", Range(0,4)) = 1
        _ReflectionTint     ("Reflection Tint", Color) = (1,1,1,1)
        _ReflectionFresnel  ("Fresnel (edge boost)", Range(0,1)) = 1
        _SpecularOcclusion  ("Specular Occlusion", Range(0,1)) = 1
        _Cubemap            ("Fallback Cubemap", Cube) = "" {}
        _CubemapBlend       ("Use Fallback Cubemap", Range(0,1)) = 0
        [Toggle(_SPECULARHIGHLIGHTS_OFF)] _NoSpecHi ("Disable Specular Highlights", Float) = 0

        [Header(Clear Coat)]
        [Toggle(_CLEARCOAT_ON)] _ClearCoatToggle ("Enable Clear Coat", Float) = 0
        _ClearCoat          ("Coat Strength", Range(0,1)) = 1
        _ClearCoatSmoothness("Coat Smoothness", Range(0,1)) = 0.9
        _ClearCoatColor     ("Coat Tint", Color) = (1,1,1,1)

        [Header(Anisotropy)]
        [Toggle(_ANISOTROPY_ON)] _AnisoToggle ("Enable Anisotropy", Float) = 0
        _Anisotropy         ("Anisotropy", Range(-1,1)) = 0.5
        _AnisoAngle         ("Anisotropy Angle", Range(0,6.2831)) = 0

        [Header(Iridescence)]
        [Toggle(_IRIDESCENCE_ON)] _IridToggle ("Enable Iridescence", Float) = 0
        _Iridescence        ("Iridescence", Range(0,1)) = 0.5
        _IridescenceFreq    ("Color Frequency", Range(1,12)) = 4
        _IridescenceShift   ("Hue Shift", Range(0,1)) = 0

        [Header(Parallax Depth)]
        [Toggle(_PARALLAX_ON)] _ParallaxToggle ("Enable Parallax", Float) = 0
        _ParallaxMap        ("Height (G)", 2D) = "grey" {}
        _Parallax           ("Height Scale", Range(0,1)) = 0.2

        [Header(Fresnel Glow)]
        [HDR] _FresnelGlowColor ("Glow Color", Color) = (0,0,0,1)
        _FresnelGlowPower   ("Glow Width", Range(0.1,16)) = 4
        _FresnelGlowStrength("Glow Strength", Range(0,8)) = 0

        [Header(Emission Glow)]
        [Toggle(_EMISSION)] _EmissionToggle ("Enable Emission", Float) = 0
        _EmissionMap        ("Emission Map", 2D) = "white" {}
        [HDR] _EmissionColor("Emission Color", Color) = (0,0,0,1)
        _EmissionStrength   ("Emission Strength", Range(0,16)) = 1
        _EmissionPulseSpeed ("Pulse Speed", Range(0,16)) = 0
        _EmissionPulseMin   ("Pulse Floor", Range(0,1)) = 0.5
        _EmissionScroll     ("Emission Scroll (xy)", Vector) = (0,0,0,0)
        _EmissionGradientStrength ("Gradient Boost", Range(0,1)) = 0

        [Header(Wetness)]
        [Toggle(_WETNESS_ON)] _WetnessToggle ("Enable Wetness", Float) = 0
        _WetnessMask        ("Wetness Mask (R)", 2D) = "white" {}
        _Wetness            ("Wetness", Range(0,1)) = 0
        _WetnessSmoothness  ("Wet Smoothness", Range(0,1)) = 0.95
        _WetnessColor       ("Wet Darkening Color", Color) = (0.5,0.5,0.5,1)
        _WetnessMetallic    ("Wet Metallic", Range(0,1)) = 0.1
        _WetnessUpAccumulation ("Top-face Pooling", Range(0,1)) = 0
        _DropletNormal      ("Droplet Normal", 2D) = "bump" {}
        _DropletStrength    ("Droplet Strength", Range(0,2)) = 0.5

        [Header(Sweat)]
        [Toggle(_SWEAT_ON)] _SweatToggle ("Enable Sweat", Float) = 0
        _SweatMask          ("Sweat Mask (R)", 2D) = "black" {}
        _SweatAmount        ("Sweat Amount", Range(0,1)) = 0
        _SweatSpeed         ("Trickle Speed", Range(0,2)) = 0.2
        _SweatSparkle       ("Sparkle Intensity", Range(0,4)) = 1
        _SweatScale         ("Sweat Tiling", Range(0.1,16)) = 4

        [Header(Rim Light)]
        [Toggle(_RIM_ON)] _RimToggle ("Enable Rim", Float) = 0
        [HDR] _RimColor     ("Rim Color", Color) = (1,1,1,1)
        _RimPower           ("Rim Width", Range(0.1,16)) = 4
        _RimStrength        ("Rim Strength", Range(0,8)) = 1
        _RimBias            ("Rim Light Bias", Range(0,1)) = 0

        [Header(Matcap)]
        [Toggle(_MATCAP_ON)] _MatcapToggle ("Enable Matcap", Float) = 0
        _Matcap             ("Matcap", 2D) = "black" {}
        _MatcapStrength     ("Matcap Strength", Range(0,4)) = 1
        _MatcapBlend        ("Add (0) - Multiply (1)", Range(0,1)) = 0

        [Header(Subsurface)]
        [Toggle(_SSS_ON)] _SSSToggle ("Enable SSS", Float) = 0
        _ThicknessMap       ("Thickness", 2D) = "white" {}
        [HDR] _SSSColor     ("SSS Color", Color) = (1,0.3,0.2,1)
        _SSSStrength        ("SSS Strength", Range(0,4)) = 1
        _SSSPower           ("SSS Falloff", Range(0.1,16)) = 4
        _SSSScale           ("SSS Distortion", Range(0,1)) = 0.5

        [Header(Color Grading)]
        _Exposure           ("Exposure", Range(0,4)) = 1
        _Contrast           ("Contrast", Range(0,2)) = 1
        _FinalSaturation    ("Saturation", Range(0,2)) = 1
        _Vibrance           ("Vibrance", Range(0,2)) = 0
        _HueShift           ("Hue Shift", Range(-3.1416,3.1416)) = 0
        [Toggle(_TONEMAP_ON)] _TonemapToggle ("Filmic Tonemap", Float) = 0

        [Header(Lighting)]
        _LightingDirectional("Directional Response", Range(0,1)) = 1
        _MinBrightness      ("Min Brightness", Range(0,1)) = 0.05
        _MaxBrightness      ("Max Brightness", Range(1,8)) = 4
        _ShadowBoost        ("Shadow Lift", Range(0,1)) = 0

        [Header(Animation)]
        _PulseSpeed         ("Vertex Pulse Speed", Range(0,16)) = 0
        _PulseAmount        ("Vertex Pulse Amount", Range(0,4)) = 0

        [Header(Rendering)]
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Float) = 2
        [Enum(Off,0,On,1)] _ZWrite ("ZWrite", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src Blend", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst Blend", Float) = 0
        [Toggle(_ALPHAPREMULTIPLY_ON)] _Premultiply ("Premultiply Alpha", Float) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Float) = 4
        _RenderQueue        ("Render Queue Hint", Float) = 2000
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" "VRCFallback"="Standard" }
        LOD 300

        // -------------------------------------------------------------
        //  Base forward pass (ambient + main directional + GI + reflections)
        // -------------------------------------------------------------
        Pass
        {
            Name "FORWARD_BASE"
            Tags { "LightMode"="ForwardBase" }
            Cull   [_Cull]
            ZWrite [_ZWrite]
            ZTest  [_ZTest]
            Blend  [_SrcBlend] [_DstBlend]

            CGPROGRAM
            #pragma target 4.0
            #pragma vertex vert
            #pragma fragment fragForward

            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #pragma multi_compile _ VERTEXLIGHT_ON

            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _DETAIL_MAP
            #pragma shader_feature_local _METALLICGLOSSMAP
            #pragma shader_feature_local _OCCLUSIONMAP
            #pragma shader_feature_local _EMISSION
            #pragma shader_feature_local _WETNESS_ON
            #pragma shader_feature_local _SWEAT_ON
            #pragma shader_feature_local _RIM_ON
            #pragma shader_feature_local _MATCAP_ON
            #pragma shader_feature_local _SSS_ON
            #pragma shader_feature_local _CLEARCOAT_ON
            #pragma shader_feature_local _ANISOTROPY_ON
            #pragma shader_feature_local _IRIDESCENCE_ON
            #pragma shader_feature_local _PARALLAX_ON
            #pragma shader_feature_local _TONEMAP_ON
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local _ALPHAPREMULTIPLY_ON
            #pragma shader_feature_local _GLOSSYREFLECTIONS_OFF
            #pragma shader_feature_local _SPECULARHIGHLIGHTS_OFF

            #include "LumiCore.cginc"
            ENDCG
        }

        // -------------------------------------------------------------
        //  Additive forward pass (extra realtime lights)
        // -------------------------------------------------------------
        Pass
        {
            Name "FORWARD_ADD"
            Tags { "LightMode"="ForwardAdd" }
            Cull   [_Cull]
            ZWrite Off
            ZTest  LEqual
            Blend  One One

            CGPROGRAM
            #pragma target 4.0
            #pragma vertex vert
            #pragma fragment fragForward

            #define LUMI_PASS_ADD
            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_fog

            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _DETAIL_MAP
            #pragma shader_feature_local _METALLICGLOSSMAP
            #pragma shader_feature_local _OCCLUSIONMAP
            #pragma shader_feature_local _WETNESS_ON
            #pragma shader_feature_local _SWEAT_ON
            #pragma shader_feature_local _RIM_ON
            #pragma shader_feature_local _SSS_ON
            #pragma shader_feature_local _CLEARCOAT_ON
            #pragma shader_feature_local _ANISOTROPY_ON
            #pragma shader_feature_local _PARALLAX_ON
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local _ALPHAPREMULTIPLY_ON
            #pragma shader_feature_local _SPECULARHIGHLIGHTS_OFF

            #include "LumiCore.cginc"
            ENDCG
        }

        // -------------------------------------------------------------
        //  Shadow caster
        // -------------------------------------------------------------
        Pass
        {
            Name "SHADOW_CASTER"
            Tags { "LightMode"="ShadowCaster" }
            Cull [_Cull]

            CGPROGRAM
            #pragma target 4.0
            #pragma vertex vertShadow
            #pragma fragment fragShadow
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_instancing
            #pragma shader_feature_local _ALPHATEST_ON

            #include "UnityCG.cginc"
            #include "LumiInput.cginc"

            struct vsIn
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv     : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct vsOut
            {
                V2F_SHADOW_CASTER;
                float2 uv : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            vsOut vertShadow(vsIn v)
            {
                vsOut o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                return o;
            }

            float4 fragShadow(vsOut i) : SV_Target
            {
            #if defined(_ALPHATEST_ON)
                float a = tex2D(_MainTex, i.uv).a * _Color.a;
                clip(a - _Cutoff);
            #endif
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }
    }

    FallBack "Standard"
    CustomEditor "LuminescenceGUI"
}

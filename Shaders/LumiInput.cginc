#ifndef LUMINESCENCE_INPUT_INCLUDED
#define LUMINESCENCE_INPUT_INCLUDED

// =====================================================================
//  Luminescence - Input declarations (properties / samplers / uniforms)
//  Built-in Render Pipeline (the pipeline VRChat uses).
// =====================================================================

#include "UnityCG.cginc"
#include "UnityStandardUtils.cginc"

// ---- Base / Albedo ----
sampler2D _MainTex;        float4 _MainTex_ST;
float4    _Color;
float     _Cutoff;
float     _Saturation;
float     _Brightness;
float     _Warmth;              // -1 cool .. +1 sun-kissed warm

// ---- Gradient skin tint (dual-tone body gradient) ----
float4    _GradientColorA;       // HDR (lower / facing)
float4    _GradientColorB;       // HDR (upper / grazing)
float     _GradientScale;
float     _GradientOffset;
float     _GradientMode;         // 0 = vertical (object Y), 1 = fresnel

// ---- Blush / flush (rosy makeup tint) ----
sampler2D _BlushMask;
float4    _BlushColor;
float     _BlushStrength;
float     _BlushFresnel;        // extra flush toward the silhouette

// ---- Glitter / body shimmer (procedural twinkle) ----
float4    _GlitterColor;        // HDR
float     _GlitterIntensity;
float     _GlitterDensity;
float     _GlitterCoverage;     // 0..1 fraction of flakes lit
float     _GlitterSpeed;
float     _GlitterSharpness;

// ---- Normal mapping ----
sampler2D _BumpMap;
float     _BumpScale;

// ---- Detail layer ----
sampler2D _DetailAlbedoMap;  float4 _DetailAlbedoMap_ST;
sampler2D _DetailNormalMap;
float     _DetailNormalMapScale;
sampler2D _DetailMask;

// ---- Metallic / Smoothness / Occlusion ----
sampler2D _MetallicGlossMap;
float     _Metallic;
float     _Glossiness;          // perceptual smoothness
float     _GlossMapScale;
sampler2D _OcclusionMap;
float     _OcclusionStrength;
float     _SpecularTint;        // 0..1 colours specular by albedo (for stylised metals)

// ---- Emission (glowing cracks / circuitry) ----
sampler2D _EmissionMap;
float4    _EmissionColor;
float     _EmissionStrength;
float     _EmissionPulseSpeed;
float     _EmissionPulseMin;    // floor of the pulse 0..1
float4    _EmissionScroll;      // uv/sec scroll for the emission map (xy)
float     _EmissionGradientStrength;

// ---- Reflections / Environment ----
float     _ReflectionStrength;
float4    _ReflectionTint;
float     _ReflectionFresnel;   // 0..1 how much grazing angles boost reflection
samplerCUBE _Cubemap;           // fallback / override cubemap
float     _CubemapBlend;        // 0 = use scene probes, 1 = use _Cubemap
float     _SpecularOcclusion;   // AO applied to indirect specular

// ---- Wetness ----
sampler2D _WetnessMask;
float     _Wetness;             // global 0..1
float     _WetnessSmoothness;   // target smoothness of wet areas
float4    _WetnessColor;        // tint/darken of wet areas (water absorbs light)
float     _WetnessMetallic;     // wet surfaces behave more mirror-like
float     _WetnessUpAccumulation; // pooling on upward-facing surfaces
sampler2D _DropletNormal;    float4 _DropletNormal_ST;
float     _DropletStrength;

// ---- Sweat (animated droplet sparkle) ----
sampler2D _SweatMask;
float     _SweatAmount;
float     _SweatSpeed;          // trickle speed
float     _SweatSparkle;        // bright pinpoint highlight intensity
float     _SweatScale;

// ---- Sheen (soft Fresnel skin/velvet glow — the flattering body contour) ----
float4    _SheenColor;           // HDR tint
float     _SheenIntensity;
float     _SheenRoughness;       // 0 = tight edge, 1 = broad wrap
float     _SheenLit;             // 0 = constant, 1 = follows the light

// ---- Clear coat (lacquered / wet-look top layer) ----
float     _ClearCoat;           // 0..1 strength
float     _ClearCoatSmoothness; // top layer gloss
float4    _ClearCoatColor;      // tint of the coat reflection
float     _ClearCoatFresnel;

// ---- Anisotropy (silky stretched highlights) ----
float     _Anisotropy;          // -1..1
float     _AnisoAngle;          // rotate the anisotropy direction (radians)

// ---- Iridescence / thin-film sheen ----
float     _Iridescence;         // 0..1 strength
float     _IridescenceFreq;     // colour banding frequency
float     _IridescenceShift;    // hue offset

// ---- Parallax depth ----
sampler2D _ParallaxMap;
float     _Parallax;            // height scale

// ---- Fresnel emissive glow (glows regardless of light) ----
float4    _FresnelGlowColor;    // HDR
float     _FresnelGlowPower;
float     _FresnelGlowStrength;

// ---- Holographic oil-slick flow ----
float     _HoloStrength;
float     _HoloScale;
float     _HoloSpeed;
float     _HoloFreq;
float     _HoloShift;

// ---- Inner glow (lit-from-within, pulsing / heartbeat) ----
float4    _InnerGlowColor;      // HDR
float     _InnerGlowStrength;
float     _InnerGlowPower;      // tightness of the central glow
float     _InnerGlowPulse;      // pulse rate
float     _InnerGlowPulseMin;   // floor of the pulse
float     _InnerGlowHeartbeat;  // 0 = smooth sine, 1 = lub-dub heartbeat

// ---- Rim light (with optional second colour for a gradient rim) ----
float4    _RimColor;
float4    _RimColor2;
float     _RimPower;
float     _RimStrength;
float     _RimBias;             // shift rim toward light direction

// ---- Matcap (fake reflection, popular for VRChat) ----
sampler2D _Matcap;
float     _MatcapStrength;
float     _MatcapBlend;         // 0 = additive, 1 = multiply

// ---- Subsurface scattering approximation ----
sampler2D _ThicknessMap;
float4    _SSSColor;
float     _SSSStrength;
float     _SSSPower;
float     _SSSScale;

// ---- Lighting controls ----
float     _MinBrightness;       // floor so avatars are never pitch black in dark worlds
float     _MaxBrightness;       // ceiling to tame over-bright worlds
float     _ShadowBoost;         // lift shadowed regions
float     _LightingDirectional; // 0 = flat ambient, 1 = full directional response

// ---- AudioLink (global texture broadcast by the AudioLink system) ----
sampler2D _AudioTexture;
float4    _AudioTexture_TexelSize;
float     _AudioLinkEmission;   // 0 = off, 1..4 = band (bass/low/high/treble)
float     _AudioLinkGlow;
float     _AudioLinkRim;
float     _AudioLinkGlitter;
float     _AudioLinkPunch;      // how hard the beat hits (1..3)

// ---- Dissolve (animatable reveal with a glowing edge) ----
sampler2D _DissolveNoise;
float     _DissolveAmount;      // 0 = solid, 1 = fully gone
float     _DissolveScale;
float     _DissolveEdgeWidth;
float     _DissolveTexInfluence;
float4    _DissolveEdgeColor;   // HDR
float     _DissolveAudio;       // band selector to drive the amount

// ---- Proximity glow (lights up as a viewer approaches) ----
float4    _ProximityColor;      // HDR
float     _ProximityNear;
float     _ProximityFar;
float     _ProximityStrength;
float     _ProximityPower;

// ---- Toon ramp (optional cel diffuse) ----
float4    _ShadowColor;
float     _RampSteps;
float     _RampHardness;        // 0 = smooth PBR, 1 = hard cel
float     _RampShadowSoftness;

// ---- Specular tint ----
float4    _SpecularColor;

// ---- Final colour grading ----
float     _Contrast;
float     _Vibrance;
float     _FinalSaturation;
float     _HueShift;
float     _Exposure;

// ---- Vertex distortion (subtle breathing / pulse) ----
float     _PulseSpeed;
float     _PulseAmount;

// ---- Shared procedural noise (used by sweat, dissolve, glitter) ----
float LumiHash21(float2 p)
{
    p = frac(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return frac(p.x * p.y);
}

float LumiVNoise(float2 p)
{
    float2 i = floor(p);
    float2 f = frac(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = LumiHash21(i);
    float b = LumiHash21(i + float2(1, 0));
    float c = LumiHash21(i + float2(0, 1));
    float d = LumiHash21(i + float2(1, 1));
    return lerp(lerp(a, b, f.x), lerp(c, d, f.x), f.y);
}

// Procedural dissolve field (fbm + optional texture), shared by all passes so
// the lit pass and the shadow caster clip identically.
float LumiDissolveField(float2 uv)
{
    float2 duv = uv * _DissolveScale;
    float fbm = LumiVNoise(duv) * 0.6 + LumiVNoise(duv * 2.3 + 5.1) * 0.3 + LumiVNoise(duv * 5.7 + 11.0) * 0.1;
    float texN = tex2D(_DissolveNoise, duv).r;
    return saturate(lerp(fbm, fbm * 0.5 + texN * 0.5, _DissolveTexInfluence));
}

#endif // LUMINESCENCE_INPUT_INCLUDED

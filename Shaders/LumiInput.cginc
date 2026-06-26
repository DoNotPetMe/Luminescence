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

// ---- Rim light ----
float4    _RimColor;
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

// ---- Final colour grading ----
float     _Contrast;
float     _Vibrance;
float     _FinalSaturation;
float     _HueShift;
float     _Exposure;

// ---- Vertex distortion (subtle breathing / pulse) ----
float     _PulseSpeed;
float     _PulseAmount;

#endif // LUMINESCENCE_INPUT_INCLUDED

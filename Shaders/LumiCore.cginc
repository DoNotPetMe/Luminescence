#ifndef LUMINESCENCE_CORE_INCLUDED
#define LUMINESCENCE_CORE_INCLUDED

// =====================================================================
//  Luminescence - Core shading
//  Custom physically based forward lighting tuned for VRChat avatars,
//  with wetness, sweat, emissive glow, rim, matcap and SSS layers.
// =====================================================================

#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"
#include "LumiInput.cginc"

#define LUMI_PI 3.14159265359
#define LUMI_EPS 1e-5

// ---------------------------------------------------------------------
//  Vertex <-> fragment data
// ---------------------------------------------------------------------
struct appdata
{
    float4 vertex   : POSITION;
    float3 normal   : NORMAL;
    float4 tangent  : TANGENT;
    float2 uv       : TEXCOORD0;
    float2 uv1      : TEXCOORD1;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f
{
    float4 pos        : SV_POSITION;
    float4 uv         : TEXCOORD0;     // xy = main uv, zw = detail uv
    float3 worldPos   : TEXCOORD1;
    float3 worldNormal: TEXCOORD2;
    float3 worldTangent: TEXCOORD3;
    float3 worldBitangent: TEXCOORD4;
    float3 viewDir    : TEXCOORD5;     // world-space, un-normalised
    UNITY_FOG_COORDS(6)
    SHADOW_COORDS(7)
    float3 vertexLight: TEXCOORD8;     // baked 4-point vertex lights (base pass)
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

// ---------------------------------------------------------------------
//  Vertex program
// ---------------------------------------------------------------------
v2f vert(appdata v)
{
    v2f o;
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_INITIALIZE_OUTPUT(v2f, o);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    // Gentle breathing/pulse along the normal.
    float pulse = sin(_Time.y * _PulseSpeed) * 0.5 + 0.5;
    v.vertex.xyz += v.normal * pulse * _PulseAmount * 0.01;

    o.worldPos       = mul(unity_ObjectToWorld, v.vertex).xyz;
    o.pos            = UnityObjectToClipPos(v.vertex);
    o.worldNormal    = UnityObjectToWorldNormal(v.normal);
    o.worldTangent   = UnityObjectToWorldDir(v.tangent.xyz);
    float tangentSign = v.tangent.w * unity_WorldTransformParams.w;
    o.worldBitangent = cross(o.worldNormal, o.worldTangent) * tangentSign;
    o.viewDir        = _WorldSpaceCameraPos.xyz - o.worldPos;

    o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
    o.uv.zw = TRANSFORM_TEX(v.uv, _DetailAlbedoMap);

    // Per-vertex point lights (only meaningful in the base pass).
    o.vertexLight = 0;
#if defined(VERTEXLIGHT_ON)
    o.vertexLight = Shade4PointLights(
        unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
        unity_LightColor[0].rgb, unity_LightColor[1].rgb,
        unity_LightColor[2].rgb, unity_LightColor[3].rgb,
        unity_4LightAtten0, o.worldPos, o.worldNormal);
#endif

    UNITY_TRANSFER_FOG(o, o.pos);
    TRANSFER_SHADOW(o);
    return o;
}

// ---------------------------------------------------------------------
//  Helpers
// ---------------------------------------------------------------------
float3 Saturation(float3 c, float s)
{
    float l = dot(c, float3(0.2126, 0.7152, 0.0722));
    return lerp(l.xxx, c, s);
}

// Box-projected reflection vector for a reflection probe.
float3 BoxProject(float3 dir, float3 worldPos, float4 probePos, float3 boxMin, float3 boxMax)
{
    UNITY_BRANCH
    if (probePos.w > 0)
    {
        float3 nrdir = normalize(dir);
        float3 rbmax = (boxMax - worldPos) / nrdir;
        float3 rbmin = (boxMin - worldPos) / nrdir;
        float3 rbminmax = (nrdir > 0) ? rbmax : rbmin;
        float fa = min(min(rbminmax.x, rbminmax.y), rbminmax.z);
        worldPos -= probePos.xyz;
        dir = worldPos + nrdir * fa;
    }
    return dir;
}

// Sample scene reflection probes (with optional probe blending) at a roughness mip.
float3 SampleSceneReflection(float3 reflDir, float3 worldPos, float perceptualRoughness)
{
    float mip = perceptualRoughness * (1.7 - 0.7 * perceptualRoughness) * UNITY_SPECCUBE_LOD_STEPS;

    float3 dir0 = BoxProject(reflDir, worldPos, unity_SpecCube0_ProbePosition,
                             unity_SpecCube0_BoxMin.xyz, unity_SpecCube0_BoxMax.xyz);
    float4 c0 = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, dir0, mip);
    float3 env = DecodeHDR(c0, unity_SpecCube0_HDR);

#if defined(UNITY_SPECCUBE_BLENDING)
    UNITY_BRANCH
    if (unity_SpecCube0_BoxMin.w < 0.99999)
    {
        float3 dir1 = BoxProject(reflDir, worldPos, unity_SpecCube1_ProbePosition,
                                 unity_SpecCube1_BoxMin.xyz, unity_SpecCube1_BoxMax.xyz);
        float4 c1 = UNITY_SAMPLE_TEXCUBE_SAMPLER_LOD(unity_SpecCube1, unity_SpecCube0, dir1, mip);
        float3 env1 = DecodeHDR(c1, unity_SpecCube1_HDR);
        env = lerp(env1, env, unity_SpecCube0_BoxMin.w);
    }
#endif
    return env;
}

// GGX normal distribution.
float D_GGX(float ndoth, float roughness)
{
    float a  = roughness * roughness;
    float a2 = a * a;
    float d  = (ndoth * a2 - ndoth) * ndoth + 1.0;
    return a2 / max(LUMI_PI * d * d, LUMI_EPS);
}

// Height-correlated Smith visibility (already folded the 1/(4 NdotL NdotV)).
float V_SmithGGX(float ndotl, float ndotv, float roughness)
{
    float a  = roughness * roughness;
    float a2 = a * a;
    float lv = ndotl * sqrt(ndotv * ndotv * (1.0 - a2) + a2);
    float vl = ndotv * sqrt(ndotl * ndotl * (1.0 - a2) + a2);
    return 0.5 / max(lv + vl, LUMI_EPS);
}

float3 F_Schlick(float3 f0, float vdoth)
{
    float f = pow(1.0 - vdoth, 5.0);
    return f0 + (1.0 - f0) * f;
}

float F_Schlick1(float f0, float f90, float vdoth)
{
    return f0 + (f90 - f0) * pow(1.0 - vdoth, 5.0);
}

// Anisotropic GGX normal distribution (stretched highlight).
float D_GGX_Aniso(float ndoth, float toth, float both, float at, float ab)
{
    float a2 = at * ab;
    float3 v = float3(ab * toth, at * both, a2 * ndoth);
    float v2 = dot(v, v);
    float w2 = a2 / max(v2, LUMI_EPS);
    return a2 * w2 * w2 * (1.0 / LUMI_PI);
}

// Cheap thin-film / iridescence tint driven by view angle.
float3 Iridescence(float cosAngle, float freq, float shift)
{
    float3 phase = float3(0.0, 0.3333, 0.6667) + shift;
    return 0.5 + 0.5 * cos(6.28318530718 * (freq * cosAngle + phase));
}

float3 HueShift(float3 col, float angle)
{
    const float3 k = float3(0.57735, 0.57735, 0.57735);
    float c = cos(angle);
    return col * c + cross(k, col) * sin(angle) + k * dot(k, col) * (1.0 - c);
}

// ACES filmic tonemap (Narkowicz fit).
float3 ACESFilmic(float3 x)
{
    return saturate((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14));
}

float3 ColorGrade(float3 c)
{
    c *= _Exposure;
    // Contrast around mid-grey.
    c = (c - 0.5) * _Contrast + 0.5;
    // Saturation + vibrance.
    float l = dot(max(c, 0.0), float3(0.2126, 0.7152, 0.0722));
    c = lerp(l.xxx, c, _FinalSaturation);
    float sat = saturate(distance(c, l.xxx));
    c = lerp(l.xxx, c, 1.0 + _Vibrance * (1.0 - sat));
    if (abs(_HueShift) > 1e-4) c = HueShift(c, _HueShift);
    return max(c, 0.0);
}

// Cheap hash / value noise so sweat works with no texture at all.
float Hash21(float2 p)
{
    p = frac(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return frac(p.x * p.y);
}

float VNoise(float2 p)
{
    float2 i = floor(p);
    float2 f = frac(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = Hash21(i);
    float b = Hash21(i + float2(1, 0));
    float c = Hash21(i + float2(0, 1));
    float d = Hash21(i + float2(1, 1));
    return lerp(lerp(a, b, f.x), lerp(c, d, f.x), f.y);
}

// Procedural sweat bead field (0..1 height). Animated to trickle downward.
// _SweatMask (default white) restricts the region; no painted droplets needed.
float SweatField(float2 uv)
{
    float t = _Time.y * _SweatSpeed;
    float2 p = uv * _SweatScale;
    p.y += t;                                   // trickle (uv +y travels down the body)
    float n = VNoise(p) * VNoise(p * 2.13 + 19.3);
    return smoothstep(0.30, 0.72, n * 2.0);
}

// ---------------------------------------------------------------------
//  Surface assembly
// ---------------------------------------------------------------------
struct Surface
{
    float3 albedo;
    float  alpha;
    float  metallic;
    float  smoothness;
    float  occlusion;
    float3 emission;
    float3 normalWorld;
    float3 tangentWorld;
    float3 bitangentWorld;
    float  sweatSparkle;
    float  thickness;
};

Surface BuildSurface(v2f i, float3 geomNormal)
{
    Surface s = (Surface)0;

    float3 wTangent   = normalize(i.worldTangent);
    float3 wBitangent = normalize(i.worldBitangent);

    // ---- Parallax depth: offset UVs along tangent-space view direction ----
#if defined(_PARALLAX_ON)
    {
        float3x3 tbnV = float3x3(wTangent, wBitangent, normalize(geomNormal));
        float3 vTan = mul(tbnV, normalize(i.viewDir));
        float h = tex2D(_ParallaxMap, i.uv.xy).g - 0.5;
        float2 off = (vTan.xy / (vTan.z + 0.42)) * h * _Parallax * 0.1;
        i.uv.xy += off;
        i.uv.zw += off;
    }
#endif

    // ---- Albedo ----
    float4 baseTex = tex2D(_MainTex, i.uv.xy);
    float3 albedo  = baseTex.rgb * _Color.rgb;
    s.alpha = baseTex.a * _Color.a;

#if defined(_DETAIL_MAP)
    float detailMask = tex2D(_DetailMask, i.uv.xy).a;
    float3 detail = tex2D(_DetailAlbedoMap, i.uv.zw).rgb;
    albedo *= lerp(float3(1, 1, 1), detail * 2.0, detailMask); // overlay-ish
#endif

    albedo = Saturation(albedo, _Saturation) * _Brightness;

    // ---- Skin warmth: sun-kissed (+) or cool porcelain (-) ----
    albedo.r = saturate(albedo.r + _Warmth * 0.10);
    albedo.b = saturate(albedo.b - _Warmth * 0.08);

    // ---- Blush / flush (rosy makeup tint, optionally stronger at the edges) ----
#if defined(_BLUSH_ON)
    {
        float bMask = tex2D(_BlushMask, i.uv.xy).r;
        float ndvB = saturate(dot(geomNormal, normalize(i.viewDir)));
        float bFres = lerp(1.0, pow(1.0 - ndvB, 2.0), _BlushFresnel);
        float blush = saturate(bMask * _BlushStrength * bFres);
        albedo = lerp(albedo, albedo * _BlushColor.rgb, blush);
    }
#endif

    // ---- Normal map ----
    float3 n = geomNormal;
#if defined(_NORMALMAP)
    float3 tn = UnpackScaleNormal(tex2D(_BumpMap, i.uv.xy), _BumpScale);
#if defined(_DETAIL_MAP)
    float3 dn = UnpackScaleNormal(tex2D(_DetailNormalMap, i.uv.zw), _DetailNormalMapScale);
    tn = BlendNormals(tn, dn);
#endif
    float3x3 tbn = float3x3(normalize(i.worldTangent), normalize(i.worldBitangent), normalize(geomNormal));
    n = normalize(mul(tn, tbn));
#endif

    // ---- Metallic / Smoothness / Occlusion ----
    float metallic   = _Metallic;
    float smoothness = _Glossiness;
#if defined(_METALLICGLOSSMAP)
    float4 mg = tex2D(_MetallicGlossMap, i.uv.xy);
    metallic   = mg.r * _Metallic;
    smoothness = mg.a * _GlossMapScale;
#endif
    float occlusion = 1.0;
#if defined(_OCCLUSIONMAP)
    occlusion = LerpOneTo(tex2D(_OcclusionMap, i.uv.xy).g, _OcclusionStrength);
#endif

    // ---- Wetness + Sweat (unified: both glisten, both can be used alone) ----
#if defined(_WETNESS_ON) || defined(_SWEAT_ON)
    float3x3 tbnW = float3x3(normalize(i.worldTangent), normalize(i.worldBitangent), normalize(n));
    float wet = 0;

#if defined(_WETNESS_ON)
    float wetMask = tex2D(_WetnessMask, i.uv.xy).r;
    wet += _Wetness * wetMask + saturate(n.y) * _WetnessUpAccumulation;
    // Sheet-of-water micro normals across wet skin.
    float3 dropTN = UnpackScaleNormal(tex2D(_DropletNormal, TRANSFORM_TEX(i.uv.xy, _DropletNormal)),
                                      _DropletStrength * saturate(wet));
    n = normalize(mul(dropTN, tbnW));
#endif

#if defined(_SWEAT_ON)
    // Procedural beads with real, analytically-derived bump normals so the
    // light visibly catches every droplet.
    float region = tex2D(_SweatMask, i.uv.xy).r;
    float gravity = saturate(0.85 - n.y * 0.35);
    float e = 0.5 / max(_SweatScale, 0.001);
    float bC = SweatField(i.uv.xy);
    float bX = SweatField(i.uv.xy + float2(e, 0));
    float bY = SweatField(i.uv.xy + float2(0, e));
    float beads = bC * _SweatAmount * region * gravity;
    s.sweatSparkle = beads * _SweatSparkle;

    float2 grad = float2(bX - bC, bY - bC) * _SweatScale * beads * 6.0;
    float3 beadN = normalize(float3(-grad, 1.0));
    n = normalize(mul(beadN, tbnW));

    // Beads are slick: darken a touch, push smoothness way up locally.
    albedo     = lerp(albedo, albedo * 0.78, beads * 0.5);
    smoothness = max(smoothness, beads * 0.97);
    wet += beads;
#endif

    wet = saturate(wet);
#if defined(_WETNESS_ON)
    albedo   = lerp(albedo, albedo * _WetnessColor.rgb, wet);
    metallic = lerp(metallic, _WetnessMetallic, wet * 0.5);
#endif
    smoothness = lerp(smoothness, max(smoothness, _WetnessSmoothness), wet);
#endif

    // ---- Emission ----
    float3 emission = 0;
#if defined(_EMISSION)
    float2 emUv = i.uv.xy + _EmissionScroll.xy * _Time.y;
    float3 emTex = tex2D(_EmissionMap, emUv).rgb;
    float pulse = lerp(_EmissionPulseMin, 1.0,
                       sin(_Time.y * _EmissionPulseSpeed) * 0.5 + 0.5);
    // Optional gradient: brighter where emission texture is already bright.
    float grad = lerp(1.0, dot(emTex, float3(0.3333, 0.3333, 0.3333)), _EmissionGradientStrength);
    emission = emTex * _EmissionColor.rgb * _EmissionStrength * pulse * grad;
#endif

    // Fresnel emissive glow — burns the silhouette regardless of scene light.
    {
        float ndv = saturate(dot(n, normalize(i.viewDir)));
        float fres = pow(1.0 - ndv, max(_FresnelGlowPower, 0.01));
        emission += _FresnelGlowColor.rgb * fres * _FresnelGlowStrength;
    }

    // ---- Glitter / body shimmer: twinkling flakes that catch the eye ----
#if defined(_GLITTER_ON)
    {
        float2 cell = floor(i.uv.xy * _GlitterDensity);
        float rnd  = Hash21(cell);
        float rnd2 = Hash21(cell + 7.3);
        float ndv  = saturate(dot(n, normalize(i.viewDir)));
        float twinkle = sin(rnd * 6.2831 + _Time.y * _GlitterSpeed + ndv * 12.0) * 0.5 + 0.5;
        float spark = pow(twinkle, max(_GlitterSharpness, 0.1));
        float present = step(1.0 - _GlitterCoverage, rnd2);
        emission += spark * present * _GlitterColor.rgb * _GlitterIntensity;
    }
#endif

    s.albedo      = saturate(albedo);
    s.metallic    = saturate(metallic);
    s.smoothness  = saturate(smoothness);
    s.occlusion   = occlusion;
    s.emission    = emission;
    s.normalWorld = n;
    s.tangentWorld   = wTangent;
    s.bitangentWorld = wBitangent;
    s.thickness   = 1.0;
#if defined(_SSS_ON)
    s.thickness   = tex2D(_ThicknessMap, i.uv.xy).r;
#endif
    return s;
}

// ---------------------------------------------------------------------
//  Lighting
// ---------------------------------------------------------------------
float3 LightingPBR(Surface s, float3 viewDir, float3 worldPos, float3 lightColor,
                   float3 lightDir, float atten, float3 indirectDiffuse, float3 vertexLight)
{
    float3 N = s.normalWorld;
    float3 V = viewDir;
    float perceptualRoughness = 1.0 - s.smoothness;
    float roughness = max(perceptualRoughness * perceptualRoughness, 2e-3);

    // Energy split between diffuse & specular based on metalness.
    float3 specColor = lerp(float3(0.04, 0.04, 0.04), s.albedo, s.metallic);
    specColor = lerp(specColor, specColor * s.albedo, _SpecularTint * (1.0 - s.metallic));
    float3 diffColor = s.albedo * (1.0 - s.metallic);

    float ndotv = saturate(dot(N, V)) + LUMI_EPS;

    // ---- Sheen: soft Fresnel glow that hugs the body's curves ----
#if defined(_SHEEN_ON)
    float sheenFres = pow(1.0 - ndotv, lerp(8.0, 1.5, _SheenRoughness));
    float3 sheenCol = _SheenColor.rgb * _SheenIntensity * sheenFres;
#endif

    // ---- Direct light ----
    float3 L = normalize(lightDir);
    float3 H = normalize(L + V);
    float ndotl = saturate(dot(N, L));
    float ndoth = saturate(dot(N, H));
    float vdoth = saturate(dot(V, H));

    float ndotlShaped = lerp(ndotl, 1.0, (1.0 - _LightingDirectional));

    float vis = V_SmithGGX(ndotl, ndotv, roughness);
    float3 f  = F_Schlick(specColor, vdoth);

#if defined(_ANISOTROPY_ON)
    // Rotate the tangent frame and stretch the highlight.
    float ca = cos(_AnisoAngle), sa = sin(_AnisoAngle);
    float3 T = normalize(s.tangentWorld * ca + s.bitangentWorld * sa);
    float3 B = normalize(cross(N, T));
    float at = max(roughness * (1.0 + _Anisotropy), 2e-3);
    float ab = max(roughness * (1.0 - _Anisotropy), 2e-3);
    float d  = D_GGX_Aniso(ndoth, dot(T, H), dot(B, H), at, ab);
#else
    float d  = D_GGX(ndoth, roughness);
#endif

#if defined(_SPECULARHIGHLIGHTS_OFF)
    float3 directSpec = 0;
#else
    float3 directSpec = d * vis * f * ndotl;
#endif

    // ---- Clear coat: a second, sharp specular lobe over the base ----
    float coatAtten = 1.0;
#if defined(_CLEARCOAT_ON)
    float coatRough = max((1.0 - _ClearCoatSmoothness) * (1.0 - _ClearCoatSmoothness), 2e-3);
    float coatD = D_GGX(ndoth, coatRough);
    float coatV = V_SmithGGX(ndotl, ndotv, coatRough);
    float coatF = F_Schlick1(0.04, 1.0, vdoth) * _ClearCoat;
    directSpec += coatD * coatV * coatF * ndotl * _ClearCoatColor.rgb;
    // Energy: everything beneath the coat dims a touch.
    coatAtten = (1.0 - coatF * 0.5);
    directSpec *= coatAtten;
#endif

    float3 directDiffuse = diffColor * ndotlShaped * coatAtten;
    float3 direct = (directDiffuse + directSpec) * lightColor * atten;

    // ---- Sub-surface scattering (translucency) ----
#if defined(_SSS_ON)
    float3 sssL = L + N * _SSSScale;
    float back = pow(saturate(dot(V, -sssL)), _SSSPower) * _SSSStrength * s.thickness;
    direct += back * _SSSColor.rgb * lightColor * atten;
#endif

    // ---- Sweat / sparkle: bright glint on top of the bead highlights ----
    float sweatGlint = pow(ndoth, 90.0) * 6.0 + pow(1.0 - ndotv, 4.0) * 0.5;
    direct += s.sweatSparkle * sweatGlint * lightColor * atten;

    // ---- Sheen, lit portion ----
#if defined(_SHEEN_ON)
    direct += sheenCol * lerp(1.0, ndotl, _SheenLit) * lightColor * atten;
#endif

    // ---- Indirect diffuse (light probes / ambient) ----
    float3 indirect = indirectDiffuse * diffColor * s.occlusion;

    // ---- Sheen, ambient portion (so it reads in flat-lit worlds) ----
#if defined(_SHEEN_ON) && !defined(LUMI_PASS_ADD)
    indirect += sheenCol * (indirectDiffuse + 0.04);
#endif

    // ---- Indirect specular (reflections) — base pass only ----
#if !defined(_GLOSSYREFLECTIONS_OFF) && !defined(LUMI_PASS_ADD)
    float3 reflDir = reflect(-V, N);
    float3 envScene = SampleSceneReflection(reflDir, worldPos, perceptualRoughness);
    float3 envCube  = DecodeHDR(texCUBElod(_Cubemap, float4(reflDir, perceptualRoughness * UNITY_SPECCUBE_LOD_STEPS)), unity_SpecCube0_HDR);
    float3 env = lerp(envScene, envCube, _CubemapBlend);

    // Grazing reflection (Fresnel) and roughness-based dimming.
    float grazing = saturate(s.smoothness + s.metallic);
    float fresnel = pow(1.0 - ndotv, 5.0) * _ReflectionFresnel;
    float3 envF = lerp(specColor, grazing.xxx, fresnel);
    float specOcc = lerp(1.0, s.occlusion, _SpecularOcclusion);

    // Iridescent thin-film tint shifts the reflection colour by view angle.
#if defined(_IRIDESCENCE_ON)
    float3 iri = Iridescence(ndotv, _IridescenceFreq, _IridescenceShift);
    envF *= lerp(float3(1, 1, 1), iri, _Iridescence);
#endif

    indirect += env * envF * _ReflectionStrength * _ReflectionTint.rgb * specOcc * coatAtten;

    // Clear-coat picks up its own sharp environment reflection.
#if defined(_CLEARCOAT_ON)
    float3 envCoat = SampleSceneReflection(reflDir, worldPos, 1.0 - _ClearCoatSmoothness);
    float coatFr = F_Schlick1(0.04, 1.0, ndotv) * _ClearCoat;
    indirect += envCoat * coatFr * _ClearCoatColor.rgb;
#endif
#endif

    float3 color = direct + indirect + vertexLight * diffColor;

    // ---- Matcap (camera-space fake reflection) — base pass only ----
#if defined(_MATCAP_ON) && !defined(LUMI_PASS_ADD)
    float3 vn = mul((float3x3)UNITY_MATRIX_V, N);
    float2 mcUv = vn.xy * 0.5 + 0.5;
    float3 mc = tex2D(_Matcap, mcUv).rgb * _MatcapStrength;
    color = lerp(color + mc, color * (1.0 + mc), _MatcapBlend);
#endif

    // ---- Rim light — base pass only ----
#if defined(_RIM_ON) && !defined(LUMI_PASS_ADD)
    float rim = 1.0 - saturate(dot(N, V));
    rim = pow(rim, max(_RimPower, 0.01));
    float rimDir = lerp(1.0, saturate(dot(N, L)), _RimBias);
    color += _RimColor.rgb * rim * rimDir * _RimStrength * lightColor;
#endif

    return color;
}

// ---------------------------------------------------------------------
//  Fragment program
// ---------------------------------------------------------------------
float4 fragForward(v2f i) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(i);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

    float3 geomNormal = normalize(i.worldNormal);
    float3 viewDir    = normalize(i.viewDir);
    Surface s = BuildSurface(i, geomNormal);

#if defined(_ALPHATEST_ON)
    clip(s.alpha - _Cutoff);
#endif

    UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

    float3 lightColor = _LightColor0.rgb;
    float3 lightDir;
#if defined(LUMI_PASS_ADD)
    #if defined(USING_DIRECTIONAL_LIGHT)
        lightDir = normalize(_WorldSpaceLightPos0.xyz);
    #else
        lightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
    #endif
    float3 indirectDiffuse = 0;
    float3 vertexLight = 0;
#else
    lightDir = normalize(_WorldSpaceLightPos0.xyz); // directional in base pass
    // Ambient / light-probe diffuse, with shadow lift and clamping.
    float3 indirectDiffuse = max(0, ShadeSH9(float4(s.normalWorld, 1)));
    indirectDiffuse = lerp(indirectDiffuse, indirectDiffuse + _ShadowBoost, _ShadowBoost);
    float3 vertexLight = i.vertexLight;
#endif

    float3 color = LightingPBR(s, viewDir, i.worldPos, lightColor, lightDir,
                               atten, indirectDiffuse, vertexLight);

    // Emission / glitter / Fresnel glow only contribute once (base pass).
#if !defined(LUMI_PASS_ADD)
    color += s.emission;
#endif

    // Brightness floor/ceiling so avatars read well in any world.
#if !defined(LUMI_PASS_ADD)
    float lum = dot(color, float3(0.2126, 0.7152, 0.0722));
    float targetLum = clamp(lum, _MinBrightness, _MaxBrightness);
    color *= (lum > LUMI_EPS) ? (targetLum / lum) : 1.0;

    // Final colour grade (exposure / contrast / vibrance / hue).
    color = ColorGrade(color);

    // Filmic tonemap tames HDR highlights into a rich, premium roll-off.
#if defined(_TONEMAP_ON)
    color = ACESFilmic(color);
#endif
#endif

    float4 outCol = float4(color, s.alpha);

#if defined(_ALPHAPREMULTIPLY_ON)
    outCol.rgb *= outCol.a;
#endif

    UNITY_APPLY_FOG(i.fogCoord, outCol);
    return outCol;
}

#endif // LUMINESCENCE_CORE_INCLUDED

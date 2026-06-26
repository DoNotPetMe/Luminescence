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

// Animated sweat: two scrolling layers of the mask whose product makes
// trickling sparkle. Returns a 0..1 sparkle factor and writes wetness.
float SweatTerm(float2 uv, float3 worldNormal, out float wetAdd)
{
    wetAdd = 0;
#if defined(_SWEAT_ON)
    float2 flow = float2(0, -_Time.y * _SweatSpeed);
    float2 uv0 = uv * _SweatScale + flow;
    float2 uv1 = uv * _SweatScale * 1.37 + flow * 0.6 + 0.21;
    float a = tex2D(_SweatMask, uv0).r;
    float b = tex2D(_SweatMask, uv1).r;
    float droplets = saturate(a * b * 4.0) * _SweatAmount;
    // Gravity bias: sweat collects on downward / vertical surfaces.
    droplets *= saturate(1.0 - worldNormal.y * 0.5);
    wetAdd = droplets;
    return droplets * _SweatSparkle;
#else
    return 0;
#endif
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
    float  sweatSparkle;
    float  thickness;
};

Surface BuildSurface(v2f i, float3 geomNormal)
{
    Surface s = (Surface)0;

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

    // ---- Wetness ----
#if defined(_WETNESS_ON)
    float wetMask = tex2D(_WetnessMask, i.uv.xy).r;
    float wet = _Wetness * wetMask;
    wet += saturate(n.y) * _WetnessUpAccumulation;           // pooling on top faces
    float sweatWet;
    s.sweatSparkle = SweatTerm(i.uv.xy, n, sweatWet);
    wet = saturate(wet + sweatWet);

    albedo     = lerp(albedo, albedo * _WetnessColor.rgb, wet);
    smoothness = lerp(smoothness, _WetnessSmoothness, wet);
    metallic   = lerp(metallic, _WetnessMetallic, wet * 0.5);

    // Droplet micro-normals only where it is wet.
    float3 dropTN = UnpackScaleNormal(tex2D(_DropletNormal, TRANSFORM_TEX(i.uv.xy, _DropletNormal)),
                                      _DropletStrength * wet);
    float3x3 tbnW = float3x3(normalize(i.worldTangent), normalize(i.worldBitangent), normalize(n));
    n = normalize(mul(dropTN, tbnW));
#else
    float sweatWet2;
    s.sweatSparkle = SweatTerm(i.uv.xy, n, sweatWet2);
    smoothness = lerp(smoothness, _WetnessSmoothness, saturate(sweatWet2));
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

    s.albedo      = saturate(albedo);
    s.metallic    = saturate(metallic);
    s.smoothness  = saturate(smoothness);
    s.occlusion   = occlusion;
    s.emission    = emission;
    s.normalWorld = n;
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

    // ---- Direct light ----
    float3 L = normalize(lightDir);
    float3 H = normalize(L + V);
    float ndotl = saturate(dot(N, L));
    float ndoth = saturate(dot(N, H));
    float vdoth = saturate(dot(V, H));

    float ndotlShaped = lerp(ndotl, 1.0, (1.0 - _LightingDirectional));

    float d  = D_GGX(ndoth, roughness);
    float vis = V_SmithGGX(ndotl, ndotv, roughness);
    float3 f  = F_Schlick(specColor, vdoth);
#if defined(_SPECULARHIGHLIGHTS_OFF)
    float3 directSpec = 0;
#else
    float3 directSpec = d * vis * f * ndotl;
#endif

    float3 directDiffuse = diffColor * ndotlShaped;
    float3 direct = (directDiffuse + directSpec) * lightColor * atten;

    // ---- Sub-surface scattering (translucency) ----
#if defined(_SSS_ON)
    float3 sssL = L + N * _SSSScale;
    float back = pow(saturate(dot(V, -sssL)), _SSSPower) * _SSSStrength * s.thickness;
    direct += back * _SSSColor.rgb * lightColor * atten;
#endif

    // ---- Sweat / sparkle: tight extra specular pinpoints ----
    direct += s.sweatSparkle * pow(ndoth, 200.0) * lightColor * atten * 8.0;

    // ---- Indirect diffuse (light probes / ambient) ----
    float3 indirect = indirectDiffuse * diffColor * s.occlusion;

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
    indirect += env * envF * _ReflectionStrength * _ReflectionTint.rgb * specOcc;
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

    color += s.emission;

    // Brightness floor/ceiling so avatars read well in any world.
#if !defined(LUMI_PASS_ADD)
    float lum = dot(color, float3(0.2126, 0.7152, 0.0722));
    float targetLum = clamp(lum, _MinBrightness, _MaxBrightness);
    color *= (lum > LUMI_EPS) ? (targetLum / lum) : 1.0;
#endif

    float4 outCol = float4(color, s.alpha);

#if defined(_ALPHAPREMULTIPLY_ON)
    outCol.rgb *= outCol.a;
#endif

    UNITY_APPLY_FOG(i.fogCoord, outCol);
    return outCol;
}

#endif // LUMINESCENCE_CORE_INCLUDED

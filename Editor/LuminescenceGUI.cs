// =====================================================================
//  LuminescenceGUI - a compact, modern inspector for the Luminescence
//  shader: styled collapsible bars with inline enable toggles, tooltips
//  and one-click look presets.
// =====================================================================
#if UNITY_EDITOR
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

public class LuminescenceGUI : ShaderGUI
{
    private const string Version = "1.4";

    // property name -> keyword managed by its [Toggle()] drawer.
    private static readonly Dictionary<string, string> Keywords = new Dictionary<string, string>
    {
        { "_AlphaTest",        "_ALPHATEST_ON" },
        { "_BlushToggle",      "_BLUSH_ON" },
        { "_GlitterToggle",    "_GLITTER_ON" },
        { "_HoloToggle",       "_HOLO_ON" },
        { "_InnerGlowToggle",  "_INNERGLOW_ON" },
        { "_AudioLinkToggle",  "_AUDIOLINK_ON" },
        { "_DissolveToggle",   "_DISSOLVE_ON" },
        { "_ProximityToggle",  "_PROXIMITY_ON" },
        { "_RampToggle",       "_RAMP_ON" },
        { "_GradientToggle",   "_GRADIENT_ON" },
        { "_NormalToggle",     "_NORMALMAP" },
        { "_DetailToggle",     "_DETAIL_MAP" },
        { "_MetalToggle",      "_METALLICGLOSSMAP" },
        { "_OcclToggle",       "_OCCLUSIONMAP" },
        { "_NoReflections",    "_GLOSSYREFLECTIONS_OFF" },
        { "_NoSpecHi",         "_SPECULARHIGHLIGHTS_OFF" },
        { "_SheenToggle",      "_SHEEN_ON" },
        { "_ClearCoatToggle",  "_CLEARCOAT_ON" },
        { "_AnisoToggle",      "_ANISOTROPY_ON" },
        { "_IridToggle",       "_IRIDESCENCE_ON" },
        { "_ParallaxToggle",   "_PARALLAX_ON" },
        { "_EmissionToggle",   "_EMISSION" },
        { "_WetnessToggle",    "_WETNESS_ON" },
        { "_SweatToggle",      "_SWEAT_ON" },
        { "_RimToggle",        "_RIM_ON" },
        { "_MatcapToggle",     "_MATCAP_ON" },
        { "_SSSToggle",        "_SSS_ON" },
        { "_TonemapToggle",    "_TONEMAP_ON" },
        { "_Premultiply",      "_ALPHAPREMULTIPLY_ON" },
    };

    private static readonly Dictionary<string, bool> Foldouts = new Dictionary<string, bool>();

    private MaterialEditor _editor;
    private MaterialProperty[] _props;
    private static GUIStyle _foldLabel, _title, _sub, _chip, _danger;
    private static bool _stylesReady;

    private static readonly Color BarOn  = new Color(0.27f, 0.22f, 0.34f, 1f);
    private static readonly Color BarOff = new Color(0.17f, 0.17f, 0.19f, 1f);
    private static readonly Color Accent = new Color(0.85f, 0.30f, 0.45f, 1f);

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        _editor = materialEditor;
        _props = properties;
        InitStyles();

        Banner();
        Toolbar();
        ImportPanel();
        PresetBar();

        Section("Base", null, () =>
        {
            Tex("_MainTex", "Albedo", "_Color", "Main colour / opacity map.");
            P("_Saturation", "Albedo saturation.");
            P("_Brightness", "Albedo multiplier.");
            P("_Warmth", "Sun-kissed (+) or cool porcelain (-) skin tone.");
            P("_AlphaTest", "Hard alpha cutout.");
            if (On("_AlphaTest")) P("_Cutoff");
        });

        Section("Gradient Tint", "_GradientToggle", () =>
        {
            EditorGUILayout.LabelField("Dual-tone body gradient — the staple of gorgeous aesthetic avatars.",
                EditorStyles.wordWrappedMiniLabel);
            P("_GradientColorA", "Lower / front colour.");
            P("_GradientColorB", "Upper / edge colour.");
            P("_GradientScale");
            P("_GradientOffset");
            P("_GradientMode", "Vertical (along the body) or Fresnel (by view angle).");
        });

        Section("Blush — Flush", "_BlushToggle", () =>
        {
            Tex("_BlushMask", "Blush Mask (R)");
            P("_BlushColor", "Rosy tint multiplied onto the skin.");
            P("_BlushStrength");
            P("_BlushFresnel", "Add extra flush toward the silhouette.");
        });

        Section("Glitter — Body Shimmer", "_GlitterToggle", () =>
        {
            P("_GlitterColor");
            P("_GlitterIntensity");
            P("_GlitterDensity", "How fine/small the flakes are.");
            P("_GlitterCoverage", "Fraction of the skin that sparkles.");
            P("_GlitterSpeed", "How fast flakes twinkle.");
            P("_GlitterSharpness", "Twinkle tightness.");
        });

        Section("Normal & Detail", "_NormalToggle", () =>
        {
            Tex("_BumpMap", "Normal Map");
            P("_BumpScale");
            Space();
            P("_DetailToggle", "Second high-frequency layer.");
            using (Disabled(!On("_DetailToggle")))
            {
                Tex("_DetailAlbedoMap", "Detail Albedo (x2)");
                Tex("_DetailNormalMap", "Detail Normal");
                P("_DetailNormalMapScale");
                Tex("_DetailMask", "Detail Mask (A)");
            }
        });

        Section("Surface (PBR)", "_MetalToggle", () =>
        {
            using (Disabled(!On("_MetalToggle")))
            {
                Tex("_MetallicGlossMap", "Metallic(R) Smooth(A)");
                P("_GlossMapScale");
            }
            P("_Metallic");
            P("_Glossiness", "Smoothness — higher = sharper, wetter reflections.");
            P("_SpecularColor", "Tint the specular highlight (try warm gold for sexy skin).");
            P("_SpecularTint", "Tint specular by albedo for stylised metals.");
            Space();
            P("_OcclToggle");
            using (Disabled(!On("_OcclToggle")))
            {
                Tex("_OcclusionMap", "Occlusion (G)");
                P("_OcclusionStrength");
            }
        });

        Section("Reflections", null, () =>
        {
            P("_NoReflections", "Disable environment reflections entirely.");
            using (Disabled(On("_NoReflections")))
            {
                P("_ReflectionStrength");
                P("_ReflectionTint");
                P("_ReflectionFresnel", "How much glancing angles boost reflection.");
                P("_SpecularOcclusion");
                Tex("_Cubemap", "Fallback Cubemap");
                P("_CubemapBlend", "0 = scene probes, 1 = the cubemap above.");
            }
            P("_NoSpecHi", "Disable direct specular highlights.");
        });

        Section("Sheen — Skin Glow", "_SheenToggle", () =>
        {
            P("_SheenColor", "Soft Fresnel glow that hugs the body's curves.");
            P("_SheenIntensity");
            P("_SheenRoughness", "0 = tight edge, 1 = broad, wrapped glow.");
            P("_SheenLit", "0 = constant glow, 1 = follows the key light.");
        });

        Section("Clear Coat", "_ClearCoatToggle", () =>
        {
            P("_ClearCoat", "Strength of the glossy lacquer layer.");
            P("_ClearCoatSmoothness", "Sharpness of the coat reflection.");
            P("_ClearCoatColor");
        });

        Section("Anisotropy", "_AnisoToggle", () =>
        {
            P("_Anisotropy", "Stretch the highlight: -1 to 1.");
            P("_AnisoAngle", "Direction of the stretched highlight.");
        });

        Section("Iridescence", "_IridToggle", () =>
        {
            P("_Iridescence", "Thin-film colour-shift strength.");
            P("_IridescenceFreq", "Colour banding frequency.");
            P("_IridescenceShift", "Hue offset.");
        });

        Section("Parallax Depth", "_ParallaxToggle", () =>
        {
            Tex("_ParallaxMap", "Height (G)");
            P("_Parallax", "Apparent depth from the height map.");
        });

        Section("Emission Glow", "_EmissionToggle", () =>
        {
            Tex("_EmissionMap", "Emission", "_EmissionColor", "HDR emission colour & map.");
            P("_EmissionStrength");
            P("_EmissionPulseSpeed", "0 = steady, higher = faster pulse.");
            P("_EmissionPulseMin", "Lowest brightness of the pulse.");
            P("_EmissionScroll", "Scroll the emission map (energy flow).");
            P("_EmissionGradientStrength");
            Space();
            MiniLabel("Fresnel Glow (always-on rim glow)");
            P("_FresnelGlowColor");
            P("_FresnelGlowPower", "Width of the silhouette glow.");
            P("_FresnelGlowStrength");
        });

        Section("Wetness", "_WetnessToggle", () =>
        {
            Tex("_WetnessMask", "Wetness Mask (R)");
            P("_Wetness");
            P("_WetnessSmoothness", "Smoothness of wet areas.");
            P("_WetnessColor", "Wet darkening tint (water absorbs light).");
            P("_WetnessMetallic");
            P("_WetnessUpAccumulation", "Pool water on upward-facing surfaces.");
            Tex("_DropletNormal", "Droplet Normal");
            P("_DropletStrength");
        });

        Section("Sweat", "_SweatToggle", () =>
        {
            Tex("_SweatMask", "Sweat Mask (R)");
            P("_SweatAmount");
            P("_SweatSpeed", "How fast droplets trickle down.");
            P("_SweatSparkle", "Brightness of pinpoint glints.");
            P("_SweatScale", "Droplet tiling.");
        });

        Section("Holographic Flow", "_HoloToggle", () =>
        {
            P("_HoloStrength", "Brightness of the flowing oil-slick film.");
            P("_HoloScale");
            P("_HoloSpeed", "How fast the hologram flows.");
            P("_HoloFreq", "Colour banding frequency.");
            P("_HoloShift", "Hue offset.");
        });

        Section("Inner Glow", "_InnerGlowToggle", () =>
        {
            P("_InnerGlowColor", "Lit-from-within core glow.");
            P("_InnerGlowStrength");
            P("_InnerGlowPower", "Tightness of the central glow.");
            P("_InnerGlowPulse", "Pulse / beat rate.");
            P("_InnerGlowPulseMin", "Lowest brightness of the pulse.");
            P("_InnerGlowHeartbeat", "0 = smooth breathing, 1 = lub-dub heartbeat.");
        });

        Section("Rim Light", "_RimToggle", () =>
        {
            P("_RimColor", "Top rim colour.");
            P("_RimColor2", "Bottom rim colour (vertical gradient).");
            P("_RimPower", "Rim width (higher = thinner).");
            P("_RimStrength");
            P("_RimBias", "Bias the rim toward the light direction.");
        });

        Section("Matcap", "_MatcapToggle", () =>
        {
            Tex("_Matcap", "Matcap");
            P("_MatcapStrength");
            P("_MatcapBlend", "0 = additive, 1 = multiply.");
        });

        Section("Subsurface (SSS)", "_SSSToggle", () =>
        {
            Tex("_ThicknessMap", "Thickness");
            P("_SSSColor");
            P("_SSSStrength");
            P("_SSSPower", "Falloff sharpness.");
            P("_SSSScale", "Light wrap / distortion.");
        });

        Section("Color Grading", null, () =>
        {
            P("_Exposure");
            P("_Contrast");
            P("_FinalSaturation");
            P("_Vibrance", "Smartly saturates the dull areas only.");
            P("_HueShift");
            P("_TonemapToggle", "Filmic ACES roll-off for rich HDR highlights.");
        });

        Section("AudioLink — React to Music", "_AudioLinkToggle", () =>
        {
            EditorGUILayout.LabelField("Works in any world running AudioLink. Pick which band drives each effect.",
                EditorStyles.wordWrappedMiniLabel);
            P("_AudioLinkPunch", "How hard the beat hits.");
            P("_AudioLinkEmission");
            P("_AudioLinkGlow");
            P("_AudioLinkRim");
            P("_AudioLinkGlitter");
        });

        Section("Dissolve", "_DissolveToggle", () =>
        {
            P("_DissolveAmount", "Animate this 0→1 for a reveal/vanish toggle.");
            P("_DissolveEdgeColor", "Glowing edge colour (HDR).");
            P("_DissolveEdgeWidth");
            P("_DissolveScale", "Pattern size.");
            Tex("_DissolveNoise", "Noise (optional)");
            P("_DissolveTexInfluence", "Blend the texture into the procedural pattern.");
            P("_DissolveAudio", "Drive the dissolve from a music band.");
        });

        Section("Proximity Glow", "_ProximityToggle", () =>
        {
            EditorGUILayout.LabelField("Blooms as a viewer moves closer — they light you up when they approach.",
                EditorStyles.wordWrappedMiniLabel);
            P("_ProximityColor");
            P("_ProximityNear", "Distance (m) where the glow is full.");
            P("_ProximityFar", "Distance (m) where the glow fades out.");
            P("_ProximityStrength");
            P("_ProximityPower", "Falloff shape.");
        });

        Section("Toon Ramp", "_RampToggle", () =>
        {
            EditorGUILayout.LabelField("Cel-style diffuse for anime looks; blends with PBR.",
                EditorStyles.wordWrappedMiniLabel);
            P("_ShadowColor", "Tint of the shadowed side.");
            P("_RampSteps", "Number of light bands.");
            P("_RampHardness", "0 = smooth, 1 = hard cel.");
            P("_RampShadowSoftness");
        });

        Section("Lighting", null, () =>
        {
            P("_LightingDirectional", "1 = full PBR, 0 = flat anime-style.");
            P("_MinBrightness", "Keeps the avatar visible in dark worlds.");
            P("_MaxBrightness", "Tames blinding worlds.");
            P("_ShadowBoost", "Lift shadowed regions.");
        });

        Section("Animation", null, () =>
        {
            P("_PulseSpeed", "Subtle breathing speed.");
            P("_PulseAmount", "Breathing displacement.");
        });

        Section("Rendering & Blending", null, () =>
        {
            EditorGUI.BeginChangeCheck();
            int preset = (int)Get("_DstBlend") == 0 ? 0 : 1;
            preset = EditorGUILayout.Popup(new GUIContent("Mode"), preset,
                new[] { new GUIContent("Opaque / Cutout"), new GUIContent("Transparent") });
            if (EditorGUI.EndChangeCheck())
                foreach (Material m in Mats()) ApplyBlendPreset(m, preset);

            P("_Cull");
            P("_ZWrite");
            P("_ZTest");
            P("_SrcBlend");
            P("_DstBlend");
            P("_Premultiply");
        });

        EditorGUILayout.Space();
        _editor.RenderQueueField();
        _editor.EnableInstancingField();
        _editor.DoubleSidedGIField();
    }

    // ===================== Quality-of-life toolbar =====================

    private void Toolbar()
    {
        Material mat = (Material)_editor.target;

        EditorGUILayout.BeginHorizontal();
        if (GUILayout.Button(new GUIContent("Copy Look",
                "Copy every setting to the clipboard as shareable text."), EditorStyles.miniButtonLeft))
            CopyLook(mat);
        using (new EditorGUI.DisabledScope(!ClipboardHasLook()))
            if (GUILayout.Button(new GUIContent("Paste Look",
                    "Apply a Luminescence look from the clipboard."), EditorStyles.miniButtonMid))
                Apply(PasteLook);
        if (GUILayout.Button(new GUIContent("🎲 Random",
                "Roll a random gorgeous look."), EditorStyles.miniButtonMid))
            Apply(RandomLook);
        if (GUILayout.Button(new GUIContent(AnyExpanded() ? "Collapse" : "Expand",
                "Collapse or expand every section."), EditorStyles.miniButtonRight))
            SetAllFoldouts(!AnyExpanded());
        EditorGUILayout.EndHorizontal();

        PerfHint(mat);
        EditorGUILayout.Space(2);
    }

    private void PerfHint(Material m)
    {
        int kw = m.shaderKeywords.Length;
        string rank = kw <= 10 ? "Light" : kw <= 18 ? "Moderate" : "Heavy";
        Color col = kw <= 10 ? new Color(0.5f, 0.85f, 0.5f)
                  : kw <= 18 ? new Color(0.9f, 0.8f, 0.4f)
                             : new Color(0.95f, 0.45f, 0.45f);
        var st = new GUIStyle(EditorStyles.miniLabel);
        st.normal.textColor = col;
        EditorGUILayout.LabelField($"Active features: {kw} keywords · {rank} — turn off sections you don't use for best performance.", st);
    }

    private static string F(float v) => v.ToString("R", CultureInfo.InvariantCulture);
    private static float PF(string s) { float.TryParse(s, NumberStyles.Float, CultureInfo.InvariantCulture, out var v); return v; }

    private void CopyLook(Material m)
    {
        var sb = new StringBuilder("LUMI1;");
        Shader sh = m.shader;
        int count = ShaderUtil.GetPropertyCount(sh);
        for (int i = 0; i < count; i++)
        {
            string name = ShaderUtil.GetPropertyName(sh, i);
            switch (ShaderUtil.GetPropertyType(sh, i))
            {
                case ShaderUtil.ShaderPropertyType.Float:
                case ShaderUtil.ShaderPropertyType.Range:
                    sb.Append(name).Append("=f:").Append(F(m.GetFloat(name))).Append(';');
                    break;
                case ShaderUtil.ShaderPropertyType.Color:
                    Color c = m.GetColor(name);
                    sb.Append(name).Append("=c:").Append(F(c.r)).Append(',').Append(F(c.g))
                      .Append(',').Append(F(c.b)).Append(',').Append(F(c.a)).Append(';');
                    break;
                case ShaderUtil.ShaderPropertyType.Vector:
                    Vector4 v = m.GetVector(name);
                    sb.Append(name).Append("=v:").Append(F(v.x)).Append(',').Append(F(v.y))
                      .Append(',').Append(F(v.z)).Append(',').Append(F(v.w)).Append(';');
                    break;
            }
        }
        foreach (var kw in m.shaderKeywords) sb.Append('#').Append(kw).Append(';');
        GUIUtility.systemCopyBuffer = sb.ToString();
        Debug.Log("[Luminescence] Look copied to clipboard.");
    }

    private static bool ClipboardHasLook()
    {
        string s = GUIUtility.systemCopyBuffer;
        return !string.IsNullOrEmpty(s) && s.StartsWith("LUMI1;");
    }

    private void PasteLook(Material m)
    {
        string s = GUIUtility.systemCopyBuffer;
        if (string.IsNullOrEmpty(s) || !s.StartsWith("LUMI1;")) return;
        Undo.RecordObject(m, "Paste Luminescence Look");

        foreach (var kw in m.shaderKeywords) m.DisableKeyword(kw);

        string[] tokens = s.Substring(6).Split(new[] { ';' }, StringSplitOptions.RemoveEmptyEntries);
        foreach (string t in tokens)
        {
            if (t[0] == '#') { m.EnableKeyword(t.Substring(1)); continue; }
            int eq = t.IndexOf('=');
            if (eq < 1) continue;
            string name = t.Substring(0, eq);
            string val = t.Substring(eq + 1);
            if (!m.HasProperty(name) || val.Length < 2) continue;
            string body = val.Substring(2);
            if (val[0] == 'f') m.SetFloat(name, PF(body));
            else if (val[0] == 'c') { var p = body.Split(','); if (p.Length == 4) m.SetColor(name, new Color(PF(p[0]), PF(p[1]), PF(p[2]), PF(p[3]))); }
            else if (val[0] == 'v') { var p = body.Split(','); if (p.Length == 4) m.SetVector(name, new Vector4(PF(p[0]), PF(p[1]), PF(p[2]), PF(p[3]))); }
        }
        EditorUtility.SetDirty(m);
    }

    private void RandomLook(Material m)
    {
        Action<Material>[] looks =
        {
            PresetGlossy, PresetOiled, PresetLatex, PresetSweat, PresetShimmer, PresetBlushed,
            PresetIridescent, PresetGalaxy, PresetHolographic, PresetSuccubus, PresetGoddess,
            PresetChrome, PresetHoney, PresetDuotone, PresetAllure, PresetAnime
        };
        looks[UnityEngine.Random.Range(0, looks.Length)](m);
    }

    private static bool AnyExpanded()
    {
        foreach (var v in Foldouts.Values) if (v) return true;
        return false;
    }

    private static void SetAllFoldouts(bool open)
    {
        var keys = new List<string>(Foldouts.Keys);
        foreach (var k in keys) Foldouts[k] = open;
    }

    // ===================== Import / migrate from another shader =====================

    private static Material _importSource;

    // Properties whose names differ between common avatar shaders and ours.
    //   sourceName  ->  ourName
    private static readonly Dictionary<string, string> AliasMap = new Dictionary<string, string>
    {
        // URP / Lit
        { "_BaseMap",        "_MainTex" },
        { "_BaseColor",      "_Color" },
        { "_BaseColorMap",   "_MainTex" },
        // common alternate names
        { "_MainColor",      "_Color" },
        { "_NormalMap",      "_BumpMap" },
        { "_Normal",         "_BumpMap" },
        { "_NormalTex",      "_BumpMap" },
        { "_MetallicMap",    "_MetallicGlossMap" },
        { "_SpecGlossMap",   "_MetallicGlossMap" },
        { "_RoughnessMap",   "_MetallicGlossMap" },
        { "_AO",             "_OcclusionMap" },
        { "_AOMap",          "_OcclusionMap" },
        { "_Emission",       "_EmissionMap" },
        { "_EmissionTex",    "_EmissionMap" },
        { "_EmissionMask",   "_EmissionMap" },
        { "_DetailMap",      "_DetailAlbedoMap" },
        // matcap aliases (Poiyomi / lilToon)
        { "_MatCap",         "_Matcap" },
        { "_MatCapTex",      "_Matcap" },
        { "_MatcapTex",      "_Matcap" },
    };

    private void ImportPanel()
    {
        var box = new GUIStyle(EditorStyles.helpBox) { padding = new RectOffset(6, 6, 6, 6) };
        EditorGUILayout.BeginVertical(box);
        EditorGUILayout.LabelField("Import from another material", EditorStyles.miniBoldLabel);

        _importSource = (Material)EditorGUILayout.ObjectField(
            new GUIContent("Source", "Drag any material here (Poiyomi, lilToon, Standard, URP…) to copy its textures and values onto this one."),
            _importSource, typeof(Material), false);

        using (new EditorGUI.DisabledScope(_importSource == null || (_importSource != null && _importSource.Equals(_editor.target))))
        {
            EditorGUILayout.BeginHorizontal();
            if (GUILayout.Button(new GUIContent("Copy Matching",
                    "Copy every property whose name matches exactly."), GUILayout.Height(20)))
                Apply(m => ImportFrom(_importSource, m, false));
            if (GUILayout.Button(new GUIContent("Copy + Smart Map",
                    "Also translate common Poiyomi/lilToon/Standard/URP names."), GUILayout.Height(20)))
                Apply(m => ImportFrom(_importSource, m, true));
            EditorGUILayout.EndHorizontal();
        }

        if (GUILayout.Button(new GUIContent("Auto-enable from assigned maps",
                "Already pasted maps the normal Unity way? Click to switch on the matching features."), GUILayout.Height(20)))
            Apply(AutoEnable);

        EditorGUILayout.LabelField(
            "Copies textures (with tiling/offset), colours and values, then turns on the matching features.",
            EditorStyles.wordWrappedMiniLabel);
        EditorGUILayout.EndVertical();
        EditorGUILayout.Space(2);
    }

    private void ImportFrom(Material src, Material dst, bool smart)
    {
        if (src == null || src.shader == null || dst == null) return;
        Undo.RecordObject(dst, "Import Material Properties");

        Shader shader = src.shader;
        int count = ShaderUtil.GetPropertyCount(shader);
        int copied = 0;
        for (int i = 0; i < count; i++)
        {
            string name = ShaderUtil.GetPropertyName(shader, i);
            var type = ShaderUtil.GetPropertyType(shader, i);
            if (CopyProp(src, dst, name, name, type, false)) copied++;
        }

        if (smart)
        {
            foreach (var kv in AliasMap)
            {
                int idx = FindPropIndex(shader, kv.Key);
                if (idx < 0) continue;
                var type = ShaderUtil.GetPropertyType(shader, idx);
                if (CopyProp(src, dst, kv.Key, kv.Value, type, true)) copied++;
            }
        }

        AutoEnable(dst);
        Debug.Log($"[Luminescence] Imported {copied} properties from \"{src.name}\" ({shader.name}) onto \"{dst.name}\".");
    }

    // Copy a single property by type. When 'guarded' (alias mode) we never
    // clobber an existing texture with a different-named source.
    private bool CopyProp(Material src, Material dst, string srcName, string dstName,
                          ShaderUtil.ShaderPropertyType type, bool guarded)
    {
        if (!dst.HasProperty(dstName) || !src.HasProperty(srcName)) return false;
        switch (type)
        {
            case ShaderUtil.ShaderPropertyType.Color:
                dst.SetColor(dstName, src.GetColor(srcName));
                return true;
            case ShaderUtil.ShaderPropertyType.Vector:
                dst.SetVector(dstName, src.GetVector(srcName));
                return true;
            case ShaderUtil.ShaderPropertyType.Float:
            case ShaderUtil.ShaderPropertyType.Range:
                dst.SetFloat(dstName, src.GetFloat(srcName));
                return true;
            case ShaderUtil.ShaderPropertyType.TexEnv:
                Texture t = src.GetTexture(srcName);
                if (guarded && (t == null || dst.GetTexture(dstName) != null)) return false;
                dst.SetTexture(dstName, t);
                dst.SetTextureScale(dstName, src.GetTextureScale(srcName));
                dst.SetTextureOffset(dstName, src.GetTextureOffset(srcName));
                return true;
        }
        return false;
    }

    private static int FindPropIndex(Shader shader, string name)
    {
        int count = ShaderUtil.GetPropertyCount(shader);
        for (int i = 0; i < count; i++)
            if (ShaderUtil.GetPropertyName(shader, i) == name) return i;
        return -1;
    }

    // Turn on the features whose maps/values are actually present, so imported
    // or hand-pasted textures don't sit there invisible.
    private void AutoEnable(Material m)
    {
        Undo.RecordObject(m, "Auto-enable Features");
        EnableIf(m, m.GetTexture("_BumpMap") != null, "_NormalToggle", "_NORMALMAP");
        EnableIf(m, m.GetTexture("_MetallicGlossMap") != null, "_MetalToggle", "_METALLICGLOSSMAP");
        EnableIf(m, m.GetTexture("_OcclusionMap") != null, "_OcclToggle", "_OCCLUSIONMAP");
        EnableIf(m, m.GetTexture("_DetailAlbedoMap") != null || m.GetTexture("_DetailNormalMap") != null,
                 "_DetailToggle", "_DETAIL_MAP");
        EnableIf(m, m.GetTexture("_Matcap") != null, "_MatcapToggle", "_MATCAP_ON");
        EnableIf(m, m.GetTexture("_ParallaxMap") != null, "_ParallaxToggle", "_PARALLAX_ON");

        bool emits = m.GetTexture("_EmissionMap") != null &&
                     m.HasProperty("_EmissionColor") && Lum(m.GetColor("_EmissionColor")) > 0.001f;
        EnableIf(m, emits, "_EmissionToggle", "_EMISSION");
        if (emits) m.globalIlluminationFlags = MaterialGlobalIlluminationFlags.RealtimeEmissive;

        EditorUtility.SetDirty(m);
    }

    private static void EnableIf(Material m, bool cond, string toggleProp, string keyword)
    {
        if (!cond) return;
        if (m.HasProperty(toggleProp)) m.SetFloat(toggleProp, 1f);
        m.EnableKeyword(keyword);
    }

    private static float Lum(Color c) => c.r * 0.2126f + c.g * 0.7152f + c.b * 0.0722f;

    // ===================== Presets =====================
    private static readonly string[] LookToggles =
    {
        "_EmissionToggle", "_SheenToggle", "_ClearCoatToggle", "_AnisoToggle",
        "_IridToggle", "_WetnessToggle", "_SweatToggle", "_RimToggle",
        "_SSSToggle", "_TonemapToggle", "_ParallaxToggle", "_BlushToggle",
        "_GlitterToggle", "_HoloToggle", "_InnerGlowToggle", "_AudioLinkToggle",
        "_DissolveToggle", "_ProximityToggle", "_RampToggle", "_GradientToggle"
    };

    private void PresetBar()
    {
        var box = new GUIStyle(EditorStyles.helpBox) { padding = new RectOffset(6, 6, 6, 6) };
        EditorGUILayout.BeginVertical(box);
        EditorGUILayout.LabelField("Quick Looks  —  one click, then tweak", EditorStyles.miniBoldLabel);
        EditorGUILayout.BeginHorizontal();
        if (Chip("✨ Glossy Skin")) Apply(PresetGlossy);
        if (Chip("💋 Oiled"))       Apply(PresetOiled);
        if (Chip("🖤 Wet Latex"))   Apply(PresetLatex);
        EditorGUILayout.EndHorizontal();
        EditorGUILayout.BeginHorizontal();
        if (Chip("💦 Sweaty"))      Apply(PresetSweat);
        if (Chip("🌟 Shimmer"))     Apply(PresetShimmer);
        if (Chip("💗 Blushed"))     Apply(PresetBlushed);
        EditorGUILayout.EndHorizontal();
        EditorGUILayout.BeginHorizontal();
        if (Chip("🔥 Demon"))       Apply(PresetDemon);
        if (Chip("🦋 Iridescent"))  Apply(PresetIridescent);
        if (Chip("♻ Reset"))        Apply(ResetLook);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.Space(3);
        EditorGUILayout.LabelField("☠  Dangerous  —  turn heads across the instance", _danger);
        EditorGUILayout.BeginHorizontal();
        if (Chip("🌌 Galaxy"))      Apply(PresetGalaxy);
        if (Chip("🪩 Holographic")) Apply(PresetHolographic);
        if (Chip("❤️‍🔥 Succubus"))  Apply(PresetSuccubus);
        EditorGUILayout.EndHorizontal();
        EditorGUILayout.BeginHorizontal();
        if (Chip("🌹 Goddess"))     Apply(PresetGoddess);
        if (Chip("🩸 Liquid Chrome")) Apply(PresetChrome);
        if (Chip("🍯 Honey"))       Apply(PresetHoney);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.Space(3);
        EditorGUILayout.LabelField("🎶  Reactive & Stylised", EditorStyles.miniBoldLabel);
        EditorGUILayout.BeginHorizontal();
        if (Chip("🎵 Club"))        Apply(PresetClub);
        if (Chip("✨ Reveal"))      Apply(PresetReveal);
        if (Chip("💖 Allure"))      Apply(PresetAllure);
        if (Chip("🌸 Anime"))       Apply(PresetAnime);
        if (Chip("🌈 Duotone"))     Apply(PresetDuotone);
        EditorGUILayout.EndHorizontal();
        EditorGUILayout.EndVertical();
        EditorGUILayout.Space(2);
    }

    // Clears every optional "look" layer back to a neutral skin base so presets
    // never stack on top of one another.
    private void ResetLook(Material m)
    {
        foreach (var t in LookToggles)
        {
            SetF(m, t, 0);
            if (Keywords.TryGetValue(t, out var kw)) SetKw(m, kw, false);
        }
        SetC(m, "_Color", Color.white);
        SetF(m, "_Brightness", 1f); SetF(m, "_Saturation", 1f); SetF(m, "_Warmth", 0f);
        SetF(m, "_Metallic", 0f); SetF(m, "_Glossiness", 0.5f);
        SetF(m, "_FresnelGlowStrength", 0f);
        SetF(m, "_ReflectionStrength", 1f); SetF(m, "_ReflectionFresnel", 1f);
        SetC(m, "_ReflectionTint", Color.white);
        SetC(m, "_SpecularColor", Color.white);
        SetC(m, "_GradientColorA", Color.white); SetC(m, "_GradientColorB", Color.white);
        SetF(m, "_LightingDirectional", 1f);
        SetF(m, "_DissolveAmount", 0f);
        SetF(m, "_AudioLinkEmission", 0f); SetF(m, "_AudioLinkGlow", 0f);
        SetF(m, "_AudioLinkRim", 0f); SetF(m, "_AudioLinkGlitter", 0f); SetF(m, "_DissolveAudio", 0f);
        SetF(m, "_Exposure", 1f); SetF(m, "_Contrast", 1f);
        SetF(m, "_FinalSaturation", 1f); SetF(m, "_Vibrance", 0f); SetF(m, "_HueShift", 0f);
    }

    private void Apply(Action<Material> preset)
    {
        foreach (var m in Mats())
        {
            preset(m);
            EditorUtility.SetDirty(m);
        }
    }

    private void Enable(Material m, string toggleProp)
    {
        SetF(m, toggleProp, 1f);
        if (Keywords.TryGetValue(toggleProp, out var kw)) SetKw(m, kw, true);
    }

    // Natural, dewy, flattering skin — the everyday "sexy".
    private void PresetGlossy(Material m)
    {
        ResetLook(m);
        SetF(m, "_Glossiness", 0.6f);
        Enable(m, "_SheenToggle");
        SetC(m, "_SheenColor", new Color(1f, 0.62f, 0.66f, 1f));
        SetF(m, "_SheenIntensity", 0.9f); SetF(m, "_SheenRoughness", 0.55f); SetF(m, "_SheenLit", 0.6f);
        Enable(m, "_ClearCoatToggle");
        SetF(m, "_ClearCoat", 0.5f); SetF(m, "_ClearCoatSmoothness", 0.85f);
        Enable(m, "_WetnessToggle");
        SetF(m, "_Wetness", 0.22f); SetF(m, "_WetnessSmoothness", 0.9f);
        SetC(m, "_WetnessColor", new Color(0.78f, 0.72f, 0.72f, 1f)); SetF(m, "_WetnessMetallic", 0.04f);
        Enable(m, "_SSSToggle");
        SetC(m, "_SSSColor", new Color(1f, 0.42f, 0.3f, 1f)); SetF(m, "_SSSStrength", 0.6f);
        Enable(m, "_TonemapToggle");
        SetF(m, "_Contrast", 1.06f); SetF(m, "_Vibrance", 0.3f);
    }

    // Oiled, sun-kissed skin with a silky anisotropic sheen — very "sexy".
    private void PresetOiled(Material m)
    {
        ResetLook(m);
        SetF(m, "_Warmth", 0.35f);
        SetF(m, "_Glossiness", 0.72f);
        Enable(m, "_AnisoToggle");
        SetF(m, "_Anisotropy", 0.6f); SetF(m, "_AnisoAngle", 1.57f);
        Enable(m, "_ClearCoatToggle");
        SetF(m, "_ClearCoat", 0.7f); SetF(m, "_ClearCoatSmoothness", 0.9f);
        Enable(m, "_WetnessToggle");
        SetF(m, "_Wetness", 0.35f); SetF(m, "_WetnessSmoothness", 0.93f);
        SetC(m, "_WetnessColor", new Color(0.7f, 0.6f, 0.55f, 1f));
        Enable(m, "_SheenToggle");
        SetC(m, "_SheenColor", new Color(1f, 0.7f, 0.55f, 1f));
        SetF(m, "_SheenIntensity", 1.0f); SetF(m, "_SheenRoughness", 0.6f); SetF(m, "_SheenLit", 0.55f);
        Enable(m, "_SSSToggle");
        SetC(m, "_SSSColor", new Color(1f, 0.4f, 0.3f, 1f)); SetF(m, "_SSSStrength", 0.7f);
        Enable(m, "_TonemapToggle");
        SetF(m, "_Contrast", 1.08f); SetF(m, "_Vibrance", 0.35f);
    }

    // Body shimmer / highlighter — twinkling glitter over dewy skin.
    private void PresetShimmer(Material m)
    {
        ResetLook(m);
        SetF(m, "_Glossiness", 0.62f); SetF(m, "_Warmth", 0.15f);
        Enable(m, "_GlitterToggle");
        SetC(m, "_GlitterColor", new Color(1f, 0.85f, 0.95f, 1f));
        SetF(m, "_GlitterIntensity", 2f); SetF(m, "_GlitterDensity", 320f);
        SetF(m, "_GlitterCoverage", 0.55f); SetF(m, "_GlitterSpeed", 5f); SetF(m, "_GlitterSharpness", 18f);
        Enable(m, "_SheenToggle");
        SetC(m, "_SheenColor", new Color(1f, 0.7f, 0.8f, 1f)); SetF(m, "_SheenIntensity", 0.9f);
        Enable(m, "_WetnessToggle");
        SetF(m, "_Wetness", 0.2f); SetF(m, "_WetnessSmoothness", 0.9f);
        Enable(m, "_TonemapToggle");
        SetF(m, "_Vibrance", 0.4f);
    }

    // Soft flushed look — rosy blush, warm skin, gentle sheen.
    private void PresetBlushed(Material m)
    {
        ResetLook(m);
        SetF(m, "_Warmth", 0.2f); SetF(m, "_Glossiness", 0.58f);
        Enable(m, "_BlushToggle");
        SetC(m, "_BlushColor", new Color(1f, 0.42f, 0.48f, 1f));
        SetF(m, "_BlushStrength", 0.55f); SetF(m, "_BlushFresnel", 0.4f);
        Enable(m, "_SheenToggle");
        SetC(m, "_SheenColor", new Color(1f, 0.6f, 0.62f, 1f)); SetF(m, "_SheenIntensity", 0.85f);
        Enable(m, "_SSSToggle");
        SetC(m, "_SSSColor", new Color(1f, 0.45f, 0.4f, 1f)); SetF(m, "_SSSStrength", 0.8f);
        Enable(m, "_ClearCoatToggle");
        SetF(m, "_ClearCoat", 0.4f); SetF(m, "_ClearCoatSmoothness", 0.82f);
        Enable(m, "_TonemapToggle");
        SetF(m, "_Contrast", 1.05f); SetF(m, "_Vibrance", 0.35f);
    }

    // Glossy black latex / rubber.
    private void PresetLatex(Material m)
    {
        ResetLook(m);
        SetC(m, "_Color", new Color(0.10f, 0.10f, 0.11f, 1f));
        SetF(m, "_Glossiness", 0.9f);
        Enable(m, "_ClearCoatToggle");
        SetF(m, "_ClearCoat", 1f); SetF(m, "_ClearCoatSmoothness", 0.97f);
        Enable(m, "_WetnessToggle");
        SetF(m, "_Wetness", 0.6f); SetF(m, "_WetnessSmoothness", 0.97f);
        SetC(m, "_WetnessColor", new Color(0.4f, 0.4f, 0.42f, 1f)); SetF(m, "_WetnessMetallic", 0.1f);
        SetF(m, "_ReflectionStrength", 1.4f);
        Enable(m, "_SheenToggle");
        SetC(m, "_SheenColor", new Color(0.8f, 0.85f, 1f, 1f));
        SetF(m, "_SheenIntensity", 0.5f); SetF(m, "_SheenRoughness", 0.4f); SetF(m, "_SheenLit", 0.4f);
        Enable(m, "_TonemapToggle");
        SetF(m, "_Contrast", 1.1f); SetF(m, "_Vibrance", 0.3f);
    }

    // Dark reflective skin with a burning red edge glow (no painted map needed).
    private void PresetDemon(Material m)
    {
        ResetLook(m);
        SetC(m, "_Color", new Color(0.14f, 0.04f, 0.05f, 1f));
        SetF(m, "_Glossiness", 0.8f); SetF(m, "_Metallic", 0.3f);
        Enable(m, "_ClearCoatToggle");
        SetF(m, "_ClearCoat", 0.8f); SetF(m, "_ClearCoatSmoothness", 0.9f);
        SetF(m, "_ReflectionStrength", 1.3f);
        SetC(m, "_FresnelGlowColor", new Color(3f, 0.15f, 0.05f, 1f));
        SetF(m, "_FresnelGlowStrength", 1.2f); SetF(m, "_FresnelGlowPower", 4f);
        Enable(m, "_RimToggle");
        SetC(m, "_RimColor", new Color(4f, 0.2f, 0.05f, 1f));
        SetF(m, "_RimPower", 5f); SetF(m, "_RimStrength", 2f);
        // Pre-tuned for a glowing crack map if you add one (Emission section).
        SetC(m, "_EmissionColor", new Color(4f, 0.2f, 0.05f, 1f));
        SetF(m, "_EmissionStrength", 3f); SetF(m, "_EmissionPulseSpeed", 1.5f); SetF(m, "_EmissionPulseMin", 0.5f);
        Enable(m, "_TonemapToggle");
        SetF(m, "_Contrast", 1.15f); SetF(m, "_Vibrance", 0.4f);
    }

    // Colour-shifting thin-film sheen.
    private void PresetIridescent(Material m)
    {
        ResetLook(m);
        SetC(m, "_Color", new Color(0.2f, 0.2f, 0.22f, 1f));
        SetF(m, "_Glossiness", 0.9f); SetF(m, "_Metallic", 0.4f);
        Enable(m, "_IridToggle");
        SetF(m, "_Iridescence", 0.85f); SetF(m, "_IridescenceFreq", 5f);
        Enable(m, "_ClearCoatToggle");
        SetF(m, "_ClearCoat", 1f); SetF(m, "_ClearCoatSmoothness", 0.95f);
        SetF(m, "_ReflectionStrength", 1.4f);
        Enable(m, "_SheenToggle");
        SetC(m, "_SheenColor", new Color(0.7f, 0.8f, 1f, 1f)); SetF(m, "_SheenIntensity", 0.7f);
        Enable(m, "_TonemapToggle");
        SetF(m, "_Contrast", 1.1f); SetF(m, "_Vibrance", 0.5f);
    }

    // Dewy skin with animated trickling sweat + warm subsurface glow.
    private void PresetSweat(Material m)
    {
        ResetLook(m);
        SetF(m, "_Glossiness", 0.7f);
        Enable(m, "_SweatToggle");
        SetF(m, "_SweatAmount", 0.5f); SetF(m, "_SweatSparkle", 1.7f);
        SetF(m, "_SweatSpeed", 0.2f); SetF(m, "_SweatScale", 7f);
        Enable(m, "_WetnessToggle");
        SetF(m, "_Wetness", 0.25f); SetF(m, "_WetnessSmoothness", 0.92f);
        Enable(m, "_SheenToggle");
        SetC(m, "_SheenColor", new Color(1f, 0.7f, 0.7f, 1f)); SetF(m, "_SheenIntensity", 0.8f);
        Enable(m, "_SSSToggle");
        SetC(m, "_SSSColor", new Color(1f, 0.4f, 0.3f, 1f)); SetF(m, "_SSSStrength", 0.8f);
        Enable(m, "_TonemapToggle");
        SetF(m, "_Vibrance", 0.35f);
    }

    // ===================== Dangerous presets =====================

    // Deep-space chrome: dark metallic body, nebula holographic reflection
    // and sparse twinkling star-flakes — like polished obsidian galaxy glass.
    private void PresetGalaxy(Material m)
    {
        ResetLook(m);
        SetC(m, "_Color", new Color(0.05f, 0.04f, 0.09f, 1f));
        SetF(m, "_Metallic", 0.9f); SetF(m, "_Glossiness", 0.93f);
        SetF(m, "_ReflectionStrength", 1.6f); SetF(m, "_ReflectionFresnel", 1f);
        Enable(m, "_ClearCoatToggle"); SetF(m, "_ClearCoat", 1f); SetF(m, "_ClearCoatSmoothness", 0.97f);
        Enable(m, "_HoloToggle");
        SetF(m, "_HoloStrength", 0.6f); SetF(m, "_HoloFreq", 3.5f); SetF(m, "_HoloSpeed", 0.4f);
        Enable(m, "_GlitterToggle");
        SetC(m, "_GlitterColor", new Color(1.2f, 1.2f, 1.8f, 1f));
        SetF(m, "_GlitterIntensity", 3f); SetF(m, "_GlitterDensity", 520f);
        SetF(m, "_GlitterCoverage", 0.1f); SetF(m, "_GlitterSharpness", 10f); SetF(m, "_GlitterSpeed", 2.5f);
        Enable(m, "_InnerGlowToggle");
        SetC(m, "_InnerGlowColor", new Color(0.7f, 0.35f, 1.6f, 1f));
        SetF(m, "_InnerGlowStrength", 0.5f); SetF(m, "_InnerGlowPower", 3.5f);
        SetF(m, "_InnerGlowPulse", 0.8f); SetF(m, "_InnerGlowPulseMin", 0.6f);
        Enable(m, "_TonemapToggle");
        SetF(m, "_Contrast", 1.12f); SetF(m, "_Vibrance", 0.5f);
    }

    // Oil-slick chrome: a flawless mirror whose every reflection runs with
    // flowing rainbow — the reflection does the work, so it follows the body.
    private void PresetHolographic(Material m)
    {
        ResetLook(m);
        SetC(m, "_Color", new Color(0.55f, 0.55f, 0.58f, 1f));
        SetF(m, "_Metallic", 0.95f); SetF(m, "_Glossiness", 0.96f);
        SetF(m, "_ReflectionStrength", 1.7f); SetF(m, "_ReflectionFresnel", 1f);
        Enable(m, "_HoloToggle");
        SetF(m, "_HoloStrength", 0.9f); SetF(m, "_HoloFreq", 5f); SetF(m, "_HoloSpeed", 0.8f);
        Enable(m, "_ClearCoatToggle"); SetF(m, "_ClearCoat", 1f); SetF(m, "_ClearCoatSmoothness", 0.99f);
        Enable(m, "_TonemapToggle");
        SetF(m, "_Contrast", 1.1f); SetF(m, "_Vibrance", 0.5f);
    }

    // Burning seductress: deep red glossy skin, a beating glow that lives only
    // at the silhouette, a red gradient rim and a sheen of sweat.
    private void PresetSuccubus(Material m)
    {
        ResetLook(m);
        SetC(m, "_Color", new Color(0.20f, 0.03f, 0.04f, 1f));
        SetF(m, "_Metallic", 0.3f); SetF(m, "_Glossiness", 0.85f);
        SetF(m, "_ReflectionStrength", 1.4f); SetF(m, "_ReflectionFresnel", 1f);
        Enable(m, "_ClearCoatToggle"); SetF(m, "_ClearCoat", 0.9f); SetF(m, "_ClearCoatSmoothness", 0.92f);
        Enable(m, "_RimToggle");
        SetC(m, "_RimColor", new Color(4f, 0.35f, 0.12f, 1f));
        SetC(m, "_RimColor2", new Color(2.5f, 0.03f, 0.12f, 1f));
        SetF(m, "_RimPower", 3.5f); SetF(m, "_RimStrength", 1.8f);
        Enable(m, "_InnerGlowToggle");
        SetC(m, "_InnerGlowColor", new Color(2.5f, 0.06f, 0.1f, 1f));
        SetF(m, "_InnerGlowStrength", 0.7f); SetF(m, "_InnerGlowPower", 3.5f);
        SetF(m, "_InnerGlowPulse", 5.5f); SetF(m, "_InnerGlowPulseMin", 0.55f); SetF(m, "_InnerGlowHeartbeat", 1f);
        Enable(m, "_SweatToggle");
        SetF(m, "_SweatAmount", 0.35f); SetF(m, "_SweatSparkle", 1.4f); SetF(m, "_SweatScale", 7f);
        Enable(m, "_TonemapToggle");
        SetF(m, "_Contrast", 1.15f); SetF(m, "_Vibrance", 0.45f);
    }

    // Radiant goddess: warm pearlescent skin, soft golden sheen, a whisper of
    // shimmer and blush, and a backlit halo that gently breathes.
    private void PresetGoddess(Material m)
    {
        ResetLook(m);
        SetF(m, "_Warmth", 0.28f); SetF(m, "_Glossiness", 0.72f); SetF(m, "_Metallic", 0.08f);
        SetC(m, "_ReflectionTint", new Color(1f, 0.92f, 0.78f, 1f)); SetF(m, "_ReflectionStrength", 1.2f);
        Enable(m, "_SheenToggle");
        SetC(m, "_SheenColor", new Color(1.4f, 1.05f, 0.7f, 1f));
        SetF(m, "_SheenIntensity", 1.1f); SetF(m, "_SheenRoughness", 0.55f); SetF(m, "_SheenLit", 0.5f);
        Enable(m, "_ClearCoatToggle"); SetF(m, "_ClearCoat", 0.55f); SetF(m, "_ClearCoatSmoothness", 0.88f);
        Enable(m, "_IridToggle"); SetF(m, "_Iridescence", 0.25f); SetF(m, "_IridescenceFreq", 4f);
        Enable(m, "_GlitterToggle");
        SetC(m, "_GlitterColor", new Color(1.6f, 1.3f, 0.85f, 1f));
        SetF(m, "_GlitterIntensity", 2.2f); SetF(m, "_GlitterCoverage", 0.08f); SetF(m, "_GlitterDensity", 420f);
        Enable(m, "_BlushToggle");
        SetC(m, "_BlushColor", new Color(1f, 0.55f, 0.55f, 1f)); SetF(m, "_BlushStrength", 0.4f); SetF(m, "_BlushFresnel", 0.35f);
        Enable(m, "_SSSToggle");
        SetC(m, "_SSSColor", new Color(1f, 0.5f, 0.35f, 1f)); SetF(m, "_SSSStrength", 0.8f);
        Enable(m, "_InnerGlowToggle");
        SetC(m, "_InnerGlowColor", new Color(1.6f, 1.25f, 0.75f, 1f));
        SetF(m, "_InnerGlowStrength", 0.5f); SetF(m, "_InnerGlowPower", 3f);
        SetF(m, "_InnerGlowPulse", 1f); SetF(m, "_InnerGlowPulseMin", 0.65f);
        Enable(m, "_RimToggle");
        SetC(m, "_RimColor", new Color(2f, 1.7f, 1.1f, 1f)); SetC(m, "_RimColor2", new Color(1.5f, 1.1f, 1.5f, 1f));
        SetF(m, "_RimPower", 5f); SetF(m, "_RimStrength", 1.2f);
        Enable(m, "_TonemapToggle");
        SetF(m, "_Contrast", 1.06f); SetF(m, "_Vibrance", 0.4f);
    }

    // Liquid chrome: flawless mirror metal that drinks in the world.
    private void PresetChrome(Material m)
    {
        ResetLook(m);
        SetC(m, "_Color", new Color(0.9f, 0.9f, 0.92f, 1f));
        SetF(m, "_Metallic", 1f); SetF(m, "_Glossiness", 1f);
        SetF(m, "_ReflectionStrength", 1.8f); SetF(m, "_ReflectionFresnel", 1f);
        Enable(m, "_ClearCoatToggle"); SetF(m, "_ClearCoat", 1f); SetF(m, "_ClearCoatSmoothness", 1f);
        Enable(m, "_AnisoToggle"); SetF(m, "_Anisotropy", 0.3f); SetF(m, "_AnisoAngle", 1.57f);
        Enable(m, "_TonemapToggle");
        SetF(m, "_Contrast", 1.12f); SetF(m, "_Vibrance", 0.3f);
    }

    // Dripping gold honey: warm molten metal sheen, slick and glistening.
    private void PresetHoney(Material m)
    {
        ResetLook(m);
        SetC(m, "_Color", new Color(0.55f, 0.32f, 0.07f, 1f));
        SetF(m, "_Warmth", 0.4f);
        SetF(m, "_Metallic", 0.85f); SetF(m, "_Glossiness", 0.9f);
        SetF(m, "_ReflectionStrength", 1.5f);
        Enable(m, "_ClearCoatToggle"); SetF(m, "_ClearCoat", 1f); SetF(m, "_ClearCoatSmoothness", 0.95f);
        Enable(m, "_WetnessToggle");
        SetF(m, "_Wetness", 0.45f); SetF(m, "_WetnessSmoothness", 0.96f);
        SetC(m, "_WetnessColor", new Color(0.7f, 0.5f, 0.2f, 1f)); SetF(m, "_WetnessMetallic", 0.3f);
        Enable(m, "_SheenToggle");
        SetC(m, "_SheenColor", new Color(1.6f, 1.0f, 0.4f, 1f)); SetF(m, "_SheenIntensity", 1.1f);
        Enable(m, "_TonemapToggle");
        SetF(m, "_Contrast", 1.12f); SetF(m, "_Vibrance", 0.5f);
    }

    // ===================== Reactive & stylised presets =====================

    // Music-reactive club skin: glossy dark body whose glow, glitter and rim
    // pulse to the beat. (Switch on in any AudioLink world.)
    private void PresetClub(Material m)
    {
        ResetLook(m);
        SetC(m, "_Color", new Color(0.06f, 0.05f, 0.09f, 1f));
        SetF(m, "_Metallic", 0.55f); SetF(m, "_Glossiness", 0.9f);
        SetF(m, "_ReflectionStrength", 1.4f);
        Enable(m, "_ClearCoatToggle"); SetF(m, "_ClearCoat", 1f); SetF(m, "_ClearCoatSmoothness", 0.95f);
        Enable(m, "_InnerGlowToggle");
        SetC(m, "_InnerGlowColor", new Color(0.4f, 1.6f, 2.2f, 1f));
        SetF(m, "_InnerGlowStrength", 0.8f); SetF(m, "_InnerGlowPower", 3f);
        SetF(m, "_InnerGlowPulse", 2f); SetF(m, "_InnerGlowPulseMin", 0.4f);
        Enable(m, "_GlitterToggle");
        SetC(m, "_GlitterColor", new Color(1.4f, 1.2f, 1.8f, 1f));
        SetF(m, "_GlitterIntensity", 3f); SetF(m, "_GlitterCoverage", 0.12f); SetF(m, "_GlitterDensity", 480f);
        Enable(m, "_RimToggle");
        SetC(m, "_RimColor", new Color(0.4f, 2.5f, 3f, 1f)); SetC(m, "_RimColor2", new Color(2.6f, 0.3f, 2.4f, 1f));
        SetF(m, "_RimPower", 4f); SetF(m, "_RimStrength", 1.8f);
        Enable(m, "_AudioLinkToggle");
        SetF(m, "_AudioLinkPunch", 2.2f);
        SetF(m, "_AudioLinkGlow", 1f);     // bass
        SetF(m, "_AudioLinkRim", 2f);      // low-mid
        SetF(m, "_AudioLinkGlitter", 4f);  // treble
        Enable(m, "_TonemapToggle");
        SetF(m, "_Contrast", 1.15f); SetF(m, "_Vibrance", 0.6f);
    }

    // Reveal / dissolve toggle, ready to animate. Amount stays 0 (fully visible);
    // animate _DissolveAmount 0→1 for a glowing vanish.
    private void PresetReveal(Material m)
    {
        ResetLook(m);
        SetF(m, "_Glossiness", 0.7f);
        Enable(m, "_SheenToggle");
        SetC(m, "_SheenColor", new Color(0.7f, 1.1f, 1.4f, 1f)); SetF(m, "_SheenIntensity", 0.8f);
        Enable(m, "_DissolveToggle");
        SetF(m, "_DissolveAmount", 0f);
        SetC(m, "_DissolveEdgeColor", new Color(0.3f, 3f, 4f, 1f));
        SetF(m, "_DissolveEdgeWidth", 0.08f); SetF(m, "_DissolveScale", 7f);
        Enable(m, "_TonemapToggle");
        SetF(m, "_Vibrance", 0.45f);
    }

    // Allure: a warm glow that blooms only as someone steps close to you.
    private void PresetAllure(Material m)
    {
        ResetLook(m);
        SetF(m, "_Warmth", 0.2f); SetF(m, "_Glossiness", 0.62f);
        Enable(m, "_SheenToggle");
        SetC(m, "_SheenColor", new Color(1.3f, 0.7f, 0.8f, 1f)); SetF(m, "_SheenIntensity", 0.9f);
        Enable(m, "_ProximityToggle");
        SetC(m, "_ProximityColor", new Color(2.2f, 0.5f, 0.9f, 1f));
        SetF(m, "_ProximityNear", 0.4f); SetF(m, "_ProximityFar", 2.5f);
        SetF(m, "_ProximityStrength", 2.5f); SetF(m, "_ProximityPower", 2f);
        Enable(m, "_BlushToggle");
        SetC(m, "_BlushColor", new Color(1f, 0.5f, 0.55f, 1f)); SetF(m, "_BlushStrength", 0.4f);
        Enable(m, "_SSSToggle");
        SetC(m, "_SSSColor", new Color(1f, 0.45f, 0.4f, 1f)); SetF(m, "_SSSStrength", 0.7f);
        Enable(m, "_TonemapToggle");
        SetF(m, "_Vibrance", 0.4f);
    }

    // Anime: cel-shaded cutie — toon ramp, blush, soft sheen and a clean rim.
    private void PresetAnime(Material m)
    {
        ResetLook(m);
        SetF(m, "_Glossiness", 0.5f); SetF(m, "_LightingDirectional", 0.85f);
        Enable(m, "_RampToggle");
        SetC(m, "_ShadowColor", new Color(0.55f, 0.45f, 0.62f, 1f));
        SetF(m, "_RampSteps", 2f); SetF(m, "_RampHardness", 0.85f); SetF(m, "_RampShadowSoftness", 0.12f);
        Enable(m, "_BlushToggle");
        SetC(m, "_BlushColor", new Color(1f, 0.5f, 0.55f, 1f)); SetF(m, "_BlushStrength", 0.5f); SetF(m, "_BlushFresnel", 0.4f);
        Enable(m, "_SheenToggle");
        SetC(m, "_SheenColor", new Color(1f, 0.85f, 0.9f, 1f)); SetF(m, "_SheenIntensity", 0.6f);
        Enable(m, "_RimToggle");
        SetC(m, "_RimColor", new Color(1.6f, 1.5f, 1.8f, 1f)); SetC(m, "_RimColor2", new Color(1.8f, 1.4f, 1.6f, 1f));
        SetF(m, "_RimPower", 6f); SetF(m, "_RimStrength", 1.2f);
        Enable(m, "_TonemapToggle");
        SetF(m, "_Contrast", 1.05f); SetF(m, "_Vibrance", 0.4f);
    }

    // Duotone: dreamy pastel gradient skin with a soft sheen and coat.
    private void PresetDuotone(Material m)
    {
        ResetLook(m);
        SetF(m, "_Glossiness", 0.62f);
        Enable(m, "_GradientToggle");
        SetC(m, "_GradientColorA", new Color(1.1f, 0.45f, 0.95f, 1f));  // magenta
        SetC(m, "_GradientColorB", new Color(0.45f, 0.85f, 1.3f, 1f));  // cyan
        SetF(m, "_GradientScale", 1.2f); SetF(m, "_GradientOffset", -0.1f); SetF(m, "_GradientMode", 0f);
        Enable(m, "_SheenToggle");
        SetC(m, "_SheenColor", new Color(1f, 0.8f, 1f, 1f)); SetF(m, "_SheenIntensity", 0.8f);
        Enable(m, "_ClearCoatToggle"); SetF(m, "_ClearCoat", 0.5f); SetF(m, "_ClearCoatSmoothness", 0.86f);
        Enable(m, "_TonemapToggle");
        SetF(m, "_Vibrance", 0.5f); SetF(m, "_Contrast", 1.05f);
    }

    // ===================== Blend presets =====================
    private void ApplyBlendPreset(Material m, int preset)
    {
        if (preset == 0)
        {
            bool cutout = m.HasProperty("_AlphaTest") && m.GetFloat("_AlphaTest") > 0.5f;
            m.SetFloat("_SrcBlend", (float)BlendMode.One);
            m.SetFloat("_DstBlend", (float)BlendMode.Zero);
            m.SetFloat("_ZWrite", 1);
            m.SetFloat("_Premultiply", 0);
            m.DisableKeyword("_ALPHAPREMULTIPLY_ON");
            m.renderQueue = cutout ? (int)RenderQueue.AlphaTest : (int)RenderQueue.Geometry;
            m.SetOverrideTag("RenderType", cutout ? "TransparentCutout" : "Opaque");
        }
        else
        {
            m.SetFloat("_SrcBlend", (float)BlendMode.One);
            m.SetFloat("_DstBlend", (float)BlendMode.OneMinusSrcAlpha);
            m.SetFloat("_ZWrite", 0);
            m.SetFloat("_Premultiply", 1);
            m.EnableKeyword("_ALPHAPREMULTIPLY_ON");
            m.renderQueue = (int)RenderQueue.Transparent;
            m.SetOverrideTag("RenderType", "Transparent");
        }
    }

    // ===================== UI primitives =====================
    private void Banner()
    {
        Rect r = EditorGUILayout.GetControlRect(false, 40);
        EditorGUI.DrawRect(r, new Color(0.12f, 0.10f, 0.16f, 1f));
        Rect strip = new Rect(r.x, r.yMax - 2, r.width, 2);
        EditorGUI.DrawRect(strip, Accent);
        EditorGUI.LabelField(new Rect(r.x + 10, r.y + 4, r.width - 20, 20), "✦  LUMINESCENCE", _title);
        EditorGUI.LabelField(new Rect(r.x + 10, r.y + 22, r.width - 20, 14),
            "Premium VRChat avatar shader  ·  v" + Version, _sub);
        EditorGUILayout.Space(2);
    }

    private void Section(string title, string toggleProp, Action body)
    {
        if (!Foldouts.ContainsKey(title)) Foldouts[title] = true;
        var tp = toggleProp != null ? Find(toggleProp) : null;
        bool enabled = tp == null || tp.floatValue > 0.5f;

        Color accent = AccentFor(title);
        Rect bar = EditorGUILayout.GetControlRect(false, 22);
        Color barCol = enabled ? Color.Lerp(BarOn, accent, 0.22f) : BarOff;
        EditorGUI.DrawRect(bar, barCol);
        if (enabled)
            EditorGUI.DrawRect(new Rect(bar.x, bar.y, 3, bar.height), accent);

        Rect foldRect = new Rect(bar.x + 10, bar.y + 3, bar.width - 40, 16);
        Foldouts[title] = EditorGUI.Foldout(foldRect, Foldouts[title], title, true, _foldLabel);

        if (tp != null)
        {
            Rect tRect = new Rect(bar.xMax - 22, bar.y + 3, 16, 16);
            EditorGUI.BeginChangeCheck();
            bool v = EditorGUI.Toggle(tRect, tp.floatValue > 0.5f);
            if (EditorGUI.EndChangeCheck())
            {
                tp.floatValue = v ? 1f : 0f;
                string kw = Keywords.ContainsKey(toggleProp) ? Keywords[toggleProp] : null;
                if (kw != null) foreach (var m in Mats()) SetKw(m, kw, v);
                enabled = v;
            }
        }

        if (Foldouts[title])
        {
            EditorGUILayout.BeginVertical(EditorStyles.helpBox);
            EditorGUI.indentLevel++;
            EditorGUI.BeginDisabledGroup(tp != null && !enabled);
            body();
            EditorGUI.EndDisabledGroup();
            EditorGUI.indentLevel--;
            EditorGUILayout.EndVertical();
        }
        EditorGUILayout.Space(1);
    }

    // Category accent colours so related sections read as a group.
    private static readonly Color AcSexy = new Color(0.92f, 0.34f, 0.55f); // rose
    private static readonly Color AcMat  = new Color(0.42f, 0.62f, 0.95f); // blue
    private static readonly Color AcFx   = new Color(0.72f, 0.45f, 0.95f); // violet
    private static readonly Color AcUtil = new Color(0.55f, 0.60f, 0.68f); // slate

    private static Color AccentFor(string title)
    {
        switch (title)
        {
            case "Sheen — Skin Glow":
            case "Wetness":
            case "Sweat":
            case "Blush — Flush":
            case "Glitter — Body Shimmer":
            case "Inner Glow":
            case "Subsurface (SSS)":
            case "Proximity Glow":
            case "Rim Light":
            case "Gradient Tint":
                return AcSexy;
            case "Base":
            case "Normal & Detail":
            case "Surface (PBR)":
            case "Reflections":
            case "Clear Coat":
                return AcMat;
            case "Emission Glow":
            case "Holographic Flow":
            case "Iridescence":
            case "Anisotropy":
            case "Parallax Depth":
            case "Matcap":
            case "Dissolve":
            case "AudioLink — React to Music":
                return AcFx;
            default:
                return AcUtil;
        }
    }

    private bool Chip(string label)
    {
        return GUILayout.Button(label, _chip, GUILayout.Height(22));
    }

    private void MiniLabel(string t) => EditorGUILayout.LabelField(t, EditorStyles.miniBoldLabel);
    private void Space() => EditorGUILayout.Space(3);

    // ===================== helpers =====================
    private IEnumerable<Material> Mats()
    {
        foreach (var o in _editor.targets) yield return (Material)o;
    }

    private MaterialProperty Find(string n) => FindProperty(n, _props, false);
    private float Get(string n) { var p = Find(n); return p != null ? p.floatValue : 0f; }
    private bool On(string n) => Get(n) > 0.5f;

    private void P(string n, string tip = null)
    {
        var p = Find(n);
        if (p == null) return;
        _editor.ShaderProperty(p, new GUIContent(p.displayName, tip));
    }

    private void Tex(string n, string label, string extra = null, string tip = null)
    {
        var p = Find(n);
        if (p == null) return;
        var ex = extra != null ? Find(extra) : null;
        _editor.TexturePropertySingleLine(new GUIContent(label, tip), p, ex);
        _editor.TextureScaleOffsetProperty(p);
    }

    private static void SetF(Material m, string n, float v) { if (m.HasProperty(n)) m.SetFloat(n, v); }
    private static void SetC(Material m, string n, Color c) { if (m.HasProperty(n)) m.SetColor(n, c); }
    private static void SetKw(Material m, string kw, bool on)
    { if (on) m.EnableKeyword(kw); else m.DisableKeyword(kw); }

    private IDisposable Disabled(bool d) => new DisabledScope(d);
    private class DisabledScope : IDisposable
    {
        public DisabledScope(bool d) => EditorGUI.BeginDisabledGroup(d);
        public void Dispose() => EditorGUI.EndDisabledGroup();
    }

    private void InitStyles()
    {
        if (_stylesReady) return;
        _foldLabel = new GUIStyle(EditorStyles.foldout)
        { fontStyle = FontStyle.Bold, richText = true };
        _foldLabel.normal.textColor = _foldLabel.onNormal.textColor = new Color(0.92f, 0.92f, 0.95f);
        _foldLabel.focused.textColor = _foldLabel.onFocused.textColor = new Color(0.92f, 0.92f, 0.95f);
        _foldLabel.active.textColor = _foldLabel.onActive.textColor = Color.white;

        _title = new GUIStyle(EditorStyles.boldLabel) { fontSize = 14 };
        _title.normal.textColor = Color.white;
        _sub = new GUIStyle(EditorStyles.miniLabel);
        _sub.normal.textColor = new Color(0.75f, 0.7f, 0.8f);

        _chip = new GUIStyle(EditorStyles.miniButton) { fontSize = 11 };

        _danger = new GUIStyle(EditorStyles.miniBoldLabel);
        _danger.normal.textColor = new Color(0.95f, 0.35f, 0.45f);
        _stylesReady = true;
    }
}
#endif

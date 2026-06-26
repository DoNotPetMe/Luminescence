// =====================================================================
//  LuminescenceGUI - organised inspector for the Luminescence shader.
//  Groups the (many) options into collapsible sections and keeps the
//  toggle keywords / render state in sync.
// =====================================================================
#if UNITY_EDITOR
using System;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

public class LuminescenceGUI : ShaderGUI
{
    private static readonly Dictionary<string, bool> Foldouts = new Dictionary<string, bool>();

    private MaterialEditor _editor;
    private MaterialProperty[] _props;

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        _editor = materialEditor;
        _props = properties;
        Material mat = materialEditor.target as Material;

        EditorGUILayout.Space();
        EditorGUILayout.LabelField("✦ Luminescence", EditorStyles.boldLabel);
        EditorGUILayout.LabelField("PBR avatar shader · reflections · wetness · sweat · glow",
            EditorStyles.miniLabel);
        EditorGUILayout.Space();

        Section("Base", () =>
        {
            TexProp("_MainTex", "Albedo", "_Color");
            Prop("_Saturation");
            Prop("_Brightness");
            Prop("_AlphaTest");
            if (GetFloat("_AlphaTest") > 0.5f) Prop("_Cutoff");
        });

        Section("Normal & Detail", () =>
        {
            Prop("_NormalToggle");
            if (GetFloat("_NormalToggle") > 0.5f)
            {
                TexProp("_BumpMap", "Normal Map");
                Prop("_BumpScale");
            }
            Prop("_DetailToggle");
            if (GetFloat("_DetailToggle") > 0.5f)
            {
                TexProp("_DetailAlbedoMap", "Detail Albedo");
                TexProp("_DetailNormalMap", "Detail Normal");
                Prop("_DetailNormalMapScale");
                TexProp("_DetailMask", "Detail Mask (A)");
            }
        });

        Section("Surface (PBR)", () =>
        {
            Prop("_MetalToggle");
            if (GetFloat("_MetalToggle") > 0.5f)
            {
                TexProp("_MetallicGlossMap", "Metallic (R) Smooth (A)");
                Prop("_GlossMapScale");
            }
            Prop("_Metallic");
            Prop("_Glossiness");
            Prop("_SpecularTint");
            Prop("_OcclToggle");
            if (GetFloat("_OcclToggle") > 0.5f)
            {
                TexProp("_OcclusionMap", "Occlusion (G)");
                Prop("_OcclusionStrength");
            }
        });

        Section("Reflections", () =>
        {
            Prop("_NoReflections");
            if (GetFloat("_NoReflections") < 0.5f)
            {
                Prop("_ReflectionStrength");
                Prop("_ReflectionTint");
                Prop("_ReflectionFresnel");
                Prop("_SpecularOcclusion");
                TexProp("_Cubemap", "Fallback Cubemap");
                Prop("_CubemapBlend");
            }
            Prop("_NoSpecHi");
        });

        Section("Emission Glow", () =>
        {
            Prop("_EmissionToggle");
            if (GetFloat("_EmissionToggle") > 0.5f)
            {
                TexProp("_EmissionMap", "Emission", "_EmissionColor");
                Prop("_EmissionStrength");
                Prop("_EmissionPulseSpeed");
                Prop("_EmissionPulseMin");
                Prop("_EmissionScroll");
                Prop("_EmissionGradientStrength");
                if (GetFloat("_EmissionToggle") > 0.5f)
                    mat.globalIlluminationFlags = MaterialGlobalIlluminationFlags.RealtimeEmissive;
            }
        });

        Section("Wetness", () =>
        {
            Prop("_WetnessToggle");
            if (GetFloat("_WetnessToggle") > 0.5f)
            {
                TexProp("_WetnessMask", "Wetness Mask (R)");
                Prop("_Wetness");
                Prop("_WetnessSmoothness");
                Prop("_WetnessColor");
                Prop("_WetnessMetallic");
                Prop("_WetnessUpAccumulation");
                TexProp("_DropletNormal", "Droplet Normal");
                Prop("_DropletStrength");
            }
        });

        Section("Sweat", () =>
        {
            Prop("_SweatToggle");
            if (GetFloat("_SweatToggle") > 0.5f)
            {
                TexProp("_SweatMask", "Sweat Mask (R)");
                Prop("_SweatAmount");
                Prop("_SweatSpeed");
                Prop("_SweatSparkle");
                Prop("_SweatScale");
            }
        });

        Section("Rim Light", () =>
        {
            Prop("_RimToggle");
            if (GetFloat("_RimToggle") > 0.5f)
            {
                Prop("_RimColor");
                Prop("_RimPower");
                Prop("_RimStrength");
                Prop("_RimBias");
            }
        });

        Section("Matcap", () =>
        {
            Prop("_MatcapToggle");
            if (GetFloat("_MatcapToggle") > 0.5f)
            {
                TexProp("_Matcap", "Matcap");
                Prop("_MatcapStrength");
                Prop("_MatcapBlend");
            }
        });

        Section("Subsurface (SSS)", () =>
        {
            Prop("_SSSToggle");
            if (GetFloat("_SSSToggle") > 0.5f)
            {
                TexProp("_ThicknessMap", "Thickness");
                Prop("_SSSColor");
                Prop("_SSSStrength");
                Prop("_SSSPower");
                Prop("_SSSScale");
            }
        });

        Section("Lighting", () =>
        {
            Prop("_LightingDirectional");
            Prop("_MinBrightness");
            Prop("_MaxBrightness");
            Prop("_ShadowBoost");
        });

        Section("Animation", () =>
        {
            Prop("_PulseSpeed");
            Prop("_PulseAmount");
        });

        Section("Rendering & Blending", () =>
        {
            EditorGUI.BeginChangeCheck();
            int preset = (int)GetFloat("_DstBlend") == 0 ? 0 : 1;
            preset = EditorGUILayout.Popup("Mode", preset, new[] { "Opaque / Cutout", "Transparent" });
            if (EditorGUI.EndChangeCheck())
                foreach (Material m in MaterialsOf()) ApplyBlendPreset(m, preset);

            Prop("_Cull");
            Prop("_ZWrite");
            Prop("_ZTest");
            Prop("_SrcBlend");
            Prop("_DstBlend");
            Prop("_Premultiply");
        });

        EditorGUILayout.Space();
        materialEditor.RenderQueueField();
        materialEditor.EnableInstancingField();
        materialEditor.DoubleSidedGIField();
    }

    // ---- helpers -----------------------------------------------------
    private IEnumerable<Material> MaterialsOf()
    {
        foreach (var o in _editor.targets) yield return (Material)o;
    }

    private void ApplyBlendPreset(Material m, int preset)
    {
        if (preset == 0) // opaque / cutout
        {
            bool cutout = m.HasProperty("_AlphaTest") && m.GetFloat("_AlphaTest") > 0.5f;
            m.SetFloat("_SrcBlend", (float)BlendMode.One);
            m.SetFloat("_DstBlend", (float)BlendMode.Zero);
            m.SetFloat("_ZWrite", 1);
            m.SetFloat("_Premultiply", 0);
            DisableKeyword(m, "_ALPHAPREMULTIPLY_ON");
            m.renderQueue = cutout ? (int)RenderQueue.AlphaTest : (int)RenderQueue.Geometry;
            m.SetOverrideTag("RenderType", cutout ? "TransparentCutout" : "Opaque");
        }
        else // transparent
        {
            m.SetFloat("_SrcBlend", (float)BlendMode.One);
            m.SetFloat("_DstBlend", (float)BlendMode.OneMinusSrcAlpha);
            m.SetFloat("_ZWrite", 0);
            m.SetFloat("_Premultiply", 1);
            EnableKeyword(m, "_ALPHAPREMULTIPLY_ON");
            m.renderQueue = (int)RenderQueue.Transparent;
            m.SetOverrideTag("RenderType", "Transparent");
        }
    }

    private static void EnableKeyword(Material m, string k) { m.EnableKeyword(k); }
    private static void DisableKeyword(Material m, string k) { m.DisableKeyword(k); }

    private void Section(string title, Action body)
    {
        if (!Foldouts.ContainsKey(title)) Foldouts[title] = true;
        var style = new GUIStyle(EditorStyles.foldoutHeader) { fontStyle = FontStyle.Bold };
        Foldouts[title] = EditorGUILayout.Foldout(Foldouts[title], title, true, style);
        if (Foldouts[title])
        {
            EditorGUI.indentLevel++;
            body();
            EditorGUI.indentLevel--;
            EditorGUILayout.Space();
        }
    }

    private MaterialProperty Find(string name) => FindProperty(name, _props, false);

    private float GetFloat(string name)
    {
        var p = Find(name);
        return p != null ? p.floatValue : 0f;
    }

    private void Prop(string name)
    {
        var p = Find(name);
        if (p != null) _editor.ShaderProperty(p, p.displayName);
    }

    private void TexProp(string name, string label, string extra = null)
    {
        var p = Find(name);
        if (p == null) return;
        var ex = extra != null ? Find(extra) : null;
        _editor.TexturePropertySingleLine(new GUIContent(label), p, ex);
        _editor.TextureScaleOffsetProperty(p);
    }
}
#endif

# ✦ Luminescence

A high-quality, physically based **VRChat avatar shader** for Unity's Built-in
Render Pipeline (the pipeline VRChat uses). Built for striking, reflective
materials — glossy black "demon skin" with glowing red cracks, wet/latex
surfaces, animated sweat, rim glow and more.

> Designed to recreate looks like the reference avatars: deep reflective blacks
> with emissive red fissures, and slick, light-catching skin with sweat.

---

## Features

| Group | What it does |
|-------|--------------|
| **PBR core** | Energy-conserving GGX specular + Smith visibility, metallic/smoothness workflow, albedo/normal/occlusion maps. |
| **Reflections** | Box-projected reflection probes with probe blending, roughness-aware mips, Fresnel edge boost, specular occlusion, and an optional **fallback cubemap** for worlds with no probes. |
| **Clear coat** ✨ | A second, sharp lacquer specular lobe with its own reflection — the secret to a wet, premium latex/glass finish. |
| **Anisotropy** ✨ | Stretched, silky highlights with adjustable direction — gorgeous on skin, hair and brushed metals. |
| **Iridescence** ✨ | Thin-film colour-shifting sheen on the reflections for that high-end, otherworldly look. |
| **Parallax depth** ✨ | Height-mapped UV offset that gives cracks and scales real perceived depth. |
| **Emission glow** | HDR emission map with **pulsing**, **scrolling**, a gradient boost, plus an always-on **Fresnel rim glow** — perfect for glowing red cracks and burning silhouettes. |
| **Wetness** | Wet-mask driven darkening, smoothness boost, added metalness, **top-face pooling**, and tiling **droplet normals**. |
| **Sweat** | Animated, gravity-biased trickling droplets with bright pinpoint **sparkle** highlights. |
| **Rim light** | HDR rim with adjustable width, strength and light-direction bias. |
| **Matcap** | Camera-space fake reflection (additive or multiply) — cheap extra shine. |
| **Subsurface** | Thickness-mapped translucency for skin / latex glow-through. |
| **Lighting safety** | Min/Max brightness clamps and shadow lift so the avatar reads well in dark *and* over-bright worlds; vertex lights + additive realtime lights + shadows. |
| **Color grading** ✨ | Final-stage exposure, contrast, saturation, smart vibrance, hue shift and an optional **ACES filmic tonemap** for a rich, cinematic roll-off. |
| **Quality of life** | Compact styled inspector with inline section toggles, tooltips, **one-click look presets**, transparency presets, GPU instancing, alpha cutout, gentle vertex "breathing". |

---

## Installation

1. Copy the `Shaders/` and `Editor/` folders into your project's `Assets/`
   (e.g. `Assets/Luminescence/`).
2. Unity will compile the shader and the custom inspector automatically.
3. On your avatar material, set the shader to **`Luminescence/Avatar`**.

> **PC focused.** Uses Shader Model 4.0 features (reflection-probe LOD sampling,
> per-pixel detail). It is not optimised for the Quest mobile feature set.

---

## One-click looks

The inspector has a **Quick Looks** bar at the top. Click a chip to instantly
configure the material:

- **🔥 Demon Skin** — reflective black, glowing red emission + pulse, clear coat,
  red rim & Fresnel glow, filmic tonemap.
- **💧 Wet Latex** — high smoothness, wetness layer + clear coat, strong reflections.
- **💦 Sweaty** — animated sparkle sweat + warm subsurface glow.
- **🦋 Iridescent** — colour-shifting thin-film sheen over a glossy coat.

Each preset is a great starting point — tweak from there with the full controls.

## Recreating the reference looks

### 🔥 "Demon Skin" — reflective black with glowing red cracks
- **Base → Tint**: near-black (e.g. `0.02, 0.02, 0.02`).
- **Surface**: Metallic `~0.6`, Smoothness `~0.85` (deep wet-looking reflections).
- **Reflections**: Strength `1.5`, Fresnel `1`. Add a dark, moody **Fallback
  Cubemap** and set *Use Fallback Cubemap* `~0.4` so it reads even in flat worlds.
- **Emission**: enable. Emission map = your crack texture, **Emission Color** a
  hot HDR red (e.g. `4, 0.2, 0.05`), Strength `3–6`. Set **Pulse Speed** `~1.5`
  and **Pulse Floor** `0.5` for a living, breathing glow. A small
  **Emission Scroll** makes energy seem to flow through the cracks.
- **Rim**: thin HDR red rim (Width `6`, Strength `1.5`) for that silhouette burn.

### 💧 "Slick Skin / Latex" — light-catching wet surface (2nd reference)
- **Base**: your skin/latex albedo.
- **Surface**: Smoothness `0.7`, Metallic `0.05`.
- **Wetness**: enable, Wetness `0.6`, **Wet Smoothness** `0.95`, **Wet Darkening
  Color** `~0.5` grey, **Wet Metallic** `0.1`. Assign a **Droplet Normal** tiled
  `4–8×` with Droplet Strength `~0.4` for rolling highlights.
- **Sweat**: enable, Amount `0.4`, Sparkle `1.5`, Speed `0.2` for trickling
  pinpoint glints that drift downward.
- **SSS**: enable with a warm `SSS Color` for soft glow-through on thin areas.

---

## Property reference (selected)

- **Reflections → Fresnel (edge boost)** — how much grazing angles intensify the
  environment reflection. Crank for glassy edges.
- **Wetness → Top-face Pooling** — adds wetness on upward-facing surfaces, like
  water settling on shoulders/collarbones.
- **Lighting → Min/Max Brightness** — keeps the avatar legible in any world;
  Min stops pitch-black worlds, Max tames blinding ones.
- **Lighting → Directional Response** — `1` = full PBR directional shading,
  `0` = flatter, more uniform anime-style lighting.

---

## File layout

```
Luminescence/
├── Shaders/
│   ├── Luminescence.shader   # properties + passes (ForwardBase/Add/ShadowCaster)
│   ├── LumiInput.cginc        # property / sampler declarations
│   └── LumiCore.cginc         # vertex + fragment + PBR/wetness/effect math
├── Editor/
│   └── LuminescenceGUI.cs     # organised foldout inspector
└── README.md
```

## License

MIT — see `LICENSE`. Use it on your avatars freely; attribution appreciated.

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
| **Holographic Flow** ☠ | Animated, flowing oil-slick rainbow film that shifts with view and time — pure eye-magnet. |
| **Inner Glow** ☠ | Lit-from-within core glow that breathes — or beats with a real **lub-dub heartbeat**. |
| **Dual Rim** ☠ | Two-colour vertical gradient rim light for a luscious silhouette. |
| **Parallax depth** ✨ | Height-mapped UV offset that gives cracks and scales real perceived depth. |
| **Emission glow** | HDR emission map with **pulsing**, **scrolling**, a gradient boost, plus an always-on **Fresnel rim glow** — perfect for glowing red cracks and burning silhouettes. |
| **Wetness** | Wet-mask driven darkening, smoothness boost, added metalness, **top-face pooling**, and tiling **droplet normals**. |
| **Sweat** ✨ | Fully procedural trickling beads with real, light-catching bump normals and bright glints — glistening wet skin, no painted map required. |
| **Glitter / Shimmer** ✨ | Procedural twinkling flakes for body shimmer / highlighter — sparkles as you move. |
| **Blush / Flush** ✨ | Rosy makeup tint with optional edge-flush for a soft, flushed look. |
| **Skin Warmth** ✨ | One slider from cool porcelain to sun-kissed warm. |
| **Rim light** | HDR rim with adjustable width, strength and light-direction bias. |
| **Matcap** | Camera-space fake reflection (additive or multiply) — cheap extra shine. |
| **Subsurface** | Thickness-mapped translucency for skin / latex glow-through. |
| **Lighting safety** | Min/Max brightness clamps and shadow lift so the avatar reads well in dark *and* over-bright worlds; vertex lights + additive realtime lights + shadows. |
| **AudioLink** 🎵 | React to the world's music: route **bass / low-mid / high-mid / treble** independently to emission, inner glow, rim and glitter. Auto-detects AudioLink and falls back gracefully when it isn't present. |
| **Dissolve** ✨ | Animatable reveal/vanish with a glowing HDR edge — procedural (no texture needed), optional texture influence, can be driven by the beat. Clips shadows too. |
| **Proximity Glow** 💖 | Blooms as a viewer moves closer — the avatar literally lights up for whoever approaches you. |
| **Toon Ramp** 🌸 | Optional cel-shaded diffuse with shadow tint and adjustable steps, blendable with the PBR base for anime looks. |
| **Color grading** ✨ | Final-stage exposure, contrast, saturation, smart vibrance, hue shift and an optional **ACES filmic tonemap** for a rich, cinematic roll-off. |
| **Quality of life** | Compact styled inspector with inline section toggles, tooltips, **one-click look presets**, **Copy/Paste Look as text** (share looks with friends), **Random** look, **Import from other shaders** (Poiyomi/lilToon/Standard/URP), collapse/expand all, a live **performance/keyword meter**, transparency presets, GPU instancing. |

---

## Migrating from another shader (Poiyomi / lilToon / Standard / URP)

Switching an existing avatar over? Use the **Import from another material**
panel at the top of the inspector:

1. Drag the avatar's current material (any shader) into the **Source** slot.
2. **Copy Matching** — copies every property whose name matches exactly
   (albedo, normal, metallic/smoothness, emission, occlusion, colours, tiling…).
3. **Copy + Smart Map** — also translates common differently-named properties
   (URP `_BaseMap`/`_BaseColor`, alternate normal/AO/emission/matcap names, …).

Both then **auto-enable the matching features**, so an imported normal or
emission map actually shows up instead of sitting there switched off.

> Already pasted maps the normal Unity way (gear ▸ *Copy/Paste Material
> Properties*)? Just hit **Auto-enable from assigned maps** and the matching
> features (normal, metallic, emission, occlusion, detail, matcap, parallax)
> switch on automatically.

## Installation

1. Copy the `Shaders/` and `Editor/` folders into your project's `Assets/`
   (e.g. `Assets/Luminescence/`).
2. Unity will compile the shader and the custom inspector automatically.
3. On your avatar material, set the shader to **`Luminescence/Avatar`**.

> **PC focused.** Uses Shader Model 4.0 features (reflection-probe LOD sampling,
> per-pixel detail). It is not optimised for the Quest mobile feature set.

---

## One-click looks

The inspector has a **Quick Looks** bar at the top. Each chip first **resets**
the look, then builds it up, so presets never stack or leave leftovers. None of
them require you to paint any masks — they work on a bare avatar:

- **✨ Glossy Skin** — natural dewy skin with a flattering pink **sheen**, soft
  clear coat, light wetness and warm subsurface. The everyday "good-looking".
- **💋 Oiled** — sun-kissed, silky **anisotropic** oiled-skin sheen with clear coat
  and subsurface. The headline "sexy" look.
- **🖤 Wet Latex** — glossy black rubber: darkened albedo, near-mirror clear coat,
  wetness and strong reflections.
- **💦 Sweaty** — procedural glistening sweat beads + dewy sheen + subsurface.
- **🌟 Shimmer** — twinkling **glitter** body shimmer over dewy skin.
- **💗 Blushed** — warm flushed skin with rosy **blush**, soft sheen and subsurface.
- **🔥 Demon** — dark reflective skin with a burning red **Fresnel edge glow** and
  red rim (no painted crack map needed — though it's pre-tuned to accept one).
- **🦋 Iridescent** — colour-shifting thin-film sheen over a glossy coat.
- **♻ Reset** — back to a neutral skin base.

### ☠ Dangerous looks

The show-stoppers — designed to turn heads across the whole instance:

- **🌌 Galaxy** — polished obsidian-galaxy chrome: a dark metallic body with a
  holographic nebula in its reflection and sparse twinkling star-flakes.
- **🪩 Holographic** — a flawless mirror whose every reflection runs with flowing
  rainbow. The reflection does the work, so it wraps the body perfectly.
- **❤️‍🔥 Succubus** — deep red glossy skin with a red gradient rim and a **beating**
  glow that lives only at the silhouette (never floods the form), plus sweat.
- **🌹 Goddess** — warm pearlescent skin, soft golden sheen, a whisper of shimmer
  and blush, and a gentle backlit halo.

> The reflective dangerous looks (Galaxy, Holographic, Chrome, Honey) shine
> brightest with a reflection probe or a skybox in the scene — their beauty
> lives in what they reflect.
- **🩸 Liquid Chrome** — a flawless mirror-metal body that drinks in the world.
- **🍯 Honey** — warm molten-gold metal, slick and glistening like dripping honey.

### 🎶 Reactive & stylised looks

- **🎵 Club** — glossy dark skin whose glow, glitter and rim **pulse to the music**
  (AudioLink). The life of the dance floor.
- **✨ Reveal** — a dissolve toggle ready to animate: drive `Dissolve Amount`
  0→1 for a glowing vanish/return.
- **💖 Allure** — a warm glow that blooms only as someone steps close to you.
- **🌸 Anime** — cel-shaded cutie: toon ramp, blush, soft sheen and a clean rim.

> **Toolbar tips:** *Copy Look* / *Paste Look* share a complete look as text —
> paste it onto another material or send it to a friend. *Random* rolls a
> gorgeous look instantly. The keyword meter under the toolbar shows how heavy
> the current material is — switch off sections you don't use to keep your
> avatar performant.

Each preset is a starting point — tweak from there with the full controls.

> **Sheen** is the secret sauce for the "sexy" look: a soft Fresnel glow that
> traces the body's silhouette and curves, working even in flat-lit worlds.

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

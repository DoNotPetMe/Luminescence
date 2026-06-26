# Changelog

All notable changes to **Luminescence** are documented here.

## v1.4
**Reactive, stylised, and quality-of-life.**

### Added
- **AudioLink** reactivity — global `_AudioTexture` sampling with availability
  detection and graceful fallback. Route bass / low-mid / high-mid / treble
  independently to emission, inner glow, rim and glitter, with a beat-punch.
- **Dissolve** — procedural fbm reveal/vanish with a glowing HDR edge (no
  texture required), optional texture influence, beat-drivable; clips the
  shadow caster too.
- **Proximity Glow** — blooms as a viewer approaches (camera distance).
- **Toon Ramp** — optional cel diffuse with shadow tint, steps and hardness,
  blendable with the PBR base.
- **Gradient Tint** — dual-tone body gradient (vertical along the body or by
  view angle), the staple of aesthetic avatars. Preset: **Duotone**.
- **Specular highlight colour** tint.
- **Quality of life:** Copy/Paste Look as shareable clipboard text, Random
  look, Collapse/Expand all, a live keyword/performance meter, and
  category-coloured section bars.
- New presets: **Club** (AudioLink), **Reveal** (dissolve), **Allure**
  (proximity), **Anime** (toon).

### Fixed
- Dissolve edge no longer glows while the material is fully solid.

## v1.3
### Added
- **Import & Migrate** panel — drag any material (Poiyomi / lilToon / Standard
  / URP) to copy textures and values over, with smart name-mapping and
  automatic feature-toggle enabling. Plus a one-click "auto-enable from
  assigned maps" for after a normal Unity paste.

## v1.2 → reworked "dangerous" looks
### Changed
- Reworked Holographic, Glitter and Inner Glow to live inside the lighting
  model (reflection thin-film, light-reactive flakes, edge-weighted backlight)
  instead of flat emissive overlays, so they follow the body and the light.
- Rebuilt Galaxy, Holographic, Succubus and Goddess around premium reflective
  PBR. Kept Liquid Chrome and Honey.

## v1.2
### Added
- **Sheen** (soft Fresnel skin glow), **Glitter / Body Shimmer**, **Blush /
  Flush**, **Skin Warmth**.
- Procedural, light-catching **Sweat** beads (no painted map needed).
- Dangerous presets: Galaxy, Holographic, Succubus, Goddess, Liquid Chrome,
  Honey.

### Fixed
- Presets no longer blanket the whole body in emission (the "yellow glow").

## v1.1
### Added
- **Clear coat**, **anisotropy**, **iridescence**, **parallax depth**,
  Fresnel emissive glow, and final **colour grading** with an ACES tonemap.
- Rebuilt inspector with inline section toggles, tooltips and one-click looks.

## v1.0
- Initial release: physically based forward avatar shader for the Built-in
  pipeline — GGX/Smith PBR, box-projected reflections, emission, wetness,
  rim, matcap, SSS, ForwardBase/Add/ShadowCaster passes, custom inspector.

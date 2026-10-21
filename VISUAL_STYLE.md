# DRONE KILLER: FRONTLINE — visual system G1–G6

G6 audits the existing artwork and UI and unifies environment, unit-shadow, menu and VFX budgets under Low / Medium / High. The [graphics audit](GRAPHICS_AUDIT.md), [human-readable inventory](ASSET_MANIFEST.md) and [Android checklist](ANDROID_VISUAL_TEST_CHECKLIST.md) record current evidence and remaining production work. G6 supersedes earlier independent quality budgets; it does not change combat tuning or the save schema.

G5 adds [native tactical menus, illustrated research, a pannable strategic map and compact battle telemetry](docs/UI_DESIGN.md). See [current UI captures and validation](docs/ui/README.md). Shared theme, safe-area and gameplay-ownership rules continue to apply.

G4 adds [bounded combat effects, weapon feedback and accessibility controls](docs/COMBAT_VFX.md). See [native G4 captures and validation](docs/effects/README.md). Its foreground layering, quality limits and settings extend/supersede the original G1/G3 VFX budgets below.

G3 adds [distinct unit artwork and reusable combat animation](docs/UNIT_VISUALS.md) for all 14 enemies and 7 weapons. See [native G3 captures and validation](docs/units/README.md).

G2 extends the existing foundation with [13 reusable battlefield kits, 5 atmosphere profiles and all 25 mission bindings](docs/ENVIRONMENTS.md). The native G2 gallery is in [docs/environments](docs/environments/README.md).

G1 establishes a modern military science-fiction 2.5D art system in the existing Godot game. The native main menu and Outpost Alpha demonstrate the new direction. All 25 missions, manual control, automatic defenses, research, currencies, enemy abilities, saves and frontline rules remain operational. This increment supplies generated artwork candidates and a reusable production pipeline; final art approval and device profiling remain outstanding.

## Palette and visual hierarchy

| Role | Color | Use |
| --- | --- | --- |
| Dark charcoal | `#151B24` | Canvas framing, HUD background, quiet negative space |
| Military steel | `#303D4C` | Chassis, panels, armor |
| Desaturated blue | `#44657F` | Secondary metal, borders, selected technology |
| Friendly cyan | `#37B7E5` | Friendly identification, primary UI, base/ammo progress |
| Enemy red | `#F04B45` | Enemy health, threat identification |
| Tactical orange | `#FF9C42` | Fire control, chapter emphasis, urgent actions |
| Background sand | `#86745E` | Asterian earth and weathered concrete |
| Interface white | `#E9F0F6` | Readable headings, body and numbers |

Keep most of the screen neutral. Identification lamps are small; no whole-unit neon fills, bloom, HDR glow or rainbow grading. Existing ability-specific colors remain where they carry established gameplay meaning. Enemy red and friendly cyan are also reinforced by health bars, silhouettes, labels and position; color alone is not the only signal.

## Camera, materials and light

Retain the existing top-down 2D battlefield. Art uses near-overhead orthographic framing with visible bevels/front faces for depth. All world positions and collision/range values remain gameplay units. Presentation transforms preserve uniform scale on different aspect ratios; the battlefield is centered within additional space and native UI stays anchored to safe margins. No 3D camera or perspective gameplay is introduced.

Use worn painted steel, metal edges, inset fasteners, layered plating, restrained specular highlights, dusty concrete and compacted earth. Key light comes from upper left; fake soft ground shadows fall down/right. Important actors are dark and distinct against warmer, quieter terrain. Keep the center of a battlefield relatively open. Avoid decorative clutter over paths, cores, placement hotspots and health bars.

PNG unit art is prelit. Its highlights rotate with the 2D sprite; it is a baked-material approach, not dynamic PBR. The generated bunker and sheets are reviewed visual candidates, with small perspective/padding differences awaiting art approval. Do not add runtime lighting on top of these baked images. True selected-asset normal lighting requires matching artist-authored albedo/normal maps; none are fabricated in G1.

## Assets and bindings

```
assets/
  environment/   terrain atlases, props, atmosphere vectors and command bunker
  drones/        G3 line/specialist/boss atlases; G1 sheet retained as reference
  turrets/       G3 weapon/primary modular atlases; pads and legacy SVG references
  projectiles/   tracer and missile sprites
  effects/       six-frame explosion, soft shadow and muzzle flash
  ui/            theme, button surfaces, badge, icons, bundled fonts
  backgrounds/   Sentinel-7 menu key art
  shaders/       Compatibility CanvasItem surface/terrain shaders
  source/        generation/provenance record
  manifest.json
  visual_catalog.json
```

`manifest.json` records each asset filename, purpose, dimensions, frames, art direction, source, license, integration status and SHA-256. `scripts/visual/visual_assets.gd` caches textures and AtlasTexture regions. `unit_visual.gd` composes shadow/body sprites and receives visual state from the existing controllers; it never acquires a target, fires, deals damage or advances simulation time. Sprite material instances keep hit/cloak/suppression state independent.

G3 uses five detailed source atlases with explicit imported regions, pivots, rotor/engine mounts, weapon mounts and muzzle FX anchors. Every enemy and weapon has a distinct binding; no support/boss silhouette fallback is used by current definitions. Original source coordinates are also recorded. Source art remains prelit and some generated padding/perspective is imperfect, so final art-direction review remains required. Godot imports the five G3 sheets at 768×512 while preserving unmodified 1536×1024 source PNGs. The nine drones and five bosses receive transform-based propulsion/hover/damage animation; weapons use separate fixed bearings, rotating heads, recoil, upgrade armor and a modular primary autoloader/barrel assembly. See the G3 guide for ownership, phase/destruction timing and replacement specs.

Texture imports use lossless RGBA, alpha-border correction and mipmaps for the large PNGs. Unit sprites use linear filtering with mipmaps; atlas filter clipping prevents neighboring objects leaking across a region. UI vectors and fonts remain crisp native resources. Track `.import` settings and `.gd.uid` identities, never `.godot/` caches.

## UI system

- Headings: Barlow Condensed Bold, normally 28–82 reference pixels. Body: Barlow Regular, normally 18–23. Dense secondary HUD/metadata: 13–17. Numeric telemetry/ammunition: DejaVu Sans Mono, 16–17. All font files and their licenses ship with the game.
- `assets/ui/frontline_theme.tres` supplies textured nine-slice buttons, primary/fire variants, translucent bordered panels, focus treatment, scrollbars and clean progress bars. The surfaces have restrained vertical metal shading and thin edge highlights.
- `ui_kit.gd` supplies common labels/buttons; `main_menu.gd` composes the dedicated menu. The existing touch button retains pointer ownership and adds a 120ms visual accent transition for hover, focus and press. UI transitions remain responsive while the battle is paused.
- Use 8/10/16/24px spacing, 4–6px corners and thin borders. Main actions are 54–58px high; keep the established mobile button geometry. Keyboard focus is visible; touch never depends on hover. Locked and selected ammunition remain labeled.
- Main menu: quiet left-side title/actions, image on right, explicit campaign identity, clear New/Continue hierarchy. Continue still depends on save availability. Desktop Exit remains absent on mobile.
- Combat: retain every existing HUD element. A cyan base-health bar reinforces numeric telemetry, the primary readout has fixed-width digits, and orange distinguishes held FIRE. Build controls, ammunition and tactical abilities retain their existing interaction rules.

## Rendering and VFX

Compatibility/GLES3 remains the configured desktop/mobile renderer. The unshaded CanvasItem shaders use ordinary color operations only. They need no screen texture, depth buffer, compute, glow, SDF occlusion or renderer-specific feature. Surface shading supplies a restrained damage flash, suppression desaturation and cloak opacity. Terrain grading adds a static cool-edge vignette beneath gameplay/UI; it is not a full-screen post-process.

Use baked soft shadows instead of runtime Light2D/shadow passes for this prelit asset set. Explosion frames advance from the existing simulation-driven effect age over 0.65s; impact sparks use 0.15s, construction rings 0.45s. EMP and phase changes use a separate tinted 0.65s tactical pulse, preserving their meaning without a full-field fireball. Muzzle flash/recoil, rotor overlays, projectiles and effects freeze with combat pause. Effects retain the 96-entry cap; textures and frame regions are shared. UI tweens are independent of battle time. G3 adds a 12-wreck detached destruction batch and a skippable terminal boss outro after the result transaction succeeds; combat stays finished and rewards cannot repeat. Ordinary EMP/Overclock effects retain their established gameplay cues; dedicated finished art remains a future replacement.

The original G1 set of five 1536×1024 RGBA PNGs costs approximately 40 MiB of GPU texture storage with complete mip chains before fonts, vectors, framebuffer and driver overhead. This is a budget estimate, not a device measurement. No dynamic light or screen-copy pass is introduced. G2 loads terrain sheets by scene lifetime rather than accumulating the complete library; its typical large-texture estimate is 48 MiB. G3 replaces the old 8 MiB active combat sheet with about 10 MiB of imported unit sheets, bringing the typical large-texture estimate to roughly 50 MiB. Target under 64 MiB for the visual texture set and profile actual frame time, overdraw, thermal behavior and memory on Android before claiming 60 FPS. Consider atlas packing/downsize or device compression only after visual/device review; do not enable unsupported compression blindly.

M1 retains this art direction and adds short orange propulsion arcs before/during Scout/Bomber acceleration. They are threat cues driven by existing enemy state; do not animate collision positions in presentation. Automatic weapon heads now follow actual bounded tracking rotation. There is no combat speed selector; temporary tactical build remains 0.25x. See [M1 evidence](docs/M1_BALANCE.md).

M2 adds original SVG projectile cutaways for research and EMP/Cryo/Rail slugs, existing Standard/AP/HE variations and bounded electric/frost/penetration impacts. Keep six technologies visually distinct at phone scale; reserve fireball blasts for explosive hits. Five Arsenal tabs and wrapping/clipped research copy must fit native safe areas. See [M2 system and art scope](docs/WEAPON_RESEARCH.md).

## Graphics presets and draw order (G6)

The canonical policy is `scripts/visual/graphics_profile.gd`, using `assets/effects/quality.json` and the existing validated schema-v3 `effects_quality` setting. Medium remains the default. Settings provides three 54px native touch buttons, with explicit save-error rollback. Presets apply to the next deployed mission; menu atmosphere reads the selected preset when composed.

| Budget | Low | Medium | High |
| --- | --- | --- | --- |
| Combat particle slots active / fixed allocated pool | 48 / 192 | 112 / 192 | 192 / 192 |
| Burst / smoke / debris / soft impact light limits | 4 / 3 / 6 / 3 | 8 / 8 / 16 / 6 | 12 / 12 / 24 / 8 |
| Emissions per simulation tick / concurrent ground explosions | 12 / 4 | 28 / 8 | 48 / 12 |
| Environmental particles / moving haze layers | 0 / 0 | ≤16 / 2 | ≤32 / 4 |
| Extra props (also constrained by path/slot exclusions) | ≤8 | ≤10 | ≤14 |
| Additional fake shadow strength | 0 | 0.65 | 1 |
| Night light pools/searchlights | Off | On | On |
| Environment redraw ceiling in simulated seconds | Static | 30 Hz | 60 Hz |
| Unit mechanical-overlay redraw ceiling | 20 Hz | 30 Hz | 60 Hz |
| Menu dust particles | 0 | ≤8 | ≤18 |

Low retains painted terrain, unit detail, readable identification, health bars, aiming, telegraphs and reload feedback. Baked image shading is not removed. This reduces rendering work, not atlas resolution or texture residency. Shots, tier changes and reload feedback force immediate overlay redraw; body aiming, simulation/collision, actual firing and input remain at their original cadence. Shader uniform writes are cached until the value changes, including instant cloak/suppression recovery and boss armor updates.

Reduced effects overrides High with Low budgets and burst 2, disables smoke/debris/impact lighting/shake and animated weather. Reduced motion freezes rotor/hover movement, disables flying debris/shake and moving weather while keeping essential hit/area/status/reload cues. The separate reduced-environment switch stops weather but leaves selected combat budgets. See the audit for exact limits and measurements.

Native battle HUD is z=10 above world artwork/screen feedback; the saved, skippable boss outro is z=20. Mission identity is in the bottom native HUD rather than an opaque plate in enemy entry lanes. Keep future decorative overlays below the HUD and pointer-ignoring. Do not raise world actors or change input transforms to repair artwork overlap.

## Exact replacement specifications

Approved artwork can replace existing filenames with matching dimensions/regions, or update `visual_catalog.json` pivots/regions without changing combat logic. Art-file changes require a fresh import and visual checks.

| Asset to author/review | Required delivery | Runtime framing and pivot |
| --- | --- | --- |
| Menu key art | 1920×1080 or larger 16:9 RGB PNG/WebP; no text/UI; quiet left 42% | Aspect-cover full screen; right-side cannon must survive wider/taller crops |
| Outpost terrain | 1536×1024 RGB, no actors or baked placement circles; upper-left diffuse light | Drawn into the existing 955×560 field, center clear; verify terrain texture scale against units |
| G3 automatic and primary refinement | Preserve 1536×1024 transparent source sheets, 768×512 imports, or explicitly update bindings | `source_region`, imported `region`/`pivot` and muzzle FX anchors are measured in the current catalog; primary tip must align with the existing 38-unit gameplay muzzle |
| Missile/Laser/EMP/Heavy AA refinement | Current 1536×1024 six-object G3 automatic-head sheet; independent transparent objects | G3 supplies distinct heads; preserve declared axes/scales and remeasure muzzle FX anchors if artwork changes |
| Command bunker | 1280×400 RGBA, low broad roof, no gun; roof mounting pivot `(640,180)`; no baked UI | Display roughly 320×100 near the existing bunker; align the roof mount under manual cannon `(560,605)` without moving gameplay |
| All nine drone refinements | Current two G3 1536×1024 transparent source atlases; optional authored rotor/damage frame sheets | Keep declared rotor/engine axes and body readability around the existing 18×size radius; source rotors/wings remain decorative beyond the physical body |
| Five chapter boss refinements | Current 1536×1024 G3 boss/component sheet; optional artist-authored phase/demolition frame sheets | Keep source pivots, articulated armor boundaries and painted core aligned with the original actual weakpoint; never move its collision to fit art |
| Explosion replacement | Six 512×512 RGBA frames, 3×2 atlas 1536×1024, equal padding, no labels | Ignition→fire→smoke in 0.65s, center-pivot, consistent ground contact and size |
| EMP/laser/overclock/impact pack | 256×256 or 512×512 RGBA with declared frame counts and timing | Must fit current simulated duration/radius and preserve threat telegraphs; restrained additive energy only |
| Environment art refinement | Existing three 1536×1024 four-map atlases, one six-cell prop atlas; or update explicit regions | All 25 now use G2 illustrated terrain; refine perspective/scale and optionally supply bespoke Hive/territory architecture without moving paths/slots |
| Optional true lighting | Matching albedo + tangent-space normal RGBA at identical dimensions/pivots; flat normal `(128,128,255)` | Artist must state normal convention. Validate Godot CanvasTexture/DirectionalLight2D/PointLight2D on GLES3 before use; remove baked highlights first |

The current generated PNGs and authored UI are integrated candidates, not evidence of final production approval. G3 now supplies distinct support/boss/weapon art and reusable transform animation. Polished authored raster rotor/damage/phase sheets, dedicated energy effects, perspective/scale refinement and optional matched normal maps remain future art work; no shared placeholder body is hidden behind these specifications. G2 replaces the former geometric terrain for all 25 missions with 13 illustrated kits, shared props and atmosphere. These are integrated generated candidates awaiting final art approval, rather than 25 unique commissioned paintings. See the G2 and G3 guides for current replacement specifications, quality settings and residency estimates. The legacy six-object sheet and SVG support heads remain reference assets, not active unit visuals.

## Verification and captures

Run `./tests/run_checks.sh` for native import/startup, all existing campaign/combat/research/input checks and the added visual-resource checks. It isolates saves and rejects engine errors. The real-render capture scene requires X11/Wayland and Compatibility rendering:

```sh
XDG_DATA_HOME=/tmp/frontline-g1-data godot --path . --audio-driver Dummy res://tests/visual_capture.tscn -- --output=/tmp/frontline-g1-captures
```

Use a separate temporary data directory: the capture scene deliberately starts a fresh test campaign. It deploys mission 1, buys defenses with the actual starting budget, simulates real manual/automatic attacks and captures the native viewport. It also captures a real destruction explosion, tactical build mode and a 1600×720 layout; no mockup compositing or fake screenshots are used. The test exits rather than pretending to capture under the headless dummy renderer.

Linux OpenGL/llvmpipe captures are checked in under `docs/visuals/`. Physical Android appearance, physical multitouch, audible playback, cutout hardware, FPS, memory and battery/thermal behavior still require device validation. Generated art should receive art-direction and commercial-clearance review before release.

For an Android export, include all resources and include `data/*.json`, `assets/*.json`, `assets/environment/*.json`, `assets/effects/*.json`, `assets/ui/*.json`, `assets/ASSET_LICENSE.md` and `assets/ui/fonts/*.txt` as non-resource files if the preset filters them. Keep dynamic atlas/catalog dependencies and font notices in the package. Export templates/SDK/signing and a physical device build remain separate validation steps.

## Tactical radar (M5)

Use the shared charcoal/metal theme and Barlow font for a pointer-ignoring preparation strip. Orange indicates incoming plans, cyan the compact active-contacts strip, and restrained red/orange chevrons indicate actual entry directions. Show scheduled W/C/E counts and the defended objective in text as well as color. Collapse the strip when combat begins; do not cover build, FIRE, reload or ammo controls. Entry animation consumes simulated delta, redraws at 10 Hz and honors Reduced motion. See `docs/TACTICAL_DIRECTOR.md` and the native captures in `docs/m5/`.

## Strategic placement (M6)

Selected real firing arcs use faint cyan sectors and a bearing line; orange previews identify the destination mount. Empty legal destinations highlight green while source remains online. In-transit arcs are muted and a restrained orange route/progress ring indicates transport. Reuse raised steel decks for elevated positions and label their data-driven range advantage. Clip reach artwork to the battlefield; keep native FIRE/reload and management controls unobstructed. The optional reach legend must state that it does not guarantee kills. The briefing's numbered terrain/corridor preview shows known geometry, never hidden wave plans. See `docs/STRATEGIC_PLACEMENT.md`.

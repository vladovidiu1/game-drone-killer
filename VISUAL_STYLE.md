# DRONE KILLER: FRONTLINE — visual foundation G1 / environments G2

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
  drones/        shared six-object rendered combat atlas
  turrets/       placement pad and editable support-weapon SVGs
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

The six-object source sheet has non-ideal generated padding. `visual_catalog.json` stores explicit regions, image-space breech pivots and scale. Turret art points up in the source; presentation adds `PI/2` to the existing +X barrel rotation. Manual recoil uses the existing simulated value. All six automatic weapon types have bindings. Shield/EMP/Bomber/Sniper/Carrier/Stealth and bosses currently reuse a base drone silhouette plus their existing semantic overlays; these are explicitly shared art, not completed unique designs.

Texture imports use lossless RGBA, alpha-border correction and mipmaps for the large PNGs. Unit sprites use linear filtering with mipmaps; atlas filter clipping prevents neighboring objects leaking across a region. UI vectors and fonts remain crisp native resources. Track `.import` settings and `.gd.uid` identities, never `.godot/` caches.

## UI system

- Headings: Barlow Condensed Bold, normally 28–82 reference pixels. Body: Barlow Regular, normally 18–23. Dense secondary HUD/metadata: 13–17. Numeric telemetry/ammunition: DejaVu Sans Mono, 16–17. All font files and their licenses ship with the game.
- `assets/ui/frontline_theme.tres` supplies textured nine-slice buttons, primary/fire variants, translucent bordered panels, focus treatment, scrollbars and clean progress bars. The surfaces have restrained vertical metal shading and thin edge highlights.
- `ui_kit.gd` supplies common labels/buttons; `main_menu.gd` composes the dedicated menu. The existing touch button retains pointer ownership and adds a 120ms visual accent transition for hover, focus and press. UI transitions remain responsive while the battle is paused.
- Use 8/10/16/24px spacing, 4–6px corners and thin borders. Main actions are 54–58px high; keep the established mobile button geometry. Keyboard focus is visible; touch never depends on hover. Locked and selected ammunition remain labeled.
- Main menu: quiet left-side title/actions, image on right, explicit campaign identity, clear New/Continue hierarchy. Continue still depends on save availability. Desktop Exit remains absent on mobile.
- Combat: retain every existing HUD element. A cyan base-health bar reinforces numeric telemetry, the primary readout has fixed-width digits, and orange distinguishes held FIRE. Build controls, ammunition and tactical abilities retain their existing interaction rules.

## Rendering and VFX

Compatibility/GLES3 remains the configured desktop/mobile renderer. The two unshaded CanvasItem shaders use ordinary color operations only. They need no screen texture, depth buffer, compute, glow, SDF occlusion or renderer-specific feature. Surface shading supplies a restrained damage flash, suppression desaturation and cloak opacity. Terrain grading adds a static cool-edge vignette beneath gameplay/UI; it is not a full-screen post-process.

Use baked soft shadows instead of runtime Light2D/shadow passes for this prelit asset set. Explosion frames advance from the existing simulation-driven effect age over 0.65s; impact sparks use 0.15s, construction rings 0.45s. EMP and phase changes use a separate tinted 0.65s tactical pulse, preserving their meaning without a full-field fireball. Muzzle flash/recoil, rotor overlays, projectiles and effects freeze with combat pause. Effects retain the 96-entry cap; textures and frame regions are shared. UI tweens are independent of battle time. Ordinary EMP/Overclock effects retain their established gameplay cues; dedicated finished art remains a future replacement.

Five 1536×1024 RGBA PNGs cost approximately 40 MiB of GPU texture storage with complete mip chains before fonts, vectors, framebuffer and driver overhead. This is a budget estimate, not a device measurement. No dynamic light or screen-copy pass is introduced. G2 loads terrain sheets by scene lifetime rather than accumulating the complete library; its typical large-texture estimate is 48 MiB. Target under 64 MiB for the visual texture set and profile actual frame time, overdraw, thermal behavior and memory on Android before claiming 60 FPS. Consider atlas packing/downsize or device compression only after visual/device review; do not enable unsupported compression blindly.

## Exact replacement specifications

Approved artwork can replace existing filenames with matching dimensions/regions, or update `visual_catalog.json` pivots/regions without changing combat logic. Art-file changes require a fresh import and visual checks.

| Asset to author/review | Required delivery | Runtime framing and pivot |
| --- | --- | --- |
| Menu key art | 1920×1080 or larger 16:9 RGB PNG/WebP; no text/UI; quiet left 42% | Aspect-cover full screen; right-side cannon must survive wider/taller crops |
| Outpost terrain | 1536×1024 RGB, no actors or baked placement circles; upper-left diffuse light | Drawn into the existing 955×560 field, center clear; verify terrain texture scale against units |
| Primary/MG/Cannon replacement sheet | Six 512×512 RGBA cells in a 1536×1024 atlas; at least 48px transparent gutters | Drones center around `(256,256)`; weapon rotation pivot/breech `(256,350)`; barrel points up; supply measured muzzle tip for visual scale alignment |
| Missile/Laser/EMP/Heavy AA heads | Separate 512×512 RGBA each, up-facing, distinct silhouette/material detail; transparent padding | Publish explicit breech pivot and scale so muzzle lies 32–38 world units forward; current SVG/shared Heavy AA are interim art |
| Command bunker | 1280×400 RGBA, low broad roof, no gun; roof mounting pivot `(640,180)`; no baked UI | Display roughly 320×100 near the existing bunker; align the roof mount under manual cannon `(560,605)` without moving gameplay |
| Shield/EMP/Bomber/Sniper/Carrier/Stealth | 512×512 RGBA per archetype, strong differing silhouette; 4 rotor frames and optional damage variants | Keep body collision readability around the existing 18×size radius; artist must label pivot/scale, not alter hit rules |
| Five chapter bosses | 1024×1024 RGBA each, three phase damage states, up to 8 frames per ability | Anchor/weakpoint coordinates remain data-driven; preserve the visible cyan core at the actual hittable position |
| Explosion replacement | Six 512×512 RGBA frames, 3×2 atlas 1536×1024, equal padding, no labels | Ignition→fire→smoke in 0.65s, center-pivot, consistent ground contact and size |
| EMP/laser/overclock/impact pack | 256×256 or 512×512 RGBA with declared frame counts and timing | Must fit current simulated duration/radius and preserve threat telegraphs; restrained additive energy only |
| Environment art refinement | Existing three 1536×1024 four-map atlases, one six-cell prop atlas; or update explicit regions | All 25 now use G2 illustrated terrain; refine perspective/scale and optionally supply bespoke Hive/territory architecture without moving paths/slots |
| Optional true lighting | Matching albedo + tangent-space normal RGBA at identical dimensions/pivots; flat normal `(128,128,255)` | Artist must state normal convention. Validate Godot CanvasTexture/DirectionalLight2D/PointLight2D on GLES3 before use; remove baked highlights first |

The current generated PNGs and authored UI are integrated candidates, not evidence of final production approval. Unique support/boss art, the three SVG support heads, standalone Heavy AA, phase/rotor sheets and dedicated energy effects still require external artist creation or a later approved generation pass. G2 replaces the former geometric terrain for all 25 missions with 13 illustrated kits, shared props and atmosphere. These are integrated generated candidates awaiting final art approval, rather than 25 unique commissioned paintings. See the G2 guide for its replacement specifications, quality setting and current memory budget.

## Verification and captures

Run `./tests/run_checks.sh` for native import/startup, all existing campaign/combat/research/input checks and the added visual-resource checks. It isolates saves and rejects engine errors. The real-render capture scene requires X11/Wayland and Compatibility rendering:

```sh
XDG_DATA_HOME=/tmp/frontline-g1-data godot --path . --audio-driver Dummy res://tests/visual_capture.tscn -- --output=/tmp/frontline-g1-captures
```

Use a separate temporary data directory: the capture scene deliberately starts a fresh test campaign. It deploys mission 1, buys defenses with the actual starting budget, simulates real manual/automatic attacks and captures the native viewport. It also captures a real destruction explosion, tactical build mode and a 1600×720 layout; no mockup compositing or fake screenshots are used. The test exits rather than pretending to capture under the headless dummy renderer.

Linux OpenGL/llvmpipe captures are checked in under `docs/visuals/`. Physical Android appearance, physical multitouch, audible playback, cutout hardware, FPS, memory and battery/thermal behavior still require device validation. Generated art should receive art-direction and commercial-clearance review before release.

For an Android export, include all resources and include `data/*.json`, `assets/*.json`, `assets/environment/*.json`, `assets/ASSET_LICENSE.md` and `assets/ui/fonts/*.txt` as non-resource files if the preset filters them. Keep dynamic atlas/catalog dependencies and font notices in the package. Export templates/SDK/signing and a physical device build remain separate validation steps.

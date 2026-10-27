# G3 — drones, bosses and weapons

G3 replaces every shared enemy silhouette and interim weapon head with original detailed military sci-fi raster art. The nine standard drones, five chapter bosses, six secondary weapons and Sentinel-7 have distinct bindings. The project remains native Godot 4.6 Compatibility with offline local resources. All gameplay definitions, statistics, collisions, paths, targeting, damage and reward rules are retained.

## Art and reusable composition

Five original 1536×1024 transparent source atlases provide 30 isolated bodies/components. They contain layered steel armor, mechanical detail and red enemy or cyan friendly identification. Source regions are individually measured because generated sheet padding is imperfect. Source PNGs are unmodified; `source_region` documents their coordinates while `region` and `pivot` use the imported texture's coordinates. Godot downsizes these five sources to **768×512**, with mipmaps and lossless alpha, for Android. A unit normally occupies 30–100 reference pixels; a boss is roughly 150–190 pixels. Artist-authored higher-resolution sources can replace these candidates by updating the catalog/import binding, without touching combat.

| Source atlas | Objects |
| --- | --- |
| `drones/line_atlas.png` | Scout quadcopter; Assault twin-fan gunship; Heavy hexacopter; three-turbine Shield guardian; forked EMP craft; H-frame Bomber |
| `drones/specialists_atlas.png` | Slender Sniper; double-hull Carrier; swept-wing Stealth; isolated rotor, jet exhaust and charred debris |
| `drones/bosses_atlas.png` | Heavy Assault Carrier; EMP Warship; Armored Border Guardian; Drone Factory Command Ship; The Hive Core; separate boss cannon |
| `turrets/weapons_atlas.png` | Machine Gun, Cannon, Missile Launcher, Laser, EMP and Heavy AA rotating heads |
| `turrets/sentinel_atlas.png` | Primary breech and independent twin barrels; primary and secondary fixed bearings; upgrade collar; autoloader cassette |

`assets/visual_catalog.json` retains all bindings, aliases, pivots, rotor axes, engine axes and boss weapon mounts. All 14 enemy names now resolve explicitly. Heavy AA has its own head; it no longer reuses the primary gun. The old G1 `combat_atlas.png` and three SVG support heads are historical reference assets and are not used by active unit bindings. Existing G2 environments are retained.

The near-overhead, prelit style follows `VISUAL_STYLE.md`: upper-left key, down-right soft ground shadows, worn charcoal/steel, restrained accents and readable silhouettes. The sources are original generated art candidates, not commissioned production-approved paintings. Some source components have a slightly steeper perspective or different padding; pivots/crops compensate at game scale. Final perspective, mechanical alignment and commercial art approval remain art-direction work.

## Animation and ownership

`unit_visual.gd` composes a stationary soft shadow, a rotating/hovering body and one batched `unit_mechanics.gd` overlay. Weapons add a fixed detailed bearing; the primary has a separate sliding barrel assembly. Bosses add two articulated armor sections. Four to six nodes per visual compose all rotors, engines and armor, instead of a node for each spinning blade or particle.

`combat_visuals.gd` reads presentation snapshots after the existing battle simulation. It supplies simulated delta, health fraction, actual shot count, upgrade tier, reload progress and boss phase. It never calls gameplay methods. `UnitVisual` has no independent `_process`, targeting, firing, collision or save logic. Animation clocks do not consume the combat RNG. All animation freezes on pause and follows the shared normal simulation time, including during construction and upgrades.

This is a reusable **simulation-driven transform animation system**, equivalent to a programmatic animation controller: rotating rendered rotor layers, pulsing rendered exhaust, bounded body hover, mechanical recoil and sliding autoloader/armor parts. The art sheets contain independent objects, not fabricated animation frames. Sprite materials supply restrained hit flashes, scorch/fracture damage states, suppression and cloak opacity. Shader UVs are normalized per atlas region. No normal map, bloom, screen read, compute shader, Forward+ feature or runtime lighting pass is introduced.

Hover offsets only the artwork by ±1.5 local units. Original enemy positions, movement, hit radii, target points and boss weakpoint circles stay fixed. Decorative rotor/wingspan areas do not extend the hittable body. Boss painted reactors and the existing cyan weakpoint cue align through the measured body pivot; do not move a gameplay weakpoint to fit future art.

Bosses retain their actual phase thresholds/attacks and telegraphs. One shared `boss_telemetry.gd` overlay keeps their name, phase, HP and siege timer above the larger silhouettes; duplicate local boss bars/labels are removed. Phase changes now open rendered armor sections, expose damage and animate separate weapon assemblies, alongside the retained phase pulse and core cues. Standard destruction shows a dark falling body and rendered debris. Boss destruction adds staggered explosion frames and six pieces of debris. A bounded, detached `destruction_batch.gd` owns these snapshots: **12 wrecks maximum**, finite 1.0/2.1-second lifetimes, no collision/targets and no retained enemy Node. Reward and enemy removal remain immediate and single-use.

## Weapon feedback and primary centerpiece

- All six automatic weapons retain target acquisition, instantaneous gameplay heading, range, fire rates, projectile/hit rules and upgrades. Their fixed bearing stays put while their rendered heads rotate/recoil. Machine Gun and Heavy AA use paired flashes, Cannon a broader kinetic flash, Missile visible backblast, Laser its continuous beam, and EMP its existing area pulse.
- Primary rotation follows the existing smoothly interpolated **actual** barrel angle. Twin barrels recoil separately from the breech/bearing; the autoloader slides with the actual reload fraction. The 60-round default magazine and 2-second default reload are unchanged.
- Heat accumulates from actual shot-count changes and cools with simulation delta. It only warms the rendered barrel material: no overheating damage, jam, reload penalty or hidden stat is added.
- Standard rounds retain a fine cyan trail; Armor Piercing adds narrow amber parallel streaks; Explosive uses a thicker orange/red trail. Each projectile snapshots its visual ammunition ID at firing time, alongside the existing damage/critical snapshot. Secondary trails are hidden while still inside the gun mount; their simulated origin and collision stay unchanged.
- Actual level 2/3 secondary purchases add rendered armor collars. Primary reinforcement tiers use the existing permanent `cannon_damage`, `cannon_rate`, `magazine` and `reload` research snapshot (combined levels ≥5 and ≥10). No new research cost, bonus or save field is introduced.

On a terminal boss victory, `_results` **settles the existing atomic campaign transaction first**. A skippable 1.9-second `combat_outro.gd` then advances only the detached destruction/effect batch. Combat is finished and frozen; input cannot resume or abandon the battle. Continue/Esc/Android Back reveals the already-settled result screen. Save failures retain the existing retry path and do not begin the outro. Non-boss outcomes retain the existing immediate transition. This is a presentation transition, not delayed enemy removal or rewards.

## Budgets and quality

Each G3 imported 768×512 RGBA sheet with complete mipmaps is approximately **2 MiB**; all five total about **10 MiB**. The old 8 MiB G1 combat sheet is not loaded during normal gameplay. With a terrain/prop pair and existing menu/bunker/explosion sources, the estimated large-texture set is about **50 MiB**, before fonts, vectors, framebuffer, driver resources and transient decode buffers. This is an estimate, not Android GPU telemetry. The manifest records source and required imported dimensions separately.

There is one mechanics draw overlay per actor, at most six rotors/turbines and two articulated boss gun mounts. Wrecks are capped at 12; existing ordinary effects retain their 96 cap. Source atlas textures and regions are shared. The existing Reduced Environment Effects setting remains available for terrain effects; weapon telegraphs, recoil and ammo feedback remain active for gameplay readability.

Native Linux Mesa/llvmpipe draw-call samples are recorded by the capture fixture; this is an integration/performance diagnostic, not proof of 60 FPS, Android GPU speed, thermal behavior, memory or battery use. Profile actual devices before release, especially boss death overdraw and high-density waves.

## Rebuild, review and testing

```sh
python tools/build_unit_catalog.py
python tools/build_asset_manifest.py
godot --headless --path . --editor --import --quit
./tests/run_checks.sh
```

Keep each G3 PNG's tracked `process/size_limit=768`, mipmaps and alpha-border import settings. Changing import size requires matching catalog coordinates and `assets/source/unit_sources.json` imported dimensions. Android export must include `data/*.json`, `assets/*.json`, `assets/environment/*.json` and license/font notices; all source atlas dependencies must remain included.

The unit suite covers every explicit enemy/weapon binding, raster art, propulsion axes, bounded nodes, visual-only transforms, cloak/shadows, boss armor/weakpoint invariance, real firing/ammunition/reload, pause, upgrades, immediate rewards, single-use deaths and detached-effect bounds/lifetimes. The full suite still tests all 25 missions and campaign/save/input/research/combat behavior.

Native capture requires a real X11/Wayland display and Compatibility renderer:

```sh
./tests/run_native_capture.sh /tmp/frontline-g3-captures
```

The wrapper isolates saves and rejects script/engine errors, including errors after a zero engine exit. `tests/unit_capture.tscn` deliberately initializes controlled units, funds, unlocks, positions, cloak time and phase damage to expose every visual. It uses the actual Gameplay/Main scenes, actual damage/shop/ammunition/reload APIs, boss phase AI and result transaction; it is **visual fixture coverage**, not a claim of normal campaign play or human skill. Full campaign completion is exercised separately by ordinary-combat regression tests. Original `tests/visual_capture.tscn` additionally captures a normal first-mission wave with manual and automatic attacks. Screenshots are unmodified Godot viewport PNGs, not image-generation screenshots or composites.

See [native gallery and validation](units/README.md). Physical Android, physical multitouch, audio playback and device performance remain unverified here. All required G3 enemy/weapon art is bundled; no external download is needed to play. Optional future deliveries include polished bespoke raster damage/rotor frame sheets, artist-refined pivots/perspective, authored demolition animation and matched albedo/normal maps. These are refinements rather than undisclosed placeholder bodies. Exact existing source regions and dimensions are in the catalog, manifest and source provenance record.

# Combat effects G4

G4 extends the existing top-down game. Real shot, impact, death, status and reload events feed presentation snapshots. Weapon statistics, hit geometry, damage/reward ownership, targeting, enemy AI, wave data and campaign transactions remain in their existing systems. See the [native gallery and validation](effects/README.md).

## Scene and ownership

`scenes/effects/combat_effects.tscn` is the reusable composition: one manager, one mouse-ignoring clipped field Control, one batched particle painter and one screen-feedback painter. There is no Node, physics body, Timer, Light2D or emitter per particle. The field clip is `(0,88,955,560)`. Foreground impacts are above drone bodies, below boss telemetry; framing and native HUD remain outside the particle clip. Damage edges and arrival banners use explicit field coordinates, with arrival above the boss-health panel.

`combat_effects.gd` preallocates **192 dictionary slots**, with an active list and reusable free list. Expiry returns the slot; scene disposal releases all effects. Emission counts and per-category limits drop excess cosmetic work. No particle retains an enemy/projectile reference or consumes the cannon's critical RNG. Integer IDs and deterministic angles give varied fragments without sharing gameplay randomness.

`battle_view.gd` retains its public `effect()` API and bounded legacy cue list. Its atlas explosions, EMP/build rings and hit sparks are painted in the foreground batch. Oversized environmental/grid cues render as restrained energy rings instead of foreground fireballs, so they cannot cover the enemy formation. Repeated laser damage at the same location refreshes a single hit cue instead of stacking flashes. Explosion density has its own smaller cap. `destruction_batch.gd` retains up to 12 detached fading wrecks and staggered boss explosions; flying fragments now belong exclusively to the central particle pool.

All world presentation advances through the shared `BattleView.tick(delta)`: pause freezes it, 2× doubles it, tactical building uses 0.25×. Reload feedback reads the real cannon's magazine state. The existing saved boss outro advances only detached presentation after combat has finished, retains Continue/Esc/Android Back skip and never pays rewards. A short results-only victory sweep cleans itself up after 1.4 seconds; UI time is independent of combat time.

## Weapons and destruction

| System | Integrated feedback |
| --- | --- |
| Machine gun | Existing restrained paired muzzle flashes/recoil and fast textured tracers; warm small metal impact streaks and a brief soft spot |
| Cannon / Heavy AA | Strong muzzle flash, physical-art recoil, smoke at the visual muzzle, thicker round, heavier warm sparks |
| Missile | Backblast, sampled exhaust/smoke trail, original six-frame impact explosion, sparks and an orange ring matching the actual splash radius |
| Laser | Broad low-alpha energy fringe and thin near-white core starting at the barrel; throttled impact glow at 10 Hz, coalesced hit sparks |
| EMP | Existing expanding gameplay pulse plus broken electrical arcs; rotating small interrupted status arcs on slowed/disabled drones (maximum 24 cues), retaining existing status labels |
| Primary Standard | Cool-white round/core, compact muzzle smoke and small impact confirmation |
| Primary AP | Longer gold-edged round with short residual streaks; shot-snapshotted ammunition tint |
| Primary Explosive | Wider orange round, short smoke trail, real splash-radius ring and explosion |
| Primary critical / reload | Existing crosshair confirmation plus a short CRIT marker/ring, real reload arc and compact progress strip; READY appears on actual completion |
| Drone destruction | Immediate gameplay removal/reward, initial atlas flash, warm sparks, small explosion, detailed detached wreck, textured metal fragments, short smoke and finite fade |
| Heavy / boss destruction | Larger explosion/smoke/sparks, more fragments, bounded gentle artwork displacement; bosses retain staged secondary detonations and the saved-result outro |

The critical effect requires critical-chance research; the initial cannon has zero critical probability. VFX does not silently grant critical hits. EMP visuals distinguish suppression using existing game status; they do not introduce a new stun or damage behavior.

Base damage adds fading red field-edge strips for 0.5 seconds and a short text warning at ≤25% HP. There is no full-screen white flash, periodic strobe, bloom or long camera shake. Major impacts can displace **artwork only** by at most 1.5 units on each axis for 0.18 seconds. Battle/controller positions, collision geometry, projectile paths, camera/input transforms, crosshair and HUD stay fixed. The field clip does not move.

## Quality and accessibility

Settings are in the existing local schema-v3 settings file, independent of campaign resets. Old settings acquire defaults; only known quality strings and actual booleans are accepted. All options appear in a scrollable, touch-sized Settings panel. Changes apply on the next mission.

`assets/effects/quality.json` is independent of combat tuning:

| Budget | Low | Medium (default) | High |
| --- | ---: | ---: | ---: |
| Active pooled particles, all categories combined | 48 | 112 | 192 |
| Sparks per burst | 4 | 8 | 12 |
| New emissions per simulation tick | 12 | 28 | 48 |
| Concurrent smoke particles | 3 | 8 | 12 |
| Concurrent flying metal fragments | 6 | 16 | 24 |
| Concurrent soft impact-light sprites | 3 | 6 | 8 |
| Concurrent main atlas explosions | 4 | 8 | 12 |

The legacy cue list is also bounded: 48 entries at Low, 96 at Medium/High, or 24 with Reduced combat effects. Wrecks are separately capped at 12; each boss wreck has at most four staggered detonations. Existing environment effects remain separately bounded at 32 small particles and four haze sprites; no per-mission emitter growth is introduced. Status arcs have a 24-drone ceiling. These counts describe presentation only; existing gameplay projectiles and enemy counts remain unchanged.

- **Reduced combat effects:** Low budgets, at most two sparks per burst; suppresses pooled smoke, flying fragments, impact lighting, shake, secondary boss explosions and moving atmosphere. Main explosions stop before smoke frames, while hit/area/reload information remains.
- **Reduced motion:** disables shake and flying debris; particles stay in place, area/EMP rings stop expanding, wrecks fade in place, rotor/hover artwork and weather sweeps hold still. Essential aiming, projectile movement, readable recoil/reload state, actual enemy movement and gameplay telegraphs remain functional.
- Individual **Smoke**, **Metal debris**, **Soft impact lighting** and **Subtle impact shake** switches can disable layers independently. Smoke also suppresses late smoke-only frames of the main/boss explosion animation. Reduced options take precedence over individual enabled switches.
- The previous **Reduced environment effects** option remains available and keeps its previous independent meaning.

## Compatibility, art and performance limits

The implementation uses ordinary CanvasItem drawing, shared AtlasTextures and authored soft-alpha utility SVG textures. It reuses the existing original six-frame raster explosion, G3 metal fragment, tracer, missile, muzzle flash and environment smoke/light utility assets. The manifest inventories the new quality configuration. No new large raster textures, normal maps, dynamic lights, screen copies, GPU particle shaders or rendering features are required. Heat distortion is deliberately omitted: no scene-copy/refraction cost is introduced for this Compatibility/mobile foundation.

CPU-batched drawing was chosen for the small, hard-bounded population and deterministic Compatibility behavior. Native Linux/Mesa measurements are documented in the validation report; **there is no measured Android CPU-versus-GPU comparison**. Physical mid-range Android profiling must determine whether a future GPU particle version is worthwhile. Do not infer 60 FPS, battery, thermal performance or actual VRAM from these desktop captures or headless tests. Typical existing large-texture residency remains approximately 50 MiB before fonts, vectors, framebuffer and driver overhead; this is an estimate.

The integrated effects are functional and visible in real gameplay. Utility arcs, sparks, smoke/light gradients and transform animation are authored procedural/vector presentation, not commissioned final raster FX sheets. Optional external art refinement remains: a seamless four/eight-frame smoke/exhaust pack (256×256 RGBA per frame), weapon-specific impact/muzzle sheets (128/256×256 RGBA), a reviewed EMP/laser energy sheet (256×256 RGBA, four/eight frames), and boss demolition variations using the existing six 512×512 frame layout. Deliver equal padding, centered pivots, explicit timing, no labels/background, restrained warm ballistic/cyan friendly/violet EMP color, and matching upper-left material shading. Integrate through visual bindings without changing hits, range or damage. Existing generated art still needs final art-direction approval; no new third-party artwork/download is needed to run.

## Reproduce

```sh
./tests/run_checks.sh
DISPLAY=:0 ./tests/run_effect_capture.sh /tmp/frontline-g4-captures
DISPLAY=:0 ./tests/run_effect_capture.sh /tmp/frontline-grid-capture --interference-only
DISPLAY=:0 ./tests/run_native_capture.sh /tmp/frontline-unit-regression
```

Use a real display for captures. The wrappers isolate saves, reject script/engine errors and fail under a headless dummy renderer. G4's scene stages real firing, hits, reloads, death signals, settings, saved victory and stress fixtures. Fixture funds, seeded critical research, direct spawns/damage and synthetic victory are clearly labeled; these are visual integration tests. The independent `tests/visual_capture.tscn` uses the real mission-one starting budget, actual waves and manual/automatic combat.

Android export must include `assets/effects/*.json` along with the existing `data/*.json`, `assets/*.json`, `assets/environment/*.json` and license/font notices if the preset filters non-resource files.

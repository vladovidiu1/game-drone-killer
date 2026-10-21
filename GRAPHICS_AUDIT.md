# Graphics audit — G6

This report records the G6 snapshot. [M1 subsequently changes combat balance and removes selectable speed](docs/M1_BALANCE.md); G6 performance/control numbers below are historical, not measurements of M1.

2026-10-21 · Godot 4.6.3 stable · Compatibility/GLES3 · existing G1–G5 project.

The game has an integrated, playable visual system and passes the available regression checks. **It is not visually production-ready:** generated artwork still needs final artist review, and physical Android appearance, touch ergonomics, GPU performance, thermals and export packaging are unverified. No 60 FPS claim is made.

## Changes implemented

| Finding | Resolution / practical limit |
| --- | --- |
| Low reduced combat particles but still ran full weather and unit shadows | One shared presentation profile now controls VFX, environment particles/haze/extra props, additional fake shadows, night light pools and menu particles. Medium remains default. |
| Enemy entry lanes crossed the opaque mission-title plate | Removed that world plate; operation number/title now lives in the native HUD footer. Flight paths, spawns and camera are unchanged. |
| Artwork/screen feedback could paint over native controls | HUD z=10, above world artwork/feedback; skippable saved boss outro z=20. Native hitboxes and input transforms are unchanged. Capture-only disclosures also sit above HUD. |
| Every actor repeatedly wrote unchanged shader uniforms | Typed cached values now suppress redundant writes. Damage, flash, heat, cloak and suppression changes/recovery still update body and boss armor immediately. |
| Mechanical/environment presentation requested redraw every tick | Environment ceilings 30/60 simulated Hz; unit overlays 20/30/60. Actual shots, tier changes and reload redraw immediately. Manual aiming and all simulation timing retain their cadence. |
| Settings quality was a dropdown despite explicit touch ownership | Three native ≥54px touch buttons, selected styling and saved feedback. Failed preset writes roll back in-memory settings. No new save key/schema. |
| Inventory incorrectly called active pause/credits icons unused | Corrected their status; root human-readable inventory generated from the same 71 entries as the hashed JSON manifest. Legacy/reference assets are explicitly identified. |

The authoritative budgets are [VISUAL_STYLE.md](VISUAL_STYLE.md#graphics-presets-and-draw-order-g6) and [quality.json](assets/effects/quality.json). Low removes runtime extra shadows, animated weather and moving haze; baked shading and static atmospheric color remain. Medium halves maximum weather particles and haze layers. High keeps all available presentation. Reduced effects and reduced motion remain stronger independent accessibility overrides. Quality does not change enemy stats, targeting, speed, collision, input ownership, mission data, save schema, research or reward transactions.

## Visual inspection

Native unmodified viewport frames were reviewed for all 25 terrain assignments, nine standard drones, five bosses, six secondary weapons, the primary cannon, menu/map/briefing/Arsenal/settings/results and representative VFX. [Current gallery and raw measurements](docs/audit/README.md). Early before-fix captures exposed the title overlap; the checked-in mission gallery is from the corrected HUD.

| Area | Observed result / remaining issue |
| --- | --- |
| Menu | Original military key art, readable condensed logo, clear New/Continue/Arsenal/Settings, local fonts, subdued atmosphere. Low freezes decorative atmosphere. Generated key art remains a review candidate. |
| Strategic map | Original vector terrain, cyan/red/orange states, chapter headings, labels, bounded drag-pan, objective/briefing access and result receipts. Conquest/counterattack presentation preserves checkpoint rules. Cartography is intentionally vector, not painted satellite art. |
| Battle terrain | 13 reusable illustrated kits with day/sunset/night/storm/smoke. First five visibly distinct. Low night captures for missions 6/18 keep enemies and slots visible with light pools removed. No missing textures or HUD-covering environment layers found. |
| Drones | Scout, Assault, Heavy, Shield, EMP, Bomber, Sniper, Carrier and Stealth each use dedicated G3 atlas regions. Rotor/hover transforms, hit/damage, suppression/cloak recovery, health bars and detached death effects function. Painted lights/body material are baked, not physically lit. |
| Bosses | Assault Carrier, EMP Warship, Border Guardian, Factory Command Ship and Hive Core each use distinct raster bodies, articulated armor, phases/core indicators and skippable destruction. Source padding/perspective and authored phase artwork still need artist approval. |
| Secondary weapons | MG/Cannon/Missile/Laser/EMP/Heavy AA retain fixed bases, rotating heads, recoil, weapon-specific effects and tier-1/3 armor progression. No collision/body scale changes. |
| Primary cannon | Separate rotating modular centerpiece; recoil, heat, magazine/reload and standard/AP/explosive effects work together. Native crosshair and aiming stay responsive in tested desktop/synthetic touch cases. |
| Arsenal / briefing | Four functional tabs, weapon portraits, upgrade levels, confirmation/purchase feedback, scrollable briefing with fixed Start/Back. Long copy requires scrolling on short screens by design. |
| Results | Victory/defeat territory messages, rewards, next/retry/map actions and saved boss outro work. Animation does not award rewards. Some capture progression is deliberately staged to cover late-chapter UI. |
| VFX | Bounded particles, density-limited six-frame blasts, tracer/missile/laser/EMP effects, hit/critical/reload feedback; no full-screen distortion or bloom. 80-death stress and reduced modes inspected. Dense health/status labels can still overlap in extreme staged groups. |
| Fonts/icons | Barlow Condensed, Barlow Regular and DejaVu Mono are local and licensed; SVG icons retain native resolution. Compact 13–17px secondary labels/small action icons need physical phone legibility review. |
| Scale/order | 1280×720, 1600×720, 1280×600 and 1024×768 native layouts tested; uniform world scale and native UI anchoring preserved. Health/status indications intentionally overlay world units. |

Transient dust/grid-surge warnings and boss telemetry still use the existing field overlay. Dense-wave overlap/contrast on physical small screens remains a polish item; mission identity no longer competes with incoming drones. No active unit type falls back to the legacy geometric/shared body. Placement pads, range rings, path dashes, radar and EMP arcs remain deliberate procedural/vector tactical indicators.

## Mission coverage

All missions instantiate the shared gameplay scene with data-specific paths, slots, waves and environment assignments. Every entry below passed resource/geometry validation in Low, Medium and High (75 combinations); native High captures contain actual deployed drones, purchased automatic defenses and manual shots. These early-wave frames are visual coverage, not completed playthroughs. Separate full-mission automated combat remains in the regression suite.

| ID | Mission / corrected native capture | Environment / atmosphere | Slots | Coverage |
| --- | --- | --- | --- | --- |
| 01 | [Outpost Alpha](docs/audit/mission_01.png) | outpost / day | 5 | Native High + all 3 headless presets |
| 02 | [Red Hill Village](docs/audit/mission_02.png) | village / sunset | 6 | Native High + all 3 headless presets |
| 03 | [East Supply Depot](docs/audit/mission_03.png) | depot / day | 7 | Native High + all 3 headless presets |
| 04 | [Broken Bridge](docs/audit/mission_04.png) | bridge / storm | 6 | Native High + all 3 headless presets |
| 05 | [Greyford](docs/audit/mission_05.png) | urban / smoke | 6 | Native High + all 3 headless presets |
| 06 | [North Power Station](docs/audit/mission_06.png) | power / night | 7 | Native High + all 3 headless presets |
| 07 | [Riverside District](docs/audit/mission_07.png) | bridge / sunset | 7 | Native High + all 3 headless presets |
| 08 | [Iron Highway](docs/audit/mission_08.png) | highway / day | 7 | Native High + all 3 headless presets |
| 09 | [Falcon Airbase](docs/audit/mission_09.png) | airbase / night | 7 | Native High + all 3 headless presets |
| 10 | [Metro Asteria](docs/audit/mission_10.png) | urban / night | 7 | Native High + all 3 headless presets |
| 11 | [Western Ruins](docs/audit/mission_11.png) | ruins / smoke | 8 | Native High + all 3 headless presets |
| 12 | [Liberation Road](docs/audit/mission_12.png) | highway / sunset | 8 | Native High + all 3 headless presets |
| 13 | [Black Ridge](docs/audit/mission_13.png) | forest / storm | 8 | Native High + all 3 headless presets |
| 14 | [Border Fortress](docs/audit/mission_14.png) | fortress / day | 8 | Native High + all 3 headless presets |
| 15 | [The Last Border](docs/audit/mission_15.png) | fortress / sunset | 8 | Native High + all 3 headless presets |
| 16 | [Varkon Frontier](docs/audit/mission_16.png) | forest / night | 8 | Native High + all 3 headless presets |
| 17 | [Steel Valley](docs/audit/mission_17.png) | forest / day | 8 | Native High + all 3 headless presets |
| 18 | [Drone Assembly Plant](docs/audit/mission_18.png) | industrial / night | 8 | Native High + all 3 headless presets |
| 19 | [Red Harbor](docs/audit/mission_19.png) | harbor / storm | 8 | Native High + all 3 headless presets |
| 20 | [Industrial Citadel](docs/audit/mission_20.png) | industrial / smoke | 8 | Native High + all 3 headless presets |
| 21 | [Deadlands](docs/audit/mission_21.png) | ruins / storm | 8 | Native High + all 3 headless presets |
| 22 | [Varkon Defense Ring](docs/audit/mission_22.png) | fortress / night | 8 | Native High + all 3 headless presets |
| 23 | [Central Command](docs/audit/mission_23.png) | urban / sunset | 8 | Native High + all 3 headless presets |
| 24 | [Capital Siege](docs/audit/mission_24.png) | ruins / sunset | 8 | Native High + all 3 headless presets |
| 25 | [The Hive Core](docs/audit/mission_25.png) | fortress / smoke | 8 | Native High + all 3 headless presets |

## Validation and control audit

- `FRONTLINE_REPORT_DIR=/tmp/g6-final-reports ./tests/run_checks.sh`: **7,332 assertions / 23 suite invocations / 0 failures**, including real Godot editor import, startup and all script/resource/campaign/combat/research/save/input suites. Logs rejected script/engine errors and ObjectDB leak warnings.
- New graphics suite: **810 assertions + 2 fresh-process assertions**. All mission/preset loads, slot access, body/shadow/cloak/armor state, pause, accessibility overrides, real synthetic preset touches and persisted Low are covered. Existing environment checks now use Medium's lower decoration budget, so totals differ from G5.
- Full campaign balance output: **28 records**, plus **2 comparison records**, structurally identical to checked-in pre-G6 results. All 25 missions remain playable; no definition files changed.
- Native environment runner: **25 missions / 29 frames / 536 real manual shots / 0 failures** at High. Extra Low-night run: **missions 6 and 18 / 3 frames / 42 shots / 0 failures**.
- Native unit runner: **14 enemy archetypes, 7 weapons, 27 frames, 0 failures**. Includes bosses/phases/destruction, tier progression, reload/ammo and saved terminal outro. Coverage fixtures deliberately grant deployment/unlocks/funds or stage enemies.
- Native UI runner: **36 frames / 0 failures** across four layouts. Uses actual native mouse interactions, map pan/gating, research confirmations/purchases, build/upgrade, reload/pause and active Overclock label.
- Native VFX runner: **36 frames / 0 failures**, real weapon-hit/death APIs plus explicitly staged seeded critical and 80-death stress fixtures. Quality/reduced toggles and victory presentation checked.
- Native profiling runner: **3 presets / 540 measured frames / 0 failures**, identical combat signature in all three modes. Gallery retains a selection; raw native counters for every capture are included.

| Requested control | Available evidence | Physical Android status |
| --- | --- | --- |
| Two-finger aim + held FIRE | Hybrid suite injects independent touch IDs through actual input/HUD, verifies ammo/aim/fire/release and UI exclusion | Pending hardware digitizer test |
| Build/upgrade | Native/synthetic slot and shop interaction; scroll does not buy; all 75 mission/preset last-slot selections | Pending thumb reach/edge gesture review |
| Ammunition + reload | Native primary standard/AP/explosive/reload frames; hybrid/research suites verify ownership, magazine and timing | Pending physical simultaneous fingers |
| Repair/EMP/Overclock | Actual ability/economy/cooldown checks and native active ability labels/VFX | Pending hardware ergonomics |
| Menu/navigation/map camera | Native buttons, research confirmation, bounded map pan and drag-release suppression; no battle camera change | Pending cutout/gesture-inset/back integration |
| Pause/resume/focus/restart | Regression verifies cleared input, frozen shared timers and reset mission state | Pending Android lifecycle/audio recovery |
| Tactical slow motion and 2x | Shared simulated-delta tests, actual build panel at 0.25x, paused/speed labels | Pending hardware interaction |

Synthetic multitouch and native Linux input validate code paths, not Android hardware. No APK export/install, physical touchscreen, audible speaker playback, cutout hardware, GPU driver, battery or thermal tests were available.

## Measured rendering diagnostics

Godot 4.6.3, X11 1280×720, Compatibility OpenGL, Mesa 25.0.7 **llvmpipe (LLVM 19.1.7, 256 bits)**, Dummy audio. One baseline and one final run on the same shared software-renderer host. The staged mission-4 storm fixture starts with 80 stationary drones from nine types, fixture funds, six real automatic weapons, actual manual fire and seed 6006. Each preset runs 240 frames at fixed simulation dt=1/60; first 60 are warmup, final 180 measured. This is deliberately heavier than early normal-budget wave captures and not an Android workload guarantee.

CPU timing uses `Time.get_ticks_usec()` around `battle.simulate`; frame wall timing includes process/render scheduling. Draw calls and texture memory use Godot `Performance` monitors. No GPU timestamp profiler or Android profiler was available. Detailed median/p95/max distributions: [before](docs/audit/profile_before.json) and [after](docs/audit/profile_after.json).

| Preset | Draw-call median before → after | Simulation CPU ms median / p95 before → after | Frame wall ms median / p95 before → after | Weather particles before → after |
| --- | --- | --- | --- | --- |
| Low | 565 → 470 | 2.609 / 3.739 → 2.556 / 3.509 | 44.375 / 125.771 → 38.674 / 50.514 | 32 → 0 |
| Medium | 571 → 569 | 2.817 / 7.758 → 2.252 / 4.684 | 43.279 / 128.144 → 46.892 / 67.058 | 32 → 16 |
| High | 573 → 571 | 2.526 / 4.160 → 2.480 / 3.444 | 39.581 / 95.722 → 48.838 / 53.738 | 32 → 32 |

Low's draw-call median falls **565 → 470 (16.8%)**. Medium/High retain detail; a smaller common reduction follows removal of the world title plate. Final particle peaks are 34/57/71 within 48/112/192 active budgets. Identical signature `[1000,3,110,18530,39,22,17,0]` represents HP, kills, earned BC, BC balance, primary shots, hits, enemy actions and support spawns.

The engine texture counter remains **69,049,775 bytes (~65.85 MiB)** in this fixture on every preset: resolution/residency was not reduced. This counter is not process RAM, Android VRAM or export size. Native early-wave High mission frames report 140–197 draw calls at the capture instant, not whole-mission maxima.

Wall timings are host/scheduling-dependent and do not show a consistent across-preset improvement; High's final median is worse than its baseline. Treat CPU/latency numbers as diagnostics from a single noisy run, not proof of an FPS increase. Shadows and weather reductions are measurable; a stable 60 FPS target still requires repeatable warm-device measurements. No automatic quality selection is introduced without device evidence.

## Artwork and release work still required

| Priority | Remaining production work | Replacement boundary |
| --- | --- | --- |
| Release gate | Artist review/cleanup of generated unit, weapon, bunker and terrain candidates: consistent upper-left key light, perspective, padding, sharp silhouettes at phone scale | Keep catalog regions/pivots, original combat geometry and 768×512 mobile G3 import size; [exact specifications](VISUAL_STYLE.md#exact-replacement-specifications) |
| Release gate | Physical Android export/driver/input/safe-area/thermal profiling and full campaign QA | [Unexecuted device checklist](ANDROID_VISUAL_TEST_CHECKLIST.md); choose final defaults from measurements |
| Recommended | Authored rotor/engine/damage and boss phase/demolition sheets with continuity review | Replace transform overlays or six-frame explosion through catalog binding without moving gameplay |
| Recommended | Painted weapon-specific smoke/impact/EMP/laser pack and improved small HUD icon legibility | Preserve effect duration, threat meaning, density limits and native touch targets |
| Recommended | High-density health/status-label decluttering and field-warning placement on small phones; review darkest night/stealth combinations | Presentation only; retain warnings/core/stealth meaning and HP visibility |
| Optional | Bespoke late-territory architecture, painted strategic map or logo treatment | Existing 13-kit library/vector map is functional and intentionally reused |
| Optional | True normal-mapped asset lighting | Requires matched artist albedo/normals and GLES3 device validation; current assets are baked/prelit, no fake PBR claim |

No new external artwork is required to run this version. Generated source candidates remain visibly integrated; they are not declared approved production art. Legacy G1 shared atlas, three SVG heads and bunker vector are reference-only; unused kit icons are available resources, not missing-texture substitutions.

## Reproduce

```sh
./tests/run_checks.sh
python tools/build_asset_manifest.py
# With an actual native display and Compatibility renderer (not --headless):
./tests/run_graphics_profile.sh /tmp/frontline-profile
FRONTLINE_CAPTURE_SCENE=res://tests/environment_capture.tscn ./tests/run_graphics_profile.sh /tmp/frontline-env --quality=high
FRONTLINE_CAPTURE_SCENE=res://tests/environment_capture.tscn ./tests/run_graphics_profile.sh /tmp/frontline-low --quality=low --missions=6,18
./tests/run_native_capture.sh /tmp/frontline-units
./tests/run_ui_capture.sh /tmp/frontline-ui
./tests/run_effect_capture.sh /tmp/frontline-effects
```

Run native windows sequentially; focus-loss pause can invalidate concurrent window captures. Wrappers isolate local saves/config/cache and reject engine errors. Keep galleries under `.gdignore`, outside runtime import. To play, import `project.godot` in Godot 4.6.3 and press F5; no test fixtures are used by the normal game.

## M7 component integration follow-up

Local destructible mounts now share the actual body/articulated armor transform. Essential pose is simulation-owned; component-bearing units skip independent hover/cosmetic shake to keep precision collision identical across presets. Capped local VFX, stopped propulsion, char masks, core windows and aim-nearest labels reuse the existing assets. See [M7 validation](docs/m7/VALIDATION.md) for native moving-target captures, all-unit/VFX/UI regressions and the 80-drone Low/Medium/High software-renderer profile. No Android performance claim follows from those measurements. Approved broken-module/crash artwork, small-screen precision readability and late-campaign human balance remain outstanding.

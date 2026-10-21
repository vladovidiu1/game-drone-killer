# M7 validation — October 21, 2026

Baseline `4171232e3597985940f19a0e520fa677a655349f` (M6). Godot **4.6.3 stable**, Compatibility renderer. Every run isolates save/config/cache directories. See [damage rules and tuning](../DRONE_COMPONENTS.md), [machine-readable evidence](validation.json) and [acceptance log](acceptance.log).

## Import and regression

`FRONTLINE_REPORT_DIR=/tmp/m7-final ./tests/run_checks.sh` exits **0**: **75,115 assertions in 34 suite invocations, zero failures**, plus editor import and project startup. No script/engine errors or leaked-object warnings. The final standalone editor import also exits zero ([log](final_import.log)). All existing combat, pause/touch/reload/ammunition, tracking/arcs/redeployment, campaign/research/economy/ad/save recovery and visual suites pass, including 75 mission/preset resource combinations and fresh-process persistence.

The new component suite contributes **5,406 assertions** ([results](component_scenarios.json), [focused log](component_focused.log)):

- All 14 enemy archetypes across all 25 missions match the staged loadouts. Component counts remain bounded; body HP aliases hull HP. Transformed analytic collision checks include actor rotation, nonuniform scale, battlefield scale/translation, misses, real movement and boss articulated parents.
- Real swept manual rounds damage an engine once, with exactly its explicit 20% hull spill; repeated callbacks do nothing. A side ray missing mounted modules hits only hull. Automatic direct fire retains the body route. Negative/NaN packets cannot heal or poison parts.
- Explosions apply one hull packet plus one reduced packet per eligible part; no doubled direct hit or direct core bonus. Rail crosses exactly three distinct actors with existing falloff, never several components on one actor or an unconfigured fourth target. A separate real core-then-body rail sequence confirms that precision-critical feedback resets per impact without changing damage.
- One engine changes actual path speed to 70%; the second starts a finite crash. Navigation/targeting stop, no early bounty is paid, and one ordinary reward arrives after the crash. The last falling enemy completes an actual battle result without a wave deadlock.
- Shield generator loss removes its real nearby aura; weapon loss interrupts a charging EMP and future matching attacks; sensor loss removes Stealth cloak. Core sealing, timed exposure, exact 2.5×/phase-2 2.75× direct packets, phase transitions and shared pause/build clocks work.
- **84 ammunition/archetype pairs** exercise all six existing payloads, status resistance and consumed-impact ownership. Existing AP/shield/critical and research migration suites remain active. Components never write persistent balances, upgrades, loadouts or frontline state.

No source currency prices/rewards, mission paths/slots/waves, original enemy HP/speed or turret/cannon statistics were rewritten. New component HP/armor/spill/exposure is centralized in its own data file. Save schema/manager and campaign transaction code are unchanged.

## Actual connected campaign and difficulty limits

[Campaign rows](campaign_balance.json) record **all 25 territories conquered in 39 deployments** under the existing assisted center/core pilot. It had one defeat at mission 12 and **six at mission 16**, followed by actual retreat/reconquest using the saved frontline. No synthetic victory, injected BC/WC, rewarded advertisement, advance farming or removed defeat assertion. Before first completion it earns **9,027 WC**, spends **8,385 WC**, and retains **642 WC**. Replay income follows the existing reduced economy. All five bosses use real abilities and receive manual core hits.

The first completed campaign records **5,194 manual component hits and 1,055 component destructions** in actual moving wave combat. A deliberate undefended mission-25 defeat and real 24/25 recovery bring the run to **42 deployments**, total income **9,198 WC** and ending bank **163 WC**. Fresh-process restoration, permanent checkpoint floors, result-token ownership and retained research pass.

The same assisted policy took 27 deployments before first completion in M6. The new routing makes indiscriminate center shots less efficient against weapon modules and armored late enemies; this pilot does not deliberately dismantle every generator/engine. **Repeated mission-16 losses are a remaining difficulty warning**, not evidence of final human balance. Test precision-aware play, progression budgets and a broader seed sample before release; do not hide this result by discarding losses or inflating credits.

[Fixed-policy comparison](fixed_policy_balance.json), [summary](fixed_policy_summary.json): **55 simulations, zero unfinished**. Explicit staged chapter-tier research, ordinary battle funds and fixed seeds are disclosed. Two mixed turrets win **1/25**; two MG and two cannon win **1/6** each. Automatic-only wins **1/6**, manual-only **2/6**; hybrid wins **6/6** milestone missions. Peak observed live enemies: **23**. [Earned-endgame comparison](campaign_comparison.json) loses with automatic-only and manual-only mission 25. Assisted input is test infrastructure, never a runtime auto-aim option or proof of human win rates.

## Native gameplay and visual inspection

All captures use **X11/OpenGL Compatibility, llvmpipe**, not the headless dummy renderer. The wrappers reject script/engine errors. These fixtures stage access/positions to isolate behaviors and do not claim to be ordinary earned-budget campaign screenshots.

- Component scene: **80 assertions, 19 viewport captures, zero failures** ([log](native/component_capture.log), [metrics](native/component_metrics.json)). At 1280×720, 1600×720, 1280×600 and 1024×768, real injected mouse clicks/holds/releases aim and fire the existing cannon, consume its real magazine, destroy two Heavy engines, defer crash bounty and collapse a Shield generator while a paid MG fires normally. No BC or research injection. A real boss is staged at 60% hull for phase/exposure presentation; actual projectiles hit its local core. An additional mission-12 Heavy follows its **real final route segment at normal speed**, with a staged 0.24-radian pose: explicit assisted mouse lead produces a real engine hit while the actor moves.
- All-archetype regression: **27 captures, zero failures** for nine ordinary drones, five bosses and seven weapons ([log](native/unit_capture.log)). The old boss-phase fixture now damages the explicit core instead of passing a point into the unambiguous hull API; its phase assertion remains enforced.
- Combat VFX regression: **36 captures, zero failures** ([log](native/effects_capture.log)). Its old immediate-fire fixture now waits a bounded two seconds for the real M1 acquisition/turn delay; firing, damage and status assertions remain enforced.
- Native UI regression: **36 captures, zero failures** ([log](native/ui_capture.log)). Existing navigation, purchases, controls, ammo, abilities, pause and responsive layouts remain functional. No input ownership or hit-test code was changed.

Representative unedited frames inspected:

| Frame | Evidence |
| --- | --- |
| [Engine disabled](native/engine_disabled_1280x720.png) | Local hit/stop/scorch, manual ammo consumption and clear feedback. |
| [Short-screen generator collapse](native/shield_destroyed_1280x600.png) | Real shield removal, automatic shot/destruction and reachable HUD. |
| [Tablet crash](native/crashing_1024x768.png) | Deferred falling state beneath native controls. |
| [Open boss core](native/boss_core_open.png) / [closed](native/boss_core_closed.png) | Actual local precision marker and matching exposure telemetry. |
| [Moving rotated engine](native/moving_rotated_engine.png) | Actual path motion, transformed hit and damaged-engine pose. |
| [Wide targeting](native/target_1600x720.png) | Uniform battlefield framing and UI scaling. |

[Provenance/hashes](native/provenance.json). Seven representative frames are committed; the runner generates all 19. Pixel data is native Godot output, not artwork editing, a composite or an HTML mockup. The staged boss is spawned during preparation, so its brief arrival banner can overlap the preparation radar in that fixture; actual boss waves and narrative/banner timing need further human review.

## Measured desktop stress

`tests/run_graphics_profile.sh /tmp/m7-profile --component-stress`: three presets, **zero failures** ([raw measurements](native/profile.json), [log](native/profile.log)). Fixture: **80 stationary drones**, real AI/weapons, staged broken left engines, 20,000 BC, fixture unlocks, seed 6006, mission 20; 60 warmup + 180 measured frames per preset at simulated dt 1/60. Rendering is native software OpenGL. This is deliberately heavier than the fixed-policy peak of 23.

| Preset | Simulation median / p95 (ms) | Native wall median / p95 (ms) | Draw calls median / p95 | Peak pooled particles |
| --- | ---: | ---: | ---: | ---: |
| Low | 2.384 / 4.980 | 40.974 / 59.991 | 712 / 795 | 37 |
| Medium | 2.638 / 4.694 | 45.801 / 56.255 | 835 / 930 | 53 |
| High | 2.487 / 5.405 | 45.758 / 61.371 | 840 / 934 | 66 |

Renderer texture memory is approximately **65.9 MiB** in this desktop fixture. All presets produce the identical combat signature `[1000,1,34,18454,38,23,18,0]` (health, kills, earnings, remaining BC, shots, manual hits, AI actions, supports). No physics shapes/per-particle nodes are introduced. Existing pool hard cap remains 192, with stricter preset/category limits. These measurements do **not** establish Android FPS, touch latency or thermal stability.

## Outstanding work

No physical Android device, APK/export, GPU mobile shader-driver check, audible cue, multitouch latency, cutout hardware or sustained thermal benchmark was available. The existing injected input suites and native mouse/UI captures are not Android hardware validation. Follow [the device checklist](../../ANDROID_VISUAL_TEST_CHECKLIST.md).

The stopped/scorched modules and falling fade/shrink reuse existing G3 candidate artwork. Separate approved damaged-engine/gun/core sheets, detached mechanical wreck parts and hand-reviewed crash animation remain external art work. Fine core radii and one aim-nearest label per nearby drone need small-screen/dense-wave readability testing. Late-game difficulty, particularly mission 16 with the current body/core pilot, needs human precision playtests and broader deterministic sampling. No production-ready artwork or final difficulty claim is made.

# Android visual and control test checklist

G6 · 2026-10-21 · **physical Android work is pending**. No Android APK was built or installed in this environment. No device FPS, GPU, RAM, thermal, battery, physical multitouch, cutout or speaker measurements are available. Linux llvmpipe measurements in [GRAPHICS_AUDIT.md](GRAPHICS_AUDIT.md) cannot substitute for this checklist.

## Completed available checks

- [x] Godot 4.6.3 import/startup/script/resource validation; 7,332 assertions, 23 suite invocations, zero failures.
- [x] All 25 mission definitions/scenes/resources instantiate at Low, Medium and High (75 combinations); paths, slots and gameplay definitions unchanged.
- [x] Fresh-process graphics persistence, accessibility overrides and synthetic native touch selection of all three presets.
- [x] Synthetic independent touch IDs for simultaneous aiming/FIRE, UI exclusion and held-input cleanup; desktop mouse/R/Escape paths.
- [x] Native Linux captures of all 25 environments, nine drone types, five bosses, seven weapons, menus/map/Arsenal/briefing/results and combat VFX.
- [x] Native layouts 1280×720, 1600×720, 1280×600 and 1024×768; build/upgrade, scrolling, purchases, active ability labels, pause and reload.
- [x] Low night samples without extra shadows/light pools, reduced effects/motion, bounded VFX stress and software-renderer metrics.
- [x] All 28 balance and 2 comparison records identical to pre-G6 outputs.

These checkmarks describe desktop/synthetic checks only. All unchecked items below require execution and evidence on hardware.

## Record each device/build before testing

| Field | Value to record |
| --- | --- |
| Build | Git commit, APK version/build type, export preset, Godot version/templates, signing type |
| Device | Manufacturer/model, SoC, GPU, driver version, RAM, Android/API version |
| Display | Physical resolution/DPI, refresh rate, reported safe area, cutout location, navigation mode |
| Runtime | Compatibility/GLES3 confirmed, selected preset and each accessibility toggle |
| Conditions | Brightness, battery %, charging state, ambient temperature, device temperature, background load |
| Evidence | Screenshot/video/log/profiler files, exact mission/wave and repetition/time range |

Cover at least one lower-spec Android device, one mid-range Adreno device and one mid-range Mali device, plus a wide cutout phone. Include a 4:3 tablet if supported. Record actual models; a desktop window size does not count as a tested device. Test both debug diagnostics and representative release exports, separating profiler overhead.

## Packaging and first run

- [ ] Export with Godot 4.6-compatible Android templates/SDK and Compatibility rendering. Install the APK on the target device; record export/install logs and package size.
- [ ] Check all dynamic catalogs/data included: `data/*.json`, `assets/*.json`, `assets/environment/*.json`, `assets/effects/*.json`, `assets/ui/*.json`, asset/font license notices. No doc gallery should be imported into the APK.
- [ ] First offline launch: all fonts/PNG/SVG/shaders load without missing resources, magenta textures or script errors. Confirm landscape orientation and audio bus initialization.
- [ ] New/Continue/overwrite confirmation, all four Arsenal tabs, settings and campaign briefings work; Continue disabled without a save.
- [ ] Change presets, quit/relaunch, verify selected preset survives; begin a new mission to apply world changes. Existing progression/research must remain intact.
- [ ] Test recovery of missing/invalid local save in a disposable QA installation; preserve normal player data separately.

## Touch and reachability

- [ ] Left finger begins in aiming zone; drag continuously while a second finger holds FIRE. Confirm aim changes, ammo consumption, actual drone damage and release-to-stop.
- [ ] Reverse finger order; lift/reapply either finger, cross the zone boundary, drag outside the viewport and cancel a touch. No stale firing or orientation ownership.
- [ ] Touch starts on HUD/scroll panels/buttons: never assigns cannon aiming or fires a world round. Mouse emulation remains disabled.
- [ ] Build each unlocked secondary turret; scroll to later choices without buying during the swipe. Upgrade and close panel. Another finger must still aim/fire where allowed.
- [ ] Standard/AP/Explosive selection remains usable and never refills a magazine. Manual reload and empty-magazine reload show correct progress; no fire during reload.
- [ ] Activate Repair/EMP/Overclock, check costs/cooldowns/disabled labels and no accidental purchase from another finger.
- [ ] Enter/leave tactical build from standardized normal combat. Effective build speed is 0.25x; closing always restores normal speed. Confirm the old 1x/2x selector is absent. Aim, shots, cooldowns and reload share simulated time.
- [ ] Pause via HUD and Android Back; resume, interrupt a held shot with pause, then verify no firing resumes without a fresh press.
- [ ] Drag map in all directions; focus current objective, inspect operations, release after drag without opening an unintended briefing. Checkpoint/locked states and labels remain clear.
- [ ] Navigate every menu/confirmation/result action with fingers. Confirm button reachability with both hands and no tiny touch-only targets.

## Safe areas and visual readability

- [ ] Check both landscape rotations with cutout, gesture navigation and three-button navigation. HUD/fire/reload/abilities/build/Back must stay inside the usable area.
- [ ] Review 16:9, tall/wide phone and tablet layouts on real panels. No clipped primary actions or overlapping controls; scrolling reaches the last item.
- [ ] Review 13–17px secondary labels and icons at normal viewing distance. Include affordability/locked states, ammo, cooldowns and active Overclock labels.
- [ ] Inspect all 25 missions in each preset. At minimum play entire missions 1, 3, 4, 6, 10, 18, 20 and 25, plus a full campaign QA pass before release.
- [ ] Check dark night/stealth and bright sunset contrast: enemy body, hostile lights, health/status bars, projectiles, crosshair and all slots stay readable on Low as well as High.
- [ ] Check dust/grid-surge warnings, boss telemetry and dense health/status labels for overlap. HUD remains above artwork; saved outro stays above HUD and is skippable via Continue/Back.
- [ ] Inspect every drone, all boss phases/destruction, six automatic turrets at each tier, primary heat/reload and all ammunition effects at real device scale. No texture bleed, jagged alpha edges, shimmer, unexpected blur or frame discontinuity.
- [ ] Large missile/EMP explosions, boss arrival, critical base damage and victory remain readable; reduced motion removes unwanted movement and reduced effects visibly reduces clutter.
- [ ] Check at dim and outdoor brightness, with device color/night modes recorded separately. Review color-vision readability through labels/silhouettes as well as cyan/red/orange.

## Profiling procedure — record results, do not infer FPS

1. Use the same device/build, seed/scenario, resolution and gameplay inputs for preset comparisons. Choose normal missions and the reproducible `tests/graphics_profile_capture.tscn` stress scene in a separate QA build. Its staged 80 stationary drones are a stress test, not normal campaign balance.
2. Warm resources/shaders and run at least three repeats per preset. Measure a full early mission and a dense late/boss wave, with and without profiler attachment. Preserve original logs; report median/p95/p99 frame time, sample count and duration.
3. Attach Godot's profiler/monitors where supported; inspect script/physics/render work, draw calls, primitives, node/object counts and texture counter. Use Android system frame/memory/thermal tools for device wall-frame behavior, process memory and throttling. Separate GPU timing if available; otherwise state it was unavailable.
4. Run a 20–30 minute continuous session and repeat the same late-wave sample warm. Record dropped/stalled frames, memory growth, thermal status and battery use. One cold burst or average FPS does not establish sustained performance.
5. Compare Low/Medium/High, then reduced effects/motion independently. Aim for stable 16.67ms frames at a 60Hz target; report actual percentiles/stalls and constraints. If the target is missed, use evidence to prioritize CPU versus GPU/overdraw/texture work. Do not lower simulation or input cadence to hide rendering stalls.

| Device/build/mission | Preset | Repeats / duration | Frame ms median / p95 / p99 | Stalls / draw calls | Process RAM / texture counter | Thermal / battery | Result |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Pending physical device | Low | — | Unmeasured | — | — | — | Pending |
| Pending physical device | Medium | — | Unmeasured | — | — | — | Pending |
| Pending physical device | High | — | Unmeasured | — | — | — | Pending |

- [ ] Normal-budget and dense-wave traces recorded on all target devices.
- [ ] No unbounded particle, debris, node or texture growth after repeated deploy/retry/map/Arsenal browsing.
- [ ] CPU versus GPU/overdraw bottleneck identified before further optimization; texture-memory values are not confused with total RAM/VRAM.
- [ ] Lowest supported preset and default chosen from sustained device evidence, with limitations documented.

## Lifecycle, audio and campaign completion

- [ ] Home/app switch/lock/notification during aim+FIRE/build/reload: battle pauses, inputs clear, returning never fires accidentally.
- [ ] Android Back behavior through menus, battle, dialogs and saved boss outro; no duplicate result/reward after background/resume.
- [ ] Process termination/relaunch retains frontline, checkpoints, research, War Credits, completed records and settings. Temporary battle state resets as designed.
- [ ] Audible shots/hits/reload/abilities/results, volume/mute settings and focus recovery on speaker/headphones; no clipping, runaway voices or unacceptable input-to-sound lag.
- [ ] Real victory, real defeat/retreat, checkpoint floor, retry, final boss/campaign completion and replay. Art/VFX never alter reward or collision behavior.

Release review must retain device evidence, close blocking readability/input/render errors, and obtain final art approval. Passing this desktop audit alone does not complete Android QA.


## M2 additions — still pending physical hardware

- [ ] Open all five Arsenal tabs at device safe areas; scroll each technology/branch to its unlock, next-tier and equip actions. Confirm long prerequisites never expand content outside the viewport.
- [ ] Equip 1–3 researched types, remove/reorder slots, reject a fourth, restart app and deploy the saved loadout. Check legacy AP/HE save migration on a disposable QA copy.
- [ ] Aim with one finger and hold FIRE with another for Standard/AP/HE/EMP/Cryo/Rail; tap another equipped chip without stealing aim or firing a world shot. Release/cancel/background never leaves FIRE stuck.
- [ ] Verify shared units (1/1/3/2/2/6), partial-magazine reload, empty-magazine reload and long Rail cooldown. Switching must not refill units, erase heat/recoil or skip cooldown/reload.
- [ ] Check electric/frost/rail cues, large direct EMP hits, per-target rail penetration/falloff and boss resistance. Review all 12 specializations with real waves and primary support.
- [ ] Profile worst-case splash/penetration/control combinations and long-session memory/thermals. Current Linux captures are functional evidence only, not an Android FPS or human-balance result.


## M7 local precision and crashes — physical device pending

- [ ] Aim at actual moving/rotating engine/core silhouettes with the left finger while holding FIRE with the right; compare Low/Medium/High and Reduced motion.
- [ ] Read one aim-nearest component HP label without covering incoming threats; distinguish sealed/open cores on a small screen.
- [ ] Destroy one engine, then all critical engines; verify smoke, crash completion, one bounty and the next wave.
- [ ] Destroy a Shield generator and a charging EMP/sniper weapon; confirm real support/attack loss.
- [ ] Compare AP, HE, EMP, Cryo and Rail against armored parts, shielded cores and moving formations; verify reload/ammo selection/build remain responsive.
- [ ] Pause or background during a crash/window; resume and restart without rewards or stale component state.
- [ ] Profile sustained component-heavy late waves for CPU/GPU frame time, memory, heat and touch latency. Desktop llvmpipe measurements in `docs/m7/VALIDATION.md` are not Android evidence.

## M8/P1 release acceptance — hardware still pending

Desktop evidence: combined import/regression 75,284 checks in 38 suite invocations; native tutorial/rating scene 118 checks and 41 captures at four logical layouts. Injected aim/FIRE/build touch IDs, mouse/R, persistence, skip, practice isolation and normal five-wave Mission 1 pass. See [P1](docs/p1/VALIDATION.md) and [M8](docs/m8/VALIDATION.md). These do not complete any physical-device item below.

- [ ] Fresh installation: first Mission-1 briefing enters guidance; verify story readability, visible Skip and approximately two-minute human pacing with novices. Record actual time/success.
- [ ] Two real fingers aim/FIRE while a third selects/builds/upgrades; no overlay/panel button assigns aim or fires a shot. Check both finger orders, drag cancellation and cutouts.
- [ ] Reload button/R fallback, magazine depletion, tactical quarter-speed, pause/background/resume and return from system UI preserve guide state and clear held inputs.
- [ ] Complete/skip, relaunch and replace campaign: status persists; Replay Tutorial remains available in Settings and cannot grant currency, stars or territory. Abort/restart an unfinished drill safely.
- [ ] Confirm the disclosed practice-to-live reset is understandable: normal supply, empty slots, full magazine and Launch wave are discoverable without assistance.
- [ ] Three-star reveal, objective/HP thresholds and detailed results remain readable/scrollable on smallest supported screen; Continue/Replay never overlap or block combat controls.
- [ ] Optional replay defeat protects frontline/checkpoints, improvements persist, worse runs preserve bests, and reward callbacks/relaunch never repeat milestone payouts.
- [ ] Test human three-star reachability across all 25 missions, especially late-game precision-engine/final-wave conditions, with varied research and ammunition. Record failures rather than assuming accounting witnesses establish gameplay balance.

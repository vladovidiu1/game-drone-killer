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

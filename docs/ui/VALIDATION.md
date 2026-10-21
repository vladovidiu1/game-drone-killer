# G5 validation — 2026-10-21 (Europe/Bucharest)

The completed `./tests/run_checks.sh` run passed **6,550 assertions across 21 suites, zero failures**, exit status 0, with no script/engine errors or ObjectDB leak warnings. Godot 4.6.3 stable imported and started the native project with isolated XDG data/config/cache. The run followed the completed responsive menu/HUD, active-ability label, map input and deferred-screen-lifetime fixes.

| Suite | Assertions |
| --- | ---: |
| COMBAT | 40 |
| HYBRID | 55 |
| SMOKE | 42 |
| SMOKE | 4 |
| SAVE/RULES | 38 |
| CAMPAIGN | 43 |
| CAMPAIGN | 5 |
| RESEARCH | 186 |
| RESEARCH | 4 |
| TACTICAL UI | 193 |
| COMBAT VFX | 310 |
| COMBAT VFX | 2 |
| VISUAL FOUNDATION | 452 |
| UNIT VISUALS | 195 |
| ENVIRONMENTS | 976 |
| ENVIRONMENTS | 2 |
| CATALOG | 3689 |
| ENEMY AI | 88 |
| FULL CAMPAIGN | 184 |
| FULL CAMPAIGN | 31 |
| FULL CAMPAIGN | 11 |

The new **193 tactical UI assertions** cover all 25 actual mission-marker/briefing/back actions, deployment gating, bounded world positions, real touch drag versus tap, panning without save mutation, saved conquest/retreat receipts, secured checkpoint preservation, permanent research retention, once-per-session animation consumption, all four Arsenal tabs, reviewed purchases with duplicate callbacks rejected, four responsive layouts, in-viewport ≥44px combat targets, unobstructed central aiming and reduced-motion map centering.

All **30 combat trace records exactly match** the committed campaign baseline: the 25 victories, defeat/reconquest sequence and automatic-only/manual-only comparisons retain identical rewards, timing, HP, actions and outcomes. No files in `scripts/game/`, `scripts/core/` or `data/` changed in G5. Existing suites retain real simultaneous manual/automatic combat, independent aim/FIRE touch logic, pause/restart, 2×/tactical timing, abilities, atomic research/save recovery, checkpoint rules and duplicate-result protection.

The asset/resource suite verifies **71 manifest entries**, their file hashes, dimensions, licenses/provenance and integration status, alongside the existing unit/environment/shader checks. The new fictional strategic map/layout and symbols are original authored vector/data assets with a reproducible generator. Screen-owned preview textures preserve the existing terrain residency convention.

## Native renderer and UI checks

`DISPLAY=:91 LIBGL_ALWAYS_SOFTWARE=1 ./tests/run_ui_capture.sh /tmp/g5-native-captures` completed with exit status 0, **36 real native viewport captures, zero fixture failures**, and no script/engine errors or leak warnings. The wrapper rejects engine errors even if the executable returns zero. The only graphics-driver warning concerns unsupported VSync switching under the software renderer.

Captures cover no-save/continue menu states; live map mouse selection; briefing; actual saved conquest and checkpoint-bound retreat transactions with staged outcomes; all four illustrated Arsenal tabs; a real reviewed purchase; settings; real Outpost shop purchases, held manual/automatic attacks and destruction; construction/upgrade; reload; a paid active Overclock and bounded sidebar; actual mouse pause clearing fire; defeat/retry and saved victory/results; reduced motion; and menu/map/Arsenal/battle views at **1280×720, 1600×720, 1280×600 and 1024×768**.

The PNGs are unmodified native game frames. The fixture grants higher campaign access and a research bank to inspect later content; synthetic outcomes explicitly exercise real result transactions rather than claiming earned campaign victories. The Outpost phase uses actual starting Battle Credits, real shop prices, researched stats, waves and combat. Full campaign completion/balance is independently tested through simulation. See the [gallery](README.md), [raw samples](render_metrics.json) and [machine-readable report](validation.json).

Native frames were inspected for map ownership/frontline readability, visible chapter and objective information, purchase actions/level indicators, compact menu footer, reachable controls at short heights, active-ability label sizing and an unobstructed battlefield center. The suite also checks that central coordinates pass through the GUI hit test and that FIRE does not overlap abilities.

## Performance and release limits

Renderer: **X11 / OpenGL 4.5 Compatibility / Mesa 25.0.7 llvmpipe**. Per-capture UI draw-call samples range **26–302**. These are integration diagnostics, not average frame time or a mid-range Android benchmark. No 60 FPS claim is made.

The map uses one 1600×900 SVG import (about 5.5 MiB RGBA, no mip chain), a bounded 25-territory/node overlay and clipped panning. Mission preview atlases are screen-owned; static composed weapon portraits have no ticking controller. Menu particles stay at 18, and feedback replaces the prior tween per Control. No new screen-copy/lighting pass, online map dependency or gameplay emitter growth was introduced. Actual GPU VRAM/overdraw, Android frame-time percentiles, thermal/battery behavior and CPU budgets still require device measurement.

Physical Android multitouch, cutouts, audible sound (Dummy audio driver), APK/export/signing and final asset approval remain separate release work. All resources needed to open and run G5 are included; optional bespoke illustrated map/logo refinements can replace the authored cartography without changing campaign or battle logic. Android export filters must retain `assets/ui/*.json` alongside existing data/environment/effects JSON and licenses.

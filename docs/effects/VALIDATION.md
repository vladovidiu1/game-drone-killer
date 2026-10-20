# G4 validation — 2026-10-20 UTC

The final `./tests/run_checks.sh` completed with **6298 assertions, zero failures**, exit status 0 and no script/engine errors or ObjectDB leak warnings. Godot 4.6.3 stable imported and started the project using isolated XDG saves. The final run followed the completed foreground layering, environmental-ring readability safeguard, quality/settings and accessibility changes.

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
| COMBAT VFX | 310 |
| COMBAT VFX | 2 |
| VISUAL FOUNDATION | 393 |
| UNIT VISUALS | 195 |
| ENVIRONMENTS | 976 |
| ENVIRONMENTS | 2 |
| CATALOG | 3689 |
| ENEMY AI | 88 |
| FULL CAMPAIGN | 184 |
| FULL CAMPAIGN | 31 |
| FULL CAMPAIGN | 11 |

The 312 new VFX checks include dense burst/category/emission/cleanup limits at every preset, fixed-slot reuse, presentation-only invariants (HP, position, rewards, counters and critical RNG), laser hit coalescing, explosion density, actual manual round collisions, reload, pause, 2× and tactical time, accessibility layer switches, artwork-only shake, restart and fresh-process saved preferences. Legacy and malformed settings receive validated defaults. Existing suites retain full enemy AI, touch logic, campaign retreat/checkpoints, migrations/recovery, research/economy, win/defeat and duplicate-result coverage.

All **30 campaign trace records exactly match** the committed baseline: the 25 victories, defeat/reconquest and automatic-only/manual-only comparisons have identical outcomes, timing, rewards, health and action counts. `data/definitions.json`, `data/progression.json`, `enemy_brain.gd` and `player_turret.gd` remain byte-for-byte unchanged; hashes are in [validation.json](validation.json).

Four native capture processes also completed with exit status 0 and no script/engine errors:

- **36 labeled VFX fixture frames:** every secondary weapon fires through the real combat controller; primary Standard/AP/Explosive rounds hit actual drones; critical research is actually purchased and a deterministic seed exercises an unchanged critical roll; real magazine reload; Scout/Heavy/boss death signals; actual breach HP warning; boss arrival; bounded 80-death stress at High/Low; reduced effects/motion; settings; saved boss victory/outro/skip/results with duplicate reward rejected.
- **27 G3 unit-regression frames:** all nine standard enemies/five bosses, all seven weapons, phase/damage/upgrade/destruction presentation, real primary fire/ammunition/reload, pause and terminal result handling still render. These are staged art fixtures, separately labeled.
- **Five normal-wave frames:** menu, Outpost Alpha manual/automatic attacks/destruction with the actual starting budget, tactical building and 1600×720 framing. Real mouse/pause input remains correct after centering on the wider display.

- **One mission-25 grid-interference frame:** advancing the existing environment clock triggers the real suppression rule; the actual cannon disables, drone HP remains unchanged, and the large surge appears as a restrained clipped ring with units/slots/HUD visible. This final readability safeguard prevents environmental cues becoming foreground fireballs.

The gallery commits 28 representative unmodified PNGs (22 VFX + one grid + all five normal-wave captures). The remaining fixture frames are reproducible from the capture scripts. [Raw VFX metrics](render_metrics.json), [unit-regression metrics](unit_regression_metrics.json) and [machine-readable validation](validation.json) record the runs. Native images were inspected for foreground hit visibility, clear enemy/slot/HUD readability, reload/critical feedback, boss-arrival placement and unobstructed settings.

## Performance evidence and limits

Renderer: **X11, OpenGL 4.5 Compatibility, Mesa 25.0.7 llvmpipe**. VFX-fixture draw-call samples range **20–186**; G3 regression samples range **20–199**. These are per-capture integration diagnostics, not average frame time or an Android benchmark. The only native graphics warning was unsupported VSync switching in the software driver.

| 80-death stress fixture | High | Low |
| --- | ---: | ---: |
| Peak pooled particles | 192 | 48 |
| Active particles at capture | 188 | 47 |
| Smoke at capture | 12 | 3 |
| Flying debris at capture | 24 | 6 |
| Soft light sprites at capture | 4 | 2 |
| Dropped excess cosmetic emissions | 768 | 592 |
| Draw calls at capture | 186 | 141 |

Stress emissions were applied across eight simulated frames, then a four-second presentation tick verified that pooled particles, atlas cues and detached wrecks were all gone. Work does not grow with repeated bursts. CPU-batched particles use at most 192 reusable slots with small per-category/work budgets, no per-particle Node/physics/Light2D, no screen-texture pass and no added large raster atlas. Existing large-texture residency remains an approximately 50 MiB estimate before fonts/vectors/framebuffer/driver overhead; actual VRAM was not measured.

**Unavailable:** physical Android hardware/performance comparison of CPU/GPU emitters, stable 60 FPS acceptance, frame-time percentiles, memory/thermal/battery profiling, hardware multitouch/cutouts, audible sound (Dummy audio driver), APK/export/signing verification. Android profiling must tune presets before a release; the code does not claim these diagnostics establish device performance.

All assets required to run are included. Dedicated artist-refined smoke/energy/impact sheets, boss demolition variants and final generated-art review remain optional external art work, with exact replacement specifications in [COMBAT_VFX.md](../COMBAT_VFX.md). Current procedural/vector utility effects and generated raster explosion candidates are described as such.

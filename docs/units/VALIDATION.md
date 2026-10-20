# G3 validation — 2026-10-20

`./tests/run_checks.sh` completed with **5983 assertions, zero failures**, exit status 0 and no script/engine errors or ObjectDB leak warnings. Godot 4.6.3 stable imported and started the project with isolated XDG saves.

| Suite | Assertions |
| --- | --- |
| COMBAT | 40 |
| HYBRID | 55 |
| SMOKE | 42 |
| SMOKE | 4 |
| SAVE/RULES | 38 |
| CAMPAIGN | 43 |
| CAMPAIGN | 5 |
| RESEARCH | 186 |
| RESEARCH | 4 |
| VISUAL FOUNDATION | 390 |
| UNIT VISUALS | 195 |
| ENVIRONMENTS | 976 |
| ENVIRONMENTS | 2 |
| CATALOG | 3689 |
| ENEMY AI | 88 |
| FULL CAMPAIGN | 184 |
| FULL CAMPAIGN | 31 |
| FULL CAMPAIGN | 11 |

All **30 combat trace records** exactly match the previously committed baseline: 25 campaign victories, defeat/reconquest and automatic-only/manual-only comparisons. Gameplay/research definitions, enemy AI and the manual cannon controller are byte-for-byte unchanged. The touched combat scripts only bind presentation snapshots/layers and projectile artwork; their stat, movement, targeting, collision, damage and reward math is retained.

The new unit suite contributes 195 checks across every unique body/head binding, imported raster art, propulsion axes, four-to-six-node composition, bounded artwork hover, invariant health/physical position/weakpoints, boss armor, cloak, real manual firing/reloading/ammo snapshots, upgrade feedback, pause and bounded immediate-reward/non-physical destruction. Existing suites retain mouse/multitouch logic, 2×/build time, all enemy abilities, checkpoints, research/economy and corrupt-save/migration coverage. Native checks also verify boss results are persisted before destruction presentation and cannot be paid twice; an actual Escape event skips the outro to results.

Two native processes completed successfully: **27 labeled visual-fixture captures** cover all 14 enemies, all seven weapons, every boss's third phase and destruction, standard-drone damage/deaths, real shop upgrades, ammunition, heat, reload, pause and terminal outro/results; **five normal-wave captures** cover the retained menu, genuine first-mission combat/destruction/build mode and a 1600×720 uniform camera with mouse/pause input checks. The fixture wrapper rejects engine errors even after exit 0. The normal capture log also contains no script/engine errors. Its only graphics-driver warning concerns unsupported VSync switching.

Renderer: X11, OpenGL 4.5 Compatibility, Mesa llvmpipe 25.0.7. Per-frame draw-call samples across the unit fixtures range from **19 to 192**; raw values are in `render_metrics.json`. These are software-renderer integration diagnostics, not a mid-range Android benchmark. Five 768×512 RGBA+mip G3 imports are estimated at 10 MiB before driver overhead; typical total large-texture residency is estimated near 50 MiB with existing environments/menu/bunker/effects. This is not measured GPU VRAM. No physical Android device, hardware multitouch, audible playback, APK/signing, 60 FPS, memory/thermal or battery acceptance was available.

The bundled art covers every required G3 body and weapon; no external asset download is needed to play. Optional artist refinements remain: camera/padding/pivot consistency, polished authored rotor/damage/phase/demolition frames and matched normals for a separately reviewed lighting pass. Current transform/damage/destruction animation is functional and is not misrepresented as finished raster animation sheets. Generated candidates still need final art approval.

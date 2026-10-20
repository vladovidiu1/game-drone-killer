# G2 validation — 2026-10-20

Godot 4.6.3 stable imported the project and completed `./tests/run_checks.sh` with **5719 assertions, zero failures**, exit status 0 and no script/engine errors or ObjectDB leak warnings. Saves were isolated in temporary XDG directories.

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
| VISUAL FOUNDATION | 321 |
| ENVIRONMENTS | 976 |
| ENVIRONMENTS | 2 |
| CATALOG | 3689 |
| ENEMY AI | 88 |
| FULL CAMPAIGN | 184 |
| FULL CAMPAIGN | 31 |
| FULL CAMPAIGN | 11 |

The environment checks load all 25 missions, validate atlas grading, unchanged geometry, safe prop placement including water exclusions, clipping/input behavior, visible enemy artwork/movement, bounded rendering work, pause timing, settings migration/type validation and low-effects mode. Weak-reference checks confirm unused terrain resources release after deferred scene cleanup. Shader-inspection temporaries are scoped outside the suspended lifetime test so the test itself does not retain a resource. This verifies Godot resource ownership, not measured Android VRAM.

The full campaign actually wins all 25 missions through ordinary combat and validates defeat/reconquest, checkpoints, rewards and fresh-process saves. All 28 campaign balance records (including defeat/reconquest) and both automatic-only/manual-only comparisons exactly match the previously committed gameplay baselines. `data/definitions.json` and `data/progression.json` are byte-for-byte unchanged from G1. The saved-effects verification restores standard effects before full-campaign simulation.

The separate native capture process also exited 0: all 25 missions rendered, 536 real manual shots were fired and 29 unmodified viewport PNGs were written. All first-wave captures use a real purchased automatic Machine Gun, existing drone waves and actual projectiles. Inspection covered the first five identities, night combat, rain/smoke readability, tactical upgrades, reduced effects and 1600×720 framing. Renderer: X11, OpenGL 4.5 Compatibility, Mesa llvmpipe. Its only driver warning concerned unsupported VSync switching. These are real native renders, not headless graphics claims or generated screenshots.

See [the gallery](README.md), [machine-readable results](validation.json) and [reproduction instructions](../ENVIRONMENTS.md). No physical Android device, signed APK, physical multitouch, audible playback, FPS, GPU memory, battery or thermal validation was available. Generated artwork remains subject to final art-direction approval; bespoke Hive architecture and further prop perspective/scale refinements remain future art work.

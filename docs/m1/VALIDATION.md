# M1 final validation

2026-10-21 · Godot 4.6.3 stable · native headless import/script checks plus separate Linux X11/llvmpipe Compatibility capture runs. No physical Android device or audible playback test.

`FRONTLINE_REPORT_DIR=/tmp/m1-release-reports ./tests/run_checks.sh` finished successfully: **7,611 assertions / 24 suite invocations / zero failures**. Wrappers reject script/engine errors and ObjectDB leak warnings, even with a zero engine exit. [Machine-readable summary](validation.json).

| Suite invocation | Assertions |
| --- | --- |
| M1 MECHANICS | 46 |
| COMBAT | 40 |
| HYBRID | 55 |
| SMOKE | 42 |
| SMOKE | 4 |
| SAVE/RULES | 38 |
| CAMPAIGN | 43 |
| CAMPAIGN | 5 |
| RESEARCH | 186 |
| RESEARCH | 4 |
| GRAPHICS AUDIT | 810 |
| GRAPHICS AUDIT | 2 |
| TACTICAL UI | 189 |
| COMBAT VFX | 310 |
| COMBAT VFX | 2 |
| VISUAL FOUNDATION | 452 |
| UNIT VISUALS | 195 |
| ENVIRONMENTS | 946 |
| ENVIRONMENTS | 2 |
| CATALOG | 3926 |
| ENEMY AI | 88 |
| FULL CAMPAIGN | 184 |
| FULL CAMPAIGN | 31 |
| FULL CAMPAIGN | 11 |

The new mechanics suite covers bounded rotation, acquisition/alignment, safe handling of a freed target, stealth/EMP, all 14 archetype speeds/movement, partition-independent burst integration, warning suppression, AP armor and multi-entry burst completion. Normal/build/pause/reload/input/save semantics are also exercised by the existing suites, updated for the requested removal of selectable speed.

## Connected campaign — ordinary earned progression

All 25 first-clear deployments use matching saved deployment/result tokens, purchased research and actual starting funds/bounties. No victory/HP/credits were injected. Every mission completed through real enemy movement, automatic/manual fire and impacts. Then the commander loses an undefended mission 25, retains permanent upgrades, reconquers 24/25, reloads the final save and verifies all checkpoint floors/records. The two isolated endgame comparison cases use legitimately earned endgame research.

[All 28 connected records](../campaign_balance.json) / [2 endgame comparisons](../campaign_comparison.json) / [pre-M1 connected baseline](baseline_campaign.json).

| First clear | Seconds incl. preparation | HP | Kills | Primary shots / hits | Core hits | Enemy actions |
| --- | --- | --- | --- | --- | --- | --- |
| 01 | 114.9 | 1000 | 61 | 81 / 40 | 0 | 0 |
| 02 | 138.8 | 1000 | 77 | 164 / 107 | 0 | 0 |
| 03 | 173.9 | 1000 | 116 | 215 / 140 | 0 | 0 |
| 04 | 144.3 | 1000 | 90 | 140 / 91 | 0 | 0 |
| 05 | 150.1 | 1000 | 85 | 169 / 114 | 20 | 1 |
| 06 | 169.3 | 1000 | 133 | 222 / 156 | 0 | 1 |
| 07 | 171.9 | 1100 | 141 | 192 / 102 | 0 | 1 |
| 08 | 173.4 | 1100 | 148 | 180 / 107 | 0 | 1 |
| 09 | 174.1 | 1150 | 132 | 196 / 119 | 0 | 4 |
| 10 | 175.2 | 1200 | 122 | 240 / 165 | 21 | 3 |
| 11 | 206.1 | 1100 | 234 | 390 / 273 | 0 | 12 |
| 12 | 210.8 | 1200 | 225 | 240 / 149 | 0 | 10 |
| 13 | 206.5 | 1250 | 235 | 360 / 246 | 0 | 10 |
| 14 | 206.3 | 1225 | 243 | 374 / 230 | 0 | 7 |
| 15 | 204.1 | 1275 | 198 | 346 / 232 | 23 | 8 |
| 16 | 199.4 | 1300 | 283 | 360 / 276 | 0 | 12 |
| 17 | 209.1 | 1375 | 298 | 425 / 284 | 0 | 23 |
| 18 | 196.2 | 1165 | 253 | 387 / 303 | 0 | 18 |
| 19 | 193.0 | 1205 | 277 | 368 / 255 | 0 | 12 |
| 20 | 197.3 | 1225 | 250 | 375 / 289 | 27 | 12 |
| 21 | 192.0 | 1175 | 314 | 396 / 302 | 0 | 17 |
| 22 | 195.9 | 1380 | 307 | 425 / 317 | 0 | 20 |
| 23 | 195.0 | 1325 | 329 | 422 / 300 | 0 | 14 |
| 24 | 193.9 | 1220 | 301 | 407 / 305 | 0 | 14 |
| 25 | 192.7 | 1470 | 267 | 414 / 332 | 30 | 14 |

## Comparison and native rendering

Two final balance runs produce identical 55-record JSON outputs at the same fixed seeds. Baseline and final scenarios use the same test-only pilot, placements, research fixtures and budgets. [Full before/after tables](COMPARISON.md); `python tools/report_m1_balance.py` passes the configurable milestone HP/manual-contribution goals and non-universal two-turret checks. These are scenario outcomes, not human win-rate or device benchmarks.

Native UI runner: **36 captures / 0 failures**, four logical layouts (1280×720, 1600×720, 1280×600, 1024×768), actual mouse controls, map/purchase/pause/reload/build/upgrade/active-ability states. Representative environment runner: **8 missions / 176 manual shots / 0 failures**, Medium, real first-wave drones and normal-budget automatic purchase. No speed selector, no missing resources, clear center and reachable controls in reviewed frames. [UI metrics](ui_metrics.json) / [world metrics](environment_metrics.json). Selected native frames are stored here and excluded from import by `.gdignore`.

Screenshots are unmodified native viewports. Deployment/unlock/phase fixtures in capture runners are separate from the connected campaign. No Android export, physical multitouch, sustained FPS, thermal, battery or audible output measurements were performed. The G6 performance baseline is historical; increased M1 concurrency requires new device profiling. See [remaining playtesting](../M1_BALANCE.md#verification-and-remaining-playtesting).

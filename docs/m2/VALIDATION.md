# M2 validation

2026-10-21 · Godot 4.6.3 stable · native import/headless tests and separate X11/llvmpipe Compatibility captures.

`FRONTLINE_REPORT_DIR=/tmp/m2-verified-reports ./tests/run_checks.sh` completed: **9,067 assertions / 26 suite invocations / zero failures**. The wrappers reject engine/script errors and ObjectDB leaks even on a zero exit. [Machine-readable summary and data hashes](validation.json).

| Suite | Assertions |
| --- | --- |
| M1 MECHANICS | 46 |
| COMBAT | 40 |
| HYBRID | 55 |
| SMOKE | 42 |
| SMOKE | 4 |
| SAVE/RULES | 38 |
| CAMPAIGN | 43 |
| CAMPAIGN | 5 |
| RESEARCH | 187 |
| RESEARCH | 4 |
| WEAPON RESEARCH | 1424 |
| WEAPON RESEARCH | 3 |
| GRAPHICS AUDIT | 810 |
| GRAPHICS AUDIT | 2 |
| TACTICAL UI | 193 |
| COMBAT VFX | 310 |
| COMBAT VFX | 2 |
| VISUAL FOUNDATION | 476 |
| UNIT VISUALS | 195 |
| ENVIRONMENTS | 946 |
| ENVIRONMENTS | 2 |
| CATALOG | 3926 |
| ENEMY AI | 88 |
| FULL CAMPAIGN | 184 |
| FULL CAMPAIGN | 31 |
| FULL CAMPAIGN | 11 |

## New weapon tests

The new weapon suite has **1,424 assertions plus 3 in a fresh process**. It exercises actual EconomyManager purchases and writes, actual deployed profiles, real projectile sweeps/impact/reward APIs and all automatic specializations firing. The catalog is not merely enumerated.

- 6 technologies × 4 levels (base plus 3 tiers) × all 14 drone/boss archetypes = **336 real direct-impact scenarios**, with guaranteed critical shots at levels 1/3 and noncritical at 0/2. Each checks damage, hit ownership, no repeated collider damage and once-only rewards. EMP/Cryo additionally check actual resisted status; bosses retain a nonzero reduced EMP window.
- Hand-calculated Standard/AP critical damage through armor plus Shield Drone aura; personal shield resistance/partial bypass; coexistence and exact movement after EMP expires while Cryo remains. Criticals never multiply control duration.
- Rail collides with the nearest three aligned Heavy targets, applies 84 / 65.52 / 51.1056 baseline damage, leaves a fourth untouched and cannot hit any collider twice. All tier profiles are snapshotted.
- Actual held shots spend 1/1/3/2/2/6 shared units, trigger reload at depletion and cannot fire through reload. Switching preserves magazine, rail cooldown, recoil/heat, blocks unequipped types/reloading and cannot change a deployed profile by mutating saved research. Pause freezes reload.
- All 12 specialization branches buy tiers, equip through the normal service and fire/control actual enemies; only the selected branch changes the deployed definition. Reverting to standard tuning and improving an unequipped branch does not re-equip it.
- v1/v2/v3 migration retains old AP/HE active preference, paid numeric research and legacy bonuses. Invalid IDs/types/duplicates/oversized/empty loadouts and unresearched branches are sanitized or rejected. Writes are intentionally blocked to verify ammo-tier debit/grant, first-branch auto-selection, loadout and branch rollback.
- Fresh process restores ordered EMP/Cryo/Rail loadout, Rail tier 3 and selected MG Armor specialization, and applies these to a new deployed cannon.

## Existing campaign and graphics regression

All 25 mission dictionaries are unchanged. Enemy definitions gain only the new resistance dictionary; existing HP, speed, AI, phase data and rewards are unchanged. Base turret/cannon/balance definitions are unchanged. All 25 missions still load in all three G6 presets.

The real connected campaign completes all 25 missions with earned legacy research/funds, then tests defeat/retreat/reconquest, checkpoint floors, duplicate-result rejection and fresh-process finale/records. [28 current connected records](campaign_balance.json) and [2 endgame comparison records](campaign_comparison.json) match M1 combat outputs exactly after ignoring the additional zero-valued research keys. This establishes retained M1 behavior with optional M2 research unused; it does not establish balance of every new loadout.

## Native input and rendering

`DISPLAY=:91 LIBGL_ALWAYS_SOFTWARE=1 FRONTLINE_CAPTURE_SCENE=res://tests/weapon_capture.tscn ./tests/run_graphics_profile.sh /tmp/m2-native-release` completed **25 captures / zero failures**. The engine was Godot 4.6.3, X11/Compatibility OpenGL, Mesa 25.0.7 llvmpipe, Dummy audio.

The staged fixture funds a real 6,320-WC complete ammo research path through native confirmation touch buttons, plus all three tiers of MG Rapid. It uses actual scroll-to-card touches to equip EMP, Cryo, remove Standard and equip Rail. Five tabs/long research text fit 1280×720, 1280×600, 1024×768 and 1600×720. Specialization copy is checked against the same layouts.

Each technology uses a real deployed three-slot loadout, native HUD chip switches, simultaneously owned aiming/FIRE fingers, a real shot/impact and a native partial-magazine reload. Every chip is disabled during reload. Render frames are unmodified; research funding, highest/frontline access and stationary Heavy targets are explicit QA fixtures, not human campaign outcomes. [Selected gallery](README.md), [all capture counters](render_metrics.json).

Earlier failed capture attempts exposed long-copy minimum-width overflow and used incorrect coordinates for embedded confirmation windows. The final UI wraps/clips variable copy and the harness injects dialog-local touches into the dialog viewport. Those failed frames are discarded. Tests also exposed/fixed small-radius EMP hits excluding a large direct target and EMP displaying an explosive fireball. Corrected native EMP uses electrical cues.

## Limits

No physical Android export/install, digitizer, cutout hardware, audible speaker output, GPU/thermal/battery or sustained FPS measurements were available. The capture runner records native draw-call counters, not a performance guarantee. No 60 FPS or final human difficulty claim is made. Further testing should cover all loadout/branch combinations, long waves with simultaneous splash/status/penetration, alternative research budgets and actual device ergonomics. Existing raster art still needs final art approval; the six new authored SVG illustrations are deliberate utility art, not painted production sprites.

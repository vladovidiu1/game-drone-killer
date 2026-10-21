# M1 — fast hybrid combat and difficulty evidence

2026-10-21 · Godot 4.6.3 · Compatibility · continuing G6 commit `f76bda4`.

M1 removes the 1x/2x selector, speeds up actual drone travel, gives automatic weapons deterministic tracking limits and redesigns every mission's wave pressure. Campaign geometry, 25 territories, checkpoint/retreat/reward transactions, save schema v3, research/unlocks, primary input ownership and all art/quality presets remain integrated. **This is a tested balance pass, not a claim that human difficulty is final.**

## Normal speed and temporary tactical build

There is no speed button, `game_speed` variable or `toggle_speed` API. `Engine.time_scale` remains 1. Native fixed-physics delta advances combat normally. Only an open build/upgrade UI applies 0.25 to that delta. Close, pause/focus loss and restart restore normal mode; another slot reuses the same panel. No prior speed choice exists. Simulation owns movement, targeting, shots, reloads, statuses, abilities, spawns and VFX time. Audio/input/menu behavior is not globally accelerated.

The primary remains entirely input-driven. No runtime auto-aim, auto-fire or guaranteed survival percentage was added. The pilot in `tests/m1_pilot.gd` exists only in tests and is never loaded by normal playable scenes.

## Central tuning

`data/definitions.json` is authoritative: `balance` contains movement, scan/switch policy, turn upgrade scaling, wave-generation coefficients and milestone simulation targets. Each turret owns its firing/turn/lock stats; enemy AI owns mobility/armor. `tools/rebalance_m1.py` can reproduce this pass from [the frozen G6 source](m1/baseline_definitions.json). Future manual tuning should edit the canonical definitions deliberately or update the generator; do not run the generator blindly over later work.

### Movement and breakthrough

- Global **1.5× nominal movement**, multiplied by each existing mission speed coefficient (1.0–1.198), capped at 245 nominal units/s. No global gameplay-speed multiplier.
- Mission 1 nominal speeds: Scout **180**, Assault **112.5**, Heavy **60**, Shield **97.5**, EMP **127.5**, Bomber **142.5**, Sniper **78**, Carrier **67.5**, Stealth **172.5** units/s. Boss approach speed becomes **67.5** before the mission coefficient. Enemy HP is unchanged for every archetype.
- Scout acceleration: after 1.4s, 1.15× for 0.45s every 4.2s. Bomber: after 1.4s, 1.18× for 0.6s every 5s. A short orange propulsion arc warns 0.35s before and remains visible during a burst. These are deterministic movement phases; the burst integral preserves distance when simulation steps are partitioned or slowed/disabled.
- Heavy/Bomber/Carrier hulls reduce ordinary incoming damage by 20%/15%/25%. AP bypasses that hull reduction and existing shield protection; AP's existing armored-target multiplier also remains. This creates an actual ammunition/decoy choice without HP inflation.
- Existing shield auras, EMP suppression, sniper windups, stealth visible windows, carrier/boss support and grid interference remain real combat systems. EMP can stop motion/attacks, reveal stealth and suppress shield protection. Boss core armor, weakpoints and overload deadlines retain their G6 tuning.
- Sequential groups are now escorted bursts with split/pincer/fan routes. Faster threats can cross a barrel's tracking arc or reach an uncovered lane while another unit absorbs fire. Nothing directly chooses drones to leak or applies random automatic misses.

### Automatic weapons

| Weapon | G6 → M1 nominal damage / shots per second | G6 → M1 range | G6 → M1 projectile speed | Tracking °/s | Acquisition s / firing tolerance ° |
| --- | --- | --- | --- | --- | --- |
| Machine Gun | 10 / 4 → 10 / 3.8 | 240 → 230 | 720 → 640 | 300 | 0.10 / 12 |
| Cannon | 55 / 0.8 → 50 / 0.78 | 260 → 250 | 480 → 440 | 180 | 0.18 / 8 |
| Missile | 80 / 0.5 → 75 / 0.48 | 300 → 290 | 340 → 320 | 120 | 0.25 / 18 |
| Laser | 24 DPS → 22 DPS | 270 → 255 | Instant beam | 200 | 0.16 / 6 |
| EMP | 0 / 0.2 → unchanged | 230 → 215 | Area pulse | 120 | 0.30 / omnidirectional |
| Heavy AA | 180 / 0.25 → 170 / 0.25 | 340 → 320 | 580 → 520 | 120 | 0.28 / 7 |

Valid locks are reconsidered every 0.12 simulated seconds; idle or invalid locks search immediately. Lowest remaining path distance wins; spawn ID breaks ties. A valid lock switches only for a threat at least 40 units closer to the base. Invalid/out-of-range/cloaked/dead targets clear immediately, with fresh acquisition for the next lock. A weapon rotates at its actual bounded rate and fires only after lock delay and alignment. Laser also requires tracking/lock; EMP pulses remain omnidirectional. Secondary projectiles keep their established guided/splash collision rules, with slower real travel; there is no random aim error.

Temporary level scaling is **×1.35 damage and +12 range** per level (previously ×1.5/+16), with +8% turn speed per level. Level cap/cost formulas, permanent purchased upgrade levels and legacy +15% coefficients remain. Selected-turret HUD and automatic Arsenal cards show tracking/lock stats. Costs, mission starting budgets, per-enemy bounties, base HP, permanent reward amounts and primary damage/rate/range/magazine/reload/velocity are unchanged.

### All 25 wave schedules

| Chapter | Group-count factor (rounded up) | Inter-burst interval factor | Burst size / intra-burst gap | Preparation seconds |
| --- | --- | --- | --- | --- |
| 1 / missions 1–5 | 1.12 | 0.92 | 2 / 0.16 | 15 |
| 2 / missions 6–10 | 1.13 | 0.90 | 2 / 0.16 | 14 |
| 3 / missions 11–15 | 1.16 | 0.88 | 3 / 0.15 | 13 |
| 4 / missions 16–20 | 1.18 | 0.86 | 3 / 0.14 | 12 |
| 5 / missions 21–25 | 1.20 | 0.84 | 3 / 0.13 | 11 |

Inter-burst interval is at least 0.44s. Mission 1 wave 1 remains a single-drone cadence to introduce aiming. Groups alternate routes; Scouts/Bombers/Stealth use pincer entries, Assaults fan across routes, support/armor use columns. From mission 6, wave 3 onward adds real bombers when that wave did not already contain them (one in chapters 2–3, two in 4–5). Boss count remains one in the existing final wave. All paths, slots, spawn geometry and chapter checkpoints are unchanged.

Outpost Alpha now has **61 enemies / 890 BC bounty**: 6 Scouts; 9 Scouts; 12 Scouts+3 Assaults; 14 Scouts+6 Assaults; 9 Assaults+2 Heavies. Briefings now display a configurable **2–5 minute** target at normal speed rather than the stale 3–7/1x text. Optional early starts remain; actual human/build time may differ.

## Before/after experiments

[Raw G6 baseline](m1/baseline.json), [raw M1](m1/after.json), [all tables](m1/COMPARISON.md). Both use the same 55 scenarios, fixed seed **1000 + mission ID**, dt=1/60, no early starts and unchanged test pilot. Every scenario finished. A second final run reproduced **all 55 records exactly**. Bad intermediate tuning runs containing script errors were discarded, not reported as difficulty evidence; the freed-target defect is now covered by a regression assertion.

The two-turret policy uses slots 3/4 (zero-based 2/3), spends only real starting funds/bounties and buys normal upgrades; it has no primary fire or abilities. MG+Cannon is sampled in all 25 territories. Dual MG and dual Cannon are also sampled at 1/5/10/15/20/25. Full automatic, manual-only and hybrid are sampled at those six milestones; they may repair using ordinary BC.

Research is a **fixture tier** of 0/1/2/3/4/5 at those milestones, with chapter-appropriate unlocks; it is not proof of earned progression. The separate full connected campaign below uses only earned research and authoritative result transactions. This distinction matters when comparing high-tier research or late boss outcomes.

- Fixed MG+Cannon wins **10/25 → 0/25**. This demonstrates the tested policy is insufficient; it is not an exhaustive search across every pair/type/placement.
- Dual MG can still win mission 1 with **125 HP and 21 breaches**, so early play remains recoverable. It loses all five later milestone tests; dual Cannon loses all six.
- Full automatic wins mission 1 with **900 HP**; it loses missions **5/10/15/20/25** in this fixture. Their G6 automatic-only cases already lost to core armor/overload; M1's main new result is pressure throughout ordinary waves and stronger manual contribution, not a newly invented boss gate.
- Manual-only can win mission 1 with **375 HP**, but loses all later milestones. Hybrid wins all six, combining the existing economy, automatic coverage, reload windows and real manual projectiles.

| Mission | G6 → M1 primary hits (hybrid) | M1 final HP | M1 peak enemies | M1 sim seconds including preparation |
| --- | --- | --- | --- | --- |
| 01 | 0 → 40 | 1000 | 6 | 114.9 |
| 05 | 44 → 144 | 1100 | 7 | 151.7 |
| 10 | 51 → 168 | 1200 | 11 | 179.8 |
| 15 | 39 → 244 | 1275 | 16 | 206.3 |
| 20 | 39 → 297 | 1190 | 16 | 195.6 |
| 25 | 51 → 353 | 1275 | 21 | 191.0 |

Thresholds in `balance.targets` make the intended milestone direction reviewable: hybrid wins with positive HP and minimum manual hits 8/15/25/35/45/55 (mission 1 minimum 250 HP). `python tools/report_m1_balance.py` checks these goals against recorded simulations. Thresholds are **test goals only**, never runtime assistance or survival rules.

## Verification and remaining playtesting

The complete Godot import/script/regression result and connected-campaign table are recorded in [current validation](m1/VALIDATION.md). Tests cover normal timing, pause/build/reset, exact ammo/reload/single-hit behavior, all enemy classes, deterministic burst integration, freed target recovery, alignment/acquisition, AP/armor, wave completion, research/save recovery, all campaign results/checkpoint floors and fresh-process final save. Existing assertions for removed 2x behavior were replaced with standardized-speed and tactical restoration assertions; combat fixtures use M1 values rather than preserving obsolete stats.

Native Linux Compatibility captures cover **36 UI states across four layouts** and **8 representative real early-wave mission deployments** (1/2/3/5/10/15/20/25, 176 real manual shots). HUD center/input remain clear; no speed selector remains. [Live HUD](m1/battle_hud_live.png), [tracking/lock upgrade panel](m1/battle_hud_upgrade.png), [1280×600 tactical controls](m1/battle_build_1280x600.png), [late multi-route wave](m1/mission_25.png). Fixtures may stage deployment/unlocks; they are not phone screenshots or completed native human playthroughs. Raw [UI](m1/ui_metrics.json) and [environment](m1/environment_metrics.json) counters are retained without FPS claims.

Remaining work: human mouse/touch playtesting at each chapter, aiming/reload ergonomics during acceleration, alternative turret placements/purchases/research routes, actual ammunition switching, hardest late shield/EMP/bomber combinations, larger seed/input-policy coverage, and physical Android performance/thermals/multitouch/audio. The test pilot reacts every simulation tick and uses deterministic leading/core aiming, so high HP in hybrid runs does not establish that humans will find later missions easy. Zero-leak clears of every late wave, every possible two-turret strategy and a final human difficulty rating have not been demonstrated. Tune from those observations; do not add forced leakage.

## Reproduce

```sh
./tests/run_checks.sh
./tests/run_m1_balance.sh /tmp/frontline-m1
# Review a new candidate before replacing docs/m1/after.json, then:
python tools/report_m1_balance.py
# Optional: intentionally rebuild the M1 tuning from its frozen G6 source:
python tools/rebalance_m1.py
# Native display/Compatibility renderer required:
./tests/run_ui_capture.sh /tmp/frontline-m1-ui
FRONTLINE_CAPTURE_SCENE=res://tests/environment_capture.tscn ./tests/run_graphics_profile.sh /tmp/frontline-m1-world --quality=medium --missions=1,2,3,5,10,15,20,25
```

The normal game still opens through `project.godot`, Godot 4.6.3, F5. No baseline/test pilot or diagnostic scene is used by the main scene.

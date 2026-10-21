# M8 — Mission stars and performance

All 25 missions have a secondary objective, visible before deployment and in the battle footer. Successful results reveal stars and a performance report. Completed nodes show best stars, and the map shows the total out of 75. **Replay** attempts protect the current frontline on both victory and defeat; deployment on the current contested territory remains an explicitly labeled frontline operation.

## Rules and configuration

`data/mission_performance.json` owns each mission's thresholds, secondary ID/name/description/conditions and optional score overrides. `scripts/core/mission_performance.gd` is the pure validation/evaluation layer. Currency stays in `data/economy.json`; Battle's event counters are in `scripts/game/battle_performance.gd`.

- Defeat: zero attempt stars; existing personal bests remain.
- Victory: one star.
- Victory with at least 60% of actual maximum base HP: two stars.
- Victory with at least 85% HP **and this attempt's secondary completed**: three stars.

HP thresholds are inclusive and configurable separately per mission. Research-increased maximum HP is the denominator. No previous objective clear can substitute for the current attempt's objective. A legacy result without a valid performance snapshot receives one victory star, no invented metrics or high-HP bonus.

Score is informational: rounded HP ratio × 10,000 + kills × 10 + manual kills × 5 + parts destroyed × 60 + completed secondary × 500 − breaches × 30 + max(0, 6,000 − ceil(seconds × 10)), bounded at zero. Per-mission score factors may override defaults. Score does not award money or control frontline progression.

## Counter definitions

| Metric | Definition |
| --- | --- |
| Primary shots | Real launched primary projectiles, once. Holding without firing is not a shot. |
| Successful primary rounds / accuracy | A registered primary shell that contacts at least one valid hull/component; at most one success per shell. Misses remain in the denominator. Accuracy is successes/shots, zero with no shots. |
| Piercing / splash | One rail shell through several actors or explosive shell hitting a group remains one successful round. Damage and kills count each distinct affected actor normally. A zero-direct-damage EMP contact can still be a hit. |
| Manual / automatic / other damage | Actual hull HP lost after shields/armor/resistances, clamped to remaining HP. Overkill and separate component HP are excluded. Explicit component-to-hull spill and exposed-core packets retain their source. Independent `other` remains visible. |
| Drone kills / manual kills | Once through the shared actual destruction lifecycle; source of the lethal hit owns the kill. A delayed engine-loss crash retains its triggering source and credits remaining hull HP when it dies. No early or second bounty. |
| Breaches | Once per drone actually reaching the base. Siege attacks/boss barrages damage the base but are not arrival counts. |
| Weak points destroyed | Actual M7 component destruction, each part once; generator/weapon/armored-part counters specialize this. No component bounty. |
| Direct Heavy engines | Heavy engine parts killed by a direct primary impact, not incidental blast or automatic fire. |
| Core contacts | Actual direct manual contacts on an exposed M7 core. |
| Critical rounds | Successful manual shells with rolled critical damage or exposed-core precision; at most one critical-round credit per projectile, even rail/splash. |
| Sector coverage | Peak simultaneous non-disabled, non-redeploying defenses mounted in distinct W/C/E sectors. It does not assert guaranteed damage. |
| Base / final-wave damage | Actual clamped HP lost, independent of later repair. Final-wave damage includes all real damage sources while that wave is active. |
| Time | Active battle simulation seconds, including ordinary preparation, excluding pause and P1 guided rehearsal. Tactical build time advances at its existing quarter speed. It is not wall-clock speedrun timing. |
| War Credits | Actual saved result payout, including mission, existing objectives and newly earned star milestones. |

Counters belong to one Battle instance, reset on deployment, and never change damage rules. Practice P1 targets cannot contribute. Presentation and star animation never mutate counters or grant rewards.

## Secondary objectives

Each row requires all conditions in that attempt, plus victory for a recorded clear/three stars. These use existing guaranteed wave enemies and M7 staged components; no convoy/radar object is invented.

| Mission | Secondary conditions |
| --- | --- |
| 1 | 5 manual kills. |
| 2 | 8 manual kills, ≥40% primary accuracy, at least 10 shots. |
| 3 | Operational defenses in two sectors simultaneously. |
| 4 | Directly destroy one Heavy engine with the primary cannon. |
| 5 | 3 open-core contacts and 8 manual kills. |
| 6 | 12 manual kills, at most 3 breaches. |
| 7 | Destroy one shield generator. |
| 8 | Destroy one weapon component. |
| 9 | Three sectors simultaneously and 12 manual kills. |
| 10 | One generator and 3 core contacts. |
| 11 | One direct Heavy engine and 15 manual kills. |
| 12 | One generator, at most 5 breaches. |
| 13 | One weapon and two sectors simultaneously. |
| 14 | Destroy 3 components. |
| 15 | 4 core contacts, at most 150 final-wave base damage. |
| 16 | 3 armored parts and 15 manual kills. |
| 17 | Destroy 2 generators. |
| 18 | 2 weapon components and one direct Heavy engine. |
| 19 | ≥25% effective hull damage from the primary, plus 10 manual kills. |
| 20 | 5 core contacts and three sectors simultaneously. |
| 21 | 25 manual kills, at most 4 breaches. |
| 22 | 6 components including a generator. |
| 23 | 3 weapon components, ≥45% accuracy and at least 20 shots. |
| 24 | 2 direct Heavy engines, at most 100 final-wave base damage. |
| 25 | 8 core contacts, one generator and 20 manual kills. |

Component availability is checked against configured waves, not probabilistic director support. Automated witness snapshots demonstrate that each rule set can be satisfied, and moving combat exercises real attribution. They do **not** prove that human three-star play is appropriately balanced across all 25 missions. The assisted earned-budget campaign currently finishes at 59/75 best stars; difficulty remains a playtest task.

## Persistence, replay and rewards

Schema v3 gains additive `performance_schema=1`. Each mission record retains prior victory/defeat/reward/HP fields and adds first-clear status, best stars, best HP ratio, fastest successful seconds, highest successful score, the coherent best-score snapshot and its payout, completed secondary IDs, and consumed star milestones. Best HP/time/score/stars improve independently on victory only; they may come from different attempts. The coherent snapshot is the best-score attempt, not fabricated combined best statistics.

v1/v2/v3 migration preserves balances, research and permanent progression. An old explicit victory or implicitly cleared territory below highest-ever reach gains one historical completion star. Unknown historical accuracy/time/HP ratio are not invented. Claimed numeric tiers are canonicalized after JSON parsing, including float representation, to prevent claiming a saved milestone twice.

Reaching two stars grants **10 WC once per mission**, then three stars grants **15 WC once**. Jumping from one to three gives 25; later improving two to three gives 15. Maximum extra campaign income is **625 WC**, about 7.23% of M3's base 8,640-WC first-clear/objective route. No repeat score rewards or mandatory ads. Existing replay income remains floor(15% of first clear), and failure/restart grants zero. See [economy](../ECONOMY_BALANCE.md).

`active_run.mode` distinguishes `frontline` and `replay`. Only current-frontline battles advance/retreat/secure floors. Completed territories remain available for optional replay after retreat, including a previously cleared territory beyond the current frontline. Replay victory/defeat cannot change frontline, highest, checkpoints or finale status. At a previously cleared contested frontline, the briefing also exposes an explicit practice replay choice; reconquest stays available as the ordinary operation.

Result token validation, mission/record/bests/bonus/objective updates, bank credit and token consumption are one persisted transaction. Duplicate/stale callbacks return nothing. Save failure rolls back everything and supports a legitimate retry. Loading retains the full ledger; it never combines an older record with a newer balance. Local saves remain user-editable, not server-authoritative.

## Verification

Run `FRONTLINE_REPORT_DIR=/tmp/frontline-validation ./tests/run_checks.sh`. It imports Godot, starts the project, exercises existing gameplay/economy/save/visual suites, runs the new performance and fresh-process suites, then completes a real earned-budget campaign.

Native tutorial/results/map coverage uses `FRONTLINE_CAPTURE_SCENE=res://tests/tutorial.tscn ./tests/run_graphics_profile.sh /tmp/tutorial-native --attack-seed=808` with a real display. Run native wrappers sequentially. See [M8 evidence and limitations](m8/VALIDATION.md) and [P1 tutorial](FIRST_MISSION_TUTORIAL.md). Android hardware/export and human three-star play remain unverified.

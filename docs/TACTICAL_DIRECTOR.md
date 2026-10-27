# M5 — tactical attack director

M5 extends the existing scheduler, combat, research and campaign. It does not replace enemy AI, targeting, collision, projectile payloads, manual controls or save transactions. The camera stays top-down; no automatic player firing is added.

## Data and ownership

- `data/definitions.json`: every mission has `approaches.sectors` (one label per route), spawn rectangles, movement bounds, target destination and original wave threat budgets. Existing slots and mission IDs are retained. Some maps gain a central/eastern route; accidental cross-map western segments and mission 20's backward segment are corrected. `docs/m5/baseline_geometry.json` preserves the previous geometry for comparison.
- `data/tactical_director.json`: enemy threat costs, pattern sector weights, warning duration, composition limits, support reserves and chapter selection/budget curves. Threat points are allocation weights, not damage, HP or money.
- `tactical_attack_director.gd`: one seeded planner per battle. It snapshots approximate turret coverage when the next intermission starts, chooses and freezes the next plan. It records kills, breaches, support production and base state per wave/sector. It never polls live defense weaknesses during an active attack.
- `wave_spawner.gd`: runs that frozen plan with the existing burst cadence. Directed routes bypass the legacy `fan`/`pincer` remapping. Existing three-argument standalone scheduler fixtures retain the legacy contract.
- `battle.gd`: owns spawning, combat and outcome transactions as before. Directed actors and their descendants carry wave/sector metadata. Presentation reads plans; it never resolves combat.

Each sector can own multiple paths. All 25 layouts have WEST, CENTER and EAST. The manual gun can reach an interception point on every path at y=460; it keeps its existing range, unrestricted aiming and ammunition/reload rules. The common final base approach remains, but enemies spend their earlier approach in distinct sectors.

## Patterns and progression

| Pattern | Allocation / composition |
| --- | --- |
| Balanced | Approximately equal contact counts across three sectors |
| West / east flank | 65% primary flank, 20% center, 15% opposite flank (mirrored) |
| Center breakthrough | Central emphasis; armored drones and bosses take center |
| Split | 48% west, 48% east, 4% center |
| Decoy | Armor/shield/EMP packet on one flank, lighter contacts on the other |
| Swarm | Replace selected armored contacts with affordable scouts, within count/threat/bounty limits |
| Elite | Up to six affordable scout-to-EMP/heavy substitutions, fewer dangerous contacts with existing escorts |

The plan interleaves enemy groups. Weighted sector quotas determine which pressure packet enters first; routes within a sector use seeded selection. Small waves, mandatory boss routing and role overrides can differ from ideal percentages; the HUD displays **actual scheduled counts**.

Missions 1–3 use predefined teaching sequences and unchanged compositions. Missions 4–10 draw basic flanks/split. Missions 11–15 add decoys, swarms and elite/support packets. Adaptation starts at 16. The last chapter increases complex-pattern weights.

New shorter flanks proved substantially harder in connected simulations. The final allocation ceiling is 100% of original wave threat through mission 15, 90% in 16–20, 85% in 21–25. Trimming keeps at least one of every original archetype and never removes a boss. Composition retains at least 90% of the resulting ceiling, cannot exceed it or inflate the original scheduled bounty. No enemy HP, travel speed, turret statistics, prices or saved balances change in M5.

Carrier/boss production has a separate finite reserve: 32 threat points per scheduled carrier and 120 per scheduled boss, configured centrally. Descendant carriers share the originating wave reserve. Existing simultaneous-support/72-live-actor caps remain. Debug plans expose both allocation and support expenditure; actual total spawned threat is bounded by `budget + support_budget`. These reserves are ceilings, not guaranteed spawns or additional starting money. They prevent indefinite support/reward farming.

## Limited reconnaissance

Coverage averages the DPS of placed turrets whose range includes route samples at y=270, 340 and 410. It does not inspect player aim, ammo, base HP, available money or future build decisions.

In missions 16–20 a 35% selection opportunity may increase the matching weakest-sector pattern weight by at most 35%; in 21–25 the opportunity is 45% and cap 40%. Completed-wave breach history adds at most 10% **in total per pattern**, not per previous wave. These are multiplicative weight bonuses; the weakest lane is never guaranteed to be chosen. The radar marks reconnaissance-influenced preparation with RECON. Building after the announcement cannot change the selected attack.

## Radar and timing

The next plan is visible from intermission start. A six-second simulated warning cannot be skipped. After it elapses, Start early can skip the remaining original build countdown. Pause freezes both; build/upgrade mode advances both at normal speed. Every active combat timer still uses standardized normal simulation delta.

The native overlay shows the named pattern, exact initial W/C/E counts and defended Sentinel base. Support-capable plans disclose `+ SUPPORT`; reserve-generated reinforcements are not claimed as initial radar contacts. The active strip becomes shorter to preserve battlefield visibility. Entry chevrons follow actual route starts/directions. The base receives a subtle objective arc. All overlays ignore pointers; the radar cue uses the existing audio settings/cache. Reduced motion removes the marker pulse; there is no fullscreen flash.

## Reproduction

```sh
godot --path . -- --attack-seed=612 --attack-debug-log
./tests/run_checks.sh
./tests/run_m1_balance.sh /tmp/m5-balance
DISPLAY=:91 LIBGL_ALWAYS_SOFTWARE=1 ./tests/run_tactical_capture.sh /tmp/m5-native
```

`--attack-seed` fixes attack planning. Reproduce combat comparisons with the same input policy, simulation delta, research, placement and manual critical RNG too (the tests fix all of these). Seed sequences are not promised to remain identical across balance/configuration versions. `--attack-debug-log` is debug-build only and prints full `TACTICAL PLAN`, `TACTICAL OUTCOME` and terminal `TACTICAL RESULT` JSON: seed, pattern, routes, sector counts, budgets, coverage, weights and outcomes. No player save mutation is needed to enable logging.

See [measured validation and limitations](m5/VALIDATION.md). Native desktop injected touches are distinct from physical Android verification; no Android FPS or perfect balance claim is made.

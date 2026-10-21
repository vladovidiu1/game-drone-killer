# M2 — projectile technologies, mission loadouts and specializations

2026-10-21 · Godot 4.6.3 · Compatibility · extends M1 commit `279938d`.

The existing Standard / Armor Piercing / Explosive implementation is extended in place. The original unlock IDs, purchased research, costs, base ammunition behavior and campaign save schema remain compatible. EMP, Cryo and Railgun use the same `projectile.tscn`, cannon/input adapter, swept collision, reward lifecycle and bounded VFX batch. No duplicate combat or campaign implementation is introduced.

## Research and progression

Arsenal now has **PRIMARY CANNON / PROJECTILES / TURRETS / RESEARCH / ABILITIES**. PROJECTILES contains six illustrated cards with role/tradeoff, actual current and next-tier stats, prerequisites, tier pips, WC cost, unlock status and loadout buttons. TURRETS retains existing unlock/stat cards and adds two specialization branches per design. All purchases use the existing reviewed confirmation/atomic save path; stale confirmations, insufficient funds, unmet requirements and failed writes do not grant or debit anything.

| Technology | Unlock WC | Highest mission required | Research prerequisites for unlock | Tier 1 / 2 / 3 WC |
| --- | --- | --- | --- | --- |
| Standard Rounds | 0 | 1 | None beyond mission gate | 60 / 120 / 220 |
| Armor Piercing | 180 | 2 | None beyond mission gate | 90 / 170 / 300 |
| High Explosive | 260 | 3 | None beyond mission gate | 100 / 190 / 330 |
| EMP Projectiles | 360 | 6 | standard tier 1 | 120 / 220 / 360 |
| Cryo Rounds | 480 | 11 | emp tier 1, emp tier 1 | 140 / 260 / 420 |
| Railgun Projectiles | 800 | 16 | armor piercing tier 2, standard tier 2 | 200 / 360 / 580 |

Standard is always available at tier 0, with a zero unlock cost. Every technology has three **purchased improvement tiers** above its unmodified tier-0 profile. Legacy AP/HE purchases are grandfathered at their existing base profile, with no repurchase or unsolicited free research. AP/HE retain their mission-2/3 eligibility; new EMP/Cryo/Rail arrive after chapter advancement to 6/11/16. Purchased tiers require that technology's unlock (Standard has no unlock prerequisite).

These costs support tradeoffs: unlocking and fully researching all six ammo technologies costs 6,320 WC. Optional specializations and the retained numeric research compete for the same War Credits. No mission checks for a required ammo type, and no enemy is given total immunity to a technology. The unresearched M1 campaign remains completable; advanced loadout balance/human difficulty remains separate playtesting work.

## Actual projectile behavior

Base figures below assume the original 15-damage, 6 shots/s, 850-speed cannon before permanent scalar research/criticals. Range stays 400 units. The magazine is a **shared pool of 60 units**, increased by existing Magazine research; expensive shots consume more units, not a separate automatically refilled magazine.

| Technology | Tier-0 behavior | Tier-3 improvement | Role / cost |
| --- | --- | --- | --- |
| Standard | 15 damage, 6/s, 1 unit, 850 speed | 18.6 damage | Balanced interception, no splash/control |
| Armor Piercing | 15 damage, 26.25 vs armored, 4.5/s, 1 unit | 35.25 vs armored, 1054 speed | Ignores ordinary hull armor and shield protection; lower firing rate and no area damage |
| High Explosive | 11.25 damage, 45 splash, 6/s, 3 units | 13.275 damage, 63 splash | Efficient grouped targets; only 20 shots per base magazine |
| EMP | 5.25 damage, 22 area, 0.7s disruption, 3.9/s, 2 units | 34 area, 1.3s disruption | Stops movement/electronic attacks, reveals stealth and suspends shield emitters; bosses resist duration |
| Cryo | 7.5 damage, 30% slow for 1.5s, 5.1/s, 2 units | 45% slow for 2.55s | Slows targets to support automatic crossfire; less direct damage and resisted by heavy/boss targets |
| Railgun | 60 damage, 84 vs armored, 1870 speed, 0.9/s, 6 units, 3 targets | 75.75 damage / 106.05 vs armor, 2252.5 speed, 6 targets | Precision ray through aligned targets; retains 78% damage per penetration, long firing cooldown, 10 shots/base magazine |

All manual shots remain straight and range-limited. Railgun is **not homing or hitscan**: it advances at its configured speed and finds nearest swept intersections. Each actor ID is consumed before resolving its hit; a ray can never hit the same actor again while inside its collider. Damage falls per penetration and stops at the target budget, lifetime or range. Collision ownership, direct-hit notification and kill bounties remain centralized. Splash replaces direct damage rather than adding a second hit.

The direct collision target is always included in its own area hit. This fixes the integration case where a small EMP radius was less than the distance from the hit point to a large drone/boss center. Nearby targets still require their center inside the configured blast radius. EMP uses electrical pulses rather than a high-explosive fireball; Cryo uses cyan frost/area cues, Railgun a long bright slug/streak, and the existing Standard/AP/HE effects remain distinct. Critical hits scale damage only, not disruption/slow duration.

## Loadout and reload rules

1. Equip **one to three unlocked technologies** in PROJECTILES before deploying. Equipping a fourth is rejected; remove a slot first. Standard can be omitted, but the loadout cannot be empty or contain duplicate/locked IDs. Slot order determines combat button order.
2. Mission start snapshots the ordered loadout, each technology tier/profile and active preference. Purchasing research or changing saved loadouts cannot modify an already deployed cannon or an in-flight projectile.
3. The HUD exposes only three touch-friendly chips; unfilled positions are labeled EMPTY and disabled. Mouse/touch select from the snapshotted loadout. Aiming and held FIRE retain independent pointer IDs.
4. Switching preserves current magazine units, recoil/visual heat and any existing cooldown. The next-shot delay is at least the greater of the remaining delay and the selected profile's firing interval, so a Railgun shot cannot be followed by an immediate free Standard shot.
5. Switching is rejected during reload, pause or a finished mission. Reload is the existing shared 2s operation (modified only by existing Reload research), fills the shared capacity once, and freezes during pause/tactical time with the rest of simulation.
6. Insufficient units for the selected shot starts a real reload when firing is requested. Holding FIRE cannot shoot through reload. Mission restart resets temporary ammunition as before; equipment/research persists.

Combat selection retains the existing saved active-preference API. Pre-mission equip/removal and preference changes are validated transactions, with rollback on disk failure. No paid battle credits or invented ammunition replenishment is introduced.

## Automatic specializations

Each design has two independently researchable three-tier branches, **120 / 220 / 380 WC per branch**. Basic designs require highest mission 4; Laser/EMP/Heavy AA branches require 6 and the corresponding turret unlock. **Only one branch per design is equipped at deployment**. Both can be researched for later flexibility; switching/returning to standard tuning between missions is free. The first purchased tier equips its branch if no branch is active. Improving an already owned, unequipped branch does not silently override an explicit standard-tuning choice.

| Turret | Branch A | Branch B |
| --- | --- | --- |
| Machine Gun | Cycling Assembly: Faster fire; less damage per round. | Hardened Feed: Armor damage; slower firing. |
| Cannon | Impact Chamber: Higher impact; longer firing cycle. | Fragmentation: Small splash; lower direct damage. |
| Missile | Wide Warhead: Larger splash; slower missile flight. | Guidance Package: Faster travel and lock; slightly lower damage. |
| Laser | Thermal Capacitor: More sustained DPS; longer acquisition. | Shield Harmonics: Bypasses shield protection; less hull damage. |
| Emp Tower | Field Antenna: Wider field; slightly shorter slow duration. | Disruption Coil: Longer slow plus short disable; shorter range. |
| Heavy Aa | Precision Breech: Higher damage; tighter required firing alignment. | Penetrator Sabot: Armored damage and bypass; lower ordinary damage. |

The catalog's `factors` multiply base stats by `1 + step × tier`; `add` adds its step per tier. Global permanent research and normal temporary turret levels are applied afterward, once. Magazine-free automatic firing, M1 lock/turn/alignment rules and target priority remain. Branches alter actual shots, beam damage, area size, projectile speed, field control and armor/shield damage; they are not cosmetic buttons. Arsenal shows tier-3 stat previews and the equipped branch.

Examples at tier 3: Rapid MG has 8.8 damage at 5.168/s versus Armor MG's 10 at 3.23/s with 1.9× armored damage and 60% armor bypass; one favors ordinary targets, the other hulls. Missile Wide Warhead trades 111 splash for slower 243.2 travel, while Guidance keeps 75 splash, raises travel to 560 and shortens lock at a small damage cost. EMP Duration adds a short disable as well as longer slow, while Radius covers more lanes. No branch adds random misses.

## Enemy resistance and effect ordering

Enemy definitions now expose `resistances.armor`, `shield`, `emp`, `cryo`, clamped to 0–0.9. M1 hull armor remains 20% Heavy / 15% Bomber / 25% Carrier; all existing HP, paths, waves, speed, budgets, checkpoints and rewards are unchanged. Personal shield resistance defaults to zero; the existing Shield Drone aura remains its configured protection for nearby actors.

EMP drones resist EMP duration by 25%; bosses by 75%. Heavy/Carrier resist Cryo by 20%, bosses by 65%. EMP multiplies disable duration by `1 - resistance`. Cryo reduces both duration and slowdown strength by that factor. Status strength/duration do not multiply with critical damage. Reapplication uses the existing strongest-slow/longest-duration rule rather than multiplying slows or adding durations; disable and slow coexist, with slow time continuing to elapse while disabled.

AP and Rail use the existing armored-damage multiplier and ordinary armor/shield bypass. Automatic armor branches instead apply their configured partial hull bypass; the anti-shield Laser applies partial personal/aura bypass. Boss phase hull armor/core multipliers remain the established boss rules; accurate manual core intersections still matter. Damage/shield checks happen as each impact is resolved, then its control payload applies to surviving targets. As with existing attacks, destroying/disabling an emitter can affect later impacts.

## Persistence and architecture

- Campaign schema stays **v3**, with additive **weapon_schema=1**, `ammo_loadout` and `turret_specializations`. The existing `research` dictionary gains bounded 0–3 ammo/branch entries; existing `unlocks` holds new ammo IDs. No parallel save or currency is introduced.
- v1/v2/v3 saves retain credits, legacy bonuses, research, records, checkpoint/frontline, tokens and settings. A missing loadout migrates active preference first, then available Standard/AP/HE, up to three entries. Invalid IDs/types/duplicates and unresearched branches are sanitized. Validation never retroactively strips a paid upgrade just because a newer tree has prerequisites.
- Existing temp-write/validation/backup/recovery/result transactions remain. M2 tests deliberately fail writes to verify tier debit/grant, first-branch auto-selection, loadout and branch selection rollback.
- `scripts/core/weapon_technology.gd` performs pure profile composition. `player_turret.gd` owns the deployed snapshot; `projectile.gd` owns frozen payload and per-hit penetration; `battle.gd` keeps impact/reward ownership. `projectile_research.gd` is UI composition, using existing EconomyManager purchase/loadout APIs.
- Definitions remain in `data/progression.json` / enemy `data/definitions.json`. No mission wave/layout was rebuilt. The M1 rebuild helper now preserves additive enemy resistance fields instead of erasing them.

## Validation, art and remaining work

[Current test results](m2/VALIDATION.md) cover six technologies × four levels (base plus three upgrades) × fourteen archetypes, actual swept collision, critical and noncritical shots, status resistance, rail ownership/falloff, reload/heat/cooldown protection, all twelve branches firing, migrations/write failures and fresh-process equipped state. Full campaign tests still complete all 25 territories with earned progression and verify retreat/reconquest/results; no new technology is required by deployment rules.

[Native gallery](m2/README.md) is unmodified Godot X11/Compatibility output: paid research confirmations through actual native touch buttons, card-based three-slot loadout changes, all five tabs on four layouts, each ammo's flight/impact/reload, three combat chips and simultaneous aiming/FIRE touches. Funding/unlocks/deployments/targets are explicitly staged render fixtures, not earned human playthroughs or Android hardware proof.

Six original **authored SVG technical illustrations**, not painted raster artwork, are generated by `tools/build_projectile_vectors.py`, MIT licensed and inventoried in [ASSET_MANIFEST.md](../ASSET_MANIFEST.md). Existing G1–G6 artwork remains intact. Runtime effects reuse the bounded batch, with no per-particle nodes, bloom or renderer-specific feature. Generated unit/environment raster art still awaits the previous final art review. Optional painted ammunition/VFX refinement can replace these utility assets without changing gameplay.

Physical Android touch ergonomics, device performance/thermals/audio and human balance of all loadout/branch combinations remain untested. Native software-renderer counters do not establish 60 FPS. No universal-best branch/ammunition or exhaustive human difficulty result is claimed; tune the data from further playtesting.

```sh
./tests/run_checks.sh
# Requires a real native display/Compatibility renderer, not --headless:
FRONTLINE_CAPTURE_SCENE=res://tests/weapon_capture.tscn ./tests/run_graphics_profile.sh /tmp/frontline-m2
python tools/build_projectile_vectors.py
python tools/build_asset_manifest.py
```

Open `project.godot` in Godot 4.6.3 and press F5. In a campaign, open Arsenal → PROJECTILES, research/equip up to three technologies, then deploy normally. Use TURRETS to research/equip specializations. No test pilot, fixture bank or rendering capture scene is loaded by the main scene.

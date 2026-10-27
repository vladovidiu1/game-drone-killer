# Campaign design and validation

M5 extends this campaign with directed multi-sector attacks. Current validation permits bounded real defeats and follows the saved retreat/reconquest rules; it still requires actual victories on all 25 territories, every boss, checkpoint retention and fresh-process restoration. See [M5 rules](TACTICAL_DIRECTOR.md) and [current measured outcomes](m5/VALIDATION.md); earlier first-pass results below describe their recorded revision.

Task 5 extends the existing native Godot hybrid battle. `data/definitions.json` is the runtime source of mission geometry, enemy statistics, formations, conditions and boss phases. No per-level scripts or external services are required.

## Territories

| Mission | Environment | Slots / waves / routes | Reward | Special encounter |
| --- | --- | --- | --- | --- |
| 01. Outpost Alpha | dry / clear | 5 / 5 / 3 | 120 | Escort waves |
| 02. Red Hill Village | rural / clear | 6 / 6 / 2 | 180 | Escort waves |
| 03. East Supply Depot | industrial / clear | 7 / 7 / 3 | 250 | Escort waves |
| 04. Broken Bridge | bridge / clear | 6 / 6 / 2 | 350 | Escort waves |
| 05. Greyford | metro / clear | 6 / 6 / 2 | 270 | Heavy Assault Carrier |
| 06. North Power Station | power / interference | 7 / 7 / 2 | 385 | Escort waves |
| 07. Riverside District | river / clear | 7 / 7 / 2 | 405 | Escort waves |
| 08. Iron Highway | highway / clear | 7 / 7 / 2 | 425 | Escort waves |
| 09. Falcon Airbase | airbase / clear | 7 / 7 / 3 | 445 | Escort waves |
| 10. Metro Asteria | metro / clear | 7 / 7 / 3 | 365 | EMP Warship |
| 11. Western Ruins | ruins / clear | 8 / 8 / 3 | 480 | Escort waves |
| 12. Liberation Road | highway / clear | 8 / 8 / 3 | 500 | Escort waves |
| 13. Black Ridge | ridge / dust | 8 / 8 / 3 | 520 | Escort waves |
| 14. Border Fortress | fortress / clear | 8 / 8 / 3 | 540 | Escort waves |
| 15. The Last Border | fortress / clear | 8 / 8 / 3 | 460 | Armored Border Guardian |
| 16. Varkon Frontier | ridge / clear | 8 / 8 / 3 | 575 | Escort waves |
| 17. Steel Valley | valley / clear | 8 / 8 / 3 | 595 | Escort waves |
| 18. Drone Assembly Plant | factory / interference | 8 / 8 / 4 | 615 | Escort waves |
| 19. Red Harbor | harbor / clear | 8 / 8 / 4 | 635 | Escort waves |
| 20. Industrial Citadel | factory / clear | 8 / 8 / 4 | 555 | Drone Factory Command Ship |
| 21. Deadlands | deadlands / dust | 8 / 8 / 4 | 670 | Escort waves |
| 22. Varkon Defense Ring | fortress / interference | 8 / 8 / 4 | 690 | Escort waves |
| 23. Central Command | metro / clear | 8 / 8 / 4 | 710 | Escort waves |
| 24. Capital Siege | capital / clear | 8 / 8 / 4 | 730 | Escort waves |
| 25. The Hive Core | hive / interference | 8 / 8 / 4 | 650 | The Hive Core |

Each territory has its own location/story, layout, landmarks, gate positions, slot arrangement and wave recipes. Recipes vary escort composition, entry lanes and intervals. G2 now supplies illustrated terrain/prop kits and atmospheric variants for every territory; see [the environment library](ENVIRONMENTS.md). The original campaign validation below predates that visual pass.

## Combat pressure and counters

| Archetype | Behavior | Counter |
| --- | --- | --- |
| Scout / Assault / Heavy | Original fixed 40 / 100 / 300 HP; route-following, differing speed and armor | Overlapping defenses; AP against armor |
| Shield | 130 HP, 125-unit aura reduces nearby damage by 55%; emitters never stack or shield themselves | Manually remove the emitter, bypass with AP, or temporarily disable with EMP Blast |
| EMP | 130 HP; a marked 1.8s charge suppresses a nearby automatic gun for 2.5s | Kill during charge; primary cannon stays online |
| Bomber | 160 HP, high 180-point breach damage | Intercept before the bunker; overlapping AA |
| Sniper | 140 HP; 2.2s beam warning followed by 3.5s defensive suppression | Prioritize the beam source; defenses recover automatically |
| Carrier | 220 HP; telegraphed launches create two real scouts, up to six living support drones | Kill before launch; explosive fire handles offspring |
| Stealth | 65 HP; 3s cloak in a 6s cycle blocks new automatic acquisition, retains a visible outline | Manual rounds always collide; EMP reveals; exploit visible windows |

Carrier offspring start at their carrier, travel to the bunker, have half bounty and share the ordinary once-only damage/reward lifecycle. Boss support uses at most eight living support units; launches also stop at 72 total living enemies. Ability timers, statuses, reloading, effects and the scheduler consume the same battle delta. Pause freezes them; build and upgrade panels preserve normal speed. There is no selectable 2x combat mode (M1).

Base archetype HP does not scale with mission number. Data raises movement speed by 0.9% per territory after mission 3, capped below +20%, while later recipes mix more armor, support units, flanks and tighter deployment intervals. Escort recipes interleave groups and configurable column/fan/pincer routing rather than spawning every escort after its protected formation. Automatic targeting remains shortest remaining path with stable spawn-ID ties, excluding cloaked units.

Dust in Black Ridge/Deadlands reduces automatic range to 87%; manual range is unchanged. Grid interference in missions 6/18/22/25 announces itself three seconds before a two-second automatic-defense outage every 34 simulation seconds. It does not take away manual control. The condition and boss warnings are drawn over the battlefield without intercepting aim.

## Chapter bosses

| Territory | Boss | Phase attacks | Supporting drones |
| --- | --- | --- | --- |
| 5 | Heavy Assault Carrier (1600 HP) | spawn → emp → spawn | scout, assault |
| 10 | EMP Warship (1900 HP) | emp → spawn → emp | emp, scout |
| 15 | Armored Border Guardian (2200 HP) | barrage → spawn → barrage | heavy, shield |
| 20 | Drone Factory Command Ship (2500 HP) | spawn → emp → spawn | carrier, stealth |
| 25 | The Hive Core (3000 HP) | barrage → spawn → barrage | emp, bomber, shield |

Bosses have distinct silhouettes/colors and three phases at 100% / 66% / 33% HP. They approach a firing anchor within primary range, attack while approaching, and never simply breach the base as an ordinary drone. Rings, beam lines, a labeled phase/HP bar and hit flashes communicate their actions. Boss launches, EMP suppression and bunker barrages use configurable windups and intervals. Escorts in the final wave remain real enemies; killing the boss alone does not instantly clear living escorts.

Hull plating takes only 3.5% automatic damage, reduced by another 25% in phases 1–2. Manual body hits retain 55% (also subject to that phase armor), while a straight manual trajectory through the lit 14-unit cyan core bypasses hull reduction and deals 2.5x / 2.75x / 3x. AP still applies its ordinary armored-target modifier. Splash does not grant precision bonuses to secondary victims. This rewards positioning/aim rather than allowing an arbitrary target lock to count as a core hit.

A clearly displayed siege capacitor charges for 55–67 simulated seconds from boss entry. If ignored, it fires 350 bunker damage every 2.5s; EMP temporarily suspends attacks. This gives a visible limit to prolonged automatic-only boss fights. Normal core-focused hybrid simulations defeat bosses before overload; comparative tests explicitly exercise the failure.

Winning chapters 1–4 permanently secures floors 5/10/15/20. Winning 25 shows Asteria’s liberation and controls the final territory. The optional validated `campaign_complete` field extends schema v3 without resetting older v1/v2/v3 saves. A replay defeat still retreats, clears the active ending flag below 25 and preserves research/history; reconquering 24 then 25 restores liberation. Each new attempt has the existing persisted token; duplicate results never pay again. Important victories append narrative updates to results/map feedback.

## Reproducible checks

Run `FRONTLINE_REPORT_DIR=/tmp/frontline-reports ./tests/run_checks.sh`. No test needs network or a user account. The runner imports Godot, rejects engine/script errors, isolates all saves and includes:

- Original combat, hybrid input, UI, research, corruption recovery and three-mission retreat/reconquest regressions.
- `campaign_catalog.tscn`: validates all 25 records, unique layouts, paths, slot bounds, wave/group references, formation names, reward/stat ranges and five ordered boss phase tables.
- `enemy_ai.tscn`: exercises shield stacking/bypass, stealth/manual hits/reveal, telegraphs, suppression/recovery/pause, carrier spawning/caps, all 15 boss phase attacks, actual boss destruction, final-wave waiting, environments and compatible ending validation.
- `full_campaign.tscn`: a deterministic assisted commander plays all 25 in sequence. It buys research/unlocks using earned War Credits, builds/upgrades using starting funds and bounties, aims/leads real straight projectiles, repairs from battle funds and waits normal intermissions. No health, bounty or victory injection occurs in these fights. It then loses 25 undefended, verifies retreat/upgrades, and reconquers 24/25.
- Fresh process `--verify-full` confirms every victory, final territory, ending flag and all checkpoint floors from disk.
- Separate `--compare` battles use the legitimately earned endgame research snapshot: automatic-only and manual-only runs are compared against the hybrid victory. Their isolated fixture changes are restored afterward.

The machine-readable files `campaign_balance.json` and `campaign_comparison.json` contain duration, health, kills, manual shots/hits, core hits, ability executions, support spawns, environmental pulses, research and War balance. `BALANCE_RESULTS.md` summarizes the latest checked data. Tests control the input adapter; runtime code never aims or fires for the player.

M2 adds optional projectile technologies and turret branches without changing these mission definitions, checkpoint rules or baseline connected combat results. See [M2 research and migration](WEAPON_RESEARCH.md).

## Remaining validation

These runs establish valid data, connected completion, affordable progression and meaningful counter behavior. The assisted commander has precise targeting, instant build decisions and perfect timer knowledge. It is not evidence that humans will find every mission balanced or enjoyable. Early missions can still be won primarily with automatic fire; later boss cores make manual shooting substantially more efficient.

All 25 missions require human difficulty/aim/reload testing, particularly opening economies in 4–6, boss readability in 5/10/15/20/25, dust in 13/21, carrier density in chapter 4 and grid outages in 22/25. Check the M1 2–5 minute target at normal speed with ordinary preparation; early starts shorten it. See [M1 balance evidence](M1_BALANCE.md).

No physical Android device, signed APK, graphical play session, audible playback, cutout/aspect-ratio hardware check or mid-range-device 60 FPS measurement was available. G1/G2 subsequently verified native Linux Compatibility rendering; see their visual reports. Physical Android acceptance and audible output still need separate passes before release.

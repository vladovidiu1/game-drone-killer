# M6 — strategic placement and redeployment

M6 extends the existing automatic turrets, battle scheduler, tactical director, native HUD and briefing. Mission IDs, slot coordinates/counts, paths, wave definitions, enemy abilities, permanent research, campaign/save transactions and manual cannon rules are preserved.

## Placement and weapon geometry

Each mission's `emplacements` array corresponds exactly to its existing `slots` array. Each entry defines WEST/CENTER/EAST, forward/fallback/support/elevated role, default bearing and range multiplier. All 25 missions have western, central and eastern positions. Selected lateral emplacements in depot/industrial/fortified layouts use existing raised-deck artwork and a documented +8% automatic range bonus. Other slots have no stat bonus. This is a top-down range advantage; it does not introduce 3D height, raycast cover or terrain collision.

`traverse_degrees` in `data/definitions.json` is the **total mounted firing arc**, centered on the emplacement's bearing. All default bearings currently face north (-90°); per-slot tuning can change that. Use the selected turret's ↶/↷ controls to rotate the mount bearing by the step in `data/placement.json` (45° initially). The physical barrel still turns at its existing bounded rate and must reacquire a valid lock. Changing the mount does not snap the barrel to an enemy.

| Automatic weapon | Total traverse | Existing response |
| --- | ---: | --- |
| Machine Gun | 300° | Fast tracking, wide flank coverage; rear blind cone |
| Cannon | 240° | Medium coverage, slower heavy shots |
| Missile Launcher | 320° | Broad coverage, slow response/projectile travel |
| Laser | 240° | Tight alignment tolerance, limited effective range |
| EMP Tower | 360° | Radial electronic support; no direct DPS |
| Heavy AA | 180° | Narrow front hemisphere, strong precision shots |

The earlier `firing_arc_degrees` remains **barrel alignment tolerance**, not total traverse. Existing turn rate, acquisition delay, stable target priority, ranges, projectiles, damage, status effects and research/specialization calculations remain. Both target acquisition and continued lock validation enforce mounted arcs. EMP pulse targets use the same range/arc check. Already launched rounds retain their existing payload/homing/splash rules, including impacts outside the mount arc after firing.

`scripts/game/placement_rules.gd` owns shared geometry. Turret acquisition, selected arc/range artwork, the optional coverage overlay and M5 reconnaissance use the same geometric reach. Research, temporary turret levels, environment visibility penalties and destination range bonuses all affect real range. No turret is granted full-map coverage.

## Preparation and information

Briefing shows actual terrain, numbered slots, known corridors and W/C/E directions, elevated markers, enemy intelligence, equipped ammunition/tier, primary cannon statistics, available automatic designs and actual starting Battle Credits including research. It does not inspect or pre-roll surprise director plans.

After Start Mission, the live battlefield enters **PREPARE**. Buy and orient defenses with ordinary starting Battle Credits. The first wave waits for explicit **Launch wave**, even after the normal build countdown expires. The six-second M5 radar warning still cannot be bypassed. Later waves keep their timed intermissions/early start. Preparation itself grants no money or research and never auto-fires the primary cannon. Tests/pilots explicitly launch the first wave rather than bypassing the scheduler.

## Moving an existing automatic turret

1. Tap a built turret, then **Move** in its scrollable management panel.
2. Empty legal slots highlight green. Tap a destination; the source remains armed until confirmation. An orange preview uses the destination's real range bonus and default bearing.
3. Review source/destination, Battle Credit cost and transport time; tap **Confirm**. Cancel before confirmation costs nothing.
4. The source becomes offline for four simulated seconds. Its source slot remains occupied and destination reserved. One progress row remains visible beside FIRE/reload; Cancel returns it to source with the escrow refunded.
5. Completion transfers the **same actor instance** to the reserved slot. Level, research, specialization, legacy amplifier and current cooldown/status remain. Its mount adopts the destination bearing/range bonus and reacquires a target.

Initially only one transport may be active. Other defenses and manual cannon continue to work; other unreserved empty slots can still be built. In-transit upgrades/rotation are rejected. Destination changes, occupied slots, repeated confirms, concurrent starts, insufficient funds and building over reservations cannot create a turret or debit twice.

Pause freezes progress. Confirm closes tactical UI to restore normal speed. Opening another build panel during transport uses the same existing 0.25x simulation clock, so four simulated seconds take sixteen real seconds while that panel stays open. The primary gun's input/aim/reload logic is untouched.

`turret_redeployment.gd` owns the mission-only transaction. It clears escrow ownership before refund/notifications and commits slot ownership before completion notifications. Cancellation, lost actors, mission victory/defeat and scene removal release reservations and refund **once**. No War Credit transaction, saved balance or persistent battle resume schema is added. Mission rewards remain guarded by the existing deployment token. Temporary BC refunds never become earned bounty or persistent credits.

## Costs

`data/economy.json.battle.redeployment.value_percent` starts at 35. Duration/rotation step/sampling live in `data/placement.json`.

```
current value = construction cost + sum of paid-level upgrade prices
move cost = ceil(current value × percentage / 100)
```

Permanent research does not inflate purchase value. Examples: MG L1 35 BC, L2 58, L3 104; Cannon L1 70, L2 116, L3 207. Moving an MG L3 costs more than building a fresh MG L1, incurs downtime and abandons previous coverage. There is no universally cheaper/free repositioning option. See [economy balance](../ECONOMY_BALANCE.md).

## Coverage and mobile UI

Selecting a turret shows a filled faint arc, mechanical boundaries and bearing line at its **actual range**. The destination preview is orange. **Coverage ON/OFF** adds every automatic arc plus route samples at y=270/340/410. Cyan dots mean geometric weapon reach; orange dots are gaps in weapon reach; purple rings show EMP support. Disabled/moving weapons do not count. The base cannon is intentionally excluded from this secondary overlay.

The legend explicitly says **NOT A KILL GUARANTEE**. It does not predict cooldown availability, damage, shields, cloaking, projectile interception or required aim skill. Different path/sample counts can produce different gap totals per sector; they are not percentages or promised survivor counts.

The layer is clipped to the battlefield beneath the native HUD, redraws at 10 Hz, and adds no particles or physics. It ignores pointers. Management actions share the existing touch-scroll panel; FIRE, reload, ammo, abilities, pause and build Close retain dedicated native targets. Inline confirmation avoids a modal that would block manual shooting.

## Run and validate

```sh
godot --editor --path .
./tests/run_checks.sh
./tests/run_m1_balance.sh /tmp/m6-balance
DISPLAY=:91 LIBGL_ALWAYS_SOFTWARE=1 FRONTLINE_CAPTURE_SCENE=res://tests/placement_capture.tscn ./tests/run_graphics_profile.sh /tmp/m6-native
DISPLAY=:91 LIBGL_ALWAYS_SOFTWARE=1 ./tests/run_ui_capture.sh /tmp/m6-ui
```

See [measured results and native frames](m6/VALIDATION.md). Native runners must run sequentially to avoid desktop focus-loss pause interference. No physical Android, APK or FPS claim follows from desktop tests.

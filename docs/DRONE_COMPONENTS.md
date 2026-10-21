# M7: local weak points and component destruction

M7 extends the existing Drone, EnemyBrain, swept manual Projectile and shared reward lifecycle. It adds no campaign/save subsystem. Source tuning is `data/drone_components.json`; imported-art mounts are `assets/visual_catalog.json.sprites.*.component_mounts`.

## Composition and geometry

`drone_components.gd` is a mission-lifetime rig. Each `drone_component.gd` Node2D owns local HP, armor, hit radius, flash, broken state and a once-only `destroyed` signal. The body component aliases existing drone hull HP. Other components have independent HP and explicitly configured hull spill. No component gives a separate bounty.

Mount coordinates are **imported sprite pixels relative to its pivot**, never world coordinates. Component nodes are children of the actual body or articulated left/right armor panel. The analytic swept segment is transformed into the node's local space; rotation, movement, body scale, nonuniform actor scale and battlefield/canvas transforms therefore affect the shape correctly. A scaled circle is tested as the corresponding ellipse. Boss panel movement and damaged-engine pose are advanced by the simulation rig; visual code does not choose vulnerable geometry.

A conservative actor broadphase skips distant drones. The manual ray selects the nearest eligible **surface component** intersected along its remaining straight trajectory, with the coarse circular hull as fallback for that actor. Surface mounts deliberately take precedence over the approximate hull volume; the ray is not consumed by an invisible hull in front of the painted core. Between actors, earliest actual contact wins. There is no input magnetism, trajectory bending, targeting assist or default automatic primary fire.

A drone has at most seven component nodes including body, plus one batched marker painter; Scouts retain their original single-body path. No per-component physics bodies, Area2D queries, particles or processing callbacks are created. Simulation clocks use the existing battle delta, including pause and temporary 25% build mode.

## Damage contract

| Attack | Routing |
| --- | --- |
| Manual Standard/AP/Cryo/Rail direct | One intersected surface component, otherwise one hull hit. Component armor and active shields apply once; existing rolled critical and penetration falloff were snapshotted upstream. |
| Direct component spill | Engine 20%, weapon 25%, generator/sensor 20%, core 100% of its final packet also damages hull. This is deliberate co-damage, not a second normal body/armor/weakpoint calculation. |
| Body / automatic direct fire | Existing hull armor, shielding, boss hull reduction and normal targeting. No precision-part selection. |
| Explosive/EMP/automatic splash | Splash replaces direct damage. Each actor selected by the existing center-in-radius rule (plus the actual direct target) receives one normal hull packet. Each live component whose **center** is inside that radius receives one additional 25% packet, with its own armor/shield and configured hull spill. There is no direct-core bonus. This preserves the existing center-based blast policy rather than pretending the blast tests every sprite pixel. |
| Rail penetration | At most one component/hull hit per distinct actor. Existing penetration count and per-actor falloff remain authoritative; a ray cannot farm several modules on one drone. |

AP's existing armored-target multiplier includes armored components and bypasses their armor/shields. Automatic specialization traits retain partial armor/shield bypass. EMP/Cryo status is applied once to the actor after the packet, using existing duration/strength resistance; component hits do not multiply status by core/critical damage. EMP can temporarily disable shielding; a destroyed generator remains offline. Negative/nonfinite component packets are rejected.

A destroyed ordinary component no longer intercepts direct rounds. A breached core remains a vulnerable wreck conduit: its HP/destruction event never repeats, but subsequent precision hits can continue damaging the hull. Core destruction also deals one configured **10% maximum-hull burst**. These are explicit rules; no component reward or forced survivor rule is added.

## Consequences and progression

| Stage | Real component behavior |
| --- | --- |
| Missions 1–3 | Existing body-only drones; unchanged tutorial waves. |
| 4–5 | One Heavy engine: 65 HP, 30% travel reduction, stopped local propulsion overlay, scorch/smoke/instability. It is not yet a complete critical-engine set. Chapter boss has a precise core and one engine. |
| 6–10 | Assault/Heavy weapons, specialist weapons and Shield generators. Weapon destruction cancels matching telegraphed/future EMP/sniper/barrage attacks and halves remaining contact payload. Generators remove their owner's configured shield and support aura. |
| 11–15 | Dual critical engines on larger/specialist drones; launch-bay attacks can be disabled on Carriers. Sensor loss removes Stealth cloaking or reduces future electronic target-acquisition range to 55%. |
| 16–20 | Non-core parts gain 25% armor; Heavy/Carrier cores and timed boss exposure. Live cores open for six seconds in each eight-second simulation cycle, and are sealed while their own generator operates. |
| 21–25 | Combined armored engines, generators, weapons and cores on late bosses and existing mixed waves. Earlier hull/path/wave/economy definitions are retained. |

Each destroyed engine multiplies nominal travel by 0.7 (two gives 0.49). Boss anchor approach uses the same reduction. Losing all eligible critical engines starts a **0.8-second crash**: no navigation, attacks, shields, targeting or projectile damage; wave ownership remains live until completion. Fade/shrink honors Reduced motion. Normal `Drone.die()` then removes the actor and pays its existing bounty once. Restart/scene removal discards unfinished temporary crashes; it does not settle rewards. A normal hull kill remains immediate.

An open direct core grants at least 2.5× damage (boss phase data can raise this to 2.75×/3×). A sealed boss core gets its ordinary configured manual-hull multiplier, rather than an exposure bonus. Destroying the core permanently opens its wreck conduit; shielding can still mitigate the packet. Existing AI phases continue to follow hull HP, including the real phase attack changes and independent siege capacitor. Breaking a gun does not disable an unrelated launch bay or the siege capacitor.

## Presentation and replacement pipeline

Local sparks, electrical arcs, shield collapse, smoke, debris and final explosion reuse the capped G4 pool. Destroyed parts stop their matching rotor/engine/weapon overlay; an atlas-UV scorch mask updates body and articulated armor together. Existing baked propeller/mechanical pixels remain part of the G3 candidate art; this is a charred/stopped module state, not a newly painted dismemberment sheet.

Only the nearest component under the aim point shows a compact name/HP percentage. Cores carry a small cyan/open or gray/sealed marker. Brief messages include ENGINE DISABLED, WEAPON OFFLINE, SHIELD DESTROYED and CRITICAL HIT. Boss telemetry describes the actual seal/window state. Existing manual hit/audio confirmation remains active. Essential mount poses do not inherit cosmetic shake or independent hover; these would otherwise make hitboxes graphics-quality dependent.

`tools/build_component_bindings.py` authors the pixel bindings from existing G3 axes plus reviewed device/core centers. `tools/build_unit_catalog.py` reapplies it after regenerating base regions. Run `python tools/build_asset_manifest.py` afterward. Replacement artwork must preserve or reauthor region/pivot/mount metadata; gameplay code needs no new global coordinates.

Separate approved broken-engine/weapon/core sprites, detached armor fragments and crash frames would improve the current stopped/scorched state. They require external art production/approval; no such newly painted frames are claimed here. Existing G3 raster candidates and licenses remain unchanged.

## Verification

Run `./tests/run_checks.sh`, `./tests/run_m1_balance.sh /tmp/m7-fixed`, and the isolated native component scene:

```sh
DISPLAY=:91 LIBGL_ALWAYS_SOFTWARE=1 FRONTLINE_CAPTURE_SCENE=res://tests/component_capture.tscn \
  ./tests/run_graphics_profile.sh /tmp/m7-native
# Use an available real display instead of :91 outside the cloud fixture.
DISPLAY=:91 LIBGL_ALWAYS_SOFTWARE=1 ./tests/run_graphics_profile.sh /tmp/m7-profile --component-stress
```

Keep native capture runners sequential. Test fixtures disclose staged mission access, poses and assisted aim intentions; runtime input never inherits their pilot. See [M7 measured validation and limitations](m7/VALIDATION.md). Physical Android precision, touch latency, thermal performance, audible cues and human balance require device/playtest work.

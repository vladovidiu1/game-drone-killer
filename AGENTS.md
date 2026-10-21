# Project conventions

- Use Godot 4.6 stable, GDScript only for runtime code, and the Compatibility renderer. No proprietary plugins, hosted services, or paid assets.
- Keep the game offline and Android-first. Preserve landscape, 1280×720 reference layout, safe-area handling, mouse testing and independent touch-pointer ownership.
- Use the existing checkout; tasks already have isolated environments. Do not create worktrees unless explicitly requested.
- Runtime service autoload order matters: SaveManager, CampaignManager, EconomyManager, AudioManager, RewardedAdsManager.
- Keep tunable mission, enemy, and turret combat definitions in `data/definitions.json`; M3 currency values and costs live in `data/economy.json`. Keep campaign credits separate from temporary battle supply.
- Use typed GDScript where concrete types are known, reusable scenes/Controls and signals. Keep battle rendering in `battle_view.gd`; do not put campaign persistence inside enemies.
- Treat `main.gd` as navigation/UI composition. Split screen builders into dedicated components when subsequent features make them larger.
- Migrations must preserve existing permanent upgrades. Replaying a completed mission must not advance the frontline beyond that mission. Defeat cannot cross the chapter checkpoint floor.
- Keep `.gd.uid` files. Do not commit `.godot/`, player saves, export artifacts, keys or SDK caches.
- Run `./tests/run_checks.sh` after runtime changes. It isolates user data and rejects engine errors in addition to nonzero exits. Extend meaningful behavioral checks when changing game rules.
- Never describe headless validation as graphical, multitouch hardware, Android export or performance verification. Document those separately.

- The primary PlayerTurret is separate from placement slots. Never add automatic targeting or firing to it without an explicit accessibility setting; input intentions belong in `player_input.gd`.
- Manual rounds are straight swept-collision shots; secondary rounds retain their existing homing/splash rules. Consume an impact before applying damage and use the shared enemy reward lifecycle.
- Keep player-cannon stats in `player_cannon` in the JSON catalog. All reload, recoil and ammunition timing uses battle simulation delta; pause/focus loss must clear input ownership and firing sources.

- Campaign schema is version 3. Preserve v1/v2 migration and validated `.bak` recovery. Settings remain independent of campaign reset. Validate types before converting untrusted JSON.
- Results require the matching persisted deployment token. Rewards, mission records, token consumption and territorial state must be one saved transaction; stale/duplicate results must do nothing.
- Defeat gives no reward and retreats the current frontline by one, bounded by the highest secured floor. Floors are 1 initially and completed missions 5, 10, 15 and 20 (never 6/11/16/21). Highest reached and permanent upgrades never decrease on defeat.
- Mission IDs 1–25 are playable. Enemy abilities and boss phases are shared through `enemy_brain.gd`; only data varies between territories. Optional `campaign_complete` extends schema v3 and must be validated against a mission 25 victory record. Gate frontline deployment by the current frontline, not highest-ever reach. M8 additionally permits optional replay of completed records after retreat; neither replay victories nor replay defeats may move the frontline. Only `frontline` deployments follow advance/retreat/checkpoint rules.
- Run the campaign and recovery suites along with combat checks. Distinguish actual full-mission combat validation from synthetic future-checkpoint rule fixtures.

## GitHub publication preference

- The user has explicitly authorized publishing this project to `vladovidiu1/game-drone-killer` and requests that future requested changes also be published to GitHub after appropriate validation.
- Commit the requested project changes and push them to `main` when complete. Use the platform's existing Git authentication. Do not ask for publication confirmation again within this authorized scope.
- Fetch and inspect remote updates before publishing. Preserve concurrent work; never force-push or overwrite remote history. If direct publication is blocked by access or branch rules, report the exact blocker and preserve the completed local changes.

- War Credits remain `state.credits`; Battle Credits remain `battle.credits`. Research/unlock/objective effects and requirements are in `data/progression.json`; their prices/rewards are in `data/economy.json`. Keep purchased legacy `damage_level` bonuses when migrating; new primary damage research is a separate +5% per level.
- Permanent research purchases must validate the expected current level and persist/rollback the debit and grant together. Objectives belong inside the mission-result transaction; never re-award a claimed objective.
- Research is applied before battle starts. Snapshot shot ammunition/critical damage at firing time, never refill magazines when switching ammunition, and retain autonomous secondary targeting.
- Tactical build mode uses a single panel at 0.25x effective simulation speed; closing or pausing restores standardized normal speed. Every cooldown/status/projectile/reload consumes the same simulated delta. Touch swipes inside a shop must scroll without purchasing.
- Run `tests/research.tscn` and its fresh-process verification in addition to the existing full suite. Physical Android performance/audio remain separate validation work.

## Visual foundation

- Follow `VISUAL_STYLE.md`. Keep art bindings/regions/pivots in `assets/visual_catalog.json` and inventory/provenance in `assets/manifest.json`; regenerate the latter with `python tools/build_asset_manifest.py` after asset changes.
- `scripts/visual/unit_visual.gd` receives presentation state only. Do not move damage, targeting, input ownership or timers into artwork code. Visual state must never alter collision or stat tuning.
- Keep Compatibility-safe shaders, local fonts and license notices, PNG transparency and tracked `.import` settings. Review actual rendered output; do not call a headless dummy-renderer run visual validation.
- Preserve uniform battlefield scale across aspect ratios and native safe-area UI. Run visual-resource checks with the full suite; use `tests/visual_capture.tscn` with a real display/renderer and isolated data for native captures.
- G3 replaces shared drone/boss silhouettes and interim SVG heads with dedicated original raster bindings. The old G1 sources are reference-only. Document generated-candidate status and any remaining art refinements honestly.

## Environment presentation

- G2 visual assignments live in `assets/environment/library.json`; keep them separate from mission gameplay conditions and geometry. Follow `docs/ENVIRONMENTS.md`.
- Terrain bindings remain in `assets/visual_catalog.json`. Load terrain per battle lifetime, bypassing the permanent global texture cache; never preload every map into the deployed mission.
- Clip decor/atmosphere to `(0,88,955,560)` beneath actors and HUD; keep Controls mouse-ignoring. Enforce slot/path/base/water exclusions for tall props.
- All environment animation consumes `battle_view.tick` simulation time. Preserve reduced-effects settings validation and the static-terrain fallback.
- Run environment tests/fresh-process settings verification with the full suite, and inspect real native captures after environment changes. Gallery PNGs are documentation, excluded from Godot import.

## G3 unit presentation

- Follow `docs/UNIT_VISUALS.md`. All animation receives the shared simulated delta through `combat_visuals.gd`/`battle_view.tick`; keep UnitVisual free of targeting, damage, firing, save writes and independent processing.
- Preserve the five G3 atlases' 768px mobile import limit. Catalog regions/pivots use imported coordinates; `source_region` retains the original 1536×1024 coordinates. Rebuild with `tools/build_unit_catalog.py` and regenerate the manifest after source changes.
- Fixed bearings, rotating heads, sliding primary barrels and boss armor are visual-only. Keep the actual manual angle, projectile origin/collision, boss weakpoint and controller positions unchanged.
- Detached destruction snapshots have no enemy references/physics and stay capped at 12. Terminal boss outros start only after the existing result transaction succeeds; they must never re-award outcomes or resume combat. Preserve Continue/Esc/Android Back skip.
- Run `tests/unit_visuals.tscn` through the full runner, and `tests/run_native_capture.sh` with a real display for all-archetype render checks. Label staged visual fixtures; distinguish them from full campaign combat and Android performance measurements.

## G4 combat presentation

- Follow `docs/COMBAT_VFX.md`. Compose the clipped `scenes/effects/combat_effects.tscn` through BattleView. Keep quality profiles in `assets/effects/quality.json`, separate from damage/stat data. Export the JSON.
- Reuse the fixed 192-slot pool, per-preset emission/category limits and independent explosion-density cap. No per-particle nodes, gameplay RNG, physics or enemy/projectile references. Coalesce repeated sustained-damage hit cues.
- Advance all world VFX with the shared simulated delta; the existing terminal outro may advance detached presentation after a successful result save. UI victory sweeps never write outcomes.
- Shake presentation artwork only, never Battle, controllers, projectile paths, camera/input transforms, field clip or HUD. Respect Reduced effects/Reduced motion and individual layer switches. Preserve schema-v3 defaults, strict type validation and fresh-process persistence.
- Run the full runner and native `tests/run_effect_capture.sh` after VFX changes. Distinguish labeled shot/death/stress fixtures from normal-budget wave captures and from unavailable Android hardware benchmarks.

## G5 interface and strategic map

- Follow `docs/UI_DESIGN.md`. Keep Main as navigation; use the campaign/results scenes and reusable UI components. Existing economy/deployment/save methods remain authoritative. Never grant progression from animation.
- Strategic cartography/positions/polygons live in `assets/ui/asteria_strategy.svg` and `campaign_layout.json`, generated by `tools/build_strategic_map.py`. Keep them separate from mission gameplay geometry. Include `assets/ui/*.json` in exports.
- Preserve bounded map pan, focus reveal, native 190×64 operation buttons and drag-release click suppression. Receipt animation is UI-only, once per session, keyed by persisted result token.
- Keep FIRE/reload/ammo/abilities reachable at short heights and preserve independent touch ownership. UI feedback must not move hitboxes or stack unbounded tweens. Honor Reduced motion/effects.
- Mission UI previews own terrain frames locally; never fill the permanent texture cache by browsing operations. Static weapon portraits have no simulation controllers.
- Run the full suite plus `tests/run_ui_capture.sh` with a real display. Check all four documented logical layouts, real purchases, active ability labels, map gating, results and native touch/mouse input. Physical Android validation is separate.

## G6 quality policy and audit

- Follow `GRAPHICS_AUDIT.md` and `ANDROID_VISUAL_TEST_CHECKLIST.md`. All presentation quality uses `scripts/visual/graphics_profile.gd` and `assets/effects/quality.json`, reusing validated schema-v3 `effects_quality`; do not add a competing graphics setting or couple quality to combat/input/RNG.
- Keep native HUD z=10 and saved terminal outro z=20; world decoration must not cover interactive controls. Mission identity belongs in the native footer, away from enemy entry lanes.
- Low removes extra runtime fake shadows/animated weather, not baked asset shading or texture resolution. Uniform caching must update body and articulated armor together on damage/cloak/suppression recovery. Never throttle manual aiming or simulation to the overlay redraw rate.
- `python tools/build_asset_manifest.py` regenerates both `assets/manifest.json` and root `ASSET_MANIFEST.md`. Preserve generated-candidate/reference-only status and font licenses.
- Run full checks including 75 mission/preset combinations, fresh-process graphics persistence and existing balance reports. `tests/run_graphics_profile.sh` requires a native display, records reproducible stress metrics, and must never be described as an Android FPS benchmark. Keep native capture runners sequential to avoid focus-loss pause interference.


## M1 combat balance

- All missions run at normal speed; no `game_speed`, selector or global Engine.time_scale modification. Only temporary build UI uses 0.25x, and closing/pausing always returns to 1.0.
- Central movement/tracking/formation targets live in `data/definitions.json` (`balance`, enemy AI mobility and turret fields). `tools/rebalance_m1.py` rebuilds this tuning from the frozen G6 source in `docs/m1/baseline_definitions.json`; do not overwrite later manual balance changes by running it blindly.
- Guard stale/freed targets before typed function calls. Acquisition, bounded turn rate, firing alignment and stable threat switching are real deterministic limitations. Do not add random automatic misses or forced drone survival.
- Burst movement uses an integral so partial disable/slow windows and simulation-step partitioning preserve travel distance. Keep manual aiming/fire exclusively input driven.
- Run mechanics/full regression plus `tests/run_m1_balance.sh` for balance changes. Compare fixed-seed records and the earned-research connected campaign; document fixture research, funds, limitations and human/device testing separately. See `docs/M1_BALANCE.md`.


## M2 weapon research

- Follow `docs/WEAPON_RESEARCH.md`. Extend the existing ammo/projectile and EconomyManager/save paths, never create duplicate combat systems. Catalog prerequisites/tier steps/specializations are in `data/progression.json`; M3 costs are in `data/economy.json`; enemy resistances in `data/definitions.json`.
- Schema v3 gains additive `weapon_schema=1`, validated ordered 1–3 `ammo_loadout` and `turret_specializations`; preserve v1/v2/v3 migrations, legacy AP/HE purchases, state tokens and atomic rollback/backup recovery.
- Snapshot ammo tiers/loadout and specialization at deployment, payload/criticals at firing. Shared magazine units and rail cooldown survive switching; switching never resets heat/recoil or bypasses reload. Only equipped slots appear as enabled combat chips.
- Rail is a straight swept projectile with bounded distinct actor IDs/penetration and per-hit falloff; mark hit ownership before damage. Include the direct collision target in its own splash even when its center lies outside a small radius. EMP uses electrical pulses, not fireball blast art.
- AP bypasses ordinary armor/shields; automatic armor/anti-shield branches use partial traits. Status duration/strength respects clamped enemy resistance and does not scale with critical damage. Keep boss core/phase rules intact.
- Run the full runner with weapon-research/fresh-process suites. Native `tests/weapon_capture.tscn` uses the existing isolated graphics wrapper; injected confirmation touches must target the dialog's own viewport. Check all five tabs/long research copy on short/wide/tablet layouts. Physical Android/device difficulty validation remains separate.
- `tools/build_projectile_vectors.py` owns the six authored SVG utility illustrations. Regenerate both manifests after asset changes. Keep fixture screenshots under `.gdignore`; never describe authored utility vectors as approved painted production art.


## M3 economy

- Follow `ECONOMY_BALANCE.md`. `economy_config.gd` hydrates both existing catalogs from `data/economy.json`; do not add duplicate prices/rewards to combat or progression data. All reward, construction, ability, research, unlock and objective values, support/replay percentages and temporary upgrade price scaling belong there.
- First clears pay the configured reward; all later clears/reconquests pay integer-floor 15%. Existing victories and implicit cleared territory below highest-ever reached prevent repeat first-clear bonuses on old saves. Preserve saved balances, bought levels and schema-v3 transactions.
- BC stays temporary and never converts to WC. Restart grants neither partial bounties nor victory income. Enemy payout ownership is consumed before credit/effects; tokens and objective claims remain atomic with the result save.
- Run economy/fresh-process suites, the earned-budget connected campaign and fixed-policy comparison after tuning. Record actual budgets/purchases, distinguish accounting fixtures from combat, and do not claim human or Android balance from assisted simulations. Regenerate measured tables with `python tools/report_m3_economy.py` after reports are current.


## M4 optional rewarded ads

- Follow `docs/REWARDED_ADS.md`. Offline campaign balance remains M3; never require ads. Reward amounts/limits/cooldown stay in `data/economy.json.rewarded_ads`; native test IDs/configuration stay in `data/advertising.json`.
- Only the current presented session's earned callback may create an ad reward. Closing, resuming, failed load/presentation, timeout and partial/restarted ads never grant credit. Retain presentation ownership until dismissal even after an earned event and with zero cooldown.
- Preserve additive v3 `ad_campaign_id` and `ad_receipts`. Journal intent/quota in installation-wide `user://rewarded_ads.json`, credit+receipt in one campaign save, then finalize the journal. Recovery must never double-credit or fund a replacement campaign. Corrupt ad history blocks ads without resetting quota or blocking offline gameplay.
- The editor simulator and test injection require editor + debug + non-Android and an explicit opt-in. Do not enable mock rewards in exported builds. The conditional native adapter is strict Android debug/official-test only; production advertising remains disabled pending actual SDK/consent/audience/privacy/SSV work.
- Use pinned Poing v5.1.0 documented APIs, never another plugin's method names. Do not initialize/load before fresh required UMP handling. Unknown/underage/mixed audiences remain ineligible until implemented. Sample Google App ID cannot host publisher-configured consent messages; do not bypass missing consent forms.
- Run full regression including rewarded/fresh-process and AdMob boundary-contract test-double suites. Use real display wrappers for native ad-offer/cancel/saved UI captures. Distinguish test doubles/editor callbacks from real SDK/test-ad/Android evidence. Local clock/file protections are best effort, not server-authoritative.

## M5 tactical attacks

- Follow `docs/TACTICAL_DIRECTOR.md`. Keep sector geometry/base budgets in mission `approaches`, and selection weights, threat costs, chapter curves, warning and support caps in `data/tactical_director.json`. Do not rerun old M1 catalog generators over M5 geometry.
- Freeze plans once at intermission start. Radar counts must describe the actual directed entries; legacy formation routing must not override them. Respect the minimum warning on early launch and the shared pause/build delta.
- Coverage is approximate placement/range/DPS only, sampled once per plan. Keep adaptation/history bonuses capped and probabilistic; never inspect live player intentions or force survivors.
- Preserve real enemy abilities and projectile/target/damage lifecycle. Directed supports inherit wave ownership and share its finite reserve, including nested carriers. Keep economy and campaign result transactions authoritative.
- Run full regression, `tests/run_m1_balance.sh`, and native `tests/run_tactical_capture.sh` for tactical changes. Record losses and bounded real retreat/reconquest in the earned-budget campaign; do not erase defeats, inject funds, or describe an assisted policy as human/device balance. Keep native capture runners sequential.

## M6 strategic placement

- Follow `docs/STRATEGIC_PLACEMENT.md`. Keep per-slot metadata in mission `emplacements`, weapon total `traverse_degrees` separate from existing alignment tolerance, non-monetary tuning in `data/placement.json`, and movement price percentage in `data/economy.json`.
- Reuse `covers_point` geometry for acquisition/continued locks, overlays and reconnaissance. Range must include research, temporary level, visibility and emplacement bonus. Presentation never changes targeting or damage.
- Redeploy the same actor: retain occupied source and reserve destination until one atomic transfer. Debit/refund escrow once; block in-flight upgrades/concurrent moves/reserved construction. Cancel safely on outcome, scene exit and invalid actor. Never convert temporary refunds into bounty/WC.
- Keep live first-wave PREPARE waiting for explicit launch; later waves remain timed and radar minimum still applies. Standalone scheduler fixtures retain their legacy default. Native confirmations must preserve independent aim/FIRE touch ownership.
- Run placement mechanics, full regression, fixed-policy balance and native placement/UI captures. Record fixture credits/research separately from earned-budget connected campaigns. Keep capture runners sequential and document physical Android limitations.


## M7 drone components

- Follow `docs/DRONE_COMPONENTS.md`. Keep staged loadouts/HP/armor/effects in `data/drone_components.json` and imported-pixel mounts in the visual catalog. `tools/build_unit_catalog.py` reapplies the M7 mount generator. Never use global weakpoint coordinates.
- Attach local component nodes to the real body/articulated armor. The simulation rig owns essential pose/exposure/crash clocks; independent hover/shake/preset redraw must not alter collision. Presentation may fade/shrink untargetable falling artwork only.
- Direct manual rays select one surface component or hull. Preserve explicit configured hull spill, center-based quarter-strength blast packets and one distinct-actor rail ledger. AP/critical/status routing must not be applied twice. Automatic direct attacks retain body targeting.
- Component destruction pays no bounty. Consume part ownership before effects. Critical-engine loss delays the ordinary `Drone.die()` by the configured crash duration; keep it live for wave completion, stop attacks/shields/navigation and pay the existing reward once. Temporary components never write campaign saves.
- Run component/full regression, fixed-policy combat comparisons, the native component scene through the isolated graphics wrapper, all-archetype/VFX captures and relevant UI regression. Record actual failures/losses, staged fixture state and Android hardware limits; do not weaken earned-campaign assertions to hide balance regressions.

## M8 mission performance

- Follow `docs/MISSION_PERFORMANCE.md`. Keep thresholds/objectives/score tuning in `data/mission_performance.json`, currency milestones in `data/economy.json`. Battle owns attempt counters; pure evaluation never writes saves or changes damage.
- One launched manual shell contributes at most one successful/critical round, including splash and rail. Count clamped effective hull damage by source, not raw overkill or component HP; preserve delayed engine-crash source and ordinary bounty ownership.
- Preserve additive v3 `performance_schema`, historical first clears and claimed numeric tiers after JSON reload. Bests, bonus claims, credits and consumed deployment token are one rollback-safe result transaction. UI animations must never grant rewards.
- Persist explicit active-run `frontline`/`replay` mode. Only the former may change territory/floors; completed optional replays protect the frontline even on failure. Current contested reconquest remains available separately.
- Run performance/fresh-process suites plus full regression and fixed-policy comparisons. Distinguish accounting witnesses from actual combat and human three-star feasibility.

## P1 first-mission guidance

- Follow `docs/FIRST_MISSION_TUTORIAL.md`. Reuse Battle, PlayerInput/PlayerTurret, actual training enemies/projectiles and the real turret shop. Tutorial data lives in `data/tutorial.json`; controller and overlay are separate scenes. Never auto-aim/fire the primary for guidance.
- Guided rehearsal pauses ordinary waves and excludes training from bounty, performance and campaign progression. Practice supply/turrets/ammo are discarded before fresh ordinary Mission 1 under the same persisted run token. Settings replay has no token/result/reward.
- Settings `tutorial_status` is independent of campaign reset. Persist completed/skipped once; failed settings writes must leave guidance retryable. Accept earlier valid actions, share pause/build simulation delta, preserve independent touch IDs and clean up overlays/held input.
- Run tutorial/fresh-process suites and native tutorial capture through the existing isolated graphics wrapper. Native wrappers run sequentially. Injected touch, scripted duration and desktop rendering never establish physical Android behavior or two-minute human pacing.

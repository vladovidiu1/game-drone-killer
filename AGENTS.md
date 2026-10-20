# Project conventions

- Use Godot 4.6 stable, GDScript only for runtime code, and the Compatibility renderer. No proprietary plugins, hosted services, or paid assets.
- Keep the game offline and Android-first. Preserve landscape, 1280×720 reference layout, safe-area handling, mouse testing and independent touch-pointer ownership.
- Use the existing checkout; tasks already have isolated environments. Do not create worktrees unless explicitly requested.
- Runtime service autoload order matters: SaveManager, CampaignManager, EconomyManager, AudioManager.
- Keep tunable mission, enemy, and turret definitions in `data/definitions.json`. Keep campaign credits separate from temporary battle supply.
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
- Mission IDs 1–25 are playable. Enemy abilities and boss phases are shared through `enemy_brain.gd`; only data varies between territories. Optional `campaign_complete` extends schema v3 and must be validated against a mission 25 victory record. Gate deployment by current frontline, not highest-ever reach. Replay wins cannot advance beyond their territory; replay defeats obey the standard retreat rule.
- Run the campaign and recovery suites along with combat checks. Distinguish actual full-mission combat validation from synthetic future-checkpoint rule fixtures.

## GitHub publication preference

- The user has explicitly authorized publishing this project to `vladovidiu1/game-drone-killer` and requests that future requested changes also be published to GitHub after appropriate validation.
- Commit the requested project changes and push them to `main` when complete. Use the platform's existing Git authentication. Do not ask for publication confirmation again within this authorized scope.
- Fetch and inspect remote updates before publishing. Preserve concurrent work; never force-push or overwrite remote history. If direct publication is blocked by access or branch rules, report the exact blocker and preserve the completed local changes.

- War Credits remain `state.credits`; Battle Credits remain `battle.credits`. Research/unlocks/objectives are in `data/progression.json`. Keep purchased legacy `damage_level` bonuses when migrating; new primary damage research is a separate +5% per level.
- Permanent research purchases must validate the expected current level and persist/rollback the debit and grant together. Objectives belong inside the mission-result transaction; never re-award a claimed objective.
- Research is applied before battle starts. Snapshot shot ammunition/critical damage at firing time, never refill magazines when switching ammunition, and retain autonomous secondary targeting.
- Tactical build mode uses a single panel at 0.25x effective simulation speed; closing or pausing restores the prior chosen speed. Every cooldown/status/projectile/reload consumes the same simulated delta. Touch swipes inside a shop must scroll without purchasing.
- Run `tests/research.tscn` and its fresh-process verification in addition to the existing full suite. Physical Android performance/audio remain separate validation work.

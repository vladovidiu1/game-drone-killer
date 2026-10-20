# Native validation and assisted-play results

This is the Task 5 combat baseline. Graphics G1 validation and native captures are recorded in [VISUAL_VALIDATION.md](VISUAL_VALIDATION.md).

Validated with Godot 4.6.3 stable, Compatibility project, on 2026-10-20. `./tests/run_checks.sh` completed successfully with native import/startup and **4420 assertions, zero failures**. The runner rejected script/engine errors and ObjectDB leak warnings.

Catalog SHA-256: `cf9c3d814b3063a4b132e76be7b5084e75e8585b91bae493608503f9fb749716`.

| Suite | Assertions |
| --- | --- |
| COMBAT | 40 |
| HYBRID | 55 |
| SMOKE | 42 |
| SMOKE | 4 |
| SAVE/RULES | 38 |
| CAMPAIGN | 43 |
| CAMPAIGN | 5 |
| RESEARCH | 186 |
| RESEARCH | 4 |
| CATALOG | 3689 |
| ENEMY AI | 88 |
| FULL CAMPAIGN | 184 |
| FULL CAMPAIGN | 31 |
| FULL CAMPAIGN | 11 |

## Connected campaign

The assisted commander earned research through mission rewards/objectives, spent ordinary starting funds/bounties on turrets/upgrades/repairs and fired actual projectiles through the input adapter. All 25 deployments and settlements were linked by the persisted frontline/token service. There were no injected combat wins, HP boosts or free battle/research funds. Normal intermissions were allowed to elapse at 1x simulation time. First-clear durations ranged from **189.8 to 308.7 seconds**. Early-wave starts, deliberate waiting, aim accuracy and build time affect human duration.

| Mission | Seconds | Base HP | Kills | Manual hits | Core hits | Enemy actions | Support spawns |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 01. Outpost Alpha | 189.8 | 1000 | 51 | 0 | 0 | 0 | 0 |
| 02. Red Hill Village | 233.0 | 1000 | 63 | 0 | 0 | 0 | 0 |
| 03. East Supply Depot | 291.7 | 1000 | 97 | 0 | 0 | 0 | 0 |
| 04. Broken Bridge | 195.0 | 1000 | 68 | 4 | 0 | 0 | 0 |
| 05. Greyford | 198.6 | 1000 | 66 | 30 | 21 | 1 | 2 |
| 06. North Power Station | 231.6 | 1000 | 99 | 1 | 0 | 0 | 0 |
| 07. Riverside District | 240.4 | 1100 | 108 | 2 | 0 | 0 | 0 |
| 08. Iron Highway | 247.7 | 1100 | 115 | 0 | 0 | 0 | 0 |
| 09. Falcon Airbase | 231.2 | 1200 | 101 | 7 | 0 | 0 | 0 |
| 10. Metro Asteria | 235.6 | 1200 | 93 | 42 | 22 | 1 | 0 |
| 11. Western Ruins | 306.2 | 1200 | 180 | 11 | 0 | 0 | 0 |
| 12. Liberation Road | 283.3 | 1200 | 164 | 8 | 0 | 0 | 0 |
| 13. Black Ridge | 297.2 | 1300 | 172 | 62 | 0 | 0 | 0 |
| 14. Border Fortress | 304.0 | 1300 | 180 | 6 | 0 | 0 | 0 |
| 15. The Last Border | 279.4 | 1275 | 144 | 38 | 23 | 1 | 0 |
| 16. Varkon Frontier | 302.1 | 1300 | 215 | 4 | 0 | 2 | 0 |
| 17. Steel Valley | 308.7 | 1400 | 223 | 6 | 0 | 1 | 0 |
| 18. Drone Assembly Plant | 291.3 | 1400 | 207 | 38 | 0 | 1 | 0 |
| 19. Red Harbor | 299.5 | 1400 | 215 | 34 | 0 | 1 | 0 |
| 20. Industrial Citadel | 299.6 | 1360 | 196 | 50 | 25 | 1 | 2 |
| 21. Deadlands | 281.3 | 1400 | 239 | 22 | 0 | 0 | 0 |
| 22. Varkon Defense Ring | 296.3 | 1500 | 247 | 24 | 0 | 0 | 0 |
| 23. Central Command | 299.8 | 1500 | 255 | 13 | 0 | 0 | 0 |
| 24. Capital Siege | 279.8 | 1500 | 239 | 12 | 0 | 1 | 0 |
| 25. The Hive Core | 290.7 | 1475 | 216 | 72 | 29 | 2 | 0 |

All five bosses executed abilities and received real precision core hits. The test subsequently lost mission 25 undefended, retreated to 24 with research intact, reconquered 24/25 and restored liberation. A fresh process verified all 25 mission victory records, controlled territory 25, the ending flag and secured floors `[1,5,10,15,20]`. Duplicate results were rejected after every deployment.

## Endgame comparison

These isolated fights restored the legitimately earned final research snapshot between runs. Both limited strategies could still buy research-supported repairs from battle funds.

| Strategy | Result | Seconds | Kills | Manual shots | Enemy actions |
| --- | --- | --- | --- | --- | --- |
| hybrid | victory | 290.7 | 216 | 107 | 2 |
| automatic | defeat | 354.2 | 224 | 0 | 13 |
| manual_only | defeat | 160.6 | 42 | 300 | 0 |

The automatic-only commander reached the boss but lost to its escalating siege pressure; the primary-only commander lost to the ordinary formations. This is evidence for the combined endgame strategy under this particular bot, equipment and build recipe. It is not proof that no other strategy can win.

## Interpretation and limitations

This is a completion and regression baseline, not a claim of commercial balance. The bot has accurate aim/leading, immediate purchases, deterministic critical RNG and timer knowledge. It leaves many early drones to automatic defenses; several missions finish with no manual hits and most bunkers retain full HP. Opening chapters remain forgiving, and non-boss difficulty needs human tuning.

All 25 missions still need human playtesting for enjoyment and difficulty, especially manual tracking, mobile reload/build decisions and boss telegraph visibility. No graphical session, audible playback, physical Android/multitouch session, APK export, frame-time/60 FPS measurement or device thermal/battery test was performed. Headless simulation timing is not a performance benchmark.

Machine-readable evidence: [campaign_balance.json](campaign_balance.json), [campaign_comparison.json](campaign_comparison.json). The first stores all 25 first clears plus undefended defeat and reconquest; the second stores the two separate comparison fights. Rerun with `FRONTLINE_REPORT_DIR=/tmp/frontline-reports ./tests/run_checks.sh` to retain fresh reports outside the checkout.

# M8 validation — October 21, 2026

Baseline: M7 `f4d1c89166c818f36e877ccfe2e5201c4378358f`. Godot **4.6.3 stable**, Compatibility renderer. Implementation accompanies P1 without replacing existing combat/campaign systems. See [rules/counter definitions/objectives](../MISSION_PERFORMANCE.md), [machine-readable validation](validation.json) and [full acceptance log](acceptance.log).

## Import and regression

`FRONTLINE_REPORT_DIR=/tmp/m8-p1-final ./tests/run_checks.sh` passes **75,284 assertions in 38 suite invocations, zero failures**, plus editor import/project startup. No script/engine errors or leaked-object warnings. The focused performance rerun is also clean ([log](performance_focused.log)); the final independent import is [here](final_import.log).

The M8 suites contribute **163 main + 6 fresh-process checks**. [Main scenario rows](performance_scenarios.json). They cover:

- Low-HP victory, exact 60% and 85% boundaries, 85% with failed secondary, defeat zero, configurable per-mission overrides and malformed/clamped metrics.
- All 25 objective definitions have an explicit rule witness, and required component types/counts exist in their actual configured waves. This checks feasibility rather than inventing unavailable radar/convoy systems.
- Real projectile misses, explosive multi-kills and rail multi-target impacts: one successful-shell accuracy credit, clamped manual/automatic hull damage, once-only kill ownership and critical-round accounting. A core-to-body rail sequence cannot retain precision feedback on later hits.
- Real Heavy engine crashes preserve the triggering manual source, attribute remaining hull damage at actual death, and pay one existing bounty. Parts do not create a second reward. Real mounted sectors, breach versus barrage, and final-wave damage after repair use actual actors/events.
- Better/worse replays, zero-star failures preserving personal bests, coherent highest-score snapshot, one-time 2/3-star bonuses, duplicate/stale/restarted callbacks and failed-write rollback/retry.
- Optional replay victory/defeat protects frontline/checkpoints, including a cleared territory beyond the retreated line and an explicit replay on a cleared contested frontline. Actual frontline defeat/reconquest still retreats/advances and respects secured floors.
- v1/v2/v3 save validation and implicit historical clears preserve existing balances/research; unknown historical stats gain only a completion star. Fresh-process reload retains claimed bonuses/objective history/bests and cannot regain a first clear or milestone.

An initial fresh-process test found that JSON-parsed numeric milestone tiers could fail an integer Array membership comparison. Canonical numeric validation now retains both claims after disk reload. The focused and complete runs above are the successful post-fix results.

## Actual earned-budget campaign

[All combat rows](campaign_balance.json) record the assisted campaign conquering all 25 missions in **33 deployments**, with **one loss at mission 12 and three at mission 16**, followed by real retreat/reconquest. No injected WC/BC, synthetic victory, advertisement or removed defeat assertion. At first completion it has earned **9,256 WC**, including **400 one-time star WC**, spent **8,455**, and retains **801**.

A deliberate undefended mission-25 frontline defeat and actual 24/25 recovery bring the total to **36 deployments**, **9,427 WC income**, **9,130 spent**, bank **297**. Best mission stars total **59/75**. The earned-endgame [comparison](campaign_comparison.json) loses mission 25 with both automatic-only and manual-only play; real hybrid support remains relevant.

These outcomes differ from M7's 39 deployments before first completion because new bounded star income changes the pilot's earned research purchases. No enemy/turret HP, movement, damage, prices, waves or paths were retuned. Mission 16 still causes repeated losses under this body/core pilot; it remains a difficulty warning, not evidence of finished human balance.

[Fixed-policy comparison](fixed_policy_balance.json), [log](fixed_policy.log): **55 simulations, zero unfinished**. Research tiers are explicit fixtures, funds ordinary, seeds fixed. Two mixed turrets win **1/25**; two MG and two Cannon each **1/6**; automatic-only **1/6**, manual-only **2/6**, hybrid **6/6** milestone missions. Peak live enemies **23**. These outcomes match M7 and show that ordinary combat without altered earned research keeps its behavior. Assisted input is test infrastructure, never a runtime auto-aim feature or a human win-rate claim.

## Native UI and gameplay

The combined P1/M8 scene runs actual guided input, then a real five-wave normal-budget Mission-1 victory with **95% HP, 60 kills, 23 manual kills, 85/159 successful primary rounds, three stars and 125 WC**. That single saved receipt is reused for additional layout screenshots, not re-awarded.

Native X11/OpenGL Compatibility/llvmpipe validation passes **118 assertions and 41 captures**. Additional UI/unit/VFX native regressions pass with 36/27/36 captures. [P1 validation and full native log/metrics](../p1/VALIDATION.md). Four logical sizes: 1280×720, 1600×720, 1280×600 and 1024×768. Representative unedited frames inspected:

| Frame | Evidence |
| --- | --- |
| [Actual Mission-1 result](native/actual_m1_stars.png) | Three stars, real damage/accuracy/kill counters and bounded first-clear/milestone receipt. |
| [Tablet results](native/ratings_1024x768.png) | Stars, reward and real replay/continue buttons; detailed stats scroll within the body. |
| [Short-screen briefing](native/star_requirements_1280x600.png) | Star thresholds/secondary shown immediately below preview; Start Replay and Back remain reachable. |
| [Campaign stars](native/stars_map_1280x720.png) | Best node glyphs and collected campaign total; normal territorial colors retained. |

[Capture provenance/hashes](native/provenance.json). Star reveal takes about 0.65 seconds and never locks buttons; Reduced motion shows immediately. No new raster artwork is required; vector star glyphs use the existing theme. Existing candidate production-art limitations remain.

## Assumptions and unverified scenarios

The 60%/85% thresholds and 25 secondary goals are initial tuning. A maximum of 625 one-time WC is deliberately bounded; M3 prices, 15% repeat victories and zero defeat/restart income remain. Historical victories receive one star without fabricated HP/accuracy/time. Damage statistics measure effective hull loss; separate component HP and absorbed shield energy are not additional hull damage. Time is simulated active/preparation time, not wall time.

Rule witnesses and the 59-star assisted campaign do not prove three-star human achievement on every mission, particularly precision-engine, high-health late-wave and shield objectives. Broader seeds, human aim, upgrades/loadout diversity, completion-time scoring and reward purchasing behavior need playtests. No Android APK, physical touch/safe-area/latency/audio or device FPS/thermal result was measured. See the [device checklist](../../ANDROID_VISUAL_TEST_CHECKLIST.md).

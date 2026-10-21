# M5 validation — October 21, 2026

Baseline: `a40211c8b0753d643552640dea895d4ca72af70b` (M4). Godot 4.6.3 stable, Compatibility renderer. Every engine run uses isolated XDG save/config/cache paths. See [implementation and configuration](../TACTICAL_DIRECTOR.md), [acceptance log](acceptance.log) and [machine-readable summary](validation.json).

## Automated evidence

- `FRONTLINE_REPORT_DIR=/tmp/m5-validated ./tests/run_checks.sh`: **68,307 assertions across 32 suite invocations, zero failures**, plus editor import and startup. The runner rejects engine/script errors and leaked-object warnings, including after a zero process exit. Existing migrations, ammunition, critical/status/resistance interactions, input, reload, slow build, pause, economy, rewards, save transactions, research, graphics and all 75 mission/quality combinations remain covered.
- New tactical suite: **58,559 assertions, zero failures**. All 25 layouts, route/spawn bounds, forward/nonzero segments, target destinations, manual interception range, all eight forced patterns against every mission wave, actual route/sector agreement, ceiling/minimum threat, bounty limits, repeated plans, tutorial gates, naturally sampled patterns and capped adaptation/history are checked. Real scheduler emissions cannot override frozen radar paths. Building after preparation cannot change a plan. Warning, pause and 0.25x build time share simulation delta. Finite support reserves, descendant ownership, bounded support positions and terminal defeat logging are exercised.
- [Real A–F pressure fixtures](tactical_scenarios.json): existing fourth-wave data, normal battle starting funds, fixed 1/60 simulation, paid construction/upgrades. A–D use no permanent research and no manual assistance; E/F explicitly use tier-two research and assisted input. They are isolated tactical fixtures, not earned campaign progression. See the table below.
- [Connected campaign](campaign_balance.json): **all 25 territories won in 29 deployments**, including two real defeats (21 and 22), retreat and reconquest. All five bosses execute abilities and take real manual weakpoint hits. No injected funds, advertisements, preliminary currency farming or synthetic victory callbacks. Total WC earned to first completion: **8,787**, including ordinary reconquest rewards/objectives; remaining WC **1,077** after **7,710** spent. Research actually used reaches tier four. The unchanged first-clear/replay price schedule remains authoritative.
- A deliberate undefended final defeat followed by actual 24/25 reconquest brings the connected run to **32 deployments**. Permanent research/checkpoints survive, duplicate results are rejected, and a separate process restores all victory records/frontline. [Endgame comparisons](campaign_comparison.json) retain earned research; automatic-only and manual-only mission 25 both lose.
- [Fixed-policy balance](fixed_policy_balance.json), `./tests/run_m1_balance.sh /tmp/m5-validated-fixed`: **55 full-mission simulations, zero unfinished**. Chapter-tier research is an explicit fixture. Two mixed turrets win only mission 1 in 25 samples; two MG win 1/6, two cannon 0/6. Automatic-only wins 1/6, manual-only 2/6; hybrid wins all six milestones 1/5/10/15/20/25. Maximum observed live actors is 23. This is a deterministic comparison, not a human win rate or performance measurement. [Summary](fixed_policy_summary.json).

### Real placement and seed cases

| Case | Attack / policy | Kills | Breaches | Base HP |
| --- | --- | ---: | ---: | ---: |
| A | West flank; all three defenses east | 1 | 23 | 0 |
| A control | Same seed/funds/types; three defenses west | 4 | 22 | 0 |
| B | Split; three distributed, unupgraded defenses | 4 | 22 | 0 |
| C | Split; two central cannon | 3 | 23 | 0 |
| D | Center armor; two central MG | 2 | 22 | 0 |
| E | West flank; distributed paid upgrades + manual input | 15 | 15 | 475 |
| F, seed 701 | Split; tier-two hybrid | 18 | 16 | 615 |
| F, seed 702 | Elite; same tier-two hybrid | 14 | 16 | 235 |
| F, seed 703 | Swarm; same tier-two hybrid | 17 | 21 | 420 |
| F, seed 704 | Elite; same tier-two hybrid | 15 | 15 | 260 |

The A control reduces western breaches from 17 to 13; both weak configurations still lose. Defeat stops a fixture with some actors potentially unresolved; the JSON records real terminal state rather than pretending all contacts were killed. E combines manual and automatic hits. All four F seeds survive this pressure wave, and repeating seed 701 reproduces its outcome exactly. This small sample supports bounded tactical variation; it cannot prove campaign-wide luck independence or perfect difficulty.

## Native desktop evidence

- `DISPLAY=:91 LIBGL_ALWAYS_SOFTWARE=1 ./tests/run_tactical_capture.sh /tmp/m5-native-final`: **76 checks, zero failures; eight rendered frames**. Real Godot/X11/GLES3 rendering on llvmpipe. Radar/counts/entry arrows and simultaneous manual/automatic combat were captured at 1280×720, 1600×720, 1280×600 and 1024×768. Injected viewport touches hold aim and FIRE concurrently, drag while firing, release both and pause. Radar ignores aiming pointers; combat controls stay inside each viewport. Mission access/tier-two research is staged; actual defenses use ordinary paid battle resources.
- `DISPLAY=:91 LIBGL_ALWAYS_SOFTWARE=1 ./tests/run_ui_capture.sh /tmp/m5-ui-final`: **36 native UI captures, zero failures**. Existing mouse navigation, purchases, results, build/upgrade, reload, ability, pause and responsive layouts remain functional. The fixture now waits out radar before requesting early launch; no behavior assertions are removed. [Log](native/ui_capture.log).
- Captured draw-call counts: **166–167 during preparation; 233–234 during active contacts**, under these specific staged desktop scenes. [Metrics](native/metrics.json) are draw counters, not Android frame times. No stable-60-FPS claim.

Retained, visually inspected examples: [radar preparation](native/radar_1280x720.png), [live flank combat](native/contacts_1280x720.png), [short landscape](native/contacts_1280x600.png), [tablet](native/contacts_1024x768.png). The runners generate all eight frames; four representative PNGs are committed. There are no composited/fake gameplay images.

## Calibration and test-policy changes

[Development observations](calibration_experiments.json) retain unsuccessful experiments. Early unchanged-threat pilots failed at missions 11, 16 or 17; blindly placing an EMP tower was not a universal solution. Shorter flank routes exposed genuine travel-time/coverage weaknesses. Late ceilings were calibrated to 90% / 85%, preserving archetypes/bosses and original HP/weapon/currency stats. These development rows describe their evolving configurations and are not promised to reproduce the final tuning.

The connected pilot buys research for deployed weapons instead of unused unlocks, keeps 90 BC for repair when damaged, and repairs before buying more upgrades. Rather than assuming every tactical seed must be a first-attempt win, it follows **real persisted retreat/reconquest**, with a strict 60-deployment completion bound and 16-deployment final recovery bound. Actual final results are 29 and two respectively. Every territory still requires an ordinary persisted win; boss, checkpoint, duplicate-token, outcome/HP and fresh-process assertions remain. No test converts a defeat to victory or skips a required territory. Campaign UI watchdog increases to 180 seconds and connected campaign to 300 because the real six-second intermissions/recovery add work; the default remains 60 seconds.

## Limits and final polish

No physical Android device, Android export/APK, audible hardware cue, touch latency, thermal/battery profiling or mid-range-device frame-time measurements were available. Injected desktop multitouch is not physical Android testing. Human learning curve, sustained late-chapter play and broader seed/placement distributions still need playtesting, especially mission 21/22 pressure and late warning recognition.

The planner performs coverage/planning only once per intermission; marker redraws are capped at 10 Hz, with one world overlay and one native Control. It adds no particle emitters or per-contact visual nodes. Existing VFX quality/motion settings remain in effect. Support budgets cap production rather than force survivors. These structural bounds are not a substitute for Android profiling.

No new external illustration is required for the radar. Existing generated unit/environment candidates still need the art approval/refinement documented in `GRAPHICS_AUDIT.md`; M5 does not make the game visually production-ready. Recommended next work: human seed sweeps, physical two-thumb/build/reload tests, late-route terrain/art alignment review and representative Android CPU/GPU/frame-pacing measurement.

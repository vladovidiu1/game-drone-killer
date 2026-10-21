# DRONE KILLER: FRONTLINE — M3 economy

M5 adds finite support reserves and retunes late-wave threat allocation without changing currency prices, first-clear/replay rules or saved balances. Historical M3 tables below remain labeled measurements of that revision; current earned-budget progression, including real losses/reconquests, is recorded in [M5 validation](docs/m5/VALIDATION.md).

All currency rewards, prices and price curves live in **`data/economy.json`**. `scripts/core/economy_config.gd` hydrates the existing mission/enemy/turret and progression catalogs so combat, Arsenal, briefings, results and tests see identical values. `definitions.json` retains combat stats, waves and geometry; `progression.json` retains research effects, prerequisites, chapter gates and descriptions. Neither duplicates prices. The historical M1 generator must not restore its frozen pre-M3 economics over current data.

## Battle Credits: tactical supply

Battle Credits exist only in the deployed battle. The free primary cannon, Standard ammunition, reloads, starting supply and retries do not charge War Credits. No ammunition operating fees were introduced. Leaving, losing, restarting or finishing a battle never converts unused BC or kill bounties into WC.

| Enemy | Old bounty | M3 bounty |
| --- | ---: | ---: |
| Scout | 10 | 7 |
| Assault | 20 | 13 |
| Heavy | 60 | 40 |
| Shield / EMP | 30 | 20 |
| Bomber | 40 | 27 |
| Sniper | 35 | 24 |
| Carrier | 50 | 34 |
| Stealth | 25 | 17 |
| Each chapter boss | 180 | 120 |

Support spawned by carriers/bosses gives **50%, rounded down**, of its normal bounty. Only destruction pays; arrival at the base does not. Each actor can pay once, including repeated damage or reward callbacks. Bounties fall roughly 30–35%; enemy health, speed, behavior and wave counts remain unchanged.

Starting BC remains 500 / 550 / 650 for missions 1–3, 650 for 4–5, then 770 / 890 / 1010 / 1130 by chapter. Existing permanent starting-supply research adds 50 BC per level and survives defeat. Mission 1's configured roster pays at most **601 BC** if all 61 drones are destroyed, compared with 890 before M3. Available resources arrive across waves, not at deployment.

| Sink | Price in BC | Decision |
| --- | ---: | --- |
| Machine Gun | 100 | Affordable tracking and light-drone coverage |
| Cannon | 200 | Heavy single impacts; slower target cycle |
| Missile | 350 | Splash against formations; expensive opening |
| Laser | 250 | Consistent beam after permanent unlock |
| EMP Tower | 230 | Slowing support, not a damage substitute |
| Heavy AA | 450 | High-value targets; expensive, slow cycle |
| Temporary turret upgrade | ceil(base price × 0.65 × current level) | +35% damage multiplicatively and +12 range per level; maximum level 3 |
| Emergency Repair | 90 | 250 HP before efficiency research; 30s cooldown |
| EMP Blast | 120 | 2.5s base disruption; 45s cooldown |
| Overclock | 100 | +50% firing for 6s; 40s cooldown |

Construction and ability prices remain unchanged: reduced income already creates pressure. A starting 500 BC buys MG + Cannon with 200 left, or Missile + MG with 50 left. Buying all three starter designs requires 650. Filling every slot and upgrading everything competes with repair/EMP/overclock. Permanent research can change these tradeoffs later, without granting unlimited supply.

## War Credits: permanent development

First-clear rewards are **100 + 20 × (mission index − 1)**: mission 1 = 100, mission 2 = 120, mission 3 = 140, mission 5 = 180, mission 10 = 280, mission 15 = 380, mission 20 = 480, mission 25 = 580. Chapter progression is smooth; bosses no longer pay less than their preceding territories.

Every subsequent victory, including reconquest after retreat, pays **floor(first-clear reward × 15%)**. Mission 1 replay = 15, mission 2 = 18, mission 3 = 21, mission 24 = 84, mission 25 = 87. Replay rewards never increase the frontline beyond that territory. Defeat, abandonment, deployment and restart pay **zero**. No entry fee, loss penalty, repair debt, advertisement requirement or real-money dependency exists.

Two objectives remain automatic, once per campaign: Veteran Commander (five won deployments) = 60 WC; Chapter Secured (checkpoint 5) = 80 WC. Veteran counts full replay victories too, but cannot be claimed twice. First-pass earnings are **8,500 mission WC + 140 objective WC = 8,640 WC**, down from 12,520 (31.0%). The once-only bonus does not create a recurring farming multiplier.

| Through mission | Cumulative first-clear income including eligible objectives |
| --- | ---: |
| 1 | 100 |
| 2 | 220 |
| 3 | 360 |
| 5 | 840 |
| 10 | 2,040 |
| 15 | 3,740 |
| 20 | 5,940 |
| 25 | 8,640 |

## Upgrade prices and choices

Early five-level research retains its previous entry prices (50–100 WC), so a first win can buy one accessible improvement or fund a more expensive unlock later. Later levels increase more steeply: old prices × **1.00 / 1.15 / 1.35 / 1.60 / 1.90**, rounded upward to the next 5 WC. This defines the final explicit arrays in `economy.json`, not a runtime extra multiplier. Changing a price never removes purchased levels.

Examples:

| Research | Level/tier prices, WC | Role |
| --- | --- | --- |
| Primary damage | 60 / 115 / 220 / 385 / 650 | +5% damage per level |
| Starting supply | 100 / 185 / 325 / 545 / 875 | +50 starting BC per level, repeated mission value |
| Base health | 80 / 150 / 260 / 435 / 685 | +100 HP per level; forgives breaches |
| Turret damage | 85 / 160 / 270 / 460 / 745 | +5% across automatic designs |
| Standard ammunition | 60 / 145 / 330 | Improves the free universal projectile |
| AP ammunition tiers | 90 / 205 / 450 | Armor specialization after 180 WC unlock |
| Railgun tiers | 200 / 435 / 870 | Late precision specialization after 800 WC unlock and prerequisites |
| Either turret branch | 120 / 265 / 570 | Three tiers; one equipped branch per turret design |

M2 three-tier price arrays use factors 1.00 / 1.20 / 1.50, rounded up to 5. Unlock prices and chapter/prerequisite gates remain unchanged: for example EMP highest 6, Cryo highest 11, Railgun highest 16 plus prerequisite research. Existing legacy amplifier costs are centralized unchanged at 100 / 175 / 250 / 325 / 400. Its already purchased bonuses remain intact.

Different stats retain distinct roles and tradeoffs: damage does not replace extra magazine capacity, reload, survivability, supply, slowing or armor counters. Buying multiple alternate branches unlocks flexibility, not simultaneous stacked benefits. Maximizing the entire optional tree is deliberately beyond one campaign's budget; it is **not** a completion requirement. The generated [measured report](docs/m3/REPORT.md) lists every actual cost array and total, along with mission earnings and expenditure.

## Expected progression without advertisements

A new commander can keep the full 500 BC opening, shoot manually, buy a 60 WC improvement after mission 1 and retain 40. Winning mission 2 makes 160 available; saving can fund AP or another early improvement. An early 180 WC AP unlock competes with basic research rather than becoming an automatic free purchase. Later missions fund selected level 3–5 upgrades or a projectile specialization. A player can finish without buying any new M2 technology; alternatives remain optional.

Loss streaks preserve bank, purchased research and unlocks; each redeployment restores its ordinary starting BC and full cannon magazine. There is no escalating retry cost or negative balance. Reconquest gives a modest income while recovering territory. If a player wants more development, full replays are available, but restarts and partial kills cannot be cashed out. No ads, paid currency or injected funds are used in the connected validation campaign.

Suggested spending priorities are coverage before maximum turret levels, a reserve for repair or a disruption burst, and focused permanent upgrades rather than buying every alternate design. Use Standard for light targets, AP for armored targets, and tactical abilities where incoming density warrants their supply cost. An EMP turret everywhere is not a universal answer: support still needs damage coverage.

## Transaction and compatibility rules

- Schema remains v3; no reset, balance haircut, unlock removal or research de-leveling. Prices only affect future purchases.
- Per-mission victory records identify prior clears. For old v1 saves without detailed records, any territory below highest-ever reached was necessarily cleared and receives replay rewards. Retreat cannot restore first-clear eligibility. Mission 25 uses its victory record.
- A result needs the current persisted random deployment token. Replacing a deployment invalidates the abandoned token; duplicate/stale callbacks do nothing.
- Currency credit, clear record, objective claims, token consumption and territorial changes are a single persisted transaction. A failed write restores the full prior state and allows one legitimate retry. Purchases similarly debit and grant atomically.
- All runtime currencies, prices and payouts are integers. Insufficient funds reject the operation; invalid saved negative balances clamp to zero. There is no arbitrary currency-grant API outside validated mission/ad reward transactions.
- Loading a valid current save cannot merge its balance with an older clear ledger. Backup recovery rolls back the **whole** snapshot together. Local files are not tamper-proof; manually restoring an older full save restores its older progress and bank together.

## Validation and remaining work

Run `./tests/run_checks.sh` with `FRONTLINE_REPORT_DIR=docs/m3` to preserve reports, `./tests/run_m1_balance.sh docs/m3/fixed_policy` for the 55 fixed-policy comparisons, then `python tools/report_m3_economy.py` to regenerate the measured tables. Isolated XDG directories protect real saves.

`tests/economy.gd` covers all 25 first-clear transactions, repeat callbacks before/after disk reload, repeated full replays, no-ad accounting, moderate earned purchases, nine losses/checkpoint floors, early loss/reconquest, legacy implicit and explicit clear history, insufficient funds, duplicate enemy bounties, restart resets and failed-write rollback. The separate fresh-process invocation verifies durable history and exact balances.

`tests/full_campaign.gd` verifies a connected real-combat path with earned money and real purchases, plus actual defeat and reduced-reward reconquest. Synthetic accounting fixtures are not described as combat victories. Fixed-seed assisted input demonstrates reachability; it does not establish final human difficulty. Physical Android controls, human spending behavior, win rates, frame rate and thermal performance still require device playtests. Final run counts and native UI evidence are recorded in [docs/m3/VALIDATION.md](docs/m3/VALIDATION.md).


## M4 optional source (M3 campaign balance unchanged)

`data/economy.json.rewarded_ads` adds a voluntary source: **50 persistent WC**, at most **5 successful rewards per UTC day**, with **60 seconds** between successes by default. Cancellation/load/presentation failure gives zero. The installation journal survives new-campaign resets and duplicates cannot re-award through the implemented callback path. This optional maximum of 250 WC/day accelerates chosen research; it is excluded from all no-ad first-pass income tables and completion simulations above. The 8,640 WC route and actual combat outcomes remain unchanged.

Ads are unavailable by default; only editor simulation is executable here. Configured official-test Android integration, release monetization, publisher consent/policy configuration and authoritative SSV/time remain separate work. See [M4 integration and limits](docs/REWARDED_ADS.md). Best-effort local daily/clock protections are not fraud-proof and are not a substitute for a production server ledger.

## M6 redeployment sink

Automatic turret relocation costs integer-ceiling **35% of current construction plus temporary upgrade investment** (`battle.redeployment.value_percent`). A Machine Gun costs 35 / 58 / 104 BC to move at L1 / L2 / L3; Cannon costs 70 / 116 / 207. Research bonuses do not add to this value. At L3, moving an MG costs more than a fresh L1 MG and takes four simulated seconds offline, so it does not universally dominate construction/positioning.

One confirmed move debits escrow; cancellation, mission end or scene exit refunds that escrow once. Unconfirmed selections spend nothing. Refunds do not increase `battle.earned`, create War Credits or alter save balances. Prices, wave bounties, permanent upgrade costs, replay rules and ad settings remain otherwise unchanged. Current real combat/accounting evidence is in [M6 validation](docs/m6/VALIDATION.md).

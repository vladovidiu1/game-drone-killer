# Combat balance results — M1 / M2 regression

M2 current regression passed **9,067 assertions / 26 suite invocations / zero failures**. Its 28 connected and 2 comparison combat outputs are identical to M1 when optional new research is unused (additional zero-valued research keys aside). See [M2 validation](m2/VALIDATION.md) and [new technology rules](WEAPON_RESEARCH.md). M2 loadout/branch human balance is not yet established.

The M1 Godot 4.6.3 run passed **7,611 assertions / 24 suite invocations / zero failures**, including real import, all 25 connected mission victories using earned progression, actual retreat/reconquest and fresh-process final save validation. [Detailed validation and all first-clear records](m1/VALIDATION.md).

M1 removes selectable combat speed, raises nominal drone movement by 50%, adds real acceleration/armor/tracking/formation limitations and revises all 25 wave schedules. [Design, reproducible targets and limitations](M1_BALANCE.md).

The same 55 fixed-seed balance scenarios were run before and after, and all 55 final records reproduced identically on a second run. The sampled fixed MG+Cannon policy went from 10/25 wins to 0/25; dual MG still clears mission 1 with 125 HP but fails later sampled chapter milestones. Hybrid clears all six milestones with significant primary contribution. This is not an exhaustive placement search or a human difficulty rating. [Full tables](m1/COMPARISON.md), [baseline](m1/baseline.json), [final](m1/after.json).

[campaign_balance.json](campaign_balance.json) contains 28 connected/replay records; [campaign_comparison.json](campaign_comparison.json) contains the two earned-endgame automatic-only/manual-only losses. [Frozen G6 connected results](m1/baseline_campaign.json) remain available for comparison.

Native Linux UI/representative-world captures pass separately; Android hardware performance and human playtesting remain outstanding. No stable FPS claim is made.

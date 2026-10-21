# P1 — Outpost Alpha interactive tutorial

Start **New Campaign → Outpost Alpha → Start Mission**. A first-time commander enters a guided drill inside the actual Mission-1 battlefield. **Skip intro** dismisses the short introduction; **Skip tutorial** immediately starts ordinary Mission 1. **Settings → Replay Tutorial** runs the drill independently, including without a campaign save.

## Composition and flow

`scenes/mission_tutorial.tscn` / `scripts/game/mission_tutorial.gd` is the state controller; `scenes/ui/tutorial_overlay.tscn` / `scripts/ui/tutorial_overlay.gd` is presentation. Copy, timings, demonstration magazine and training speeds live in `data/tutorial.json`. Main composes these with the existing Battle, HUD, PlayerInput, PlayerTurret, enemy/projectile scenes and turret shop. No parallel combat implementation or automatic primary aiming/firing is introduced.

| State | Actual completion condition |
| --- | --- |
| Introduction | Eight simulated seconds or Skip intro; includes all four requested Asteria/Sentinel lines. |
| 1 Aim | Accepted human mouse motion or an owned aiming-finger drag moves aim at least eight battlefield units. Initial/default orientation is insufficient. |
| 2 Fire | A real primary projectile damages the slow practice Scout. It is respawned if it reaches the base before being hit. |
| 3 Reload | The cannon completes its existing reload; remaining ammo is capped to six demonstration rounds when needed. R, Reload and empty-magazine reload all use existing logic. |
| 4 Build | A real, purchased automatic turret occupies a slot. The guide highlights the slot and then the Machine Gun shop control. |
| 5 Sectors | Three real Scouts enter from the opposite sector to the first defense. After at least three simulated seconds, a manual hit or an actual group member's destruction/arrival advances the lesson. Automatic interception can satisfy it too. |
| 6 Upgrade | Any actual turret reaches level 2. Selecting it uses the existing tactical build state at 25% speed. |
| 7 Objective | Acknowledge the base-health/five-wave objective with Begin live defense. The final instruction explains placing defenses and launching the first wave. |

The state machine checks enduring facts rather than requiring a fragile sequence of one-frame UI events. Early aim, training hit, reload, construction and upgrade remain recognized. Other necessary controls remain available. Practice abilities are disabled so their purchases cannot consume demonstration supply; ordinary abilities return in live defense.

## Input, presentation and pause

The overlay uses the existing military panels, fonts, cyan/orange accents, a short fade, animated outlines/chevrons and a cannon ring. It docks away from the active approach or upgrade target. It does not move input hitboxes. Only its buttons capture pointer events; the remainder ignores input. HUD exclusion explicitly includes Skip/Continue rectangles, keeping UI clicks out of desktop firing/aiming.

Existing independent touch ownership supports an aiming finger, a FIRE finger and a third construction touch. This was exercised with injected Godot touch events, not Android hardware. Mouse motion/held fire, R and pause also use the existing abstraction.

Guidance, reload, actual actors and upgrades consume the shared battle delta. Pause freezes simulation and clears firing/touch ownership. Closing construction restores normal speed. Highlights stop pulsing during pause; Reduced motion removes pulses/fades. A terminal action clears the guide input, and navigation removes its overlay. The ordinary campaign still owns its result and skippable end presentation.

## Practice isolation and ordinary mission handover

While `Battle.guided` is active, the ordinary wave scheduler and mission clock/environment/ability schedule are held. Practice Scouts have zero bounty and base damage; they cannot create kills, damage statistics, accuracy, star progress or permanent rewards. The UI labels this **GUIDED DRILL** and explains that supply/targets do not transfer.

Construction spends real temporary BC. If necessary, a small supply floor allows the required build/upgrade; all practice supply and purchases are discarded. Completing or skipping replaces the rehearsal Battle with a fresh ordinary Mission-1 Battle **under the same already-persisted deployment token**. It restores the configured starting supply (500 BC before existing research), full normal magazine, empty slots and zero attempt counters. Five normal balanced waves remain unchanged; first-wave PREPARE awaits the existing Launch wave action.

This reset is intentional and disclosed: tutorial assistance cannot be laundered into a stronger campaign defense by restarting or spending it differently. It is a short rehearsal followed by live defense in the same mission deployment, rather than a grant of permanent or transferable funds.

Settings replay creates no deployment token and never calls CampaignManager.resolve. Completing, skipping or aborting it shows a training summary and returns to Settings. WC, upgrades, records, first clears, stars, ad receipts and territorial state remain unchanged. Replaying does not create a free campaign result.

## Persistence and recovery

Settings gains strictly validated `tutorial_status`: `unseen`, `completed`, or `skipped`. Settings already survive campaign replacement. Automatic guidance requires unseen status, Mission 1, no prior wins/clear and highest territory 1; existing progressed saves are not redirected into a new tutorial.

Only completion or full tutorial skip writes terminal status. A failed settings write restores the previous settings and leaves the guide active with a retry message. Terminal emission is once-only, bound to the originating controller; deferred live handover verifies the current battle and matching active-run token.

Leaving/restarting an unfinished tutorial keeps unseen status and starts a fresh drill next deployment. Once completed/skipped, even a subsequent Mission-1 defeat or new campaign does not force repetition. Replay Tutorial remains available. Campaign saves retain schema v3 and existing migration/recovery behavior.

## Validation and remaining release work

[Validation, captures and commands](p1/VALIDATION.md). No extra raster assets, voice recording, production radio VO, Android export or SDK is needed for this implementation. Optional radio speech remains future polish; existing gun/hit/reload/audio hooks are used.

Approximately two minutes is the **human onboarding target**, not a forced minimum. Actions govern progression, the introduction lasts eight simulated seconds, and there are no long artificial waits. The automated pilot skips the introduction and completes the guided actions in 6.44 simulated seconds; that measures test execution only. Human discovery, reading/aiming time, accessibility, localization and novice success rates still require playtests. Physical Android multitouch/latency/safe-area/audio and device performance are untested.

# P1 validation — October 21, 2026

Baseline: M7 `f4d1c89166c818f36e877ccfe2e5201c4378358f`. Godot **4.6.3 stable**, Compatibility renderer. See [tutorial architecture](../FIRST_MISSION_TUTORIAL.md), [machine summary](validation.json) and [scenario report](tutorial_scenarios.json).

## Available verification

The combined M8/P1 full runner passes **75,284 assertions in 38 suite invocations, zero failures**, plus editor import/startup. [Acceptance log](../m8/acceptance.log), [suite-by-suite counts](../m8/validation.json). Existing 25-mission campaign, M7 components, turret arcs/movement, manual/automatic weapons, ammunition/research, economy, ads boundary mocks, save recovery and all visual-resource tests remain active. The final independent [editor import](final_import.log) is clean.

The latest [focused P1 run](tutorial_focused.log) passes **37 main checks and 3 fresh-process checks** (one additional completion-status disk-reload assertion follows the combined run). It covers:

- Actual first-campaign briefing Start button enters the introduction. Skip intro enters AIM without marking the tutorial skipped. All seven lessons wait for real input/actions or resolved actor state.
- Injected desktop mouse movement satisfies AIM; held mouse fire launches real projectiles, hits the training Scout and consumes ammo. R invokes the real two-second reload. Pause freezes guidance/reload and resume continues.
- Three independently owned touch IDs aim, hold FIRE and buy an actual Machine Gun. Construction moves to a real three-Scout attack from a different sector. Real group damage/arrival proceeds to upgrade; a paid level upgrade uses tactical 25% speed and closing returns normal speed.
- Completion acknowledges the objective and writes status once. The ordinary battle uses the **same deployment token**, normal 500 BC, no practice turret, full 60-round magazine and zero attempt clock/counters. It then survives all **five actual waves** with ordinary funds and an assisted primary pilot; the saved result pays 100 first-clear WC plus 25 earned star WC exactly once.
- Practice hits/kills never generate normal bounty/accuracy/damage/star statistics. Settings replay completion/skip/abort never changes campaign bank, frontline, records or first-clear eligibility; it also works without a campaign.
- Early aiming, firing, reload, building and upgrading remain recognized. The automatic intro timeout is finite. Restarting an unfinished drill clears its temporary state, and the replaced token is invalidated. A stale controller cannot hand over another battle.
- Failed terminal-status persistence rolls back and leaves the guide retryable; completion persistence is loaded successfully. The subsequent skip is also verified by a **new Godot process**, which retains unseen/completed/skipped semantics and grants no practice money.

The fixed-seed guided pilot completes actions in **6.44 simulated seconds**, skipping the introduction and acting immediately. This is deliberately accelerated automation, not a novice duration or an assertion that the two-minute human pacing target is achieved.

## Native input and responsive rendering

Command (with native display):

```sh
DISPLAY=:91 LIBGL_ALWAYS_SOFTWARE=1 \
FRONTLINE_CAPTURE_SCENE=res://tests/tutorial.tscn \
./tests/run_graphics_profile.sh /tmp/p1-native --attack-seed=808
```

The runner exits zero with **118 assertions, 41 native viewport captures, zero failures**, using Linux X11/OpenGL Compatibility **llvmpipe**. [Native log](native/tutorial_capture.log), [frame sizes/draw-call observations](native/metrics.json), [source/hashes](native/provenance.json). This is actual Godot gameplay/UI output, not a screenshot mockup or image edit.

The first nine frames follow the real guided actions and ordinary-budget Mission-1 victory. Additional layout views **stage tutorial phases** and re-present that archived real receipt, without resolving a second mission. This isolates responsive presentation at **1280×720, 1600×720, 1280×600 and 1024×768**. Assertions verify Skip remains inside the viewport and instruction panels do not cover FIRE. Representative unedited frames were visually inspected:

| Frame | What was checked |
| --- | --- |
| [Introduction](native/intro.png) | Four requested story lines, visible Skip intro/tutorial, no oversized blank panel. |
| [Aim](native/aim.png) / [Fire](native/fire.png) | Battlefield aim zone, primary cannon ring, real FIRE highlight. |
| [Reload](native/reload.png) | Existing ammo/reload control and brief instruction. |
| [Short-screen build](native/layout_1280x600_step4.png) | Reachable highlighted slot, instruction panel beside it, FIRE unobstructed. |
| [Different sector](native/sectors.png) | Real opposite-side Scout group and simultaneous existing combat controls. |
| [Upgrade](native/upgrade.png) / [Objective](native/objective.png) | Existing tactical upgrade shop and return-to-live explanation. |

The existing native regressions also exit zero: **36 UI captures**, **27 all-archetype captures**, **36 VFX captures** ([UI](native/ui_capture.log), [units](native/unit_capture.log), [VFX](native/effects_capture.log)). They ran sequentially to avoid desktop focus-loss pauses.

No Android frame-time benchmark was performed. The tutorial frames expose desktop draw-call observations only; they do not measure mobile performance.

## Remaining release checks

No physical Android device, signed APK/export, cutout/safe-area hardware, speaker/headphone/audio review, multitouch latency or sustained thermal measurement was available. Injected InputEventScreenTouch/Drag ownership checks are not hardware tests. Follow the [Android checklist](../../ANDROID_VISUAL_TEST_CHECKLIST.md).

Human onboarding duration near two minutes, reading load, left-handed reach, first-time aim success, accidental Skip taps, discovery of Launch wave after the drill, localized text and pause/backgrounding on a device still need playtests. The drill deliberately discards practice purchases before normal defense; test whether that clearly disclosed handover needs additional novice feedback. Optional radio voiceover and final art/audio approval remain separate polish, not missing gameplay dependencies.

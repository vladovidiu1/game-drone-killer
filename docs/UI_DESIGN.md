# G5 tactical interface and campaign map

M1 update: the combat speed selector is removed; temporary tactical build closes back to normal speed. Tracking and lock stats are shown for automatic weapons. See [M1 validation](M1_BALANCE.md).

G6 update: [the unified graphics policy and audit](../GRAPHICS_AUDIT.md) supersedes earlier independent preset/environment budgets. Existing captures below document their original increment.

G5 extends the existing Godot game with native interactive Controls. Campaign state, combat controllers, economy, save schema and all gameplay data retain their existing ownership. The [native gallery](ui/README.md) and [validation](ui/VALIDATION.md) show real rendered screens and describe staged fixtures.

## Shared visual language

The existing bundled Barlow/Barlow Condensed/DejaVu fonts, textured military button theme and cyan/orange/red palette continue across every screen. Dark translucent panels use thin metallic edges and small accent lines. `ui_kit.gd` supplies shared panels, icons, local mission previews and a bounded reusable feedback tween per Control. `telemetry_card.gd` combines a symbol, caption, real number and optional meter. Values update immediately; a brief gain annotation/pulse supplies feedback without inventing delayed balances. All UI remains interactive throughout short transitions.

The icon additions use the existing 24×24 canvas, 1.7px round strokes and interface-white source color; Controls tint them semantically. `tools/build_strategic_map.py` authors the icons, terrain and visual-only node layout. Sources and imports are included; no map service, external font account or asset download is needed.

## Screens

- **Main menu:** retained original cinematic Sentinel key art, typographic logo/badge, current campaign chapter, New/Continue hierarchy, Arsenal/Settings and desktop Exit. An 18-mote dust layer and slow faint radar arc add atmosphere. Compact heading/spacing rules retain all controls at 1280×600. Continue still depends on the real save. New Campaign retains replacement confirmation.
- **Campaign:** `scenes/ui/campaign_map.tscn` composes a clipped, smoothly pannable strategic world and a current-objective/intelligence panel, mission terrain preview, reward, floor, legend, feedback and navigation. All 25 operation markers are real touch/keyboard/mouse buttons. Locked territory opens its real briefing; deployment remains locked through `CampaignManager.can_play()`.
- **Briefing:** operation/chapter overview, local environment preview and illustrated tactical panel supplement existing story, intelligence, preparation, reward and records. Start Mission and Back use the existing deployment token/navigation paths.
- **Arsenal:** four working tabs, current currency, composed G3 weapon illustrations, real researched stats and equipped ammunition, five-step upgrade indicators, unlock/affordability states and purchase confirmation. Cards switch between two columns and one at 980px available width. The existing expected-level purchase transaction still prevents duplicate charging; confirmation feedback follows a successful saved purchase.
- **Battle:** four compact readouts show base HP, current wave, threat count and Battle Credits. Icons, primary ammo/reload, held FIRE, ammo selection, abilities, construction/upgrade and pause remain real controls. The center is mouse-ignoring and unblocked. At shorter logical heights the sidebar hides explanatory copy and temporarily hides early-wave controls while the build panel is open; current wave remains in top telemetry and closing build restores the action. FIRE/reload/abilities remain pinned and accessible. Active Overclock uses a compact label to prevent sidebar expansion over approach lanes.
- **Results:** `scenes/ui/mission_results.tscn` presents victory/liberation or defeat, a terrain preview, real territorial transition, metric cards, actual rewards and retained upgrades, followed by the existing next/retry/replay/map/Arsenal actions. Content scrolls independently of navigation. Existing boss-outro saving/skipping remains unchanged.
- **Settings:** the existing scrollable audio, quality and accessibility panel retains the shared theme and all working persistence callbacks.

## Strategic geography and panning

`assets/ui/asteria_strategy.svg` is original vector tactical cartography: relief gradients, contour bands, coastal shelf, river, roads/bridge, settlement blocks, military installations and the eastern border. It is fictional and uses no third-party geography. `assets/ui/campaign_layout.json` supplies a 1600×900 visual world, 25 distinct operation positions and shared territory vertices. These are separate from `data/definitions.json` and never alter battlefield paths, spawns or emplacements.

Five west-to-east chapter corridors arrange the mission route in a north/south serpentine. Country/territory detail scrolls beneath fixed objective/navigation panels. Drag empty space or an operation marker to pan; wheel scrolling pans vertically, keyboard focus brings offscreen nodes into view. Node hit targets are 190×64 and labels wrap without changing their geometry. Drag threshold is 12 logical pixels; release after a drag suppresses the click, while the next deliberate tap works. Pointer release outside the map clears drag ownership. Panning is bounded by the clipped world, and resize re-centers the current objective. The battlefield camera is unchanged.

Blue indicates actual controlled territory, orange the current contested operation and red enemy/locked territory. Secured checkpoint icons use the real saved floors. Completing mission 25 changes its territory/node to controlled and keeps replay available.

## Conquest, retreat and animation ownership

After a successful result transaction, the map reads `last_result.from`, `.to`, `.mission_id` and `.run_id`. Cells interpolate their ownership tint, a short operation ring marks the affected area and the frontline moves between the saved operation positions in 0.95 seconds. A UI-only receipt in `Main` consumes that result animation once per session. Reopening the screen reads current ownership immediately. No animation modifies a save, grants a reward, changes a floor or delays mission availability.

Defeat uses the actual saved retreat result. A secured floor remains secured; a checkpoint-hold result pulses the same contested operation instead of showing a fictional territorial loss. Permanent research continues to come directly from saved levels. Replay results never claim a new advance.

Menu/research/results transitions last 0.18–0.4 seconds. Button feedback changes the accent without moving hit rectangles. Gains clear their annotation after 0.8 seconds. The previous 1.4-second results sweep and skippable saved-boss outro remain presentation-only. Navigation can interrupt these effects; no long unskippable transition was added.

**Reduced motion** uses immediate map centering/state, still frontline indicators, instant button feedback, no menu dust/sweep, and skips screen/feedback tweens. **Reduced effects** also disables menu particles. Existing combat VFX quality/motion preferences remain in effect; no new save schema or settings migration is required.

## Mobile layout and budgets

Native UI stays within the existing safe-area MarginContainer. All tested action targets are at least 44px high; principal actions use 54–58px and map nodes 64px. Four automated/native logical layouts are covered: 1280×720, 1600×720, 1280×600 and 1024×768. Touch does not depend on hover. The existing primary cannon input adapter and independent aim/FIRE pointer ownership remain unchanged. The full hybrid/research suites exercise them through the redesigned HUD.

The strategic world is one cached SVG texture with a bounded overlay (25 cells/markers and one frontier), not hundreds of terrain nodes. Its uncompressed 1600×900 RGBA import is about 5.5 MiB before driver overhead; no map mip chain is enabled. Mission previews use screen-owned AtlasTextures and bypass the permanent terrain cache. Weapon portraits use static composed game artwork and do not tick, fire or retain gameplay controllers. One mote batch has 18 entries; one feedback tween per Control replaces the previous tween instead of stacking. There are no screen-copy shaders or dynamic lights added by G5. Native draw-call samples are diagnostics in the validation report; Android FPS/VRAM/thermal behavior is not established by them.

All required artwork is integrated. Optional future refinements include a bespoke illustrated 1600×900 campaign terrain plate using the same visual coordinates and a separately approved brand-logo drawing. The current map is authored tactical cartography, and existing generated G1/G3 art retains its documented art-review status. Replacing art must not change campaign rules or gameplay geometry.

## Reproduce and export

```sh
python tools/build_strategic_map.py
python tools/build_asset_manifest.py
./tests/run_checks.sh
DISPLAY=:0 ./tests/run_ui_capture.sh /tmp/frontline-g5-captures
```

The native wrapper isolates XDG saves, requires a real renderer and rejects script/engine errors even after exit 0. Its fixture progress/funds, direct result transactions and synthetic wins/defeats are explicitly documented in the gallery. Full campaign combat/balance remains a separate real-simulation suite.

When filtering non-resource files for Android export, retain `assets/ui/*.json` in addition to the existing gameplay/environment/effects JSON and license/font notices. No SDK/export template, APK signing, physical cutout/multitouch/audio or Android performance result is supplied by these desktop checks.

# G2 battlefield environment library

G6 update: [the unified graphics policy and audit](../GRAPHICS_AUDIT.md) supersedes earlier independent preset/environment budgets. Existing captures below document their original increment.

G2 replaces the old flat-color/procedural arenas in the existing game with 13 reusable illustrated terrain kits, six layered prop types and five atmosphere profiles. All 25 territories use this library. The first five are an outpost, a rural village at sunset, a supply yard, a damaged river bridge in rain and a smoke-filled town. These are integrated original generated art candidates; final commercial art approval remains outstanding.

## Runtime composition

`assets/environment/library.json` assigns a type, atmosphere, deterministic decoration seed and location identity to every mission. The gameplay catalog (`data/definitions.json`) and progression/research catalog are unchanged. Visual weather is independent of gameplay dust/range/interference conditions: those original mechanics still apply and retain their warnings.

`scripts/visual/battle_environment.gd` adds one clipped Control with one terrain Sprite2D beneath `battle_view.gd`. The Control draws cached prop regions and bounded atmosphere commands. Actors, shots, selection rings, placement pads, the base and combat warnings are drawn above this environment. It never participates in physics, input ownership, targeting, spawning or mission progression. The world rectangle stays `(0,88,955,560)`; native safe-area UI and uniform camera scaling are preserved.

Terrain and props use the established `assets/visual_catalog.json` region bindings. Terrain sheets are loaded per deployed scene, bypassing the global lifetime texture cache. Leaving a mission releases unused terrain resources; the entire campaign is not kept resident. The outpost retains its reviewed G1 terrain; three new four-map 1536×1024 sheets provide 12 additional kits. Each region is 768×512, filter-clipped and drawn into the existing battlefield. One 1536×1024 RGBA prop sheet contains six padded 512×512 cells. No ground image repeats as a tiled fill. Locations that share a kit differ in atmosphere and seeded prop composition.

Tall props reject the original air-route segments with clearance, all 44px placement touch discs with extra clearance, the bunker and the location title. Water regions additionally exclude loose ground props. River/quay slots retain their exact game positions and use raised steel emplacement decks. Background buildings are prepainted scenery beneath actors, not physical obstacles. Terrain art can be replaced without migrating saves or adjusting combat geometry.

## Atmosphere and low-effects mode

| Profile | Presentation |
| --- | --- |
| Day | Warm diffuse ground grading, short contact shadows, sparse dust motes |
| Sunset | Orange ground highlights, extended supplemental prop shadows, sparse warm motes |
| Night | Dark blue terrain, soft searchlight cones/pools; unshaded weapons, flashes and enemy indicators remain visible |
| Storm | Cool dim ground, bounded diagonal rain, drifting low-opacity cloud wisps |
| Smoke | Desaturated warm terrain, moving haze, restrained perimeter embers and small fire glints |

The shader grades terrain only. The art already contains lighting: this is a baked-material system, not PBR or dynamic day/night relighting. Sunset extends supplemental shadows; baked building shadows remain part of the illustration. Searchlights are inexpensive blended textures on the ground, not live Light2D/shadow passes. Nothing samples the screen or uses glow, compute or Forward+-only features. Haze is capped at 0.07 opacity and stays below actors. All environmental drawing is clipped away from the top/bottom HUD and right sidebar.

Settings → **Reduced environment effects** persists independently of campaign data, defaults off for existing saves and applies on the next deployment. It retains terrain, static props and stationary night lighting while skipping rain, motes, moving haze, embers, fires and light sweeps. Environment time advances only through the existing battle simulation delta: pause freezes it; construction and upgrades retain normal simulation speed. Combat stats do not change with the quality setting.

## Android budgets

- Two environment nodes per battle; at most 14 supplemental props, 32 particles, four haze wisps, two searchlight cones and three light pools. No particle/emitter node per decoration and no physics objects are added.
- At most one terrain sheet plus one shared prop sheet is referenced by a deployed environment. Each 1536×1024 RGBA texture with full mipmaps is approximately 8 MiB; environmental texture residency is about 16 MiB plus small SVG textures.
- With the existing menu/units/bunker/explosion set, a typical deployed mission references about 48 MiB of large RGBA+mip textures. Fonts, framebuffer, driver resources and temporary import/decode copies are additional. This is an estimate, not a measured Android memory figure.
- The native captures use Linux Mesa software OpenGL. They prove real Compatibility rendering, resource resolution and framing, not 60 FPS or mobile thermal/overdraw behavior. Profile the standard/reduced settings on a representative Android device before shipping.

## Rebuilding and replacement

```sh
python tools/build_environment_library.py
python tools/build_emplacement_deck.py
python tools/build_asset_manifest.py
godot --headless --path . --editor --import --quit
./tests/run_checks.sh
```

The first two commands regenerate editable JSON/vector sources only; they do not regenerate or edit the raster artwork. PNGs ship in the repository, with source IDs in `assets/source/environment_sources.json`, provenance in `assets/source/GENERATION.md`, licenses in `assets/ASSET_LICENSE.md` and inventory/hashes in `assets/manifest.json`. Keep tracked import settings and their mipmaps enabled. Android export non-resource filters must include `data/*.json`, `assets/*.json` and `assets/environment/*.json`, plus license/font notices; the environment library JSON is required at runtime.

To replace a terrain, deliver the same 1536×1024 sheet and exact four 768×512 regions, or deliver standalone 1536×1024 images and update the binding. Retain near-overhead orthographic framing, upper-left diffuse key light, quiet central play space and structures concentrated on edges. Props need transparent 512×512 cells with consistent scale and measured bounds; no opaque backing, baked UI, turrets or placement circles. Guard existing water exclusions and verify every original slot/path against the new art. Artist adjustments to perspective, prop scale and building shadows remain desirable. Unique architectural kits for every one of the 25 missions, a dedicated Hive reactor complex and matched albedo/normal sets remain external art opportunities; they are not required to run the complete campaign.

## Validation and native gallery

`tests/environments.tscn` loads all 25 missions, checks bindings, clipping, node/particle/prop bounds, decorative clearance, selectable slots, unchanged mission data, enemy movement/art, shared pause timing, weather/stat separation, old/invalid quality settings and reduced-effects persistence. The runner also verifies the saved flag in a fresh process and runs every existing combat/input/save/research/campaign suite, including actual 25-mission wins and defeat/reconquest.

Generate actual gameplay screenshots with a display and a real Compatibility renderer:

```sh
XDG_DATA_HOME=/tmp/frontline-g2-data godot --path . --audio-driver Dummy \
  res://tests/environment_capture.tscn -- --output=/tmp/frontline-g2-captures
```

Use isolated test saves. This capture fixture grants deployment access to all territories, buys a real Machine Gun, starts the actual first wave and fires the manual cannon through its real controller. It does not claim to complete those missions. It renders each territory, reduced storm effects, tactical upgrades, a 1600×720 battlefield and Settings. It rejects a headless dummy renderer. Full campaign progression is verified separately by the combat suite. Selected unmodified native PNGs are in [the G2 gallery](environments/README.md).

Physical Android GPU appearance, cutouts, physical multitouch, audible playback, frame time, VRAM and thermal behavior have not been verified in this cloud environment.

## Territory assignments

| Mission | Terrain kit | Atmosphere |
| --- | --- | --- |
| 01 — Outpost Alpha | outpost | day |
| 02 — Red Hill Village | village | sunset |
| 03 — East Supply Depot | depot | day |
| 04 — Broken Bridge | bridge | storm |
| 05 — Greyford | urban | smoke |
| 06 — North Power Station | power | night |
| 07 — Riverside District | bridge | sunset |
| 08 — Iron Highway | highway | day |
| 09 — Falcon Airbase | airbase | night |
| 10 — Metro Asteria | urban | night |
| 11 — Western Ruins | ruins | smoke |
| 12 — Liberation Road | highway | sunset |
| 13 — Black Ridge | forest | storm |
| 14 — Border Fortress | fortress | day |
| 15 — The Last Border | fortress | sunset |
| 16 — Varkon Frontier | forest | night |
| 17 — Steel Valley | forest | day |
| 18 — Drone Assembly Plant | industrial | night |
| 19 — Red Harbor | harbor | storm |
| 20 — Industrial Citadel | industrial | smoke |
| 21 — Deadlands | ruins | storm |
| 22 — Varkon Defense Ring | fortress | night |
| 23 — Central Command | urban | sunset |
| 24 — Capital Siege | ruins | sunset |
| 25 — The Hive Core | fortress | smoke |

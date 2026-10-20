# G1 source and generation record

These are original generated art candidates, visually inspected before integration. They are not screenshots or borrowed commercial art. The rendered game captures under `docs/visuals/` are produced separately by native Godot.

| Runtime file | Source output ID | Generation brief |
| --- | --- | --- |
| `backgrounds/sentinel_keyart.png` | `exec-916191e1-8a66-484a-9f06-f5503b31b972` | Original military sci-fi anti-aircraft outpost at dusk; quiet dark left 42% for native menu; detailed twin cannon on right; dusty Asteria, small hostile drones, restrained cyan/red lamps, believable worn steel; no UI/text/logos/franchise references. |
| `drones/combat_atlas.png` | `exec-74e5acd9-f126-4fc0-b63b-ad034baf298f` | Transparent 3×2 sprite sheet: Scout, Assault, Heavy above; MG head, cannon head, primary twin head below; overhead orthographic camera, upper-left key light, steel blue/charcoal paint, red enemies/cyan friendly. |
| `environment/outpost_alpha.png` | `exec-9215633d-f3d2-4b00-b0e2-0d43aaac4df0` | Near-overhead dry military terrain; open central 75%, textured dust/concrete, sparse tracks, perimeter blast walls, sandbags, crates and blue steel utility shelters; no actors, roads, weapons, labels or baked UI. |
| `effects/explosion_atlas.png` | `exec-6a37c7cb-222e-469a-bbdc-6257438301a3` | Transparent 3×2 sequential overhead ordnance explosion: ignition, expansion, peak fire, smoke/fire, smoke, wisps; detailed turbulent flames, charcoal smoke and sparks, no neon or text. |
| `environment/command_bunker.png` | `exec-ae36df4a-ba4a-4db1-89f7-06832bb9e38e` | Single wide low command bunker on transparency; worn concrete, steel blue roof plates, ventilation, inset doors and cyan lamps; empty center mounting recess for the existing player cannon; no cannon, antennas, scenery or labels. |

All five source images are 1536×1024. PNG source bytes are preserved; texture slicing uses explicit Godot AtlasTexture regions. There is no destructive background removal, color keying, resampling script or repainting hidden in the pipeline. Generated sheets do not follow exact ideal-cell padding: `visual_catalog.json` records reviewed weapon regions and breech pivots so rotating barrels remain centered. Future approved art should follow the exact specifications in `VISUAL_STYLE.md` rather than reproduce these incidental generation defects.

The faint alpha fringes and baked highlights are generated source characteristics. Normal maps, PBR channels, phase damage sheets and full rotor animation are not inferred or fabricated from color images.

Project-authored editable vector resources are reproducible with `python tools/generate_visual_vectors.py`; theme resources with `python tools/build_visual_theme.py`. These scripts use Python's standard library and never call a generation service. They do not overwrite reviewed catalog bindings or generated PNGs. `environment/command_bunker.svg` is retained as an editable construction reference, not the active bunker artwork.

Font sources: https://github.com/google/fonts/tree/main/ofl/barlow and https://github.com/google/fonts/tree/main/ofl/barlowcondensed. The bundled DejaVu font is from the execution environment's Debian font distribution, with its full license notices included. All fonts are local at runtime.

## G2 environment generation — 2026-10-20

Four original image-generation requests supplied the new environment sources. The prompts requested modern military sci-fi materials, near-overhead orthographic 2.5D framing, upper-left daylight, down-right soft shadows, quiet open centers, detailed perimeter architecture, no units/turrets/UI/text/logos and no third-party reference artwork. These are original project outputs subject to the applicable OpenAI terms; no external asset pack, account, API key or runtime generation is required. Final production art approval remains outstanding.

| File | Original output | Layout/content |
| --- | --- | --- |
| `environment/settlements_atlas.png` | `exec-e4075b3b-f782-486c-b136-7cef4388697a` | 1536×1024 RGB; four 768×512 quadrants: village, supply depot, damaged bridge, urban district |
| `environment/frontiers_atlas.png` | `exec-8f111bc8-6c87-4cea-a030-95f79ed800b1` | 1536×1024 RGB; four quadrants: forest/mountain clearing, industrial facility, ruined city, military airbase |
| `environment/strongholds_atlas.png` | `exec-cb521a6e-49a2-4249-934a-76d49dc0e62d` | 1536×1024 RGB; four quadrants: enemy fortress, highway, harbor, power station |
| `environment/props_atlas.png` | `exec-83554f56-85f7-4981-b117-6d227ff83edf` | 1536×1024 RGBA, transparent; six 512×512 cells: radar, cargo, sandbags, trees, house, damaged generator |

The PNG sources were copied unmodified from image-generation outputs. Regions are bound using Godot AtlasTexture; no script removes backgrounds, paints pixels or composites the screenshots. The prop sheet was explicitly generated with transparency and its alpha was checked. The prop perspective is somewhat steeper than the terrain plate; supplemental props are kept small and require final perspective/scale review. Detailed terrain includes prepainted shadows; runtime grading is deliberately limited instead of pretending to relight baked artwork physically.

The warm/cool grading shader, light pools, searchlight cones, smoke wisps, contact shadows and raised emplacement decks are locally authored editable CanvasItem/SVG presentation resources. They are utility lighting/detail layers, not represented as commissioned raster paintings. Their source generators and provenance are listed in the manifest. Native screenshots in `docs/environments` come directly from Godot's viewport with real waves and projectiles; they are not generated game screenshots.

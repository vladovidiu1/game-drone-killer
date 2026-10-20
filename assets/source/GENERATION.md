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

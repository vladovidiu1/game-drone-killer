# Asset provenance and licenses

No stock game artwork, franchise art or paid asset packs are used.

The PNG artwork listed as generated in `manifest.json` was created specifically for this project with OpenAI image generation from original written prompts. Use of generated output is subject to the applicable OpenAI terms. These files are supplied as project artwork candidates for use, modification and distribution with this game. No claim of exclusive copyright, human authorship, third-party rights clearance or trademark clearance is made for generated output. Art approval before commercial publication remains a production step.

Project-authored SVGs, shaders, visual catalog and theme resources in this directory are available under the MIT License below. This notice does not change licenses of the existing game or of the fonts.

Copyright (c) 2026 DRONE KILLER: FRONTLINE contributors

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Fonts are distributed unmodified with their original notices:

- Barlow Regular and Barlow Condensed Bold: SIL Open Font License 1.1. See `ui/fonts/Barlow-OFL.txt` and `ui/fonts/BarlowCondensed-OFL.txt`. Retrieved from the Google Fonts `ofl/barlow` and `ofl/barlowcondensed` directories; hashes in the manifest pin the actual bundled files.
- DejaVu Sans Mono: Bitstream Vera / DejaVu font licenses and notices, preserved in `ui/fonts/DejaVu-LICENSE.txt`.

Artwork, fonts and music load from local files. No generation service, font CDN, account or API key is required for offline gameplay. Optional advertising uses separately configured Google SDKs and their own terms.

G2 adds three original terrain atlases and one original transparent prop atlas under the same generated-project-output terms described above. IDs and integration status are recorded in `source/environment_sources.json`, `source/GENERATION.md` and `manifest.json`. New environment JSON, shaders, SVG utility layers and generators are project-authored sources under the project's MIT license. No licensed third-party game environments were used.

G3 adds five original transparent enemy/boss/weapon/component atlases under the same generated-project-output terms above. IDs and import/source dimensions are in `source/unit_sources.json`, `source/GENERATION.md` and the manifest. New GDScript presentation controllers and shader additions are project-authored code. No third-party drone, weapon or franchise designs were supplied as references.

G4 reuses the existing licensed original explosion, G3 fragment and authored vector/tracer/muzzle/smoke/light textures. The combat particle algorithms, screen-feedback drawing and quality configuration are original project code/data under the repository MIT license. No new third-party art or generated raster source was introduced by G4; optional commissioned energy/smoke/impact refinements remain documented in `docs/COMBAT_VFX.md`.

G5's fictional Asteria strategic cartography, 25-node visual layout and 13 matching UI symbols are original authored vector/data work under the repository MIT license. `tools/build_strategic_map.py` is the reproducible source; no geographic dataset, map API or third-party illustration is used. UI portraits/previews reuse existing licensed G1–G3 game artwork.

M2 adds six original authored SVG projectile technical illustrations under the project MIT license. Their reproducible source is `tools/build_projectile_vectors.py`. No new generated raster output or third-party weapon artwork is introduced. Electric/frost/rail effects extend the existing bounded authored VFX code.

## Original menu music

`audio/night_watch.ogg` (Night Watch, 48 seconds, 80 BPM) is an original project-authored ambient synthesizer composition, not a recording sampled from a third-party song. Composition, synthesis source and recording are supplied under the MIT license above, with no royalties or external attribution requirement beyond retaining that notice. Its reproducible source is `tools/build_menu_music.py`; it uses only mathematical oscillators, with no downloaded samples or hosted generation service. The game plays this locally in menus/pause at a low level and stops it during active combat, backgrounding and full-screen ads.

## Official application branding

The drone/red-reticle artwork used by `branding/*.png` was supplied by the publisher for this application. Its original rights are retained; the project-authored vector/music MIT notice above does not relicense the supplied artwork. The icon variants preserve the supplied design, with assisted corner extension/background isolation and technical launcher-layer preparation. Source provenance is documented in `branding/NOTICE.md` and `docs/ANDROID_APP_ICON.md`.

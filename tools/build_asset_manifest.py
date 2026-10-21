"""Inventory the checked-in visual sources; never edit raster image pixels."""
from pathlib import Path
import hashlib,json,re,struct
root=Path(__file__).resolve().parents[1]
assets=root/'assets'
originals={
 'backgrounds/sentinel_keyart.png':('Main-menu key art','exec-916191e1-8a66-484a-9f06-f5503b31b972',1,'Integrated generated candidate; art approval pending'),
 'drones/combat_atlas.png':('Shared Scout/Assault/Heavy and MG/Cannon/Primary art','exec-74e5acd9-f126-4fc0-b63b-ad034baf298f',6,'Integrated six-object atlas; explicit reviewed regions/pivots'),
 'environment/outpost_alpha.png':('Military outpost library terrain plate','exec-9215633d-f3d2-4b00-b0e2-0d43aaac4df0',1,'Integrated in G2 environment library; original G1 outpost plate'),
 'effects/explosion_atlas.png':('Ignition, fire and smoke one-shot','exec-6a37c7cb-222e-469a-bbdc-6257438301a3',6,'Integrated six-frame 0.65s animation; needs final continuity review'),
 'environment/command_bunker.png':('Defended command bunker with separate player cannon','exec-ae36df4a-ba4a-4db1-89f7-06832bb9e38e',1,'Integrated cropped AtlasTexture candidate; roof-mount/perspective approval pending')}
g2_sources = assets/'source/environment_sources.json'
if g2_sources.exists():
 for name, entry in json.loads(g2_sources.read_text()).items():
  originals['environment/'+name] = (entry['purpose'],entry['output'],entry['panels'],entry['status'])
g3_sources = assets/'source/unit_sources.json'
g3_imports = json.loads(g3_sources.read_text()) if g3_sources.exists() else {}
for name, entry in g3_imports.items():
 originals[name] = (entry['purpose'],entry['output'],entry['panels'],entry['status'])
items=[]
for path in sorted(assets.rglob('*')):
 if not path.is_file() or path.suffix not in ['.png','.svg','.ttf','.tres','.gdshader','.json'] or path.name=='manifest.json':continue
 relative=path.relative_to(assets).as_posix()
 dimensions=None
 frames=1
 source='Authored locally for G1/G2/G3/G4/G5/G6/M2/M7; editable source in repository'
 license='MIT; assets/ASSET_LICENSE.md'
 status='Integrated'
 purpose=relative.rsplit('/',1)[-1].split('.')[0].replace('_',' ')
 if path.suffix=='.png':
  payload=path.read_bytes();dimensions=list(struct.unpack('>II',payload[16:24]));purpose,identifier,frames,status=originals[relative]
  source='OpenAI image generation, original prompt; output '+identifier+'; assets/source/GENERATION.md'
  license='Generated project output under applicable OpenAI terms; assets/ASSET_LICENSE.md'
 elif path.suffix=='.svg':
  text=path.read_text();dimensions=[int(re.search('width="([0-9]+)"',text)[1]),int(re.search('height="([0-9]+)"',text)[1])]
  if relative in ["ui/asteria_strategy.svg"] or relative.startswith("ui/icon_") and relative.split("icon_")[1].split(".")[0] in ["wave","drone","ammo","reload","speed","research","ability","checkpoint","map","lock","back","target","repair"]:source="tools/build_strategic_map.py"
  elif relative.startswith('projectiles/') and relative.endswith('_round.svg'):source='tools/build_projectile_vectors.py'
  elif '/button_' in relative:source='tools/build_visual_theme.py'
  elif relative.startswith('environment/') and relative!='environment/command_bunker.svg':source='tools/build_emplacement_deck.py' if 'emplacement_deck' in relative else 'tools/build_environment_library.py'
  else:source='tools/generate_visual_vectors.py'
  if relative in ['turrets/missile_head.svg','turrets/laser_head.svg','turrets/emp_head.svg']:status='Integrated interim authored vector; dedicated rendered weapon art required'
  if relative in ['turrets/missile_head.svg','turrets/laser_head.svg','turrets/emp_head.svg']:status='Legacy G1 reference only; G3 uses rendered weapon atlas'
  if relative=='environment/command_bunker.svg':status='Reference only; runtime uses command_bunker.png'
  if relative in ['ui/icon_crosshair.svg','ui/icon_chevron.svg','ui/icon_exit.svg','ui/icon_ammo.svg','ui/icon_map.svg']:status='Available UI kit resource; not currently placed'
 elif path.suffix=='.ttf':
  if path.name.startswith('Barlow'):
   license='SIL OFL 1.1; adjacent Barlow*-OFL.txt'
   source='Google Fonts / '+('ofl/barlowcondensed' if 'Condensed' in path.name else 'ofl/barlow')
  else:
   license='Bitstream Vera / DejaVu licenses; ui/fonts/DejaVu-LICENSE.txt'
   source='Unmodified Debian DejaVu font distribution'
 elif relative=='ui/frontline_theme.tres':source='tools/build_visual_theme.py'
 elif relative=='ui/campaign_layout.json':source='tools/build_strategic_map.py'
 items.append(dict(filename=relative,purpose=purpose,required_dimensions=dimensions,animation_frames=frames,frame_semantics='Six independent objects, not animation frames' if relative=='drones/combat_atlas.png' else 'Sequential 3 by 2 frames' if relative=='effects/explosion_atlas.png' else 'Independent environment/prop atlas cells, not animation' if relative.startswith('environment/') and '_atlas' in relative else 'Static or parameter-driven',art_direction='Modern military sci-fi 2.5D; restrained charcoal/steel/cyan; upper-left baked light where applicable',source_or_generation_method=source,license=license,integration_status=status,sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
# Keep source dimensions separate from Godot's intentional mobile import size.
for item in items:
 if item['filename'] in g3_imports:
  item['source_dimensions'] = item['required_dimensions']
  item['required_dimensions'] = g3_imports[item['filename']]['import_dimensions']
  item['frame_semantics'] = 'Independent G3 objects, transform-animated at runtime; not raster animation frames'
 if item['filename'] == 'drones/combat_atlas.png':
  item['integration_status'] = 'Legacy G1 reference only; all runtime enemy/weapon aliases use G3 artwork'
# Atlas cells are independent maps/props/actors, not animation frames.
for item in items:
 if item['filename'].endswith('_atlas.png') and item['filename'] != 'effects/explosion_atlas.png':
  item['atlas_cells'] = item['animation_frames']
  item['animation_frames'] = 1
(assets/'manifest.json').write_text(json.dumps(dict(version=1,guide='VISUAL_STYLE.md',license_notice='assets/ASSET_LICENSE.md',assets=items),indent=2)+'\n')
print('Inventoried',len(items),'visual source assets')

# Human-readable release inventory stays synchronized with the machine manifest.
lines = ["# Asset manifest", "", "G1–G6 / M2 inventory — 2026-10-21. Generated by `python tools/build_asset_manifest.py`.", "", "The canonical [JSON manifest](assets/manifest.json) includes SHA-256 hashes. All paths below are relative to `assets/`. Dimensions are imported width × height; source dimensions are shown where different. Atlas cells are independent objects/maps unless explicitly labeled sequential animation.", "", "Shared art direction: modern military sci-fi 2.5D, near-overhead camera, charcoal/steel surfaces, cyan friendly and red hostile identification, upper-left baked lighting. No runtime downloads or external artwork are required to launch the game.", "", "Generated raster art remains an integrated candidate awaiting final artistic/commercial review. Authored vectors and procedural mechanics/particles are deliberate presentation utilities, not a claim of finished painted animation. [Replacement specifications](VISUAL_STYLE.md#exact-replacement-specifications) and the [G6 audit](GRAPHICS_AUDIT.md) identify remaining production work. See [license notices](assets/ASSET_LICENSE.md) and bundled font notices.", "", "| File / purpose | Dimensions / animation | Source or generation | License | Integration status |", "| --- | --- | --- | --- | --- |"]
for item in items:
 dims = " × ".join(map(str,item["required_dimensions"])) if item["required_dimensions"] else "Not pixel-sized (font/config/theme/shader)"
 if "source_dimensions" in item:
  dims += "; source " + " × ".join(map(str,item["source_dimensions"]))
 animation = str(item["animation_frames"]) + " frame(s)"
 if "atlas_cells" in item:
  animation += "; " + str(item["atlas_cells"]) + " independent cells"
 animation += "; " + item["frame_semantics"]
 columns = ["[" + item["filename"] + "](assets/" + item["filename"] + ") — " + item["purpose"], dims + "; " + animation, item["source_or_generation_method"], item["license"], item["integration_status"]]
 lines.append("| " + " | ".join(value.replace("|","/") for value in columns) + " |")
lines += ["", "Total: " + str(len(items)) + " inventory entries. Legacy G1 drone atlas/three SVG heads/bunker vector are reference-only. Available unused UI kit icons are explicitly marked; active gameplay uses G3 raster bindings. Runtime alias, pivot and scale details live in [visual_catalog.json](assets/visual_catalog.json).", ""]
(root/"ASSET_MANIFEST.md").write_text("\n".join(lines))

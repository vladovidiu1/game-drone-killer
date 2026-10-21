"""Bind original G3 source regions to Godot's half-resolution Android imports.
Does not edit image pixels or gameplay definitions. Source coordinates are retained
for an art director; all runtime pivots/regions are in imported-texture pixels.
"""
from pathlib import Path
import json,math
root=Path(__file__).resolve().parents[1]
p=root/'assets/visual_catalog.json';data=json.loads(p.read_text());sprites=data['sprites']
def add(name,file,rect,pivot,scale=.26,**extra):
 sprites[name]=dict(file=file,source_region=rect,region=[v/2 for v in rect],pivot=[v/2 for v in pivot],scale=scale,**extra)
def coords(points):return [[v/2 for v in a] for a in points]
line='drones/line_atlas.png';special='drones/specialists_atlas.png';boss='drones/bosses_atlas.png';guns='turrets/weapons_atlas.png';sentinel='turrets/sentinel_atlas.png'
add('drone_scout',line,[0,0,512,480],[250,250],rotors=coords([[110,140,53],[384,140,53],[106,345,53],[386,345,53]]))
add('drone_assault',line,[512,0,512,480],[256,245],rotors=coords([[91,194,65],[420,194,65]]))
add('drone_heavy',line,[1024,0,512,480],[270,240],rotors=coords([[184,73,44],[367,73,44],[100,218,45],[448,220,45],[170,375,46],[378,374,46]]))
add('drone_shield',line,[0,480,512,544],[253,263],rotors=coords([[251,102,69],[110,339,71],[396,339,71]]))
add('drone_emp',line,[512,480,512,544],[256,280],rotors=coords([[96,271,57],[417,272,57]]))
add('drone_bomber',line,[1024,480,512,544],[256,260],rotors=coords([[111,108,53],[413,108,53],[91,357,57],[426,359,57]]))
add('drone_sniper',special,[0,0,512,512],[256,280],facing=math.pi,rotors=coords([[178,252,26],[337,252,26],[178,406,26],[337,406,26]]))
add('drone_carrier',special,[512,0,512,512],[256,270],rotors=coords([[56,150,41],[56,296,41],[56,434,41],[456,150,41],[456,296,41],[456,434,41]]))
add('drone_stealth',special,[1024,0,512,512],[256,300],facing=math.pi,engines=coords([[212,444,35],[302,444,35]]))
add('rotor_blade',special,[0,512,512,512],[251,267])
add('jet_exhaust',special,[612,564,310,420],[155,20])
add('wreck_fragment',special,[1040,544,496,480],[248,240])
# Boss pivots place the painted reactor at the existing world weakpoint (0,+27).
# Their body_scale stays the original 2.4; source scale .15 -> .36 world/sourcepx.
add('boss_assault_carrier',boss,[0,0,544,480],[274,264],.30,rotors=coords([[143,116,32],[402,116,32],[143,357,33],[401,357,33]]),weapons=coords([[70,269,38],[474,269,38]]))
add('boss_emp_warship',boss,[570,0,454,480],[198,253],.30,engines=coords([[100,419,43],[253,419,43]]),weapons=coords([[82,255,29],[305,255,29]]))
add('boss_border_guardian',boss,[1030,0,506,480],[250,289],.30,rotors=coords([[154,103,31],[347,103,31],[116,336,31],[376,336,31],[171,401,31],[327,401,31]]),weapons=coords([[65,247,45],[446,247,45]]))
add('boss_factory_ship',boss,[0,480,512,544],[256,291],.30,rotors=coords([[72,106,34],[466,106,34],[60,402,35],[470,402,35]]),weapons=coords([[120,239,25],[407,239,25]]))
add('boss_hive_core',boss,[512,480,536,544],[266,165],.30,rotors=coords([[117,117,32],[396,117,32],[40,230,34],[476,230,34],[118,384,34],[401,384,34]]),weapons=coords([[118,218,35],[410,218,35]]))
add('boss_gun',boss,[1080,480,456,544],[199,370])
for name,rect,pivot,recoil in [
 ('gun_machine',[0,0,512,512],[265,378],1.8),
 ('gun_cannon',[512,0,512,512],[256,377],4.0),
 ('gun_missile',[1024,0,512,496],[256,355],2.0),
 ('gun_laser',[0,512,512,512],[265,338],.2),
 ('gun_emp',[512,512,512,512],[256,302],.1),
 ('gun_heavy_aa',[1024,496,512,528],[256,399],5.0)]:
 add(name,guns,rect,pivot,.20,weapon=True,recoil=recoil)
add('gun_primary',sentinel,[100,330,380,240],[187,105],.184,weapon=True,recoil=5.0,scale_x=.36)
add('primary_barrels',sentinel,[1134,0,310,422],[1259-1134,435])
add('primary_base',sentinel,[512,80,520,480],[260,240])
add('secondary_base',sentinel,[64,576,448,416],[224,208])
add('upgrade_collar',sentinel,[520,560,500,440],[250,220])
add('magazine_cassette',sentinel,[1080,560,400,440],[200,220])
for key in ['boss_assault_carrier','boss_emp_warship','boss_border_guardian','boss_factory_ship','boss_hive_core']:
 sprites[key]['boss']=True
for key,reach,spread in [('gun_machine',29,6),('gun_cannon',32,0),('gun_missile',18,12),('gun_laser',30,0),('gun_emp',24,0),('gun_heavy_aa',39,5),('gun_primary',38,9)]:
 sprites[key]['muzzle_forward']=reach
 sprites[key]['muzzle_lateral']=spread
data['enemy_aliases']={name:('boss_'+kind if info.get('boss') else 'drone_'+kind) for kind,info in json.loads((root/'data/definitions.json').read_text())['enemies'].items() for name in [info['name']]}
data['turret_aliases']['heavy_aa']='gun_heavy_aa'
p.write_text(json.dumps(data,indent=2)+'\n')
outputs={
 'drones/line_atlas.png':('exec-a08514a4-9625-4b33-a036-b9999c1d43f7','Scout, Assault, Heavy, Shield, EMP and Bomber',6),
 'drones/specialists_atlas.png':('exec-b8907fc4-a8e7-42cd-9476-72d93af8c93a','Sniper, Carrier, Stealth and isolated rotor/exhaust/debris',6),
 'drones/bosses_atlas.png':('exec-24d33cd7-e310-42bf-b7fa-68389e59f1c0','Five unique chapter bosses and articulated cannon module',6),
 'turrets/weapons_atlas.png':('exec-f8ccb52e-d815-4998-bcd1-53a773d13a13','Six distinct automatic weapon heads',6),
 'turrets/sentinel_atlas.png':('exec-2db81b9b-996e-40c8-a8d5-557e55e0e5b8','Sentinel primary breech/barrels, two bases, armor and autoloader',6)}
record={name:dict(output=identifier,purpose=purpose,panels=panels,import_dimensions=[768,512],status='Integrated original G3 generated candidate; native animation review; final art approval pending') for name,(identifier,purpose,panels) in outputs.items()}
(root/'assets/source/unit_sources.json').write_text(json.dumps(record,indent=2)+'\n')
print('Bound 14 unique enemy silhouettes, 7 weapon heads and modular mechanics')

# Preserve M7 imported-pixel component mounts after regenerating base art metadata.
import runpy
runpy.run_path(str(root/'tools/build_component_bindings.py'))

"""Build editable G2 visual bindings/profiles; does not edit gameplay or raster art."""
from pathlib import Path
import json
r=Path(__file__).resolve().parents[1]
types={
'outpost':('outpost_alpha.png',None,['radar','crates','sandbags']),
'village':('settlements_atlas.png',[0,0,768,512],['house','trees','sandbags']),
'depot':('settlements_atlas.png',[768,0,768,512],['crates','generator','radar']),
'bridge':('settlements_atlas.png',[0,512,768,512],['sandbags','crates','radar']),
'urban':('settlements_atlas.png',[768,512,768,512],['sandbags','crates','generator']),
'forest':('frontiers_atlas.png',[0,0,768,512],['trees','sandbags','radar']),
'industrial':('frontiers_atlas.png',[768,0,768,512],['generator','crates','radar']),
'ruins':('frontiers_atlas.png',[0,512,768,512],['generator','sandbags','crates']),
'airbase':('frontiers_atlas.png',[768,512,768,512],['radar','crates','sandbags']),
'fortress':('strongholds_atlas.png',[0,0,768,512],['generator','radar','sandbags']),
'highway':('strongholds_atlas.png',[768,0,768,512],['sandbags','crates','trees']),
'harbor':('strongholds_atlas.png',[0,512,768,512],['crates','generator','radar']),
'power':('strongholds_atlas.png',[768,512,768,512],['generator','radar','crates'])}
profiles={
'day':dict(tint='fff3df',exposure=1.0,shadow=[9,12],particles=8,haze=0.0,label='Warm daylight'),
'sunset':dict(tint='ffc18a',exposure=0.92,shadow=[25,19],particles=12,haze=0.025,label='Low sun / long shadows'),
'night':dict(tint='809fce',exposure=0.67,shadow=[7,9],particles=8,haze=0.025,label='Night watch / searchlights'),
'storm':dict(tint='a5b7c9',exposure=0.79,shadow=[4,5],particles=32,haze=0.07,label='Wind / rainfall'),
'smoke':dict(tint='d5b79b',exposure=0.85,shadow=[10,13],particles=20,haze=0.06,label='Battlefield smoke / embers')}
assign=[('outpost','day','Remote garrison'),('village','sunset','Red Hill homesteads'),('depot','day','East loading yards'),('bridge','storm','Broken river crossing'),('urban','smoke','Greyford town square'),('power','night','Northern grid'),('bridge','sunset','Riverside approaches'),('highway','day','Iron transit corridor'),('airbase','night','Falcon flight line'),('urban','night','Asterian civic center'),('ruins','smoke','Western destruction'),('highway','sunset','Liberation convoy road'),('forest','storm','Black Ridge switchbacks'),('fortress','day','Border bastion'),('fortress','sunset','Last border gates'),('forest','night','Varkon treeline'),('forest','day','Steel Valley pass'),('industrial','night','Assembly line'),('harbor','storm','Red Harbor quays'),('industrial','smoke','Citadel furnaces'),('ruins','storm','Deadlands crater field'),('fortress','night','Defense ring'),('urban','sunset','Command district'),('ruins','sunset','Capital siege grounds'),('fortress','smoke','Hive reactor perimeter')]
catalog=dict(version=1,field=[0,88,955,560],types={},profiles=profiles,missions={})
for key,(file,region,props) in types.items():
 catalog['types'][key]=dict(file='environment/'+file,props=props)
 if region:catalog['types'][key]['region']=region
# Presentation exclusions in existing world coordinates, independent of physics.
catalog['types']['bridge']['no_props']=[[0,160,955,310]]
catalog['types']['harbor']['no_props']=[[0,88,215,560]]
for i,(kind,profile,label) in enumerate(assign,1):
 catalog['missions'][str(i)]=dict(type=kind,profile=profile,seed=7100+i*137,identity=label,accent='ac7b55' if i<16 else '8e6f69')
(r/'assets/environment/library.json').write_text(json.dumps(catalog,indent=2)+'\n')
# Keep all region/pivot bindings in the established visual catalog. These definitions
# are read locally by the environment renderer, not globally cached across missions.
p=r/'assets/visual_catalog.json';v=json.loads(p.read_text())
for key,t in catalog['types'].items():
 v['sprites']['terrain_'+key]={k:val for k,val in t.items() if k in ('file','region')}
for i,key in enumerate(['radar','crates','sandbags','trees','house','generator']):
 v['sprites']['prop_'+key]=dict(file='environment/props_atlas.png',region=[i%3*512,i//3*512,512,512],pivot=[256,256])
p.write_text(json.dumps(v,indent=2)+'\n')
(r/'assets/environment/light_pool.svg').write_text('''<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256"><defs><radialGradient id="g"><stop stop-color="#b8d8ed" stop-opacity=".5"/><stop offset=".4" stop-color="#94b8d2" stop-opacity=".22"/><stop offset="1" stop-color="#94b8d2" stop-opacity="0"/></radialGradient></defs><circle cx="128" cy="128" r="126" fill="url(#g)"/></svg>''')
(r/'assets/environment/smoke_wisp.svg').write_text('''<svg xmlns="http://www.w3.org/2000/svg" width="256" height="128" viewBox="0 0 256 128"><defs><radialGradient id="g"><stop stop-color="#a0a5aa" stop-opacity=".36"/><stop offset=".55" stop-color="#7b8993" stop-opacity=".17"/><stop offset="1" stop-color="#7b8993" stop-opacity="0"/></radialGradient></defs><ellipse cx="128" cy="64" rx="127" ry="63" fill="url(#g)"/></svg>''')
print('Created 13 environment kits, 5 atmosphere profiles, 25 assignments, 6 prop bindings')

(r/'assets/environment/searchlight_cone.svg').write_text('''<svg xmlns="http://www.w3.org/2000/svg" width="256" height="512" viewBox="0 0 256 512"><defs><linearGradient id="side"><stop stop-color="#b8d5ee" stop-opacity="0"/><stop offset=".5" stop-color="#b8d5ee" stop-opacity=".3"/><stop offset="1" stop-color="#b8d5ee" stop-opacity="0"/></linearGradient><linearGradient id="fade" x2="0" y2="1"><stop stop-color="white"/><stop offset="1" stop-color="black"/></linearGradient><mask id="m"><rect width="256" height="512" fill="url(#fade)"/></mask></defs><path d="M122 0h12l121 512H1z" fill="url(#side)" mask="url(#m)"/></svg>''')

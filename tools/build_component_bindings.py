"""M7 hitbox mounts in imported atlas pixels, measured on existing G3 artwork.
Does not edit pixels, gameplay data or world coordinates. Re-run after G3 catalog builds.
"""
import json
from pathlib import Path
root=Path(__file__).resolve().parents[1]
p=root/'assets/visual_catalog.json';data=json.loads(p.read_text())
# Core and device centers are relative to each imported sprite region.
centers={
'drone_assault':{'weapon':[90,139,22]},
'drone_heavy':{'weapon':[135,124,22],'core':[135,101,20]},
'drone_shield':{'generator':[126,124,24]},
'drone_emp':{'weapon':[126,110,23],'sensor':[129,205,15]},
'drone_bomber':{'weapon':[130,130,30]},
'drone_sniper':{'weapon':[128,90,20],'sensor':[128,160,14]},
'drone_carrier':{'weapon':[130,140,28],'core':[128,178,20]},
'drone_stealth':{'sensor':[128,140,18]},
'boss_assault_carrier':{'core':[137,169.5,18]},
'boss_emp_warship':{'core':[99,162.5,18]},
'boss_border_guardian':{'core':[125,182,18]},
'boss_factory_ship':{'core':[128,183,18],'generator':[128,98,21]},
'boss_hive_core':{'core':[133,119.5,19],'generator':[133,71,18]}}
for name,mounts in centers.items():
 entry=data['sprites'][name];bindings={}
 for key,(x,y,radius) in mounts.items():bindings[key]={'point':[x,y],'radius':radius,'parent':'body'}
 axes=entry.get('rotors',entry.get('engines',[]))
 if axes:
  left=min(range(len(axes)),key=lambda i:axes[i][0]);right=max(range(len(axes)),key=lambda i:axes[i][0])
  for key,index in [('engine_left',left),('engine_right',right)]:
   x,y,r=axes[index];bindings[key]={'point':[x,y],'radius':r*.90,'rotor':index,'parent':'body'}
 if entry.get('weapons'):
  x,y,r=entry['weapons'][0];bindings['weapon']={'point':[x,y],'radius':r,'weapon':0,'parent':'body'}
 if name.startswith('boss_'):
  width=entry['region'][2];cut=int(width*.25)
  for mount in bindings.values():
   if mount['point'][0]<cut:mount['parent']='armor_left'
   elif mount['point'][0]>width-cut:mount['parent']='armor_right'
 if name=='boss_emp_warship':bindings['generator']={'point':[99,100],'radius':18,'parent':'body'}
 entry['component_mounts']=bindings
p.write_text(json.dumps(data,indent=2)+'\n')
print('M7 component bindings updated for',len(centers),'archetypes; Scouts keep their single hull collider')

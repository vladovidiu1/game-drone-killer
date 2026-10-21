"""Rebuild M1 tuning from the checked-in G6 baseline; never mutate art/geometry/saves."""
from pathlib import Path
import json, math
root=Path(__file__).resolve().parents[1]
data=json.loads((root/'docs/m1/baseline_definitions.json').read_text())
# M2's additive enemy resistance definitions must survive an intentional M1 rebuild.
current=json.loads((root/'data/definitions.json').read_text())
for key,unit in current['enemies'].items():
 if 'resistances' in unit and key in data['enemies']:
  data['enemies'][key]['resistances']=unit['resistances']
data['balance']={
 'version':'M1',
 'movement_multiplier':1.5,
 'maximum_drone_speed':245,
 'target_scan_interval':0.12,
 'target_switch_margin':40,
 'upgrade_turn_step':0.08,
 'wave_policy':{'count_multiplier':[1.12,1.13,1.16,1.18,1.20], 'interval_multiplier':[0.92,0.9,0.88,0.86,0.84], 'burst_size':[2,2,3,3,3], 'burst_gap':[0.16,0.16,0.15,0.14,0.13], 'build_seconds':[15,14,13,12,11]},
 'targets':{'1':{'hybrid_min_health':250,'hybrid_min_manual_hits':8,'description':'Approachable, needs interception and crossfire'}, '5':{'hybrid_min_health':1,'hybrid_min_manual_hits':15,'description':'Basic coverage plus shield/core prioritization'}, '10':{'hybrid_min_health':1,'hybrid_min_manual_hits':25,'description':'Regular manual support against EMP and split escorts'}, '15':{'hybrid_min_health':1,'hybrid_min_manual_hits':35,'description':'Upgraded defenses and target prioritization'}, '20':{'hybrid_min_health':1,'hybrid_min_manual_hits':45,'description':'Strong combinations and active interception'}, '25':{'hybrid_min_health':1,'hybrid_min_manual_hits':55,'description':'Difficult combined-arms finale'}}}
# Costs, base HP, permanent progression and primary magazine/rate stay intact.
for key,stats in {
 'machine_gun':(10,3.8,230,640,300,.10,12),
 'cannon':(50,.78,250,440,180,.18,8),
 'missile':(75,.48,290,320,120,.25,18),
 'laser':(22,1,255,0,200,.16,6),
 'emp_tower':(0,.2,215,0,120,.3,180),
 'heavy_aa':(170,.25,320,520,120,.28,7)}.items():
 t=data['turrets'][key]
 for field,value in zip(['damage','fire_rate','range','projectile_speed','turn_degrees','acquisition_delay','firing_arc_degrees'],stats):t[field]=value
# Keep each purchased permanent upgrade and its existing coefficient.
data['combat']['upgrade_damage_multiplier']=1.35
data['combat']['upgrade_range_step']=12
for key in ['scout','bomber']:
 data['enemies'][key].setdefault('ai',{})['mobility']={'period':4.2 if key=='scout' else 5.0,'duration':.45 if key=='scout' else .6,'multiplier':1.15 if key=='scout' else 1.18,'delay':1.4,'warning':.35}
for key,reduction in [('heavy',.20),('bomber',.15),('carrier',.25)]:
 data['enemies'][key].setdefault('ai',{})['armor_reduction']=reduction
for m in data['missions']:
 chapter=(m['id']-1)//5;p=data['balance']['wave_policy']
 m['build_time']=p['build_seconds'][chapter]
 m['target_minutes']=[2,5]
 for i,w in enumerate(m['waves']):
  w['interval']=round(max(.44,float(w['interval'])*p['interval_multiplier'][chapter]),3)
  w['burst_size']=1 if m['id']==1 and i==0 else p['burst_size'][chapter]
  w['burst_gap']=p['burst_gap'][chapter]
  w['deployment']='escort'
  for j,g in enumerate(w['groups']):
   if data['enemies'][g['enemy']].get('boss'):continue
   g['count']=math.ceil(g['count']*p['count_multiplier'][chapter])
   g['path']=(i+j)%len(m['paths'])
   g['formation']='pincer' if g['enemy'] in ['scout','bomber','stealth'] else 'fan' if g['enemy']=='assault' else 'column'
  # Heavy decoys and shield/EMP escorts are actual existing actors, not scripted leaks.
  if m['id']>=6 and i>=2 and not any(g['enemy']=='bomber' for g in w['groups']):
   w['groups'].append({'enemy':'bomber','count':1 if chapter<3 else 2,'path':(i+1)%len(m['paths']),'formation':'pincer'})
 m['preparation']='Cover split entry lanes; use the primary cannon during reload gaps. '+m['preparation']
(root/'data/definitions.json').write_text(json.dumps(data,indent=2)+'\n')
print('Rebalanced 25 missions; geometry, HP, costs, research and rewards retained')

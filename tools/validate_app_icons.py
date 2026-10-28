#!/usr/bin/env python3
"""Read-only validation of launcher PNGs and Godot 4.6.3 references."""
import argparse,json,math,struct
from pathlib import Path
from PIL import Image
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
DIRECTORY=ROOT/'assets/branding'
FILES={
 'google_play_icon_512.png':(512,'RGB'),
 'android_launcher_icon_192.png':(192,'RGB'),
 'android_adaptive_foreground_432.png':(432,'RGBA'),
 'android_adaptive_background_432.png':(432,'RGB'),
 'android_monochrome_432.png':(432,'RGBA'),
}
PROPERTIES={
 'launcher_icons/main_192x192':'android_launcher_icon_192.png',
 'launcher_icons/adaptive_foreground_432x432':'android_adaptive_foreground_432.png',
 'launcher_icons/adaptive_background_432x432':'android_adaptive_background_432.png',
 'launcher_icons/adaptive_monochrome_432x432':'android_monochrome_432.png',
}
def radius(alpha,center=None):
 y,x=np.where(alpha>0)
 assert len(x),'Empty foreground'
 if center is None:center=((int(x.min())+int(x.max()))/2,(int(y.min())+int(y.max()))/2)
 return float(np.sqrt((x-center[0])**2+(y-center[1])**2).max())
def main():
 parser=argparse.ArgumentParser();parser.add_argument('--foreground-scale',type=Path);args=parser.parse_args()
 if args.foreground_scale:
  image=Image.open(args.foreground_scale)
  assert image.mode=='RGBA','Foreground master must have real alpha'
  print(f'{128.0/radius(np.array(image.getchannel("A")))*100:.10f}')
  return
 report={}
 for name,(size,mode) in FILES.items():
  path=DIRECTORY/name;image=Image.open(path);payload=path.read_bytes()
  assert payload[:8]==b'\x89PNG\r\n\x1a\n',name
  assert image.size==(size,size) and image.mode==mode,(name,image.size,image.mode)
  bit_depth,color_type=payload[24:26]
  assert bit_depth==8 and color_type==(6 if mode=='RGBA' else 2),(name,bit_depth,color_type)
  values=np.array(image)
  if mode=='RGB':
   # The original white, pre-rounded outer corners must not survive.
   for x,y in [(0,0),(0,size-1),(size-1,0),(size-1,size-1)]:
    assert int(values[y,x].max())<110,(name,'Unwanted bright corner')
  else:
   alpha=values[:,:,3]
   assert alpha.min()==0 and alpha.max()==255,(name,'Missing transparent/solid regions')
   assert radius(alpha,((size-1)/2,(size-1)/2))<=132,(name,'Outside 66dp safe circle')
   if 'monochrome' in name:assert np.all(values[:,:,:3][alpha>0]==255),'Monochrome must be white + alpha only'
  if name=='google_play_icon_512.png':assert len(payload)<=512000,'Play PNG exceeds 512KB'
  report[name]={'dimensions':list(image.size),'mode':mode,'bytes':len(payload)}
  if mode=='RGBA':report[name]['max_alpha_radius_px']=round(radius(values[:,:,3],((size-1)/2,(size-1)/2)),3)
 fg=np.array(Image.open(DIRECTORY/'android_adaptive_foreground_432.png').getchannel('A'))
 mono=np.array(Image.open(DIRECTORY/'android_monochrome_432.png').getchannel('A'))
 assert np.array_equal(fg,mono),'Themed mask must preserve the foreground silhouette'
 sections=[];current=None
 for line in (ROOT/'export_presets.cfg').read_text().splitlines():
  if line.startswith('[preset.') and line.endswith('.options]'):
   current={};sections.append(current)
  elif line.startswith('['):current=None
  elif current is not None and '=' in line:
   key,value=line.split('=',1);current[key]=value.strip('"')
 assert len(sections)==3,'Inspect any new export presets before changing validation'
 for section in sections:
  for key,name in PROPERTIES.items():
   assert section.get(key)=='res://assets/branding/'+name,(key,section.get(key))
  assert section['package/unique_name']=='com.vladovidiu.dronekiller'
 assert 'config/icon="res://assets/branding/android_launcher_icon_192.png"' in (ROOT/'project.godot').read_text()
 print(json.dumps({'pngs':report,'safe_circle_diameter_px':264,'safe_circle_dp':66,'adaptive_canvas_dp':108,'export_presets_checked':len(sections)},indent=2))
if __name__=='__main__':main()

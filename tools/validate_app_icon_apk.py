#!/usr/bin/env python3
"""Verify actual Godot-generated density icons in a debug Android package."""
import argparse,io,json,zipfile
from pathlib import Path
from PIL import Image
import numpy as np
from validate_app_icons import radius
parser=argparse.ArgumentParser();parser.add_argument('apk',type=Path);args=parser.parse_args()
expected={'mipmap-xxxhdpi-v4':(192,432),'mipmap-xxhdpi-v4':(144,324),'mipmap-xhdpi-v4':(96,216),'mipmap-hdpi-v4':(72,162),'mipmap-mdpi-v4':(48,108),'mipmap':(192,432)}
results=[]
with zipfile.ZipFile(args.apk) as z:
 for density,(legacy,adaptive) in expected.items():
  for name in ['icon','icon_foreground','icon_background','icon_monochrome']:
   path=f'res/{density}/{name}.webp'
   assert path in z.namelist(),path
   image=Image.open(io.BytesIO(z.read(path)))
   size=legacy if name=='icon' else adaptive
   assert image.size==(size,size),(path,image.size)
   if name in ['icon_foreground','icon_monochrome']:
    assert image.mode=='RGBA',path
    data=np.array(image);alpha=data[:,:,3]
    assert alpha.min()==0 and alpha.max()==255,path
    # Density resampling can add a faint one-pixel antialias fringe. All
    # meaningful-opacity pixels still have to remain inside the 66dp circle.
    meaningful=np.where(alpha>=32,alpha,0)
    safe=size*(66/108)/2
    assert radius(meaningful,((size-1)/2,(size-1)/2))<=safe,(path,'Unsafe critical content')
    if name=='icon_monochrome':assert np.all(data[:,:,:3][alpha>0]==255),path
   results.append({'resource':path,'size':size,'mode':image.mode})
 assert 'res/mipmap-anydpi-v26/icon.xml' in z.namelist(),'Adaptive icon XML missing'
 for entry in z.namelist():
  assert not entry.startswith('assets/docs/branding/source/'),'Working masters must not ship as game resources'
print(json.dumps({'apk':str(args.apk),'density_resources_verified':len(results),'resources':results},indent=2))

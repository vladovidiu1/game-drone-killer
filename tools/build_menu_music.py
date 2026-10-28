#!/usr/bin/env python3
"""Render the original 'Night Watch' ambient loop; no samples or hosted service.
Composition and synthesis are project-authored, distributed under assets/ASSET_LICENSE.md (MIT).
Requires numpy and ffmpeg only when regenerating the checked-in Ogg asset.
"""
from pathlib import Path
import subprocess, tempfile, wave
import numpy as np
ROOT = Path(__file__).resolve().parents[1]
RATE = 44100
DURATION = 48.0
track = np.zeros((int(RATE*DURATION),2),dtype=np.float64)
def note(midi, start, length, gain, pan, pad=False):
    t=np.arange(int(RATE*length))/RATE
    hz=440*2**((midi-69)/12)
    if pad:
        attack=np.minimum(1,t/1.2)
        release=np.minimum(1,(length-t)/1.8)
        envelope=attack*release
        tone=(np.sin(2*np.pi*hz*t)+.22*np.sin(2*np.pi*(hz*1.0017)*t)+.12*np.sin(4*np.pi*hz*t))/1.34
    else:
        envelope=np.minimum(1,t/.015)*np.exp(-t/1.1)*np.minimum(1,(length-t)/.25)
        tone=np.sin(2*np.pi*hz*t)+.15*np.sin(4*np.pi*hz*t)*np.exp(-t)
    signal=tone*envelope*gain
    indexes=(int(start*RATE)+np.arange(len(t)))%len(track)
    track[indexes,0]+=signal*np.sqrt((1-pan)/2)
    track[indexes,1]+=signal*np.sqrt((1+pan)/2)
chords=[[52,55,59,66],[48,52,55,59],[43,50,55,62],[50,54,57,64]]
melodies=[[71,66,67,64],[67,64,62,59],[62,67,69,71],[69,66,64,62]]
for cycle in range(2):
    for bar,chord in enumerate(chords):
        start=cycle*24+bar*6
        for index,pitch in enumerate(chord):
            note(pitch,start,7.5,.115,[-.65,.4,-.25,.7][index],True)
        note(chord[0]-12,start,6,.09,0,True)
        for index,pitch in enumerate(melodies[bar]):
            note(pitch,start+.75+index*1.5,2.8,.065,(-.3 if index%2 else .3))
track*=.65/np.max(np.abs(track))
asset=ROOT/'assets/audio/night_watch.ogg';asset.parent.mkdir(parents=True,exist_ok=True)
with tempfile.TemporaryDirectory() as temp:
    wav=Path(temp)/'night_watch.wav'
    with wave.open(str(wav),'wb') as output:
        output.setnchannels(2);output.setsampwidth(2);output.setframerate(RATE)
        output.writeframes((track*32767).astype('<i2').tobytes())
    subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-i',str(wav),'-map_metadata','-1',
                    '-c:a','libvorbis','-q:a','4','-metadata','title=Night Watch',
                    '-metadata','artist=DRONE KILLER: FRONTLINE contributors',str(asset)],check=True)
print('Rendered original 48-second seamless ambient loop:',asset)

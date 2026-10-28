#!/usr/bin/env python3
"""Install checksum-pinned MIT AdMob bridge binaries for exactly Godot 4.6.3."""
from pathlib import Path
import hashlib, os, urllib.request, zipfile
ROOT=Path(__file__).resolve().parents[1]
TOOLS=Path(os.environ.get('FRONTLINE_TOOLS','/workspace/toolchains'))
SHA256='f7fdf644d50c0e231d8f02ae044057e489d0bcafcf50e908a4858477e7ee05ee'
URL='https://github.com/poingstudios/godot-admob-plugin/releases/download/v5.1.0/android-template-v4.6.3.zip'
FILES=['ads/libs/poing-godot-admob-'+kind+'-'+variant+'.aar' for kind in ['ads','core'] for variant in ['debug','release']]
def main():
 path=TOOLS/'downloads/admob-v5.1.0-godot-4.6.3.zip';path.parent.mkdir(parents=True,exist_ok=True)
 if not path.exists():
  temporary=path.with_suffix('.part');urllib.request.urlretrieve(URL,temporary);temporary.replace(path)
 if hashlib.sha256(path.read_bytes()).hexdigest()!=SHA256:
  raise RuntimeError('AdMob template checksum mismatch; do not use this download.')
 with zipfile.ZipFile(path) as archive:
  for name in FILES:
   output=ROOT/'addons/admob/android/bin'/name;output.parent.mkdir(parents=True,exist_ok=True)
   data=archive.read(name)
   if not output.exists() or output.read_bytes()!=data:output.write_bytes(data)
 print('Verified AdMob 5.1.0 native bridge / Godot 4.6.3; account configuration remains separate.')
if __name__=='__main__':main()

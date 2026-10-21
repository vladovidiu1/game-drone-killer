"""Original editable tactical cartography and matching UI symbols; no map service."""
from pathlib import Path
import math,random,json
root=Path(__file__).resolve().parents[1];rng=random.Random(705)
out=root/'assets/ui';out.mkdir(exist_ok=True)
svg=['<svg xmlns="http://www.w3.org/2000/svg" width="1600" height="900" viewBox="0 0 1600 900"><defs><linearGradient id="sea" x2="1" y2="1"><stop stop-color="#152c3a"/><stop offset="1" stop-color="#0b1722"/></linearGradient><linearGradient id="land" x2=".6" y2="1"><stop stop-color="#48534a"/><stop offset=".5" stop-color="#3e483e"/><stop offset="1" stop-color="#5a5141"/></linearGradient><radialGradient id="relief"><stop stop-color="#a0a08a" stop-opacity=".4"/><stop offset="1" stop-color="#273329" stop-opacity="0"/></radialGradient><pattern id="grid" width="100" height="100" patternUnits="userSpaceOnUse"><path d="M100 0H0V100" fill="none" stroke="#9cb6bd" stroke-opacity=".075"/></pattern><clipPath id="country"><path d="M44 197C73 166 85 137 159 125L297 92 448 128 601 84 755 103 893 74 1055 125 1198 72 1384 104 1537 183 1570 306 1537 452 1577 590 1500 763 1377 843 1225 818 1093 865 932 823 789 853 654 805 503 839 335 801 203 828 112 733 68 606 95 478 37 369Z"/></clipPath></defs>','<rect width="1600" height="900" fill="url(#sea)"/>']
coast='M44 197C73 166 85 137 159 125L297 92 448 128 601 84 755 103 893 74 1055 125 1198 72 1384 104 1537 183 1570 306 1537 452 1577 590 1500 763 1377 843 1225 818 1093 865 932 823 789 853 654 805 503 839 335 801 203 828 112 733 68 606 95 478 37 369Z'
svg+=[f'<path d="{coast}" fill="none" stroke="#557e8a" stroke-opacity=".12" stroke-width="22"/>',f'<path d="{coast}" fill="url(#land)" stroke="#71928c" stroke-width="2"/>','<g clip-path="url(#country)">']
for cx,cy,rx,ry in [(430,300,330,220),(1040,180,420,220),(1350,530,270,310),(750,710,340,180)]:
 svg.append(f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="url(#relief)"/>')
 for band in range(9):
  points=[]
  for j in range(65):
   a=j*math.tau/64;factor=.28+band*.077;noise=1+.1*math.sin(a*5+cx)+.05*math.cos(a*9)
   points.append(f'{cx+math.cos(a)*rx*factor*noise:.1f},{cy+math.sin(a)*ry*factor*noise:.1f}')
  svg.append('<polygon points="'+' '.join(points)+'" fill="none" stroke="#b8b39a" stroke-opacity=".1" stroke-width="1"/>')
for i in range(180):
 x=rng.randrange(90,1510);y=rng.randrange(100,820);r=rng.randrange(4,25)
 svg.append(f'<ellipse cx="{x}" cy="{y}" rx="{r}" ry="{r*.55:.1f}" fill="#1f382f" opacity=".17"/>')
svg.append('<path d="M780 70C710 190 850 265 720 375S580 495 675 610 705 730 645 845" fill="none" stroke="#182e38" stroke-width="23"/>')
svg.append('<path d="M780 70C710 190 850 265 720 375S580 495 675 610 705 730 645 845" fill="none" stroke="#63808b" stroke-opacity=".45" stroke-width="10"/>')
positions=[]
for c in range(5):
 for j in range(5):
  row=4-j if c%2==0 else j
  positions.append([170+c*310+(32 if row%2 else -22)-(20 if c==4 else 0),190+row*135])
for i in range(1,25):
 a,b=positions[i-1],positions[i]
 svg.append(f'<path d="M{a[0]} {a[1]}C{a[0]+65} {a[1]-20} {b[0]-65} {b[1]+20} {b[0]} {b[1]}" fill="none" stroke="#1e2929" stroke-width="9"/>')
 svg.append(f'<path d="M{a[0]} {a[1]}C{a[0]+65} {a[1]-20} {b[0]-65} {b[1]+20} {b[0]} {b[1]}" fill="none" stroke="#a8a38c" stroke-opacity=".42" stroke-width="2"/>')
for i,(x,y) in enumerate(positions):
 # Settlements sit beside, rather than under, the selectable operation marker.
 cx=x-45;cy=y+46
 for b in range(6+(i%4)*3):
  bx=cx+(b%5)*9;by=cy+(b//5)*12;w=5+rng.randrange(3);h=6+rng.randrange(4)
  svg.append(f'<rect x="{bx+2}" y="{by+3}" width="{w}" height="{h}" fill="#142129" opacity=".7"/><rect x="{bx}" y="{by}" width="{w}" height="{h}" fill="#9b9d8d" opacity=".6"/>')
 if i%5==4:
  svg.append(f'<path d="M{x-65} {y+32}h65v36h-65Z" fill="none" stroke="#b3b5a4" stroke-opacity=".55"/><path d="M{x-57} {y+39}h46m-46 9h46m-46 9h46" stroke="#99a8a4" stroke-opacity=".5"/>')
svg+=['</g>','<rect width="1600" height="900" fill="url(#grid)"/>','<path d="M1418 95L1490 180 1460 280 1505 390 1460 500 1495 650 1430 800" fill="none" stroke="#c16b61" stroke-opacity=".65" stroke-width="3" stroke-dasharray="10 8"/>','</svg>']
(out/'asteria_strategy.svg').write_text(''.join(svg)+'\n')
icons={
 'wave':'<path d="M3 16l5-8 4 8 4-8 5 8M3 21h18"/>',
 'drone':'<path d="M8 8h8v8H8Z M8 8L4 4m12 4l4-4M8 16l-4 4m12-4l4 4"/><circle cx="4" cy="4" r="2.5"/><circle cx="20" cy="4" r="2.5"/><circle cx="4" cy="20" r="2.5"/><circle cx="20" cy="20" r="2.5"/>',
 'ammo':'<path d="M6 20V7l3-5 3 5v13Zm9 0V8l3-5 3 5v12ZM6 16h6m3 0h6"/>',
 'reload':'<path d="M19 8a8 8 0 1 0 0 9M19 2v6h-6"/>',
 'speed':'<path d="M3 5l8 7-8 7Zm10 0l8 7-8 7Z"/>',
 'research':'<path d="M9 3h6M10 3v6l-6 10v2h16v-2L14 9V3M8 14h8"/>',
 'ability':'<path d="M13 2L4 14h7l-1 8 10-13h-7Z"/>',
 'checkpoint':'<path d="M12 2l9 10-9 10-9-10ZM7 12l3 3 7-7"/>',
 'map':'<path d="M2 6l7-3 7 3 6-3v15l-6 3-7-3-7 3ZM9 3v15m7-12v15"/>',
 'lock':'<rect x="5" y="10" width="14" height="12" rx="2"/><path d="M8 10V6a4 4 0 0 1 8 0v4M12 15v3"/>',
 'back':'<path d="M14 4l-8 8 8 8M6 12h16"/>',
 'target':'<circle cx="12" cy="12" r="7"/><path d="M12 1v6m0 10v6M1 12h6m10 0h6"/>',
 'repair':'<path d="M9 3h6v6h6v6h-6v6H9v-6H3V9h6Z"/>'}
for name,shapes in icons.items():
 (out/f'icon_{name}.svg').write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><g fill="none" stroke="#E9F0F6" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">{shapes}</g></svg>\n')
vertices=[]
for r in range(6):
 vertices.append([[35+c*310+(rng.randrange(-18,19) if c not in (0,5) else 0),122+r*135+(rng.randrange(-14,15) if r not in (0,5) else 0)] for c in range(6)])
territories=[]
for i,(x,y) in enumerate(positions):
 c=i//5;j=i%5;r=4-j if c%2==0 else j
 territories.append({'id':i+1,'position':[x,y],'polygon':[vertices[r][c],vertices[r][c+1],vertices[r+1][c+1],vertices[r+1][c]],'kind':['OUTPOST','VILLAGE','DEPOT','BRIDGE','CITY'][j]})
(out/'campaign_layout.json').write_text(json.dumps({'size':[1600,900],'territories':territories},indent=2)+'\n')
print('Authored strategic terrain, 13 matching icons and 25 visual map bindings')

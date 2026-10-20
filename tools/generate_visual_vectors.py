from pathlib import Path
import json,math
r=Path(__file__).resolve().parents[1];a=r/'assets'
def svg(path,w,h,body,defs=''):
 (a/path).write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}"><defs>{defs}</defs>{body}</svg>\n')
metal='<linearGradient id="steel" x2=".8" y2="1"><stop stop-color="#65788a"/><stop offset=".3" stop-color="#303D4C"/><stop offset=".7" stop-color="#24313e"/><stop offset="1" stop-color="#101720"/></linearGradient><linearGradient id="edge" x2=".7" y2="1"><stop stop-color="#bac5cb"/><stop offset=".25" stop-color="#617989"/><stop offset=".55" stop-color="#27333e"/><stop offset=".8" stop-color="#617383"/><stop offset="1" stop-color="#151B24"/></linearGradient><radialGradient id="shadow"><stop stop-color="#060a10" stop-opacity=".6"/><stop offset=".65" stop-color="#060a10" stop-opacity=".25"/><stop offset="1" stop-color="#060a10" stop-opacity="0"/></radialGradient>'
svg(Path('effects/soft_shadow.svg'),128,64,'<ellipse cx="64" cy="32" rx="63" ry="31" fill="url(#shadow)"/>',metal)
body='<path d="M18 7H62L77 22V58L62 73H18L3 58V22Z" fill="#121922" stroke="#111720" stroke-width="3"/><path d="M19 5H61L75 20V57L61 71H19L5 57V20Z" fill="url(#steel)" stroke="#71808b"/><path d="M24 13H56L67 24V52L56 63H24L13 52V24Z" fill="#26323b" stroke="#141b22"/><circle cx="40" cy="38" r="22" fill="none" stroke="url(#edge)" stroke-width="4"/><circle cx="40" cy="38" r="15" fill="#39454b" stroke="#151b24"/>'
for x,y in [(17,18),(63,18),(17,58),(63,58)]:body+=f'<circle cx="{x}" cy="{y}" r="2.6" fill="#101720"/><path d="M{x-1.5} {y}h3" stroke="#85939d"/>'
for angle in [0,90,180,270]:body+=f'<path d="M35 7h10v3H35Z" fill="#86745E" transform="rotate({angle} 40 38)"/>'
svg(Path('turrets/placement_pad.svg'),80,80,body,metal)
body='<ellipse cx="160" cy="74" rx="153" ry="22" fill="url(#shadow)"/><path d="M18 30L38 13H280L303 34V77H18Z" fill="#242d36"/><path d="M18 30H303V39H18Z" fill="url(#edge)"/><path d="M30 24L44 5H272L289 24V54H30Z" fill="url(#steel)" stroke="#151B24" stroke-width="2"/><path d="M45 10H270L281 25H35Z" fill="#64707a"/><path d="M62 14H253L263 23H53Z" fill="#3e4b56"/><path d="M110 30H209V66H110Z" fill="#18232e" stroke="#71818b"/><path d="M117 36H202V64H117Z" fill="#0f1720"/>'
for x in range(46,277,19):body+=f'<path d="M{x} 29h11v6h-11Z" fill="#171f27"/><path d="M{x} 29h11" stroke="#37B7E5" stroke-opacity=".6"/>'
for x in [39,261]:
 body+=f'<path d="M{x} 43h25v18h-25Z" fill="#1c2833" stroke="#61717f"/>'
 for y in range(46,59,4):body+=f'<path d="M{x+3} {y}h19" stroke="#81909b" stroke-width="1.2"/>'
for x in range(25,304,22):body+=f'<path d="M{x} 74l5-6h8l-5 6Z" fill="#b49c6b"/>'
svg(Path('environment/command_bunker.svg'),320,100,body,metal)
for kind in ['missile','laser','emp']:
 body='<ellipse cx="64" cy="91" rx="43" ry="15" fill="url(#shadow)"/><path d="M30 49L42 35H86L98 49V102L86 115H42L30 102Z" fill="url(#steel)" stroke="#879aa6" stroke-width="2"/><path d="M39 53H89V101H39Z" fill="#24333e" stroke="#121a24"/>'
 if kind=='missile':
  for x in [18,77]:
   body+=f'<rect x="{x}" y="17" width="33" height="76" rx="4" fill="url(#edge)" stroke="#121922" stroke-width="3"/><rect x="{x+4}" y="22" width="25" height="61" fill="#1e2b36"/>'
   for y in [32,52,72]:body+=f'<ellipse cx="{x+16}" cy="{y}" rx="9" ry="7" fill="#10161d" stroke="#6f8390"/><ellipse cx="{x+16}" cy="{y}" rx="4" ry="3" fill="#7b8589"/>'
 elif kind=='laser':
  body+='<path d="M54 10H74V77H54Z" fill="url(#edge)" stroke="#0f1720" stroke-width="2"/><path d="M58 5H70V18H58Z" fill="#9baeb9"/>'
  for y in range(24,66,8):body+=f'<path d="M49 {y}h30v4H49Z" fill="#526c7c" stroke="#15232e"/>'
  body+='<circle cx="64" cy="42" r="6" fill="#37B7E5"/>'
 else:
  body+='<circle cx="64" cy="59" r="37" fill="url(#edge)" stroke="#17232f" stroke-width="3"/><circle cx="64" cy="59" r="29" fill="url(#steel)"/><path d="M44 59H84M64 39V79" stroke="#8194a0" stroke-width="3"/><circle cx="64" cy="59" r="11" fill="#24343f" stroke="#37B7E5" stroke-width="2"/><path d="M64 9V35" stroke="url(#edge)" stroke-width="7"/>'
 for x in [43,82]:body+=f'<path d="M{x} 95v9h3v-9" stroke="#37B7E5" stroke-width="2"/>'
 svg(Path(f'turrets/{kind}_head.svg'),128,128,body,metal)
svg(Path('projectiles/tracer.svg'),64,16,'<path d="M2 8L53 5L63 8L53 11Z" fill="url(#trail)"/><path d="M39 8H61" stroke="#fff8e7" stroke-width="2"/>','<linearGradient id="trail"><stop stop-color="#e4c89d" stop-opacity="0"/><stop offset=".8" stop-color="#d2e7ef" stop-opacity=".8"/><stop offset="1" stop-color="#ffffff"/></linearGradient>')
svg(Path('projectiles/missile.svg'),64,24,'<path d="M1 12L20 6V18Z" fill="url(#flame)"/><path d="M17 8H45L59 12L45 16H17Z" fill="url(#edge)" stroke="#19212b"/><path d="M24 8L18 2H28L33 8M24 16L18 22H28L33 16" fill="#718796"/><path d="M41 8H45V16H41Z" fill="#FF9C42"/>',metal+'<linearGradient id="flame"><stop stop-color="#f29442" stop-opacity="0"/><stop offset="1" stop-color="#fff7c1"/></linearGradient>')
svg(Path('effects/muzzle_flash.svg'),128,64,'<path d="M10 32L43 18L37 5L70 24L122 32L70 40L37 59L43 46Z" fill="url(#flare)"/><ellipse cx="31" cy="32" rx="22" ry="9" fill="#fff9d9"/>','<radialGradient id="flare"><stop stop-color="#fffde5"/><stop offset=".35" stop-color="#ffc276" stop-opacity=".85"/><stop offset="1" stop-color="#e59c4e" stop-opacity="0"/></radialGradient>')
icons={'shield':'<path d="M12 3l7 3v6c0 4-7 9-7 9S5 16 5 12V6Z"/><path d="M12 7v9M8 12h8"/>','crosshair':'<circle cx="12" cy="12" r="6"/><path d="M12 1v5m0 12v5M1 12h5m12 0h5"/>','arsenal':'<path d="M4 8h16v12H4ZM3 8l3-4h12l3 4M9 9v11m6-11v11"/>','settings':'<path d="M9 3h6l1 3 3 1 2 5-2 5-3 1-1 3H9l-1-3-3-1-2-5 2-5 3-1Z"/><circle cx="12" cy="12" r="3"/>','play':'<path d="M8 4l12 8-12 8Z"/>','pause':'<path d="M7 5v14m10-14v14"/>','credits':'<path d="M5 5h14v14H5Z"/><path d="M15 8h-5l-2 4 2 4h5M12 3v3m0 12v3"/>','chevron':'<path d="M8 4l8 8-8 8"/>','exit':'<path d="M11 4H4v16h7m3-13 5 5-5 5m-5-5h10"/>'}
for name,path in icons.items():svg(Path(f'ui/icon_{name}.svg'),24,24,f'<g fill="none" stroke="#E9F0F6" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">{path}</g>')
svg(Path('ui/sentinel_badge.svg'),80,80,'<path d="M40 4L69 15V41L40 73L11 41V15Z" fill="#1c2935" stroke="#698598" stroke-width="2"/><path d="M40 11L61 19V39L40 62L19 39V19Z" fill="none" stroke="#37B7E5"/><path d="M27 27H52L43 35H32L48 43L40 53L26 43H39L24 35Z" fill="#E9F0F6"/>')
# Atlas regions/pivots are hand-reviewed in assets/visual_catalog.json.
# Do not overwrite approved bindings when regenerating vector resources.

"""Original editable projectile cutaway/vector illustrations; no third-party art."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]/'assets/projectiles'
colors={'standard':'82E8FC','armor_piercing':'EFBD6B','explosive':'FF857C','emp':'B29AFF','cryo':'85DDEB','railgun':'D5E6FA'}
for i,(name,color) in enumerate(colors.items()):
 nose='114,24 90,11 90,37' if name!='armor_piercing' else '124,24 88,16 88,32'
 detail=''
 if name=='emp':detail=f'<circle cx="68" cy="24" r="13" fill="#151B24" stroke="#{color}" stroke-width="3"/><path d="M61 17L74 23L64 26L71 32" fill="none" stroke="#{color}" stroke-width="2"/>'
 elif name=='cryo':detail=f'<path d="M69 12V36M58 18L80 30M58 30L80 18M65 14L69 18L73 14M65 34L69 30L73 34" fill="none" stroke="#{color}" stroke-width="2"/>'
 elif name=='railgun':detail=f'<path d="M30 9H99L113 16H31ZM30 39H99L113 32H31Z" fill="#44657F" stroke="#{color}"/><path d="M52 24H118" stroke="#{color}" stroke-width="3"/>'
 elif name=='explosive':detail='<path d="M61 12V36M74 12V36M87 12V36" stroke="#151B24" stroke-width="3"/><rect x="65" y="18" width="5" height="12" fill="#FF9C42"/>'
 else:detail=f'<path d="M40 17H81M40 31H81" stroke="#{color}" stroke-opacity=".6"/><circle cx="54" cy="24" r="2" fill="#{color}"/>'
 svg=f'''<svg xmlns="http://www.w3.org/2000/svg" width="128" height="48" viewBox="0 0 128 48"><defs><linearGradient id="steel" x2="0" y2="1"><stop stop-color="#718395"/><stop offset=".4" stop-color="#303D4C"/><stop offset="1" stop-color="#151B24"/></linearGradient></defs><path d="M10 16H93L120 28L94 41H10Z" fill="#080D14" opacity=".6"/><rect x="14" y="12" width="80" height="24" rx="5" fill="url(#steel)" stroke="#90A3B5"/><polygon points="{nose}" fill="#{color}" stroke="#E9F0F6" stroke-width="1"/><rect x="9" y="11" width="15" height="26" rx="2" fill="#44657F" stroke="#A3B4C0"/><path d="M13 15V33M18 15V33M29 14V34M34 14V34" stroke="#151B24"/>{detail}</svg>'''
 (root/(name+'_round.svg')).write_text(svg+'\n')

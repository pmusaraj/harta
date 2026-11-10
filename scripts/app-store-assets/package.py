#!/usr/bin/env python3
"""Package unmodified XCTest screenshots with upload names and an offline review gallery."""
import hashlib
import html
import json
from pathlib import Path
import shutil
import struct
import zipfile

root = Path('output/app-store')
sets = [('medium', 'iphone-medium', (1206, 2622), 'iPhone · Dynamic Island, medium'),
        ('large-final', 'iphone-large', (1320, 2868), 'iPhone · Dynamic Island, large'),
        ('ipad-retry', 'ipad-13-inch', (2064, 2752), 'iPad · 13-inch')]
labels = {'01-explore': 'Explore your surroundings', '02-your-places': 'Keep your favourite places close',
          '03-plan-a-visit': 'Choose your way there', '04-make-it-yours': 'Make each place your own',
          '05-explore-more': 'See what matters to you'}
manifest = []
sections = []
for source, destination, expected, title in sets:
    captured = root / ('capture-' + source)
    target = root / 'screenshots' / destination
    target.mkdir(parents=True, exist_ok=True)
    records = json.loads((captured / 'manifest.json').read_text())
    found = {}
    for test in records:
        for attachment in test['attachments']:
            stem = attachment['suggestedHumanReadableName'].split('_')[0]
            if source == 'ipad-retry' and stem == '05-explore-more':
                continue
            if stem not in labels:
                continue
            original = captured / attachment['exportedFileName']
            content = original.read_bytes()
            assert content[:8] == b'\x89PNG\r\n\x1a\n'
            width, height, depth, colour = struct.unpack('>IIBB', content[16:26])
            assert (width, height) == expected, (source, width, height, expected)
            assert colour in (0, 2, 3), ('PNG must not have alpha', original, colour)
            file = target / (stem + '.png')
            shutil.copyfile(original, file)
            found[stem] = file
            manifest.append(dict(file=str(file.relative_to(root)), width=width, height=height,
                                 sha256=hashlib.sha256(content).hexdigest(), source='Unmodified simulator screenshot'))
    assert len(found) == (4 if source == 'ipad-retry' else 5), (source, list(found))
    cards = ''.join(f'<a class="card" href="{p.relative_to(root)}" target="_blank"><img loading="lazy" src="{p.relative_to(root)}" alt="{labels[stem]}"><span>{stem[:2]} / {labels[stem]}</span><small>{expected[0]} × {expected[1]} · PNG</small></a>' for stem,p in sorted(found.items()))
    sections.append(f'<section id="{destination}"><h2>{title}</h2><div class="grid">{cards}</div></section>')
(root/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
metadata=json.loads((root/'copy/app-store-en-US.json').read_text())
page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Harta · App Store assets</title><style>
:root{color-scheme:light;--ink:#004d50;--paper:#fbf8ef}*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:17px/1.5 -apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif}header,main,footer{max-width:1500px;margin:auto;padding:40px}header{display:flex;align-items:center;gap:32px;padding-top:64px}header img{width:120px;border-radius:26px}h1{font-size:clamp(40px,6vw,76px);letter-spacing:-3px;margin:0;line-height:1.1}p{max-width:800px}nav{display:flex;gap:12px;flex-wrap:wrap;margin:28px 0}nav a,.download{padding:10px 18px;border:1px solid #b5c8bf;border-radius:30px;color:inherit;text-decoration:none}nav a:hover,.download:hover{background:#e8efe7}h2{font-size:28px;letter-spacing:-.7px;margin-top:60px}.grid{display:grid;grid-template-columns:repeat(5,minmax(0,1fr));gap:20px}.card{color:inherit;text-decoration:none;display:block}.card img{width:100%;border-radius:16px;border:1px solid #ced6ca;box-shadow:0 8px 30px #004d5010}.card span{display:block;font-weight:650;margin-top:14px}.card small{opacity:.65}.brand{display:flex;flex-wrap:wrap;gap:20px}.brand img{max-width:100%;width:560px;border-radius:16px}pre{white-space:pre-wrap;max-width:900px;background:white;padding:24px;border-radius:16px;font:inherit}.note{padding:18px 22px;border-left:4px solid #ff5f17;background:#fff2df}footer{border-top:1px solid #d9dfd2;font-size:14px}@media(max-width:900px){.grid{grid-template-columns:repeat(2,minmax(0,1fr))}header,main,footer{padding:24px}}@media(max-width:500px){header img{width:80px}.grid{gap:14px}h1{letter-spacing:-1px}}
</style><header><img src="brand/harta-icon-1024.png" alt="Harta app icon"><div><h1>Your places.<br>Your way.</h1><p>Harta / App Store asset pack / English</p></div></header><main>
<p>Fresh captures of the app, with sample saved places around Montréal. Click any screenshot to open the original upload-ready PNG.</p><nav><a href="#iphone-medium">iPhone medium</a><a href="#iphone-large">iPhone large</a><a href="#ipad-13-inch">iPad 13-inch</a><a href="#brand">Brand</a><a href="#copy">Listing copy</a><a href="README.md">Upload guide</a></nav>
'''+''.join(sections)+'''<section id="brand"><h2>The Harta mark</h2><div class="brand"><a href="brand/harta-wordmark-light.svg"><img src="brand/harta-wordmark-light.svg" alt="Harta wordmark on a light background"></a><a href="brand/harta-wordmark-dark.svg"><img src="brand/harta-wordmark-dark.svg" alt="Harta wordmark on a dark background"></a></div><p><a class="download" href="brand/harta-icon-1024.png" download>Download 1024 × 1024 icon</a></p><p>The app icon is the original asset already included in the build. SVG wordmarks are supporting brand assets, not App Store screenshot uploads.</p></section><section id="copy"><h2>App-page copy</h2><p><strong>Subtitle:</strong> '''+html.escape(metadata['subtitle'])+'''</p><p>'''+html.escape(metadata['promotional_text'])+'''</p><pre>'''+html.escape(metadata['description'])+'''</pre><a class="download" href="copy/app-store-en-US.md">All listing fields</a><p class="note">Supply support and privacy-policy URLs and the copyright holder before submission. Verify family sharing in TestFlight before publishing the sharing claims.</p></section></main><footer>Captured from Harta on iOS/iPadOS 26 simulators. Map-provider attribution is preserved. No personal saved places or account information are included.</footer></html>'''
(root/'index.html').write_text(page)
with zipfile.ZipFile(root.parent/'Harta-App-Store-Assets.zip','w',zipfile.ZIP_DEFLATED) as archive:
    for file in sorted(root.rglob('*')):
        if file.is_file() and not any(p.startswith('capture-') for p in file.relative_to(root).parts):
            archive.write(file,Path('Harta-App-Store-Assets')/file.relative_to(root))
print('Packaged',len(manifest),'screenshots, brand assets, listing copy, and gallery.')

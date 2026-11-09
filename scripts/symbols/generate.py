"""Refresh symbol names/search keywords from Apple's installed SF Symbols app.

Only metadata is bundled; artwork is rendered by the OS using public APIs.
Usage: python3 scripts/symbols/generate.py [path/to/SF Symbols.app]
"""
import json
import plistlib
import sys
from pathlib import Path

app = Path(sys.argv[1] if len(sys.argv) > 1 else '/Applications/SF Symbols.app')
metadata = app / 'Contents/Resources/Metadata'
names = plistlib.loads((metadata / 'name_availability.plist').read_bytes())['symbols']
keywords = plistlib.loads((metadata / 'symbol_search.plist').read_bytes())
output = Path(__file__).resolve().parents[2] / 'Harta/Resources/SymbolCatalog.json'
output.write_text(json.dumps({name: keywords.get(name, []) for name in sorted(names)},
                             ensure_ascii=False, indent=2) + '\n')
print(f'Wrote {len(names)} symbol names to {output.name}')

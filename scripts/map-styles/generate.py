"""Build bundled light/dark styles from the checked-in OpenFreeMap snapshots.
Run: python3 scripts/map-styles/generate.py
Upstream: https://github.com/hyperknot/openfreemap-styles
License: Harta/Resources/MapStyles/OpenFreeMapStylesLicense.txt
"""
import copy
import json
import pathlib
from overlays import optional_layers
root = pathlib.Path(__file__).resolve().parents[2]
out = root / "Harta/Resources/MapStyles"
names = ['quiet', 'everyday', 'walking', 'explore']
landmarks = ['attraction', 'museum', 'monument', 'art_gallery', 'theatre', 'stadium', 'town_hall', 'hospital', 'college', 'university', 'library']
transit = ['railway', 'station', 'bus', 'bus_stop', 'ferry_terminal']
for appearance in ['dark', 'light']:
    dark = appearance == 'dark'
    base = json.loads((pathlib.Path(__file__).parent / (appearance + '-base.json')).read_text())
    for name in names:
        s = copy.deepcopy(base)
        s['name'] = 'Harta ' + name + ' ' + appearance
        for l in s['layers']:
            lid, paint = l['id'], l.setdefault('paint', {})
            if lid == 'background': paint['background-color'] = ('#13171b' if dark else '#f7f7f2')
            if lid == 'water': paint['fill-color'] = ('#152b3a' if dark else '#c5dfe9')
            if lid == 'landuse_residential': paint['fill-color'] = ('#191e23' if dark else '#f1f1eb')
            if lid in ['landuse_park', 'landcover_wood', 'park']:
                paint['fill-color'] = (('#254333' if name == 'walking' else '#22342c') if dark else ('#cbe1bd' if name == 'walking' else '#dde7d5'))
            if lid == 'building':
                paint.update({'fill-color':('#262d34' if dark else '#e3e2dc'),'fill-outline-color':('#2d353d' if dark else '#d0d1ca')})
                l['minzoom'] = 16.5 if name == 'quiet' else 14.5
            if lid == 'highway_minor': paint['line-color'] = ('#3c444c' if dark else '#ffffff')
            if lid in ['highway_major_inner', 'highway_motorway_inner']: paint['line-color'] = ('#66717d' if dark else '#ffffff')
            if lid == 'highway_path':
                paint['line-color'] = (('#b9c997' if name == 'walking' else '#505a60') if dark else ('#708c49' if name == 'walking' else '#abb5a2'))
                if name in ['quiet', 'everyday']: l['minzoom'] = 17
                paint['line-width'] = ['interpolate',['linear'],['zoom'],13,0.6,18,1.6]
            if lid.startswith('railway'):
                if name == 'quiet': l['minzoom'] = 17
                if name == 'walking': paint['line-color'] = ('#8499b1' if dark else '#879bab')
            if lid.startswith('road_oneway') and name in ['quiet','everyday','walking']:
                l['minzoom'] = 17
            if l['type'] == 'symbol':
                paint['text-color'] = ('#a6adb4' if dark else '#59616b')
                paint['text-halo-color'] = ('#171b20' if dark else '#f7f7f2')
                paint['text-halo-width'] = 1.4
            if lid == 'highway_name_other' or lid in ['highway-name-path', 'highway-name-minor', 'highway-name-major']:
                l['layout'].update({'text-size':11,'text-transform':'none','symbol-spacing':450 if name=='quiet' else 280})
        if name != 'quiet':
            classes = landmarks + transit if name == 'everyday' else transit + ['park','hospital','library','museum','attraction']
            filt = ['all',['has','name']]
            if name != 'explore': filt.append(['match',['get','class'],classes,True,False])
            s['layers'].append({
                'id':'harta-places','type':'symbol','source':'openmaptiles','source-layer':'poi','minzoom':14,
                'filter':filt,
                'layout':{'text-field':['coalesce',['get','name:en'],['get','name']],
                          'text-font':['Noto Sans Regular'],'text-size':11 if name=='explore' else 12,
                          'text-max-width':9,'text-padding':12 if name=='everyday' else 5,
                          'symbol-sort-key':['coalesce',['get','rank'],100],
                          'text-allow-overlap':False},
                'paint':{'text-color':(('#c8bdaa' if name=='explore' else '#b3c7cb') if dark else ('#786140' if name=='explore' else '#48646d')),
                         'text-halo-color':('#15191d' if dark else '#f7f7f2'),'text-halo-width':1.5}})
        if name == 'walking':
            s['layers'].append({'id':'harta-park-names','type':'symbol','source':'openmaptiles','source-layer':'park','minzoom':13,
              'layout':{'text-field':['coalesce',['get','name:en'],['get','name']],'text-font':['Noto Sans Regular'],'text-size':12,'text-max-width':8,'text-padding':6},
              'paint':{'text-color':('#b6d1ae' if dark else '#4d703f'),'text-halo-color':('#203326' if dark else '#dce9d1'),'text-halo-width':1.5}})
        s['layers'].extend(optional_layers(dark))
        (out / ('harta-'+name+'-'+appearance+'.json')).write_text(json.dumps(s,indent=2)+'\n')

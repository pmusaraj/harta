"""Optional overlays using the OpenMapTiles poi and transportation schemas."""


def optional_layers(dark):
    colors = {'chargers': '#23845b', 'toilets': '#277ca5', 'parking': '#4268bb',
              'transit': '#a34aa3', 'essentials': '#a16624'}
    subclasses = {
        'chargers': ['charging_station'],
        'toilets': ['toilets'],
        'parking': ['parking', 'parking_entrance'],
        'transit': ['bus_stop', 'bus_station', 'station', 'halt', 'tram_stop',
                    'subway', 'subway_entrance', 'train_station_entrance', 'ferry_terminal'],
        'essentials': ['supermarket', 'convenience', 'grocery', 'greengrocer',
                       'marketplace', 'pharmacy', 'atm'],
    }
    labels = {'chargers': 'EV charger', 'toilets': 'Toilets', 'parking': 'Parking',
              'transit': 'Transit stop', 'essentials': 'Essentials'}
    layers = [{
        'id': 'harta-overlay-cycling', 'type': 'line', 'source': 'openmaptiles',
        'source-layer': 'transportation', 'minzoom': 12,
        'filter': ['all', ['==', ['geometry-type'], 'LineString'],
                   ['!=', ['get', 'access'], 'no'],
                   ['any', ['==', ['get', 'subclass'], 'cycleway'],
                    ['all', ['==', ['get', 'class'], 'path'],
                     ['match', ['get', 'bicycle'], ['designated', 'official'], True, False]]]],
        'layout': {'visibility': 'none', 'line-cap': 'round', 'line-join': 'round'},
        'paint': {'line-color': '#52745f' if dark else '#a3c9ac',
                  'line-width': ['interpolate', ['linear'], ['zoom'], 12, 2, 18, 5],
                  'line-dasharray': [2, 1]}
    }]
    for key, values in subclasses.items():
        layers.append({
            'id': 'harta-overlay-' + key, 'type': 'symbol', 'source': 'openmaptiles',
            'source-layer': 'poi', 'minzoom': 14,
            'filter': ['match', ['get', 'subclass'], values, True, False],
            'layout': {'visibility': 'none', 'icon-image': 'harta-overlay-' + key,
                       'icon-size': 1, 'icon-padding': 3,
                       'text-field': ['case', ['all', ['has', 'name'], ['!=', ['get', 'name'], '']],
                                      ['coalesce', ['get', 'name:en'], ['get', 'name']], labels[key]],
                       'text-font': ['Noto Sans Regular'], 'text-size': 12,
                       'text-anchor': 'top', 'text-offset': [0, 1.2],
                       'text-max-width': 10, 'text-padding': 4, 'text-optional': True},
            'paint': {'text-color': '#f0f2f4' if dark else colors[key],
                      'text-halo-color': '#171b20' if dark else '#ffffff',
                      'text-halo-width': 2}
        })
    transit = next(layer for layer in layers if layer['id'] == 'harta-overlay-transit')
    transit['layout']['icon-image'] = [
        'match', ['get', 'subclass'],
        ['bus_stop', 'bus_station'], 'harta-transit-bus',
        ['subway', 'subway_entrance'], 'harta-transit-metro',
        'tram_stop', 'harta-transit-tram',
        'ferry_terminal', 'harta-transit-ferry',
        'harta-transit-rail']
    transit['layout']['text-field'][-1] = [
        'match', ['get', 'subclass'],
        ['bus_stop', 'bus_station'], 'Bus stop / station',
        ['subway', 'subway_entrance'], 'Metro / subway',
        'tram_stop', 'Tram stop', 'ferry_terminal', 'Ferry terminal', 'Rail station']
    essentials = next(layer for layer in layers if layer['id'] == 'harta-overlay-essentials')
    essentials['layout']['icon-image'] = [
        'match', ['get', 'subclass'],
        'pharmacy', 'harta-essential-pharmacy',
        'convenience', 'harta-essential-convenience',
        'atm', 'harta-essential-atm',
        'harta-essential-grocery']
    essentials['layout']['text-field'][-1] = [
        'match', ['get', 'subclass'],
        'pharmacy', 'Pharmacy', 'convenience', 'Corner store',
        'atm', 'ATM', 'Groceries']
    return layers

#!/usr/bin/env python3
"""Prepare ONLY a dedicated Harta App Store simulator; never alters a physical device."""
import json
import pathlib
import subprocess
import sys

identifier = sys.argv[1]
app = sys.argv[2]
def sim(*args):
    return subprocess.check_output(["xcrun", "simctl", *args], text=True).strip()

devices = json.loads(sim("list", "devices", "--json"))
device = next(d for group in devices["devices"].values() for d in group if d["udid"] == identifier)
if not device["name"].startswith("Harta App Store"):
    raise SystemExit("Refusing to seed a simulator that isn't dedicated to Harta App Store assets")
if device["state"] != "Booted":
    sim("boot", identifier)
sim("bootstatus", identifier, "-b")
sim("install", identifier, app)
sim("privacy", identifier, "grant", "location", "com.musaraj.harta")
sim("location", identifier, "set", "45.5205,-73.5795")
sim("ui", identifier, "appearance", "light")
sim("status_bar", identifier, "override", "--time", "9:41", "--dataNetwork", "wifi",
    "--wifiMode", "active", "--wifiBars", "3", "--batteryState", "charged", "--batteryLevel", "100")
container = pathlib.Path(sim("get_app_container", identifier, "com.musaraj.harta", "data"))
places = [
    ("park", "Parc La Fontaine", "Le Plateau-Mont-Royal, Montréal", 45.5264, -73.5690, "symbol:tree.fill", "green"),
    ("market", "Marché Jean-Talon", "Petite Italie, Montréal", 45.5362, -73.6140, "symbol:carrot.fill", "orange"),
    ("cafe", "Café Olimpico", "Mile End, Montréal", 45.5220, -73.6010, "symbol:cup.and.saucer.fill", "teal"),
    ("mountain", "Belvédère Kondiaronk", "Parc du Mont-Royal, Montréal", 45.5033, -73.5875, "symbol:mountain.2.fill", "purple"),
    ("museum", "Musée des beaux-arts", "Rue Sherbrooke Ouest, Montréal", 45.4987, -73.5793, "symbol:building.columns.fill", "blue"),
]
records = [dict(id="demo-"+i, name=n, address=a, latitude=lat, longitude=lon, savedIcon=icon, savedTint=tint)
           for i,n,a,lat,lon,icon,tint in places]
file = container / "Library/Application Support/Harta/places.json"
file.parent.mkdir(parents=True, exist_ok=True)
file.write_text(json.dumps(records))
print("Prepared", device["name"], "with fictional saved-place selections of public Montréal destinations")

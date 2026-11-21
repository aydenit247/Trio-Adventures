#!/usr/bin/env python3
"""Download CC0 assets from Poly Haven into the Godot project.

  python3 tools/fetch_polyhaven.py model wooden_barrels_01 [res]      -> godot/assets/models/<id>/
  python3 tools/fetch_polyhaven.py texture weathered_planks [res]     -> godot/assets/textures/<id>/{albedo,normal,rough}.jpg
  python3 tools/fetch_polyhaven.py size model wooden_barrels_01 [res] -> print download size only

res defaults to 1k (keeps the web build small). Everything on Poly Haven is CC0: no credit required.
"""
import json, os, sys, urllib.request

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "godot", "assets")

def get(url):
    with urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "trio-adventures-fetch"}), timeout=60) as r:
        return r.read()

def files(asset_id):
    return json.loads(get("https://api.polyhaven.com/files/" + asset_id))

def model(asset_id, res="1k", dry=False):
    fl = files(asset_id)
    if "gltf" not in fl:
        print(f"  ({asset_id} has no glTF download, skipped)")
        return 0
    f = fl["gltf"]
    res = res if res in f else sorted(f.keys())[0]
    g = f[res]["gltf"]
    items = [(asset_id + ".gltf", g["url"], g.get("size", 0))] + [(k, v["url"], v.get("size", 0)) for k, v in g.get("include", {}).items()]
    total = sum(s for _, _, s in items)
    if dry:
        return total
    out = os.path.join(ROOT, "models", asset_id)
    for rel, url, _ in items:
        p = os.path.join(out, rel)
        os.makedirs(os.path.dirname(p), exist_ok=True)
        with open(p, "wb") as fh:
            fh.write(get(url))
    return total

MAPS = {"albedo": ["Diffuse", "diff", "col_1", "col_01", "col_03"], "normal": ["nor_gl"], "rough": ["Rough", "rough"]}

def texture(asset_id, res="1k", dry=False):
    f = files(asset_id)
    total = 0
    out = os.path.join(ROOT, "textures", asset_id)
    for name, keys in MAPS.items():
        k = next((k for k in keys if k in f), None)
        if not k:
            continue
        e = f[k][res if res in f[k] else sorted(f[k].keys())[0]]["jpg"]
        total += e.get("size", 0)
        if not dry:
            os.makedirs(out, exist_ok=True)
            with open(os.path.join(out, name + ".jpg"), "wb") as fh:
                fh.write(get(e["url"]))
    return total

if __name__ == "__main__":
    a = sys.argv[1:]
    dry = a[0] == "size"
    if dry:
        a = a[1:]
    kind, ids, res = a[0], a[1].split(","), (a[2] if len(a) > 2 else "1k")
    for i in ids:
        n = (model if kind == "model" else texture)(i, res, dry)
        print(f"{kind} {i}: {n / 1e6:.1f} MB{' (not downloaded)' if dry else ''}")

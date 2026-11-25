# Usage: python3 tools/glb_keep_anims.py in.glb out.glb Idle,Walking,Running   (Asar 11/24, for the Meshy trio models)
# Keep only the named animations in a GLB and rebuild its binary buffer without the dropped data.
import json, struct, sys
src, dst, keep = sys.argv[1], sys.argv[2], set(sys.argv[3].split(","))
b = open(src, "rb").read()
_, _, _ = struct.unpack("<III", b[:12])
jl, _ = struct.unpack("<II", b[12:20]); j = json.loads(b[20:20 + jl])
o = 20 + jl; bl, _ = struct.unpack("<II", b[o:o + 8]); bin_ = b[o + 8:o + 8 + bl]
j["animations"] = [a for a in j.get("animations", []) if a["name"] in keep]
# accessors still used
used_acc = set()
def walk(x):
    if isinstance(x, dict):
        for k, v in x.items():
            if k in ("input", "output", "indices", "inverseBindMatrices") and isinstance(v, int): used_acc.add(v)
            elif k == "attributes" or k == "targets": pass
            walk(v)
    elif isinstance(x, list):
        for v in x: walk(v)
for m in j.get("meshes", []):
    for p in m["primitives"]:
        used_acc.update(p["attributes"].values())
        if "indices" in p: used_acc.add(p["indices"])
        for t in p.get("targets", []): used_acc.update(t.values())
for s in j.get("skins", []):
    if "inverseBindMatrices" in s: used_acc.add(s["inverseBindMatrices"])
for a in j["animations"]:
    for sm in a["samplers"]: used_acc.update([sm["input"], sm["output"]])
acc_map = {}; new_acc = []
for i, a in enumerate(j["accessors"]):
    if i in used_acc: acc_map[i] = len(new_acc); new_acc.append(a)
used_bv = {a["bufferView"] for a in new_acc if "bufferView" in a}
used_bv |= {im["bufferView"] for im in j.get("images", []) if "bufferView" in im}
bv_map = {}; new_bv = []; out = bytearray()
for i, v in enumerate(j["bufferViews"]):
    if i not in used_bv: continue
    while len(out) % 4: out.append(0)
    s = v.get("byteOffset", 0); data = bin_[s:s + v["byteLength"]]
    nv = dict(v); nv["byteOffset"] = len(out); out += data
    bv_map[i] = len(new_bv); new_bv.append(nv)
for a in new_acc:
    if "bufferView" in a: a["bufferView"] = bv_map[a["bufferView"]]
for im in j.get("images", []):
    if "bufferView" in im: im["bufferView"] = bv_map[im["bufferView"]]
for m in j.get("meshes", []):
    for p in m["primitives"]:
        p["attributes"] = {k: acc_map[v] for k, v in p["attributes"].items()}
        if "indices" in p: p["indices"] = acc_map[p["indices"]]
        if "targets" in p: p["targets"] = [{k: acc_map[v] for k, v in t.items()} for t in p["targets"]]
for s in j.get("skins", []):
    if "inverseBindMatrices" in s: s["inverseBindMatrices"] = acc_map[s["inverseBindMatrices"]]
for a in j["animations"]:
    for sm in a["samplers"]: sm["input"] = acc_map[sm["input"]]; sm["output"] = acc_map[sm["output"]]
j["accessors"] = new_acc; j["bufferViews"] = new_bv
while len(out) % 4: out.append(0)
j["buffers"] = [{"byteLength": len(out)}]
js = json.dumps(j, separators=(",", ":")).encode()
while len(js) % 4: js += b" "
res = struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(out)) + struct.pack("<II", len(js), 0x4E4F534A) + js + struct.pack("<II", len(out), 0x004E4942) + bytes(out)
open(dst, "wb").write(res)
print(dst, len(b), "->", len(res), [a["name"] for a in j["animations"]])

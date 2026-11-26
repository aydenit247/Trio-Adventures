# Usage: python3 tools/glb_shrink_textures.py in.glb out.glb [max_size=1024]   (Asar 11/25, for Meshy props)
# Rebuilds a GLB with every embedded texture scaled down to max_size (keeps PNG, so normal/roughness maps stay
# exact-ish). Meshy exports 2K-4K PNGs that make a prop 12-20 MB; at 1024 a prop is ~3 MB and looks the same in-game.
import io, json, struct, sys
from PIL import Image

src, dst = sys.argv[1], sys.argv[2]
max_size = int(sys.argv[3]) if len(sys.argv) > 3 else 1024
data = open(src, "rb").read()
jlen = struct.unpack("<I", data[12:16])[0]
gltf = json.loads(data[20:20 + jlen])
p = 20 + jlen
blen = struct.unpack("<I", data[p:p + 4])[0]
binbuf = data[p + 8:p + 8 + blen]

views = gltf["bufferViews"]
blobs = [binbuf[v.get("byteOffset", 0):v.get("byteOffset", 0) + v["byteLength"]] for v in views]
for img in gltf.get("images", []):
    if "bufferView" not in img:
        continue
    im = Image.open(io.BytesIO(blobs[img["bufferView"]]))
    if max(im.size) > max_size:
        im.thumbnail((max_size, max_size), Image.LANCZOS)
    out = io.BytesIO()
    im.save(out, "PNG", optimize=True)
    blobs[img["bufferView"]] = out.getvalue()
    img["mimeType"] = "image/png"

newbin = bytearray()
for v, b in zip(views, blobs):
    while len(newbin) % 4:
        newbin.append(0)
    v["byteOffset"] = len(newbin)
    v["byteLength"] = len(b)
    newbin += b
while len(newbin) % 4:
    newbin.append(0)
gltf["buffers"][0]["byteLength"] = len(newbin)
js = json.dumps(gltf, separators=(",", ":")).encode()
while len(js) % 4:
    js += b" "
out = struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(newbin))
out += struct.pack("<II", len(js), 0x4E4F534A) + js + struct.pack("<II", len(newbin), 0x004E4942) + bytes(newbin)
open(dst, "wb").write(out)
print(src, len(data), "->", dst, len(out))

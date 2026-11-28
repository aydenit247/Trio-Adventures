"""Square dialogue portraits from cut-out character art (Rat Casino art, Asar 11/27).

    python3 tools/make_portraits.py <out_dir> <cutout.png>[=name] ...

Crops head + shoulders from the top of each cutout and puts it on a dark, warm, softly lit backdrop like the other
painted portraits (512x512 RGB).
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter


def backdrop(n: int) -> Image.Image:
    y, x = np.mgrid[0:n, 0:n] / n
    d = np.sqrt((x - 0.5) ** 2 + (y - 0.42) ** 2)
    glow = np.clip(1.0 - d * 1.6, 0, 1) ** 1.6
    base = np.array([14, 10, 8], np.float32)
    warm = np.array([120, 78, 36], np.float32)
    img = base + warm[None, None, :] * glow[..., None]
    return Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), "RGB")


def portrait(src: Path, size: int = 512) -> Image.Image:
    im = Image.open(src).convert("RGBA")
    a = np.array(im)[..., 3] > 40
    h, w = a.shape
    top = int(np.argmax(a.any(1)))
    band = a[top: top + max(1, int(h * 0.3))]
    xs = np.where(band.any(0))[0]
    cx = int(xs.mean()) if len(xs) else w // 2
    side = int(min(w, h * 0.55))
    x0 = max(0, min(w - side, cx - side // 2))
    y0 = max(0, top - int(side * 0.06))
    crop = im.crop((x0, y0, x0 + side, y0 + side)).resize((size, size), Image.LANCZOS)
    bg = backdrop(size).convert("RGBA")
    shadow = Image.new("RGBA", crop.size, (0, 0, 0, 0))
    shadow.putalpha(crop.getchannel("A").filter(ImageFilter.GaussianBlur(14)).point(lambda v: v * 0.6))
    bg.alpha_composite(shadow, (8, 10))
    bg.alpha_composite(crop)
    return bg.convert("RGB")


def main() -> None:
    out = Path(sys.argv[1])
    out.mkdir(parents=True, exist_ok=True)
    for arg in sys.argv[2:]:
        path, _, name = arg.partition("=")
        p = Path(path)
        portrait(p).save(out / ((name or p.stem) + ".png"), optimize=True)
        print(name or p.stem)


if __name__ == "__main__":
    main()

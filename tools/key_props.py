"""Cut props out of green-screen images and split sheets with several objects into separate PNGs.

    python3 tools/key_props.py <src_dir> <out_dir>

Each source image: the background green is sampled from the border, pixels close to it become
transparent (soft edge), green spill on the edges is removed, tiny specks are dropped, then every
separate object in the image is cropped into its own file (<name>_1.png, <name>_2.png, ...).
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

SHEETS = {  # file stem -> (output name, expected object count or None for 1)
    'trees': 'tree', 'rocks': 'rock', 'bushes3': 'bush', 'bush_big': 'bush_big', 'tent_green': 'tent_green',
    'tent_purple': 'tent_purple', 'campfire_unlit': 'campfire', 'log': 'log', 'bag': 'bag', 'sign': 'sign',
}


def key(img: np.ndarray) -> np.ndarray:
    a = img.astype(np.float32)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    border = np.concatenate([a[:6].reshape(-1, 3), a[-6:].reshape(-1, 3), a[:, :6].reshape(-1, 3), a[:, -6:].reshape(-1, 3)])
    bg = np.median(border, axis=0)
    # "How much like the screen" = green dominance scaled by brightness, relative to the screen itself
    gdom = g - np.maximum(r, b)
    bg_dom = bg[1] - max(bg[0], bg[2])
    score = (gdom / bg_dom) * np.clip(g / bg[1], 0, 1.2)
    alpha = 1.0 - np.clip((score - 0.42) / (0.72 - 0.42), 0, 1)
    # drop specks / keep real objects
    solid = alpha > 0.5
    lab, n = ndimage.label(solid)
    if n:
        sizes = ndimage.sum(solid, lab, range(1, n + 1))
        for i, s in enumerate(sizes, 1):
            if s < 120:
                alpha[lab == i] = 0
    # soften + pull the edge in by a pixel to lose the green fringe
    alpha = ndimage.grey_erosion(alpha, size=(3, 3)) * 0.5 + alpha * 0.5
    # despill: clamp green toward the other channels, strongest on soft edges
    m = np.maximum(r, b)
    spill = np.clip(g - m, 0, None)
    strength = 0.55 + 0.45 * (1 - alpha)
    g2 = g - spill * strength
    out = np.dstack([r, g2, b, alpha * 255]).clip(0, 255).astype(np.uint8)
    return out


def remove_fire(rgba: np.ndarray) -> np.ndarray:
    """Campfire: cut the baked-in flames and smoke (real particles + light replace them in-game)."""
    a = rgba.astype(np.float32)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    h = rgba.shape[0]
    fire = (r > 150) & (r > b * 1.6) & (r + g > 260) & (b < 170)
    fire |= (r > 200) & (g > 170) & (b < 200) & (r > b * 1.3)       # yellow-white core
    glow = (r > 120) & (r > g * 1.25) & (r > b * 1.8)                 # orange embers
    fire = ndimage.binary_dilation(fire | glow, iterations=2)
    top = np.zeros_like(fire)
    top[: int(h * 0.62)] = True                                       # keep ground-level embers low down
    cut = fire & top
    rgba = rgba.copy()
    rgba[cut, 3] = 0
    # smoke haze above the logs: anything faint in the upper third goes
    up = np.zeros_like(fire)
    up[: int(h * 0.38)] = True
    rgba[up & (rgba[..., 3] < 235), 3] = 0
    # cut the whole teepee + flames out of the middle and everything high up (plume, sparks, tips);
    # the stone ring and seating logs stay, the game adds animated logs + flames in the gap
    w = rgba.shape[1]
    yy, xx = np.mgrid[0:h, 0:w]
    rgba[yy < int(h * 0.45), 3] = 0
    pit = ((xx - w * 0.5) / (w * 0.165)) ** 2 + ((yy - h * 0.40) / (h * 0.23)) ** 2 < 1.0
    rgba[pit, 3] = 0
    # leftover smoke plume (greenish/grey, upper half)
    upper = np.zeros_like(fire)
    upper[: int(h * 0.5)] = True
    smoky = (g >= r * 0.92) & (g >= b * 0.9)
    rgba[upper & smoky, 3] = 0
    # darken what's left of the embers so the unlit pit reads as cold
    ember = glow & ~top
    rgba[ember, 0] = (rgba[ember, 0] * 0.45).astype(np.uint8)
    rgba[ember, 1] = (rgba[ember, 1] * 0.4).astype(np.uint8)
    return rgba


def split(rgba: np.ndarray, merge_px=10, min_area=2500):
    mask = rgba[..., 3] > 60
    grown = ndimage.binary_dilation(mask, iterations=merge_px)
    lab, n = ndimage.label(grown)
    objs = []
    for i in range(1, n + 1):
        ys, xs = np.where((lab == i) & mask)
        if len(ys) < min_area:
            continue
        y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
        crop = rgba[y0:y1, x0:x1].copy()
        crop[..., 3] = np.where((lab[y0:y1, x0:x1] == i), crop[..., 3], 0)
        objs.append(((y0 // 200, x0), np.pad(crop, ((6, 6), (6, 6), (0, 0)))))
    objs.sort(key=lambda o: o[0])   # top row first, then left to right
    return [o[1] for o in objs]


def main(src: str, out: str):
    Path(out).mkdir(parents=True, exist_ok=True)
    for stem, name in SHEETS.items():
        p = next(Path(src).glob(stem + '.*'))
        rgba = key(np.asarray(Image.open(p).convert('RGB')))
        if stem == 'campfire':   # old lit campfire art: cut the baked flames out (unused now that there's an unlit version)
            rgba = remove_fire(rgba)
        if stem == 'trees':   # 2x2 grid: split by quadrant (branches nearly touch)
            h, w = rgba.shape[:2]
            parts = []
            for qy in (0, 1):
                for qx in (0, 1):
                    q = rgba[qy * h // 2:(qy + 1) * h // 2, qx * w // 2:(qx + 1) * w // 2]
                    parts += split(q, merge_px=10)
        elif stem == 'rocks':   # 4 rocks side by side that touch: cut at the thinnest columns
            w = rgba.shape[1]
            col = (rgba[..., 3] > 60).sum(axis=0)
            cuts = [0]
            for f in (0.33, 0.55, 0.77):
                lo, hi = int(w * f) - 45, int(w * f) + 45
                cuts.append(lo + int(np.argmin(col[lo:hi])))
            cuts.append(w)
            parts = []
            for x0, x1 in zip(cuts[:-1], cuts[1:]):
                pieces = split(rgba[:, x0:x1], merge_px=1, min_area=200)
                parts.append(max(pieces, key=lambda c: (c[..., 3] > 60).sum()))   # the rock, not its neighbour's sliver
        else:
            parts = split(rgba, merge_px={'campfire_unlit': 14, 'sign': 14}.get(stem, 10))
        for i, part in enumerate(parts, 1):
            fn = f'{name}.png' if len(parts) == 1 else f'{name}_{i}.png'
            Image.fromarray(part).save(Path(out) / fn)
            print(fn, part.shape[1], 'x', part.shape[0])


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])

"""Cut character views (back / side) out of studio green-screen shots.

    python3 tools/key_chars.py <src_dir> <out_dir>

Keys by green *saturation* (how green a pixel is relative to its brightness), which removes both the
bright backdrop and the darker green floor shadows while keeping dark armor. Keeps the biggest object
(the character, tail included), removes green spill, and crops tight like the front cutouts so all views
of a character line up at the same size.
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage


def key_char(img: np.ndarray) -> np.ndarray:
    a = img.astype(np.float32)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    m = np.maximum(r, b)
    ratio = (g - m) / np.maximum(g, 1.0)           # 0 = not green at all, ~0.5 = backdrop
    # Background = clearly-green pixels CONNECTED to the image border (backdrop + floor shadows).
    # Green-tinted dark spots inside the outfit aren't connected, so they stay solid.
    cand = ratio > 0.27
    lab, n = ndimage.label(cand)
    edge_ids = np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))
    bg = np.isin(lab, edge_ids[edge_ids > 0])
    # enclosed pockets of backdrop (gap between arm and body): strongly green and not tiny
    strong = ratio > 0.36
    lab2, n2 = ndimage.label(strong)
    if n2:
        sizes2 = ndimage.sum(strong, lab2, range(1, n2 + 1))
        big = np.where(sizes2 > 120)[0] + 1
        bg |= np.isin(lab2, big)
    # take a soft edge band just around that background
    band = ndimage.binary_dilation(bg, iterations=2) & (ratio > 0.12)
    soft = 1.0 - np.clip((ratio - 0.12) / (0.30 - 0.12), 0, 1)
    alpha = np.where(bg, 0.0, np.where(band, soft, 1.0))
    # keep the character: biggest solid blob (plus anything attached to it)
    solid = alpha > 0.5
    lab, n = ndimage.label(solid)
    if n:
        sizes = ndimage.sum(solid, lab, range(1, n + 1))
        keep = lab == (int(np.argmax(sizes)) + 1)
        keep = ndimage.binary_dilation(keep, iterations=3)
        alpha = np.where(keep, alpha, 0)
    alpha = ndimage.grey_erosion(alpha, size=(3, 3)) * 0.5 + alpha * 0.5
    spill = np.clip(g - m, 0, None)
    g2 = g - spill * (0.7 + 0.3 * (1 - alpha))
    out = np.dstack([r, g2, b, alpha * 255]).clip(0, 255).astype(np.uint8)
    ys, xs = np.where(out[..., 3] > 20)
    return np.pad(out[ys.min():ys.max() + 1, xs.min():xs.max() + 1], ((2, 2), (2, 2), (0, 0)))


if __name__ == '__main__':
    src, dst = Path(sys.argv[1]), Path(sys.argv[2])
    dst.mkdir(parents=True, exist_ok=True)
    for p in sorted(src.glob('*.jpg')):
        out = key_char(np.asarray(Image.open(p).convert('RGB')))
        Image.fromarray(out).save(dst / (p.stem + '.png'))
        print(p.stem, out.shape[1], 'x', out.shape[0])

"""Cut characters out of plain light-grey studio renders (the Rat Casino art, Asar 11/27).

    python3 tools/key_grey.py <src_dir> <out_dir> [tolerance=26]

Fits the backdrop as a smooth gradient from the image border, marks pixels close to it AND connected to the
border as background (so grey fur inside the character stays), feathers the edge, keeps the biggest object,
and crops tight like the other cutouts. Output: <out_dir>/<name>.png with transparency.
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage


def backdrop(a: np.ndarray) -> np.ndarray:
    """Least-squares quadratic surface per channel through the border pixels."""
    h, w, _ = a.shape
    b = max(4, min(h, w) // 40)
    ys, xs = np.mgrid[0:h, 0:w]
    border = np.zeros((h, w), bool)
    border[:b] = border[-b:] = True
    border[:, :b] = border[:, -b:] = True
    y = ys[border] / h
    x = xs[border] / w
    A = np.stack([np.ones_like(x), x, y, x * x, y * y, x * y], 1)
    Y, X = ys / h, xs / w
    full = np.stack([np.ones_like(X), X, Y, X * X, Y * Y, X * Y], -1)
    out = np.empty_like(a)
    for c in range(3):
        coef, *_ = np.linalg.lstsq(A, a[..., c][border], rcond=None)
        out[..., c] = full @ coef
    return out


def key(img: np.ndarray, tol: float) -> np.ndarray:
    a = img[..., :3].astype(np.float32)
    bg = backdrop(a)
    diff = np.abs(a - bg).max(-1)
    lab, _ = ndimage.label(diff < tol)
    edge = np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))
    back = np.isin(lab, edge[edge > 0])
    h, w = diff.shape
    # floor shadow: grey, a bit darker than the backdrop, low in the frame, touching the background
    mx, mn = a.max(-1), a.min(-1)
    sat = (mx - mn) / np.maximum(mx, 1)
    rows = np.arange(h)[:, None] >= int(h * 0.82)
    shadowish = rows & (sat < 0.09) & (diff < tol * 2.4) & (a.mean(-1) < bg.mean(-1))
    lab_s, _ = ndimage.label(shadowish | back)
    keep = np.unique(lab_s[back])
    back |= np.isin(lab_s, keep[keep > 0]) & shadowish
    # big enclosed patches of backdrop (inside the wheel, between arms)
    lum = a.mean(-1)
    std = np.sqrt(np.maximum(ndimage.uniform_filter(lum * lum, 7) - ndimage.uniform_filter(lum, 7) ** 2, 0))
    smooth = ndimage.binary_opening((diff < tol * 0.6) & (std < 2.5) & ~back, iterations=2)
    lab_h, nh = ndimage.label(smooth)
    if nh:
        sizes = ndimage.sum(np.ones_like(diff), lab_h, range(1, nh + 1))
        big = np.where(sizes > h * w * 0.002)[0] + 1
        back |= np.isin(lab_h, big)
    fg = ~back
    lab2, n = ndimage.label(fg)
    if n > 1:   # keep the character, drop specks
        sizes = ndimage.sum(fg, lab2, range(1, n + 1))
        fg = lab2 == (int(np.argmax(sizes)) + 1)
    alpha = ndimage.gaussian_filter(fg.astype(np.float32), 0.8)
    # soft edge: partly-background pixels fade with how close they are to the backdrop
    soft = np.clip((diff - tol * 0.5) / (tol * 0.8), 0, 1)
    alpha = np.where(fg, alpha, alpha * soft)
    rgba = np.dstack([img[..., :3], (np.clip(alpha, 0, 1) * 255).astype(np.uint8)])
    ys, xs = np.where(alpha > 0.05)
    pad = 4
    y0, y1 = max(0, ys.min() - pad), min(img.shape[0], ys.max() + pad)
    x0, x1 = max(0, xs.min() - pad), min(img.shape[1], xs.max() + pad)
    return rgba[y0:y1, x0:x1]


# per-picture tolerance: white suit nearly matches the backdrop; chinchilla has a strong vignette + bright floor
GRABCUT = {"staff_high_roller", "race_chinchilla"}   # backdrop too close to the subject for a plain key


def grabcut(img: np.ndarray, tol: float) -> np.ndarray:
    import cv2
    a = img[..., :3].astype(np.float32)
    diff = np.abs(a - backdrop(a)).max(-1)
    h, w = diff.shape
    m = np.full((h, w), cv2.GC_PR_FGD, np.uint8)
    m[diff < tol * 0.7] = cv2.GC_PR_BGD
    b = max(4, min(h, w) // 30)
    m[:b] = m[-b:] = cv2.GC_BGD
    m[:, :b] = m[:, -b:] = cv2.GC_BGD
    m[diff > tol * 2.5] = cv2.GC_FGD
    # floor glow / vignette: grey and BRIGHTER than the fitted backdrop -> backdrop
    mx, mn = a.max(-1), a.min(-1)
    sat = (mx - mn) / np.maximum(mx, 1)
    glow = (sat < 0.06) & (a.mean(-1) > backdrop(a).mean(-1) + 6)
    m[glow & (m != cv2.GC_FGD)] = cv2.GC_PR_BGD
    bgm, fgm = np.zeros((1, 65)), np.zeros((1, 65))
    cv2.grabCut(np.ascontiguousarray(img[..., ::-1]), m, None, bgm, fgm, 6, cv2.GC_INIT_WITH_MASK)
    fg = (m == cv2.GC_FGD) | (m == cv2.GC_PR_FGD)
    lab, n = ndimage.label(fg)
    if n > 1:
        sizes = ndimage.sum(fg, lab, range(1, n + 1))
        fg = lab == (int(np.argmax(sizes)) + 1)
    fg = ndimage.binary_fill_holes(fg)
    alpha = ndimage.gaussian_filter(fg.astype(np.float32), 1.0)
    rgba = np.dstack([img[..., :3], (np.clip(alpha, 0, 1) * 255).astype(np.uint8)])
    ys, xs = np.where(alpha > 0.05)
    return rgba[max(0, ys.min() - 4):ys.max() + 4, max(0, xs.min() - 4):xs.max() + 4]


def main() -> None:
    src, out = Path(sys.argv[1]), Path(sys.argv[2])
    tol = float(sys.argv[3]) if len(sys.argv) > 3 else 26.0
    out.mkdir(parents=True, exist_ok=True)
    for f in sorted(src.iterdir()):
        if f.suffix.lower() not in (".png", ".jpg", ".jpeg"):
            continue
        img = np.array(Image.open(f).convert("RGB"))
        cut = grabcut(img, tol) if f.stem in GRABCUT else key(img, tol)
        im = Image.fromarray(cut, "RGBA")
        if max(im.size) > 700:   # same size range as the other character art
            im.thumbnail((700, 700), Image.LANCZOS)
        im.save(out / (f.stem + ".png"), optimize=True)
        print(f.name, "->", im.size)


if __name__ == "__main__":
    main()

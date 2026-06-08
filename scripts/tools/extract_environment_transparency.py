from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter


def _sample_background(rgb: np.ndarray) -> np.ndarray:
    h, w, _ = rgb.shape
    border = max(8, min(h, w) // 80)
    samples = np.concatenate(
        [
            rgb[:border, :, :].reshape(-1, 3),
            rgb[-border:, :, :].reshape(-1, 3),
            rgb[:, :border, :].reshape(-1, 3),
            rgb[:, -border:, :].reshape(-1, 3),
        ],
        axis=0,
    )
    brightness = samples.mean(axis=1)
    light_samples = samples[brightness >= np.percentile(brightness, 45)]
    if light_samples.size == 0:
        light_samples = samples
    return np.median(light_samples, axis=0)


def _make_background_mask(rgb: np.ndarray, threshold: float) -> np.ndarray:
    h, w, _ = rgb.shape
    bg = _sample_background(rgb)
    diff = rgb.astype(np.float32) - bg.astype(np.float32)
    dist = np.sqrt(np.sum(diff * diff, axis=2))
    bright = rgb.mean(axis=2)
    if bg.mean() < 150:
        candidate = dist <= threshold
    else:
        candidate = (dist <= threshold) & (bright >= 166)

    mask = np.zeros((h, w), dtype=bool)
    queue: deque[tuple[int, int]] = deque()

    def push_if_candidate(y: int, x: int) -> None:
        if candidate[y, x] and not mask[y, x]:
            mask[y, x] = True
            queue.append((y, x))

    for x in range(w):
        push_if_candidate(0, x)
        push_if_candidate(h - 1, x)
    for y in range(h):
        push_if_candidate(y, 0)
        push_if_candidate(y, w - 1)

    while queue:
        y, x = queue.popleft()
        if y > 0:
            push_if_candidate(y - 1, x)
        if y + 1 < h:
            push_if_candidate(y + 1, x)
        if x > 0:
            push_if_candidate(y, x - 1)
        if x + 1 < w:
            push_if_candidate(y, x + 1)

    return mask


def transparentize_image(src: Path, dst: Path, threshold: float, feather: float) -> None:
    image = Image.open(src).convert("RGBA")
    rgba = np.array(image)
    rgb = rgba[:, :, :3]
    bg_mask = _make_background_mask(rgb, threshold)

    alpha = rgba[:, :, 3].copy()
    alpha[bg_mask] = 0

    alpha_image = Image.fromarray(alpha)
    if feather > 0:
        alpha_image = alpha_image.filter(ImageFilter.GaussianBlur(radius=feather))
        alpha = np.array(alpha_image)
        alpha[bg_mask] = 0

    rgba[:, :, 3] = alpha
    dst.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(rgba).save(dst)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Remove connected light paper backgrounds from id0001 environment PNGs."
    )
    parser.add_argument(
        "--src",
        default="assets/papercraft/fragments/id0001/environment",
        help="Source directory containing PNG files.",
    )
    parser.add_argument(
        "--dst",
        default="assets/papercraft/fragments/id0001/environment2",
        help="Destination directory for transparent PNG files.",
    )
    parser.add_argument(
        "--threshold",
        type=float,
        default=54.0,
        help="RGB distance threshold for edge-connected background detection.",
    )
    parser.add_argument(
        "--feather",
        type=float,
        default=0.6,
        help="Small alpha feather radius for antialiased cutout edges.",
    )
    args = parser.parse_args()

    src_dir = Path(args.src)
    dst_dir = Path(args.dst)
    files = sorted(src_dir.glob("*.png"))
    if not files:
        raise SystemExit(f"No PNG files found in {src_dir}")

    for src in files:
        dst = dst_dir / src.name
        transparentize_image(src, dst, args.threshold, args.feather)
        print(f"[cutout] {src.name} -> {dst}")

    print(f"[done] wrote {len(files)} transparent PNG files to {dst_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

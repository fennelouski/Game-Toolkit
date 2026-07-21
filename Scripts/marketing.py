#!/usr/bin/env python3
"""Composites App Store marketing images from the raw screenshots in Screenshots/.

Each marketing shot is the raw screenshot, rounded and shadowed, under a serif
headline on a Hearth-palette background, at the exact App Store pixel size.
Output: Screenshots/marketing/{iphone-6.9,ipad-13}/.

Run after ./Scripts/screenshots.sh:  python3 Scripts/marketing.py
"""

from PIL import Image, ImageDraw, ImageFilter, ImageFont
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "Screenshots"
OUT = ROOT / "marketing"

# Hearth palette
PARCHMENT_TOP = (243, 238, 226)
PARCHMENT_BOTTOM = (228, 217, 194)
NIGHT_TOP = (32, 48, 40)
NIGHT_BOTTOM = (16, 25, 20)
INK = (36, 49, 43)
INK_SOFT = (92, 102, 96)
CREAM = (237, 229, 212)
CREAM_SOFT = (176, 184, 172)

CAPTIONS = [
    ("1-dice", "Dice that feel like dice", "Hold a die, shake to roll — 1 to 30 dice, 2 to 100 sides.", False),
    ("2-timer", "A chess clock for game night", "Tap a player to start their turn. It never drifts.", False),
    ("3-scores", "A scorepad worth staring at", "Rounds, running totals, and a crown on the leader.", False),
    ("4-chart", "Watch the lead change hands", "Charts for the whole table, or one player at a time.", False),
    ("5-settings", "Tuned to how you play", "Dice, timer, sound, and sync — all in one place.", False),
    ("6-theme-gaslight", "A night mode for dim rooms", "Gaslight: brass and candlelight for late games.", True),
    ("7-theme-azul", "Themed to tonight's game", "Search a board game and the app dresses to match.", True),
]

SIZES = {"iphone-6.9": (1320, 2868), "ipad-13": (2064, 2752)}


def vertical_gradient(size, top, bottom):
    w, h = size
    col = Image.new("RGB", (1, h))
    for y in range(h):
        t = y / max(h - 1, 1)
        col.putpixel((0, y), tuple(round(a + (b - a) * t) for a, b in zip(top, bottom)))
    return col.resize((w, h))


def rounded(img, radius):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, *img.size], radius=radius, fill=255)
    img = img.convert("RGBA")
    img.putalpha(mask)
    return img


def font(path, size, weight=None):
    f = ImageFont.truetype(path, size)
    if weight is not None:
        try:
            f.set_variation_by_axes([weight])
        except Exception:
            pass
    return f


def compose(device, size):
    w, h = size
    scale = w / 1320  # captions tuned on iPhone width
    headline_font = font("/System/Library/Fonts/NewYork.ttf", round(86 * scale), 640)
    sub_font = font("/System/Library/Fonts/SFNS.ttf", round(44 * scale))

    out_dir = OUT / device
    out_dir.mkdir(parents=True, exist_ok=True)

    for name, headline, sub, dark in CAPTIONS:
        src = ROOT / device / f"{name}.png"
        if not src.exists():
            print(f"  skip {device}/{name} (no source)")
            continue

        canvas = vertical_gradient(size, NIGHT_TOP if dark else PARCHMENT_TOP,
                                   NIGHT_BOTTOM if dark else PARCHMENT_BOTTOM).convert("RGBA")
        draw = ImageDraw.Draw(canvas)

        # Caption block
        top_pad = round(120 * scale)
        fg = CREAM if dark else INK
        fg_soft = CREAM_SOFT if dark else INK_SOFT
        hw = draw.textbbox((0, 0), headline, font=headline_font)
        draw.text(((w - (hw[2] - hw[0])) / 2, top_pad), headline, font=headline_font, fill=fg)
        sw = draw.textbbox((0, 0), sub, font=sub_font)
        sub_y = top_pad + (hw[3] - hw[1]) + round(46 * scale)
        draw.text(((w - (sw[2] - sw[0])) / 2, sub_y), sub, font=sub_font, fill=fg_soft)

        # Screenshot, scaled to fit the space below the caption, bottom-cropped so it
        # "rises" from the bottom edge like a device held toward you.
        shot = Image.open(src).convert("RGB")
        shot_top = sub_y + (sw[3] - sw[1]) + round(90 * scale)
        avail_h = h - shot_top
        target_w = round(w * 0.84)
        ratio = target_w / shot.width
        shot = shot.resize((target_w, round(shot.height * ratio)), Image.LANCZOS)
        radius = round(56 * scale)
        shot = rounded(shot, radius)

        # Soft shadow
        margin = round(60 * scale)
        shadow = Image.new("RGBA", (shot.width + margin * 2, shot.height + margin * 2), (0, 0, 0, 0))
        ImageDraw.Draw(shadow).rounded_rectangle(
            [margin, margin, margin + shot.width, margin + shot.height],
            radius=radius, fill=(0, 0, 0, 110 if not dark else 160))
        shadow = shadow.filter(ImageFilter.GaussianBlur(round(28 * scale)))

        x = (w - shot.width) // 2
        canvas.alpha_composite(shadow, (x - margin, shot_top - margin + round(16 * scale)))
        canvas.alpha_composite(shot, (x, shot_top))

        # Crop anything past the bottom edge and hard-trim to exact size.
        final = canvas.convert("RGB").crop((0, 0, w, h))
        final.save(out_dir / f"{name}.png")
        print(f"  {device}/{name}.png")


if __name__ == "__main__":
    for device, size in SIZES.items():
        print(f"==> {device}")
        compose(device, size)
    print("Done. See Screenshots/marketing/")

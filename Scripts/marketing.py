#!/usr/bin/env python3
"""Composites App Store marketing images from the raw screenshots in Screenshots/.

Two kinds of output, both at exact App Store pixel sizes:
  - singles: one rounded, shadowed screenshot under a serif headline (13 per device)
  - multis:  2-4 screenshots in a fanned/paired layout under a headline (7 per device)

Output: Screenshots/marketing/{iphone-6.9,ipad-13,mac}/  (20 candidates per device;
App Store Connect accepts up to 10 — pick your favorites).

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

# (source, headline, subhead, dark)
SINGLES = [
    ("1-dice", "Dice that feel like dice", "Hold a die, shake to roll — 1 to 30 dice, 2 to 100 sides.", False),
    ("2-timer", "A chess clock for game night", "Tap a player to start their turn. It never drifts.", False),
    ("3-scores", "A scorepad worth staring at", "Rounds, running totals, and a crown on the leader.", False),
    ("4-chart", "Watch the lead change hands", "Charts for the whole table, or one player at a time.", False),
    ("5-settings", "Tuned to how you play", "Dice, timer, sound, and sync — all in one place.", False),
    ("6-theme-gaslight", "A night mode for dim rooms", "Gaslight: brass and candlelight for late games.", True),
    ("7-theme-azul", "Themed to tonight's game", "Search a board game and the app dresses to match.", True),
    ("8-players", "Every game night, remembered", "Each table keeps its own roster, scores, and history.", False),
    ("9-timer-hourglass", "Time you can watch run out", "The hourglass clock — one of ten timer styles.", False),
    ("10-timer-analog", "Ten looks for the clock", "Analog, hourglass, water clock, sundial, and more.", False),
    ("11-dice-dark", "Easy on late-night eyes", "A true dark mode for every theme.", True),
    ("12-theme-wingspan", "Palettes from your shelf", "Colors inspired by the games you already love.", False),
    ("13-theme-catan", "Dressed for the table", "Bricks, wheat, and wool — without leaving the app.", False),
]

# (output name, [sources back→front], headline, subhead, dark,
#  [(scale of front width, rotation°, x center fraction, y nudge fraction)])
MULTIS = [
    ("m1-hero", ["2-timer", "3-scores", "1-dice"],
     "Everything game night needs", "Dice, timer, and scorecard — one app.", False,
     [(0.92, -9, 0.24, 0.05), (0.92, 9, 0.76, 0.05), (1.0, 0, 0.5, 0.0)]),
    ("m2-themes", ["6-theme-gaslight", "13-theme-catan", "7-theme-azul"],
     "Dressed for tonight's game", "Search a board game; the whole app matches.", False,
     [(0.92, -9, 0.24, 0.05), (0.92, 9, 0.76, 0.05), (1.0, 0, 0.5, 0.0)]),
    ("m3-clocks", ["10-timer-analog", "9-timer-hourglass"],
     "Pick your clock", "Ten timer styles, from analog to hourglass.", False,
     [(0.96, -5, 0.31, 0.02), (1.0, 5, 0.69, 0.0)]),
    ("m4-score-story", ["3-scores", "4-chart"],
     "Scores, then the story", "Running totals become a race chart.", False,
     [(0.96, -5, 0.31, 0.02), (1.0, 5, 0.69, 0.0)]),
    ("m5-night", ["11-dice-dark", "6-theme-gaslight"],
     "Built for late nights", "True dark modes for dim rooms.", True,
     [(0.96, -5, 0.31, 0.02), (1.0, 5, 0.69, 0.0)]),
    ("m6-tables", ["8-players", "3-scores"],
     "Every table, remembered", "Game nights keep their own rosters and scores.", False,
     [(0.96, -5, 0.31, 0.02), (1.0, 5, 0.69, 0.0)]),
    ("m7-spread", ["5-settings", "4-chart", "2-timer", "1-dice"],
     "One app on the table", "Replace the dice, the clock, and the pad.", False,
     [(0.86, -14, 0.14, 0.10), (0.86, 14, 0.86, 0.10),
      (0.93, -6, 0.34, 0.03), (1.0, 4, 0.62, 0.0)]),
]

# device -> (canvas size, front-shot width fraction for singles/multis)
DEVICES = {
    "iphone-6.9": {"size": (1320, 2868), "single_w": 0.84, "multi_w": 0.72},
    "ipad-13": {"size": (2064, 2752), "single_w": 0.80, "multi_w": 0.68},
    "mac": {"size": (2560, 1600), "single_w": 0.72, "multi_w": 0.52},
}


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


def load_card(path, width, radius, rotation):
    """A screenshot as a rounded 'card', optionally rotated, plus its soft shadow."""
    shot = Image.open(path).convert("RGB")
    shot = shot.resize((width, round(shot.height * width / shot.width)), Image.LANCZOS)
    card = rounded(shot, radius)
    if rotation:
        card = card.rotate(rotation, expand=True, resample=Image.BICUBIC)
    shadow = Image.new("RGBA", card.size, (0, 0, 0, 0))
    shadow.putalpha(card.getchannel("A").point(lambda a: a * 130 // 255))
    return card, shadow


def draw_caption(canvas, headline, sub, cfg, dark):
    """Draws the caption block, returns the y where artwork may start."""
    w, h = canvas.size
    scale = cfg["cap_scale"]
    headline_font = font("/System/Library/Fonts/NewYork.ttf", round(86 * scale), 640)
    sub_font = font("/System/Library/Fonts/SFNS.ttf", round(44 * scale))
    draw = ImageDraw.Draw(canvas)
    top_pad = round(120 * scale)
    fg = CREAM if dark else INK
    fg_soft = CREAM_SOFT if dark else INK_SOFT
    hw = draw.textbbox((0, 0), headline, font=headline_font)
    draw.text(((w - (hw[2] - hw[0])) / 2, top_pad), headline, font=headline_font, fill=fg)
    sw = draw.textbbox((0, 0), sub, font=sub_font)
    sub_y = top_pad + (hw[3] - hw[1]) + round(46 * scale)
    draw.text(((w - (sw[2] - sw[0])) / 2, sub_y), sub, font=sub_font, fill=fg_soft)
    return sub_y + (sw[3] - sw[1]) + round(90 * scale)


def new_canvas(size, dark):
    return vertical_gradient(size, NIGHT_TOP if dark else PARCHMENT_TOP,
                             NIGHT_BOTTOM if dark else PARCHMENT_BOTTOM).convert("RGBA")


def save(canvas, path):
    canvas.convert("RGB").crop((0, 0, *canvas.size)).save(path)
    print(f"  {path.relative_to(OUT)}")


def compose_single(device, cfg, out_dir):
    w, h = cfg["size"]
    for name, headline, sub, dark in SINGLES:
        src = ROOT / device / f"{name}.png"
        if not src.exists():
            print(f"  skip {device}/{name} (no source)")
            continue
        canvas = new_canvas((w, h), dark)
        shot_top = draw_caption(canvas, headline, sub, cfg, dark)
        radius = round(56 * cfg["cap_scale"])
        card, shadow = load_card(src, round(w * cfg["single_w"]), radius, 0)
        blur = round(28 * cfg["cap_scale"])
        shadow = shadow.filter(ImageFilter.GaussianBlur(blur))
        x = (w - card.width) // 2
        canvas.alpha_composite(shadow, (x, shot_top + round(16 * cfg["cap_scale"])))
        canvas.alpha_composite(card, (x, shot_top))
        save(canvas, out_dir / f"{name}.png")


def compose_multi(device, cfg, out_dir):
    w, h = cfg["size"]
    for name, sources, headline, sub, dark, layout in MULTIS:
        paths = [ROOT / device / f"{s}.png" for s in sources]
        if not all(p.exists() for p in paths):
            print(f"  skip {device}/{name} (missing source)")
            continue
        canvas = new_canvas((w, h), dark)
        shot_top = draw_caption(canvas, headline, sub, cfg, dark)
        avail_h = h - shot_top
        front_w = round(w * cfg["multi_w"])
        radius = round(48 * cfg["cap_scale"])
        blur = round(24 * cfg["cap_scale"])
        for path, (rel_w, rot, cx, ny) in zip(paths, layout):
            card, shadow = load_card(path, round(front_w * rel_w), radius, rot)
            shadow = shadow.filter(ImageFilter.GaussianBlur(blur))
            x = round(w * cx - card.width / 2)
            y = shot_top + round(avail_h * ny)
            canvas.alpha_composite(shadow, (x, y + round(14 * cfg["cap_scale"])))
            canvas.alpha_composite(card, (x, y))
        save(canvas, out_dir / f"{name}.png")


if __name__ == "__main__":
    for device, cfg in DEVICES.items():
        print(f"==> {device}")
        # Caption sizes were tuned on the iPhone canvas; the Mac canvas is short and
        # wide, so it gets a smaller hand-picked scale instead of width-proportional.
        cfg["cap_scale"] = 1.10 if device == "mac" else cfg["size"][0] / 1320
        out_dir = OUT / device
        out_dir.mkdir(parents=True, exist_ok=True)
        compose_single(device, cfg, out_dir)
        compose_multi(device, cfg, out_dir)
    print("Done. See Screenshots/marketing/")

"""Generates docs/art/logo.png (400x400) and docs/art/banner.png (1280x320).

Run: python scripts/make_art.py   (needs Pillow; Windows fonts Georgia)
Palette: dark parchment, Classic gold, hunter green (the hunter class color #ABD473).
"""
import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

OUT = os.path.join(os.path.dirname(__file__), "..", "docs", "art")
FONT_BOLD = "C:/Windows/Fonts/georgiab.ttf"
FONT_ITALIC = "C:/Windows/Fonts/georgiai.ttf"

BG_DARK = (22, 20, 15)
BG_MID = (45, 38, 26)
GOLD = (201, 162, 39)
GOLD_LIGHT = (240, 208, 110)
GREEN = (171, 212, 115)
CREAM = (236, 226, 198)
SS = 4  # supersampling factor for smooth edges


def radial_bg(size, inner, outer):
    w, h = size
    img = Image.new("RGB", size, outer)
    px = img.load()
    cx, cy = w / 2, h / 2
    maxd = (cx ** 2 + cy ** 2) ** 0.5
    for y in range(h):
        for x in range(w):
            t = min(1.0, (((x - cx) ** 2 + (y - cy) ** 2) ** 0.5) / maxd)
            px[x, y] = tuple(int(inner[i] + (outer[i] - inner[i]) * t) for i in range(3))
    return img


def paw(draw, cx, cy, s, fill, outline=None, width=0):
    """Paw print centered at cx,cy; s = overall width."""
    def ell(x, y, rx, ry):
        draw.ellipse([x - rx, y - ry, x + rx, y + ry], fill=fill, outline=outline, width=width)
    ell(cx, cy + 0.14 * s, 0.30 * s, 0.24 * s)               # main pad
    ell(cx - 0.34 * s, cy - 0.08 * s, 0.10 * s, 0.14 * s)    # outer toes
    ell(cx + 0.34 * s, cy - 0.08 * s, 0.10 * s, 0.14 * s)
    ell(cx - 0.13 * s, cy - 0.27 * s, 0.10 * s, 0.15 * s)    # inner toes
    ell(cx + 0.13 * s, cy - 0.27 * s, 0.10 * s, 0.15 * s)


def logo_image(px):
    n = px * SS
    img = radial_bg((n // 2, n // 2), BG_MID, BG_DARK).resize((n, n), Image.BICUBIC)
    d = ImageDraw.Draw(img)
    c = n / 2
    # gold double ring (the "bond")
    for r, w in ((0.46, 0.022), (0.41, 0.008)):
        d.ellipse([c - r * n, c - r * n, c + r * n, c + r * n], outline=GOLD, width=int(w * n))
    # paw: dark offset shadow, gold outline, green fill
    paw(d, c + 0.012 * n, c + 0.03 * n, 0.50 * n, (10, 9, 6))
    paw(d, c, c + 0.02 * n, 0.50 * n, GREEN, outline=GOLD_LIGHT, width=int(0.008 * n))
    return img.resize((px, px), Image.LANCZOS)


def banner_image(w, h):
    n_w, n_h = w * SS, h * SS
    img = radial_bg((n_w // 4, n_h // 4), BG_MID, BG_DARK).resize((n_w, n_h), Image.BICUBIC)
    d = ImageDraw.Draw(img)
    # gold frame lines
    m = int(0.05 * n_h)
    d.rectangle([m, m, n_w - m, n_h - m], outline=GOLD, width=int(0.012 * n_h))
    d.rectangle([2 * m, 2 * m, n_w - 2 * m, n_h - 2 * m], outline=(120, 96, 28), width=int(0.005 * n_h))
    # logo on the left
    lh = int(0.74 * n_h)
    mask = Image.new("L", (lh, lh), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, lh - 1, lh - 1], fill=255)  # circular crop: no square background
    img.paste(logo_image(lh // SS).resize((lh, lh), Image.LANCZOS), (int(0.09 * n_h), (n_h - lh) // 2), mask)
    d = ImageDraw.Draw(img)
    tx = int(0.09 * n_h) + lh + int(0.10 * n_h)
    title = ImageFont.truetype(FONT_BOLD, int(0.27 * n_h))
    tag = ImageFont.truetype(FONT_ITALIC, int(0.085 * n_h))
    small = ImageFont.truetype(FONT_BOLD, int(0.062 * n_h))
    d.text((tx + 4, int(0.22 * n_h) + 4), "BeastBond", font=title, fill=(8, 7, 5))
    d.text((tx, int(0.22 * n_h)), "BeastBond", font=title, fill=GOLD_LIGHT)
    d.text((tx, int(0.55 * n_h)), "Forge the bond with your beast.", font=tag, fill=CREAM)
    d.text((tx, int(0.70 * n_h)), "MOOD  -  BOND  -  CARE   |   WOW: FOREVER HUNTER ADDON", font=small, fill=GREEN)
    return img.resize((w, h), Image.LANCZOS)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    logo_image(400).save(os.path.join(OUT, "logo.png"), optimize=True)
    banner_image(1280, 320).save(os.path.join(OUT, "banner.png"), optimize=True)
    print("wrote", os.path.abspath(OUT))

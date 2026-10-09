"""Generates the in-game textures in Media/ (32-bit TGA, power-of-two sizes).

Run: python scripts/make_textures.py   (needs Pillow)
Style: classic WoW. Dark leather and gold trim for the card, gold portrait rings,
a glossy bond bar, and a parchment page for the journal.
Note: the game only sees NEW texture files after a full restart (not /reload).
"""
import os
import random
from PIL import Image, ImageChops, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(__file__), "..", "Media")
SS = 4  # supersampling for smooth edges
GOLD = (201, 162, 39)
GOLD_LIGHT = (240, 208, 110)
GOLD_DARK = (122, 97, 24)
INK = (10, 6, 3)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def vgrad(size, top, bottom):
    w, h = size
    img = Image.new("RGB", size)
    d = ImageDraw.Draw(img)
    for y in range(h):
        d.line([(0, y), (w, y)], fill=lerp(top, bottom, y / max(1, h - 1)))
    return img


def save(img, name):
    os.makedirs(OUT, exist_ok=True)
    img.save(os.path.join(OUT, name), compression=None)


def card():
    """256x128 sheet; the used part is the top 84 rows (the card is 256x84)."""
    w, h, ch = 256, 128, 84
    W, H, CH = w * SS, h * SS, ch * SS
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    body = vgrad((W, CH), (58, 40, 26), (24, 16, 10))
    grain = Image.effect_noise((W, CH), 30).convert("RGB")
    body = Image.blend(body, ImageChops.overlay(body, grain), 0.28)
    mask = Image.new("L", (W, CH), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, W - 1, CH - 1], radius=12 * SS, fill=255)
    img.paste(body, (0, 0), mask)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, W - 1, CH - 1], radius=12 * SS, outline=GOLD, width=2 * SS)
    d.rounded_rectangle([2 * SS, 2 * SS, W - 1 - 2 * SS, CH - 1 - 2 * SS], radius=10 * SS, outline=INK, width=SS)
    d.rounded_rectangle([4 * SS, 4 * SS, W - 1 - 4 * SS, CH - 1 - 4 * SS], radius=8 * SS, outline=GOLD_DARK, width=SS)
    # corner studs
    for x, y in [(9, 9), (w - 10, 9), (9, ch - 10), (w - 10, ch - 10)]:
        r = 2.4 * SS
        d.ellipse([x * SS - r, y * SS - r, x * SS + r, y * SS + r], fill=GOLD_LIGHT, outline=INK)
    save(img.resize((w, h), Image.LANCZOS), "card.tga")


def ring():
    """64x64 gold ring with a transparent centre (the portrait shows through)."""
    n = 64 * SS
    img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    grad = Image.new("RGB", (n, n))
    gd = ImageDraw.Draw(grad)
    for i in range(2 * n):
        gd.line([(i, 0), (0, i)], fill=lerp((252, 228, 140), (110, 82, 16), i / (2 * n)))
    mask = Image.new("L", (n, n), 0)
    md = ImageDraw.Draw(mask)
    c = n / 2
    md.ellipse([c - 31 * SS, c - 31 * SS, c + 31 * SS, c + 31 * SS], fill=255)
    md.ellipse([c - 23 * SS, c - 23 * SS, c + 23 * SS, c + 23 * SS], fill=0)
    img.paste(grad, (0, 0), mask)
    d = ImageDraw.Draw(img)
    d.ellipse([c - 31 * SS, c - 31 * SS, c + 31 * SS, c + 31 * SS], outline=(35, 25, 8), width=SS)
    d.ellipse([c - 23 * SS, c - 23 * SS, c + 23 * SS, c + 23 * SS], outline=(35, 25, 8), width=SS)
    d.ellipse([c - 28 * SS, c - 28 * SS, c + 28 * SS, c + 28 * SS], outline=(255, 240, 175, 150), width=SS // 2)
    save(img.resize((64, 64), Image.LANCZOS), "ring.tga")


def barframe():
    """256x32 groove with gold trim and a transparent window, drawn over the bar fill."""
    w, h = 256 * SS, 32 * SS
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, w - 1, h - 1], radius=9 * SS, outline=GOLD, width=2 * SS)
    d.rounded_rectangle([2 * SS, 2 * SS, w - 1 - 2 * SS, h - 1 - 2 * SS], radius=7 * SS, outline=INK, width=2 * SS)
    for i in range(7 * SS):  # inner shadow at the top gives the groove depth
        a = int(120 * (1 - i / (7 * SS)))
        d.line([(7 * SS, 4 * SS + i), (w - 7 * SS, 4 * SS + i)], fill=(0, 0, 0, a))
    save(img.resize((256, 32), Image.LANCZOS), "barframe.tga")


def barfill():
    """256x16 glossy fill, near white so the game can tint it (green, gold at max rank)."""
    img = Image.new("RGBA", (256, 16))
    d = ImageDraw.Draw(img)
    for y in range(16):
        v = 255 - int(95 * (y / 15))
        if y < 6:
            v = min(255, v + 10)
        d.line([(0, y), (256, y)], fill=(v, v, v, 255))
    save(img, "barfill.tga")


def barback():
    """256x16 dark backing behind the fill."""
    save(vgrad((256, 16), (18, 12, 8), (40, 28, 18)).convert("RGBA"), "barback.tga")


def parchment():
    """512x512 aged paper with a vignette. Dark ink reads well on it."""
    n = 512
    base = Image.new("RGB", (n, n), (216, 197, 150))
    random.seed(7)
    mottle = Image.effect_noise((64, 64), 60).convert("RGB").resize((n, n), Image.BICUBIC).filter(ImageFilter.GaussianBlur(6))
    base = Image.blend(base, ImageChops.overlay(base, mottle), 0.55)
    grain = Image.effect_noise((n, n), 26).convert("RGB").filter(ImageFilter.GaussianBlur(0.7))
    base = Image.blend(base, ImageChops.overlay(base, grain), 0.30)
    vignette = Image.new("L", (n, n), 0)
    px = vignette.load()
    c = n / 2
    for y in range(n):
        for x in range(n):
            dist = ((x - c) ** 2 + (y - c) ** 2) ** 0.5 / (c * 1.414)
            px[x, y] = int(255 * min(1.0, dist ** 2.3) * 0.85)
    edge = Image.new("RGB", (n, n), (96, 64, 30))
    base = Image.composite(edge, base, vignette)
    d = ImageDraw.Draw(base)
    d.rectangle([0, 0, n - 1, n - 1], outline=(70, 46, 20), width=3)
    save(base.convert("RGBA"), "parchment.tga")


def divider():
    """256x16 gold rule with a diamond in the middle."""
    w, h = 256 * SS, 16 * SS
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cy = h // 2
    for x in range(w):
        t = abs(x - w / 2) / (w / 2)
        a = int(255 * (1 - t ** 1.6))
        d.line([(x, cy - SS), (x, cy + SS - 1)], fill=GOLD + (a,))
    r = 6 * SS
    d.polygon([(w / 2, cy - r), (w / 2 + r, cy), (w / 2, cy + r), (w / 2 - r, cy)], fill=GOLD_LIGHT, outline=INK)
    for off in (-22, 22):
        x = w / 2 + off * SS
        rr = 2 * SS
        d.ellipse([x - rr, cy - rr, x + rr, cy + rr], fill=GOLD_LIGHT, outline=INK)
    save(img.resize((256, 16), Image.LANCZOS), "divider.tga")


def paw(d, cx, cy, size, fill, outline, width):
    """Paw print centred at cx, cy; size = overall width."""
    def ell(x, y, rx, ry):
        d.ellipse([x - rx, y - ry, x + rx, y + ry], fill=fill, outline=outline, width=width)
    ell(cx, cy + 0.14 * size, 0.30 * size, 0.24 * size)
    ell(cx - 0.34 * size, cy - 0.08 * size, 0.10 * size, 0.14 * size)
    ell(cx + 0.34 * size, cy - 0.08 * size, 0.10 * size, 0.14 * size)
    ell(cx - 0.13 * size, cy - 0.27 * size, 0.10 * size, 0.15 * size)
    ell(cx + 0.13 * size, cy - 0.27 * size, 0.10 * size, 0.15 * size)


def emblem():
    """64x64 round medallion with a gold paw: the journal's header icon (sits inside ring.tga)."""
    n = 64 * SS
    img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    c = n / 2
    disc = Image.new("RGB", (n, n))
    px = disc.load()
    for y in range(n):
        for x in range(n):
            t = min(1.0, (((x - c) ** 2 + (y - c) ** 2) ** 0.5) / c)
            px[x, y] = lerp((62, 70, 40), (22, 26, 14), t ** 1.4)
    mask = Image.new("L", (n, n), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, n - 1, n - 1], fill=255)
    img.paste(disc, (0, 0), mask)
    d = ImageDraw.Draw(img)
    d.ellipse([3 * SS, 3 * SS, n - 3 * SS, n - 3 * SS], outline=(120, 96, 28, 200), width=SS)
    paw(d, c + SS, c + 3 * SS, 0.66 * n, (10, 8, 4), None, 0)  # soft shadow
    paw(d, c, c + 2 * SS, 0.66 * n, (232, 192, 84), (60, 44, 10), SS)
    save(img.resize((64, 64), Image.LANCZOS), "emblem.tga")


if __name__ == "__main__":
    for fn in (card, ring, emblem, barframe, barfill, barback, parchment, divider):
        fn()
    print("wrote", os.path.abspath(OUT))

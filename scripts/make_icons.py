#!/usr/bin/env python3
"""Generate PWA icons for Fridge Chef.

Draws a simple fridge + fork mark on a warm background. Produces the maskable
and any-purpose sizes the web manifest references, plus an Apple touch icon and
a favicon. Run from the repo root:  python3 scripts/make_icons.py
"""
import os
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "..", "app", "public", "icons")
os.makedirs(OUT, exist_ok=True)

BG = (34, 139, 110)        # teal-green
BG_DARK = (24, 105, 83)
FRIDGE = (245, 241, 234)   # cream
FRIDGE_SHADOW = (224, 217, 204)
ACCENT = (232, 122, 65)    # terracotta
LINE = (60, 60, 60)


def draw_icon(size, maskable=False):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    s = size / 512.0

    # Background. Maskable needs full-bleed with the art kept inside the safe
    # zone (~80%); non-maskable gets a rounded square.
    if maskable:
        d.rectangle([0, 0, size, size], fill=BG)
    else:
        r = int(96 * s)
        d.rounded_rectangle([0, 0, size - 1, size - 1], radius=r, fill=BG)

    pad = 0.20 if maskable else 0.0
    inset = size * pad

    def px(x, y):
        # map a 0..512 design coordinate into the (possibly inset) canvas
        scale = (size - 2 * inset) / 512.0
        return (inset + x * scale, inset + y * scale)

    # Fridge body
    body = [px(150, 70), px(362, 442)]
    d.rounded_rectangle([body[0][0], body[0][1], body[1][0], body[1][1]],
                        radius=int(34 * s), fill=FRIDGE)
    # divider between freezer and fridge
    dy = px(150, 190)[1]
    d.line([px(150, 190)[0] + 6 * s, dy, px(362, 190)[0] - 6 * s, dy],
           fill=FRIDGE_SHADOW, width=max(2, int(8 * s)))
    # handles
    d.rounded_rectangle([px(318, 110)[0], px(318, 110)[1], px(330, 168)[0], px(330, 168)[1]],
                        radius=int(8 * s), fill=ACCENT)
    d.rounded_rectangle([px(318, 214)[0], px(318, 214)[1], px(330, 300)[0], px(330, 300)[1]],
                        radius=int(8 * s), fill=ACCENT)

    # A fork over the fridge door to say "food"
    fx = 250
    d.line([px(fx, 250), px(fx, 410)], fill=ACCENT, width=max(3, int(14 * s)))
    for tx in (232, 242, 252, 262):
        d.line([px(tx, 250), px(tx, 300)], fill=ACCENT, width=max(2, int(7 * s)))
    d.ellipse([px(228, 250)[0], px(228, 250)[1], px(266, 312)[0], px(266, 312)[1]],
              outline=ACCENT, width=max(2, int(7 * s)))

    return img


def save(img, name):
    img.save(os.path.join(OUT, name))
    print("wrote", name)


save(draw_icon(192), "icon-192.png")
save(draw_icon(512), "icon-512.png")
save(draw_icon(512, maskable=True), "icon-maskable-512.png")
save(draw_icon(180), "apple-touch-icon.png")
save(draw_icon(64), "favicon-64.png")
print("done")

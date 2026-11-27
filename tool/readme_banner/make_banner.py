"""The README banner: the purple-to-magenta gradient, the envelopes, the logo
and the title (taken from the previous banner), and a row with one icon and
label per package.

    python3 tool/readme_banner/make_banner.py <MaterialIcons-Regular.otf> <bold.ttf> <source.jpg> <out.png>

MaterialIcons-Regular.otf ships with Flutter (bin/cache/artifacts/material_fonts).
"""
import sys
from PIL import Image, ImageDraw, ImageFont
import numpy as np

ICONS, BOLD, SOURCE, OUT = sys.argv[1:5]
W, H = 2170, 725
LEFT, RIGHT = (145, 12, 185), (174, 21, 158)

# label, Flutter's Icons code point (the example apps' icons: tool/example_icons)
PACKAGES = [
    ("Local", 0xe44f),           # Icons.notifications
    ("Push", 0xe16f),            # Icons.cloud
    ("Schedule", 0xe556),        # Icons.schedule
    ("Translation", 0xe67b),     # Icons.translate
    ("Media", 0xe415),           # Icons.music_note
    ("Chat", 0xe153),            # Icons.chat
    ("Call", 0xe126),            # Icons.call
    ("Live Activities", 0xe0ee), # Icons.bolt
]

src = np.asarray(Image.open(SOURCE).convert("RGB").resize((W, H), Image.LANCZOS)).astype(float)
lum = src.mean(axis=2)

# The previous banner's background: bilinear between its corners.
c = [lum[:20, :20].mean(), lum[:20, -20:].mean(), lum[-20:, :20].mean(), lum[-20:, -20:].mean()]
ys, xs = np.mgrid[0:H, 0:W]
fx, fy = xs / (W - 1), ys / (H - 1)
bg = (c[0] * (1 - fx) + c[1] * fx) * (1 - fy) + (c[2] * (1 - fx) + c[3] * fx) * fy
# How white each pixel is over that background (0: background, 1: white).
alpha = np.clip((lum - bg) / (255 - bg), 0, 1)
# The previous banner's compression noise and shading are not drawings.
alpha = np.where(alpha < 0.08, 0, alpha)

# Its title block (logo, "Awesome Notifications", "for Flutter") and its old
# text line at the bottom.
TITLE = (460, 220, 1720, 405)
OLD_LINE = (350, 560, 1820, 670)
TITLE_UP = 70

def box(b):
    m = np.zeros((H, W), bool)
    m[b[1]:b[3], b[0]:b[2]] = True
    return m

envelopes = np.where(box(TITLE) | box(OLD_LINE), 0, alpha)
title = np.zeros_like(alpha)
x0, y0, x1, y1 = TITLE
title[y0 - TITLE_UP:y1 - TITLE_UP, x0:x1] = alpha[y0:y1, x0:x1]

# The gradient.
t = (xs / (W - 1))[..., None]
image = np.array(LEFT, float) * (1 - t) + np.array(RIGHT, float) * t
for layer in (envelopes, title):
    image = image * (1 - layer[..., None]) + 255 * layer[..., None]
out = Image.fromarray(image.clip(0, 255).astype(np.uint8))

# The packages' row: each item as wide as its label, a "+" between them,
# spread over the banner's width.
draw = ImageDraw.Draw(out)
icon_font = ImageFont.truetype(ICONS, 68)
label_font = ImageFont.truetype(BOLD, 36)
widths = [draw.textlength(label, font=label_font) for label, _ in PACKAGES]
plus_width = (W * 0.92 - sum(widths)) / (len(PACKAGES) - 1)
x = (W - (sum(widths) + plus_width * (len(PACKAGES) - 1))) / 2
icon_y, label_y = 555, 635
for i, ((label, code), width) in enumerate(zip(PACKAGES, widths)):
    if i:
        draw.text((x + plus_width / 2, label_y), "+", font=label_font, fill="white", anchor="mm")
        x += plus_width
    cx = x + width / 2
    draw.text((cx, icon_y), chr(code), font=icon_font, fill="white", anchor="mm")
    draw.text((cx, label_y), label, font=label_font, fill="white", anchor="mm")
    x += width
out.save(OUT, optimize=True)

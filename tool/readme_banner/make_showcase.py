"""Composes a package README's showcase image (assets/readme/awesome-notifications-<feature>.jpg) in the style of the media package's one:
the purple gradient, outlined envelopes, three device screens with rounded
corners and white curved arrows.

    python3 compose.py <spec.json> <out.jpg>

spec: {"panels": [panel, panel, panel], "arrows": [[x0,y0,cx,cy,x1,y1], ...]}
panel: {"x", "y", "w"} plus either
  {"screen": "<png>", "blur": [[x0,y0,x1,y1], ...]}  (blur boxes in screen px)
  {"shade": "<name>", "cards": ["<png>", ...]}        (an Android shade rebuilt
     from its header and our own notification cards only)
"""
import json, math, random, sys
from PIL import Image, ImageDraw, ImageFilter

W, H = 1670, 1272
TOP, BOTTOM = (170, 74, 220), (115, 11, 178)
SS = 2  # supersampling for the vector drawings


def background():
    img = Image.new('RGB', (W, H))
    px = img.load()
    for y in range(H):
        t = y / (H - 1)
        c = tuple(round(TOP[i] * (1 - t) + BOTTOM[i] * t) for i in range(3))
        for x in range(W):
            px[x, y] = c
    layer = Image.new('RGBA', (W * SS, H * SS), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    rnd = random.Random(7)
    placed = []
    tries = 0
    while len(placed) < 34 and tries < 4000:
        tries += 1
        w = rnd.uniform(45, 110)
        x, y = rnd.uniform(-20, W + 20), rnd.uniform(-20, H + 20)
        if any(math.hypot(x - a, y - b) < (w + c) * 0.9 for a, b, c in placed):
            continue
        placed.append((x, y, w))
        h = w * 0.62
        ang = math.radians(rnd.uniform(-35, 35))
        alpha = int(255 * rnd.uniform(0.14, 0.24))

        def pt(u, v):
            return ((x + u * math.cos(ang) - v * math.sin(ang)) * SS,
                    (y + u * math.sin(ang) + v * math.cos(ang)) * SS)
        corners = [pt(-w / 2, -h / 2), pt(w / 2, -h / 2), pt(w / 2, h / 2), pt(-w / 2, h / 2)]
        lw = int(3 * SS)
        col = (255, 255, 255, alpha)
        d.line(corners + [corners[0]], fill=col, width=lw, joint='curve')
        d.line([corners[0], pt(0, h * 0.08), corners[1]], fill=col, width=lw, joint='curve')
        d.line([corners[3], pt(-w * 0.12, -h * 0.02)], fill=col, width=lw)
        d.line([corners[2], pt(w * 0.12, -h * 0.02)], fill=col, width=lw)
    layer = layer.resize((W, H), Image.LANCZOS)
    img.paste(layer, (0, 0), layer)
    return img


def shade_image(spec):
    """The shade's header (status bar + quick settings), then our cards, then
    the shade's own background colour down to the screen's height."""
    name = spec['shade']
    (sw, sh), _, first_top, samples = eval(open(name + '_bg.txt').read())
    top = Image.open(name + '_top.png').convert('RGB')
    bg = tuple(sorted(samples)[len(samples) // 2])
    img = Image.new('RGB', (sw, sh), bg)
    img.paste(top, (0, 0))
    y = first_top
    for path in spec['cards']:
        card = Image.open(path).convert('RGB')
        r = 56
        m = Image.new('L', (card.width * SS, card.height * SS), 0)
        ImageDraw.Draw(m).rounded_rectangle((0, 0, card.width * SS - 1, card.height * SS - 1), r * SS, fill=255)
        m = m.resize(card.size, Image.LANCZOS)
        img.paste(card, (40, y), m)
        y += card.height + 16
    return img


def panel(img, spec):
    if 'shade' in spec:
        shot = shade_image(spec)
    else:
        shot = Image.open(spec['screen']).convert('RGB')
        for box in spec.get('blur', []):
            region = shot.crop(box).filter(ImageFilter.GaussianBlur(18))
            shot.paste(region, box[:2])
    if 'crop' in spec:
        shot = shot.crop(spec['crop'])
    w = spec['w']
    h = round(shot.height * w / shot.width)
    shot = shot.resize((w, h), Image.LANCZOS)
    r = spec.get('radius', 14)
    mask = Image.new('L', (w * SS, h * SS), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, w * SS - 1, h * SS - 1), r * SS, fill=255)
    mask = mask.resize((w, h), Image.LANCZOS)
    shadow = Image.new('RGBA', img.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        (spec['x'] + 6, spec['y'] + 12, spec['x'] + w + 6, spec['y'] + h + 12), r, fill=(40, 0, 70, 90))
    shadow = shadow.filter(ImageFilter.GaussianBlur(16))
    img.paste(shadow, (0, 0), shadow)
    img.paste(shot, (spec['x'], spec['y']), mask)


def arrows(img, specs):
    layer = Image.new('RGBA', (W * SS, H * SS), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for x0, y0, cx, cy, x1, y1 in specs:
        pts = []
        for i in range(61):
            t = i / 60
            x = (1 - t) ** 2 * x0 + 2 * (1 - t) * t * cx + t ** 2 * x1
            y = (1 - t) ** 2 * y0 + 2 * (1 - t) * t * cy + t ** 2 * y1
            pts.append((x * SS, y * SS))
        d.line(pts, fill=(255, 255, 255, 255), width=10 * SS, joint='curve')
        # the head, along the curve's final direction
        dx, dy = x1 - cx, y1 - cy
        n = math.hypot(dx, dy)
        dx, dy = dx / n, dy / n
        L, Wd = 44, 24
        tip = (x1 * SS, y1 * SS)
        for s in (1, -1):
            bx = x1 - dx * L - dy * Wd * s
            by = y1 - dy * L + dx * Wd * s
            d.line([tip, (bx * SS, by * SS)], fill=(255, 255, 255, 255), width=10 * SS)
            d.ellipse((bx * SS - 5 * SS, by * SS - 5 * SS, bx * SS + 5 * SS, by * SS + 5 * SS), fill=(255, 255, 255, 255))
        d.ellipse((tip[0] - 5 * SS, tip[1] - 5 * SS, tip[0] + 5 * SS, tip[1] + 5 * SS), fill=(255, 255, 255, 255))
    layer = layer.resize((W, H), Image.LANCZOS)
    img.paste(layer, (0, 0), layer)


if __name__ == '__main__':
    spec = json.load(open(sys.argv[1]))
    img = background()
    for p in spec['panels']:
        panel(img, p)
    arrows(img, spec.get('arrows', []))
    img.save(sys.argv[2], quality=90, optimize=True)

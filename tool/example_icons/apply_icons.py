import sys, os, json, re
sys.path.insert(0, os.path.dirname(__file__))
from PIL import Image, ImageDraw
import make_icons as mk
mk.FONT = sys.argv[1]
ROOT = sys.argv[2]
APPS = {
  'awesome_notifications':               ('core',          'Awesome Notifications'),
  'awesome_notifications_schedules':     ('schedules',     'Awesome Schedules'),
  'awesome_notifications_localizations': ('localizations', 'Awesome Localizations'),
  'awesome_notifications_fcm':           ('fcm',           'Awesome Push'),
  'awesome_notifications_chat':          ('chat',          'Awesome Chat'),
  'awesome_notifications_media':         ('media',         'Awesome Media'),
  'awesome_notifications_calls':         ('calls',         'Awesome Calls'),
}
TOP = '#%02X%02X%02X' % mk.TOP; BOTTOM = '#%02X%02X%02X' % mk.BOTTOM

def sub(path, pattern, repl, count=1):
    if not os.path.exists(path): return False
    s = open(path).read(); n = re.subn(pattern, repl, s, count=count)
    if n[1]: open(path, 'w').write(n[0])
    return n[1] > 0

for pkg, (key, name) in APPS.items():
    ex = os.path.join(ROOT, 'packages', pkg, 'example')
    big = mk.icon(key, 1024)
    done = []
    # ---- Android
    res = os.path.join(ex, 'android/app/src/main/res')
    if os.path.isdir(res):
        for d, px in {'mdpi':48,'hdpi':72,'xhdpi':96,'xxhdpi':144,'xxxhdpi':192}.items():
            big.resize((px,px), Image.LANCZOS).convert('RGB').save(f'{res}/mipmap-{d}/ic_launcher.png')
        for d, px in {'mdpi':108,'hdpi':162,'xhdpi':216,'xxhdpi':324,'xxxhdpi':432}.items():
            mk.foreground(key, 432).resize((px,px), Image.LANCZOS).save(f'{res}/mipmap-{d}/ic_launcher_foreground.png')
        os.makedirs(f'{res}/mipmap-anydpi-v26', exist_ok=True)
        open(f'{res}/mipmap-anydpi-v26/ic_launcher.xml','w').write('''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
''')
        open(f'{res}/drawable/ic_launcher_background.xml','w').write(f'''<?xml version="1.0" encoding="utf-8"?>
<!-- The Awesome purple to pink gradient behind the adaptive icon. -->
<shape xmlns:android="http://schemas.android.com/apk/res/android">
    <gradient
        android:angle="315"
        android:startColor="{TOP}"
        android:endColor="{BOTTOM}"
        android:type="linear" />
</shape>
''')
        # Status bar (small) icon: Android draws only its alpha, so a white
        # glyph on transparent, on the 24dp grid. `res_` keeps it from being
        # shrunk in release builds (with raw/keep.xml), as 0.12 documents.
        for d, px in {'mdpi':24,'hdpi':36,'xhdpi':48,'xxhdpi':72,'xxxhdpi':96}.items():
            os.makedirs(f'{res}/drawable-{d}', exist_ok=True)
            mk.glyph_layer(px*4, mk.GLYPHS[key], scale=20/24, alpha=1.0).resize((px,px), Image.LANCZOS).save(f'{res}/drawable-{d}/res_notification_icon.png')
        os.makedirs(f'{res}/raw', exist_ok=True)
        open(f'{res}/raw/keep.xml','w').write('''<?xml version="1.0" encoding="utf-8"?>
<!-- Keeps the notification icon, referenced only by name from Dart. -->
<resources xmlns:tools="http://schemas.android.com/tools"
    tools:keep="@drawable/res_notification_icon" />
''')
        sub(os.path.join(ex,'android/app/src/main/AndroidManifest.xml'), r'android:label="[^"]*"', f'android:label="{name}"')
        done.append('android')
    # ---- iOS
    set_ = os.path.join(ex, 'ios/Runner/Assets.xcassets/AppIcon.appiconset')
    if os.path.isdir(set_):
        for img in json.load(open(f'{set_}/Contents.json'))['images']:
            if 'filename' not in img: continue
            pts = float(img['size'].split('x')[0]); sc = int(img['scale'].rstrip('x'))
            px = int(round(pts*sc))
            big.resize((px,px), Image.LANCZOS).convert('RGB').save(f"{set_}/{img['filename']}")
        sub(os.path.join(ex,'ios/Runner/Info.plist'), r'(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)', rf'\g<1>{name}\g<2>')
        done.append('ios')
    # ---- macOS (rounded tile with the standard margin)
    set_ = os.path.join(ex, 'macos/Runner/Assets.xcassets/AppIcon.appiconset')
    if os.path.isdir(set_):
        tile = Image.new('RGBA',(1024,1024),(0,0,0,0))
        inner = mk.icon(key, 824)
        mask = Image.new('L',(824,824),0); ImageDraw.Draw(mask).rounded_rectangle((0,0,823,823),radius=185,fill=255)
        tile.paste(inner,(100,100),mask)
        for img in json.load(open(f'{set_}/Contents.json'))['images']:
            if 'filename' not in img: continue
            px = int(round(float(img['size'].split('x')[0])*int(img['scale'].rstrip('x'))))
            tile.resize((px,px), Image.LANCZOS).save(f"{set_}/{img['filename']}")
        sub(os.path.join(ex,'macos/Runner/Configs/AppInfo.xcconfig'), r'PRODUCT_NAME = .*', f'PRODUCT_NAME = {name}')
        done.append('macos')
    # ---- Web
    web = os.path.join(ex, 'web')
    if os.path.isdir(web):
        big.resize((32,32), Image.LANCZOS).save(f'{web}/favicon.png')
        for f, px in {'Icon-192.png':192,'Icon-512.png':512,'Icon-maskable-192.png':192,'Icon-maskable-512.png':512}.items():
            if os.path.exists(f'{web}/icons/{f}'): big.resize((px,px), Image.LANCZOS).save(f'{web}/icons/{f}')
        m = json.load(open(f'{web}/manifest.json')); m['name']=name; m['short_name']=name
        m['background_color']=TOP; m['theme_color']=TOP
        open(f'{web}/manifest.json','w').write(json.dumps(m, indent=4)+'\n')
        sub(f'{web}/index.html', r'<title>[^<]*</title>', f'<title>{name}</title>')
        sub(f'{web}/index.html', r'(name="apple-mobile-web-app-title" content=")[^"]*', rf'\g<1>{name}')
        done.append('web')
    # ---- Windows
    win = os.path.join(ex, 'windows/runner')
    if os.path.isdir(win):
        big.convert('RGBA').save(f'{win}/resources/app_icon.ico', sizes=[(16,16),(24,24),(32,32),(48,48),(64,64),(128,128),(256,256)])
        sub(f'{win}/main.cpp', r'window\.Create\(L"[^"]*"', f'window.Create(L"{name}"')
        for k in ('FileDescription','ProductName'):
            sub(f'{win}/Runner.rc', rf'(VALUE "{k}", ")[^"]*', rf'\g<1>{name}')
        done.append('windows')
    # ---- Linux
    lin = os.path.join(ex, 'linux/runner/my_application.cc')
    if os.path.exists(lin):
        sub(lin, r'gtk_header_bar_set_title\(header_bar, "[^"]*"\)', f'gtk_header_bar_set_title(header_bar, "{name}")')
        sub(lin, r'gtk_window_set_title\(window, "[^"]*"\)', f'gtk_window_set_title(window, "{name}")')
        done.append('linux')
    print(f'{pkg}: {name} -> {", ".join(done)}')

# Example app icons and names

Generates every example app's icon (the Awesome purple → pink gradient with a
white glyph at 86% opacity, one Material glyph per package) and sets its name,
on every platform the example has.

```bash
pip3 install pillow
FONT="$(dirname "$(dirname "$(which flutter)")")/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf"
python3 tool/example_icons/apply_icons.py "$FONT" .
```

Glyphs, colors and names are at the top of `make_icons.py` and `apply_icons.py`
(glyph codepoints are Flutter's `Icons.*` values).

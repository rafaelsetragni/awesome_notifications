import sys, math
from PIL import Image, ImageDraw, ImageFont, ImageFilter
FONT=sys.argv[1]; OUT=sys.argv[2]
# Awesome purple -> pink (from the 0.12 icon and logo)
TOP=(0x7B,0x0A,0xC4); BOTTOM=(0xC2,0x18,0x8E)
GLYPHS={'core':0xe44f,'schedules':0xe556,'localizations':0xe67b,'fcm':0xe16f,'chat':0xe153,'media':0xe415,'calls':0xe126,'live_activities':0xe0ee}
def background(size):
    img=Image.new('RGB',(size,size))
    px=img.load()
    for y in range(size):
        for x in range(size):
            t=min(1,max(0,(x*0.35+y)/(size*1.35)))   # diagonal: purple top-left -> pink bottom-right
            px[x,y]=tuple(int(TOP[i]+(BOTTOM[i]-TOP[i])*t) for i in range(3))
    return img
def glyph_layer(size, code, scale=0.56, alpha=0.86):
    # Drawn on a larger canvas, then centered by its drawn pixels: the font's
    # text box doesn't match the glyph's ink, which left it off center.
    font=ImageFont.truetype(FONT,int(size*scale))
    big=Image.new('RGBA',(size*2,size*2),(0,0,0,0))
    ImageDraw.Draw(big).text((size//2,size//2),chr(code),font=font,fill=(255,255,255,int(255*alpha)))
    ink=big.crop(big.getchannel('A').getbbox())
    layer=Image.new('RGBA',(size,size),(0,0,0,0))
    layer.paste(ink,((size-ink.width)//2,(size-ink.height)//2))
    return layer
def icon(name,size=1024,scale=0.56):
    bg=background(size).convert('RGBA')
    return Image.alpha_composite(bg,glyph_layer(size,GLYPHS[name],scale))
def foreground(name,size=432):   # Android adaptive foreground: glyph inside the 66% safe zone
    return glyph_layer(size,GLYPHS[name],scale=0.42)
if __name__=='__main__':
    sheet=Image.new('RGB',(6*272+16,288),(245,245,245))
    for i,n in enumerate(GLYPHS):
        ic=icon(n,256).resize((256,256))
        mask=Image.new('L',(256,256),0); ImageDraw.Draw(mask).rounded_rectangle((0,0,255,255),radius=56,fill=255)
        sheet.paste(ic,(16+i*272,16),mask)
    sheet.save(OUT+'/preview.png')

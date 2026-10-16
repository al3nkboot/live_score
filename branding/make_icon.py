# Generates Mi5G Score icons (Mi5G branding: dark purple gradient, white "5G", green ball + lightning)
from PIL import Image, ImageDraw, ImageFont
import math
F='/workspace/apps/live_score/assets/fonts/Inter-ExtraBold.ttf'
S=2048; G=(34,197,94)
def grad(sz):
    im=Image.new('RGBA',(sz,sz)); d=ImageDraw.Draw(im)
    for y in range(sz):
        t=y/sz; c=tuple(int(a+(b-a)*t) for a,b in zip((0x2B,0x0A,0x63),(0x05,0x00,0x0C))); d.line([(0,y),(sz,y)],fill=c+(255,))
    return im
def art(sz, scale=1.0):
    im=Image.new('RGBA',(sz,sz),(0,0,0,0)); d=ImageDraw.Draw(im)
    c=sz/2; k=sz*scale
    # ball
    r=k*0.21; cx,cy=c,c-k*0.10
    d.ellipse([cx-r,cy-r,cx+r,cy+r],fill=G+(255,))
    # lightning bolt
    pts=[(0.10,-0.75),(-0.38,0.08),(-0.02,0.08),(-0.14,0.75),(0.38,-0.12),(0.02,-0.12),(0.14,-0.75)]
    d.polygon([(cx+x*r,cy+y*r) for x,y in pts],fill=(5,0,12,255))
    # 5G
    f=ImageFont.truetype(F,int(k*0.22)); t='5G'
    b=d.textbbox((0,0),t,font=f); w=b[2]-b[0]
    d.text((c-w/2-b[0], cy+r+k*0.04-b[1]),t,font=f,fill=(243,236,255,255))
    return im
def full(sz):
    bg=grad(S); bg.alpha_composite(art(S)); return bg.resize((sz,sz),Image.LANCZOS)
full(1024).save('icon-1024.png')
full(512).save('icon-512.png')
art(S,0.62).resize((1024,1024),Image.LANCZOS).save('icon-foreground.png')
# splash: art on transparent, smaller
art(S,0.9).resize((1152,1152),Image.LANCZOS).save('splash.png')
# rounded preview
p=full(512); m=Image.new('L',(512,512),0); ImageDraw.Draw(m).rounded_rectangle([0,0,511,511],110,fill=255)
o=Image.new('RGBA',(512,512),(0,0,0,0)); o.paste(p,(0,0),m); o.save('icon-squircle-512.png')

from PIL import Image, ImageDraw
from pathlib import Path

out = Path(r"D:\app\app\assets\images")
out.mkdir(parents=True, exist_ok=True)


def save(img, name):
    p = out / name
    img.save(p, "PNG")
    print(name, img.size, img.mode)


# --- Logo: script page + clapper, lake blue ---
S = 512
img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
blue = (37, 78, 144, 255)
white = (255, 255, 255, 255)

# open script (two pages)
d.polygon([(90, 150), (240, 130), (240, 390), (90, 410)], fill=blue)
d.polygon([(272, 130), (422, 150), (422, 410), (272, 390)], fill=blue)

# text lines as white cutouts
for y, x0, x1 in [(190, 115, 220), (230, 115, 220), (270, 115, 200), (310, 115, 220)]:
    d.rounded_rectangle([x0, y, x1, y + 14], radius=7, fill=white)
for y, x0, x1 in [(190, 292, 397), (230, 292, 397), (270, 292, 377), (310, 292, 397)]:
    d.rounded_rectangle([x0, y, x1, y + 14], radius=7, fill=white)

# clapperboard top-left
d.rounded_rectangle([70, 70, 250, 130], radius=10, fill=blue)
for i, x in enumerate(range(80, 250, 28)):
    if i % 2 == 0:
        d.polygon([(x, 70), (x + 16, 70), (x + 8, 120), (x - 8, 120)], fill=white)

# pen nib bottom-right
d.polygon([(360, 300), (430, 300), (430, 420), (395, 460), (360, 420)], fill=blue)
d.polygon([(375, 320), (415, 320), (415, 400), (395, 430), (375, 400)], fill=white)
d.ellipse([385, 360, 405, 380], fill=blue)

save(img, "logo_script.png")

# --- WeChat: two speech bubbles ---
img = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
green = (7, 193, 96, 255)
d.ellipse([40, 40, 170, 150], fill=green)
d.polygon([(70, 130), (55, 175), (100, 140)], fill=green)
d.ellipse([110, 100, 230, 205], fill=green)
d.polygon([(185, 185), (210, 230), (150, 195)], fill=green)
d.ellipse([145, 135, 161, 151], fill=(255, 255, 255, 255))
d.ellipse([185, 135, 201, 151], fill=(255, 255, 255, 255))

save(img, "icon_wechat.png")

# --- QQ: simple penguin ---
img = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
qq = (18, 183, 245, 255)
white = (255, 255, 255, 255)
orange = (255, 140, 0, 255)
d.ellipse([60, 70, 196, 230], fill=qq)
d.ellipse([78, 40, 178, 130], fill=qq)
d.ellipse([88, 120, 168, 220], fill=white)
d.ellipse([100, 75, 122, 97], fill=white)
d.ellipse([134, 75, 156, 97], fill=white)
d.ellipse([106, 81, 116, 91], fill=(20, 20, 30, 255))
d.ellipse([140, 81, 150, 91], fill=(20, 20, 30, 255))
d.polygon([(120, 100), (136, 100), (128, 114)], fill=orange)
d.ellipse([88, 215, 120, 238], fill=orange)
d.ellipse([136, 215, 168, 238], fill=orange)

save(img, "icon_qq.png")

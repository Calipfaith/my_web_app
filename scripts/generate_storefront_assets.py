from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
ASSET_DIR = ROOT / 'assets'
AMBER = (245, 166, 35, 255)
CREAM = (255, 248, 231, 255)
DARK = (43, 43, 43, 255)


def save_placeholder(name, accent, symbol):
    image = Image.new('RGBA', (800, 600), CREAM)
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle((48, 48, 752, 552), radius=48, fill=accent)
    draw.ellipse((250, 140, 550, 440), fill=DARK)
    draw.text((365, 270), symbol, fill=CREAM, anchor='mm')
    image.save(ASSET_DIR / name)


ASSET_DIR.mkdir(exist_ok=True)
image = Image.new('RGBA', (1000, 700), DARK)
draw = ImageDraw.Draw(image)
draw.rounded_rectangle((40, 40, 960, 660), radius=80, fill=AMBER)
draw.ellipse((385, 190, 615, 420), fill=DARK)
draw.ellipse((205, 190, 430, 400), fill=CREAM)
draw.ellipse((570, 190, 795, 400), fill=CREAM)
draw.rectangle((425, 350, 575, 520), fill=DARK)
for y in (385, 445):
    draw.rectangle((420, y, 580, y + 22), fill=AMBER)
draw.ellipse((435, 125, 565, 255), fill=DARK)
image.save(ASSET_DIR / 'hero_bee.png')

save_placeholder('placeholder_electronics.png', (214, 231, 236, 255), 'ELECTRONICS')
save_placeholder('placeholder_men.png', (218, 224, 235, 255), 'MEN')
save_placeholder('placeholder_women.png', (240, 215, 204, 255), 'WOMEN')
save_placeholder('placeholder_fashion.png', (240, 215, 204, 255), 'FASHION')
save_placeholder('placeholder_home.png', (219, 231, 211, 255), 'HOME')
save_placeholder('placeholder_beauty.png', (232, 216, 232, 255), 'BEAUTY')

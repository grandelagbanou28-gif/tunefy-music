from PIL import Image, ImageDraw, ImageFont
import math

def draw_hexagon(draw, cx, cy, r, fill):
    points = []
    for i in range(6):
        angle = math.radians(60 * i - 90)
        dx = cx + r * math.cos(angle)
        dy = cy + r * math.sin(angle)
        points.append((dx, dy))
    draw.polygon(points, fill=fill)

def gen_icon(size):
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size / 2, size / 2
    r = size * 0.46

    green_top = (29, 185, 84)
    green_bot = (21, 138, 62)

    img_bg = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw_bg = ImageDraw.Draw(img_bg)
    draw_hexagon(draw_bg, cx, cy, r, green_top)

    mask = Image.new('L', (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    points = []
    for i in range(6):
        angle = math.radians(60 * i - 90)
        dx = cx + r * math.cos(angle)
        dy = cy + r * math.sin(angle)
        points.append((dx, dy))
    mask_draw.polygon(points, fill=255)

    gradient = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    for y in range(size):
        t = y / size
        r_c = int(green_top[0] + (green_bot[0] - green_top[0]) * t)
        g_c = int(green_top[1] + (green_bot[1] - green_top[1]) * t)
        b_c = int(green_top[2] + (green_bot[2] - green_top[2]) * t)
        for x in range(size):
            gradient.putpixel((x, y), (r_c, g_c, b_c, 255))

    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    img.paste(gradient, mask=mask)

    draw = ImageDraw.Draw(img)
    font_size = int(size * 0.52)
    try:
        font = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", font_size)
    except:
        font = ImageFont.load_default()

    bbox = draw.textbbox((0, 0), "H", font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    tx = cx - tw / 2
    ty = cy - th / 2 - bbox[1]
    draw.text((tx, ty), "H", fill=(255, 255, 255, 255), font=font)

    return img

icon = gen_icon(1024)
icon.save("C:/flutter/My_music/Tunefy/assets/icon/icon.png")
icon.resize((192, 192)).save("C:/flutter/My_music/Tunefy/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png")
icon.resize((144, 144)).save("C:/flutter/My_music/Tunefy/android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png")
icon.resize((96, 96)).save("C:/flutter/My_music/Tunefy/android/app/src/main/res/mipmap-xhdpi/ic_launcher.png")
icon.resize((72, 72)).save("C:/flutter/My_music/Tunefy/android/app/src/main/res/mipmap-hdpi/ic_launcher.png")
icon.resize((48, 48)).save("C:/flutter/My_music/Tunefy/android/app/src/main/res/mipmap-mdpi/ic_launcher.png")
icon.resize((512, 512)).save("C:/flutter/My_music/Tunefy/images/hivefy_logo.png")
print("Icons generated!")

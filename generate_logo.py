"""
Genera il logo dell'app Spendly - 1024x1024.
Design: sfondo scuro con "S" stilizzata in gradiente viola→ciano,
cerchio decorativo, stile moderno e minimale.

Genera:
  - assets/icon/icon.png (1024x1024, sfondo pieno per iOS + fallback)
  - assets/icon/icon_foreground.png (1024x1024, sfondo trasparente per adaptive icon Android)
"""

from PIL import Image, ImageDraw, ImageFont
import math
import os

SIZE = 1024
CENTER = SIZE // 2

# Brand colors
PRIMARY = (108, 99, 255)      # #6C63FF viola
SECONDARY = (0, 217, 255)     # #00D9FF ciano
BG_DARK = (13, 13, 13)        # #0D0D0D
SURFACE = (26, 26, 46)        # #1A1A2E


def lerp_color(c1, c2, t):
    """Interpolazione lineare tra due colori."""
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))


def draw_gradient_rect(draw, bbox, c1, c2, direction='vertical'):
    """Riempie un rettangolo con un gradiente."""
    x0, y0, x1, y1 = bbox
    if direction == 'vertical':
        for y in range(y0, y1):
            t = (y - y0) / max(1, y1 - y0 - 1)
            color = lerp_color(c1, c2, t)
            draw.line([(x0, y), (x1, y)], fill=color)
    else:
        for x in range(x0, x1):
            t = (x - x0) / max(1, x1 - x0 - 1)
            color = lerp_color(c1, c2, t)
            draw.line([(x, y0), (x, y1)], fill=color)


def draw_rounded_rect(draw, bbox, radius, fill):
    """Rettangolo arrotondato."""
    x0, y0, x1, y1 = bbox
    draw.rectangle([x0 + radius, y0, x1 - radius, y1], fill=fill)
    draw.rectangle([x0, y0 + radius, x1, y1 - radius], fill=fill)
    draw.pieslice([x0, y0, x0 + 2 * radius, y0 + 2 * radius], 180, 270, fill=fill)
    draw.pieslice([x1 - 2 * radius, y0, x1, y0 + 2 * radius], 270, 360, fill=fill)
    draw.pieslice([x0, y1 - 2 * radius, x0 + 2 * radius, y1], 90, 180, fill=fill)
    draw.pieslice([x1 - 2 * radius, y1 - 2 * radius, x1, y1], 0, 90, fill=fill)


def create_gradient_circle(size, center, radius, c1, c2, alpha=255):
    """Crea un cerchio con gradiente radiale su immagine RGBA."""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    cx, cy = center
    for y in range(max(0, cy - radius), min(size, cy + radius)):
        for x in range(max(0, cx - radius), min(size, cx + radius)):
            dist = math.sqrt((x - cx) ** 2 + (y - cy) ** 2)
            if dist <= radius:
                t = dist / radius
                color = lerp_color(c1, c2, t)
                a = int(alpha * (1 - t * 0.3))
                img.putpixel((x, y), (*color, a))
    return img


def draw_s_letter(img, offset_x=0, offset_y=0):
    """Disegna una 'S' stilizzata con gradiente viola→ciano, composta da archi e linee."""
    draw = ImageDraw.Draw(img)
    
    # Parametri della S
    s_width = 340
    s_height = 480
    stroke_width = 72
    sx = CENTER - s_width // 2 + offset_x
    sy = CENTER - s_height // 2 + offset_y - 10

    # Creiamo la S come gradiente su un layer separato, poi la mascheriamo
    # Layer gradiente pieno
    grad_layer = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    for y in range(sy, sy + s_height):
        t = (y - sy) / max(1, s_height - 1)
        color = lerp_color(PRIMARY, SECONDARY, t)
        for x in range(SIZE):
            grad_layer.putpixel((x, y), (*color, 255))

    # Layer maschera per la forma della S
    mask = Image.new('L', (SIZE, SIZE), 0)
    mask_draw = ImageDraw.Draw(mask)
    
    half_h = s_height // 2
    r_top = half_h // 2
    r_bot = half_h // 2

    # Arco superiore (curva a destra, aperta a sinistra)
    top_box = [sx, sy, sx + s_width, sy + half_h]
    mask_draw.arc(top_box, 180, 360 + 45, fill=255, width=stroke_width)
    
    # Linea diagonale centrale
    mask_draw.line(
        [(sx + s_width // 2 + r_top // 2, sy + half_h // 2 + r_top // 3),
         (sx + s_width // 2 - r_bot // 2, sy + half_h + r_bot // 2 - r_bot // 3)],
        fill=255, width=stroke_width
    )
    
    # Arco inferiore (curva a sinistra, aperta a destra)
    bot_box = [sx, sy + half_h, sx + s_width, sy + s_height]
    mask_draw.arc(bot_box, 0, 180 + 45, fill=255, width=stroke_width)

    # Applica maschera al gradiente
    grad_layer.putalpha(mask)
    img.paste(grad_layer, (0, 0), grad_layer)
    
    return img


def draw_coin_accent(img, offset_x=0, offset_y=0):
    """Aggiunge un piccolo cerchio decorativo (moneta) in alto a destra della S."""
    draw = ImageDraw.Draw(img)
    
    cx = CENTER + 180 + offset_x
    cy = CENTER - 190 + offset_y
    r = 52

    # Cerchio esterno ciano con glow
    for i in range(20, 0, -1):
        alpha = int(30 * (1 - i / 20))
        color = (*SECONDARY, alpha)
        glow = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
        glow_draw = ImageDraw.Draw(glow)
        glow_draw.ellipse([cx - r - i, cy - r - i, cx + r + i, cy + r + i], fill=color)
        img = Image.alpha_composite(img, glow)

    draw = ImageDraw.Draw(img)
    # Cerchio pieno ciano
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(*SECONDARY, 240))
    
    # Simbolo € dentro la moneta
    # Usiamo un font di default piccolo
    try:
        font = ImageFont.truetype("arial.ttf", 52)
    except OSError:
        try:
            font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 52)
        except OSError:
            font = ImageFont.load_default()
    
    draw.text((cx, cy), "€", fill=BG_DARK + (255,), font=font, anchor="mm")
    
    return img


def draw_decorative_elements(img, offset_x=0, offset_y=0):
    """Aggiunge elementi decorativi sottili."""
    # Piccolo cerchietto viola in basso a sinistra
    draw = ImageDraw.Draw(img)
    cx = CENTER - 195 + offset_x
    cy = CENTER + 210 + offset_y
    r = 28
    
    for i in range(15, 0, -1):
        alpha = int(25 * (1 - i / 15))
        color = (*PRIMARY, alpha)
        glow = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
        glow_draw = ImageDraw.Draw(glow)
        glow_draw.ellipse([cx - r - i, cy - r - i, cx + r + i, cy + r + i], fill=color)
        img = Image.alpha_composite(img, glow)
    
    draw = ImageDraw.Draw(img)
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(*PRIMARY, 200))
    
    # Linee sottili decorative
    draw.line(
        [(CENTER - 220 + offset_x, CENTER + 260 + offset_y),
         (CENTER - 140 + offset_x, CENTER + 260 + offset_y)],
        fill=(*PRIMARY, 60), width=3
    )
    
    return img


def generate_icon():
    """Genera icon.png con sfondo pieno."""
    img = Image.new('RGBA', (SIZE, SIZE), (*BG_DARK, 255))
    draw = ImageDraw.Draw(img)
    
    # Sfondo: rettangolo arrotondato leggero (per dare profondità)
    draw_rounded_rect(draw, [40, 40, SIZE - 40, SIZE - 40], 180, (*SURFACE, 80))
    
    # Glow di sfondo viola
    glow = create_gradient_circle(SIZE, (CENTER - 50, CENTER - 80), 350, PRIMARY, (40, 35, 100), alpha=50)
    img = Image.alpha_composite(img, glow)
    
    # Glow ciano sottile
    glow2 = create_gradient_circle(SIZE, (CENTER + 120, CENTER + 150), 250, SECONDARY, (0, 80, 100), alpha=30)
    img = Image.alpha_composite(img, glow2)
    
    # Disegna la S
    img = draw_s_letter(img)
    
    # Moneta decorativa
    img = draw_coin_accent(img)
    
    # Elementi decorativi
    img = draw_decorative_elements(img)
    
    # Salva
    out_path = os.path.join('assets', 'icon', 'icon.png')
    img.convert('RGBA').save(out_path, 'PNG')
    print(f"✓ Generato {out_path} ({SIZE}x{SIZE})")
    return img


def generate_foreground():
    """Genera icon_foreground.png con sfondo trasparente per adaptive icon Android."""
    img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    
    # La S è centrata con un leggero offset verso il basso (safe zone adaptive icon = 66%)
    img = draw_s_letter(img, offset_y=20)
    img = draw_coin_accent(img, offset_y=20)
    img = draw_decorative_elements(img, offset_y=20)
    
    out_path = os.path.join('assets', 'icon', 'icon_foreground.png')
    img.save(out_path, 'PNG')
    print(f"✓ Generato {out_path} ({SIZE}x{SIZE})")


if __name__ == '__main__':
    generate_icon()
    generate_foreground()
    print("\nOra esegui: dart run flutter_launcher_icons")

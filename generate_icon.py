"""Generate Spendly app icon - a modern wallet/money design with purple-cyan gradient."""
from PIL import Image, ImageDraw, ImageFont
import math
import os

def lerp_color(c1, c2, t):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))

def create_icon(size=1024):
    img = Image.new('RGBA', (size, size), (13, 13, 13, 255))
    draw = ImageDraw.Draw(img)
    
    # Colors
    purple = (108, 99, 255)
    cyan = (0, 217, 255)
    bg = (13, 13, 13)
    
    cx, cy = size // 2, size // 2
    
    # Draw a rounded rectangle background with gradient border effect
    margin = int(size * 0.08)
    radius = int(size * 0.22)
    
    # Gradient circle glow behind
    for r in range(int(size * 0.45), int(size * 0.25), -2):
        t = (r - size * 0.25) / (size * 0.2)
        alpha = int(40 * (1 - t))
        color = lerp_color(purple, cyan, t)
        draw.ellipse(
            [cx - r, cy - r, cx + r, cy + r],
            fill=(*color, alpha)
        )
    
    # Main wallet shape - a stylized "S" representing Spendly
    # Draw a large bold "S" with gradient effect
    
    # Create gradient "S" using circles/arcs
    s_width = int(size * 0.42)
    s_height = int(size * 0.52)
    stroke = int(size * 0.09)
    
    s_cx = cx
    s_top = cy - s_height // 2
    s_bot = cy + s_height // 2
    s_mid = cy
    
    # Top arc of S
    arc_radius = s_width // 2
    
    # Draw S shape with gradient strokes
    steps = 100
    for i in range(steps):
        t = i / steps
        color = lerp_color(purple, cyan, t)
        
        if t < 0.5:
            # Top arc (going right then curving left)
            angle = math.pi * (1 - t * 2)  # pi to 0
            x = s_cx + int(arc_radius * 0.9 * math.cos(angle))
            y = s_top + arc_radius + int(arc_radius * 0.85 * math.sin(angle))
        else:
            # Bottom arc (going left then curving right)
            angle = math.pi * ((t - 0.5) * 2)  # 0 to pi
            x = s_cx - int(arc_radius * 0.9 * math.cos(angle))
            y = s_bot - arc_radius - int(arc_radius * 0.85 * math.sin(angle))
        
        draw.ellipse(
            [x - stroke//2, y - stroke//2, x + stroke//2, y + stroke//2],
            fill=(*color, 255)
        )
    
    # Add a small coin/dollar accent
    coin_r = int(size * 0.06)
    coin_cx = cx + int(size * 0.25)
    coin_cy = cy - int(size * 0.28)
    
    # Coin glow
    for r in range(coin_r + 15, coin_r, -1):
        alpha = int(80 * (1 - (r - coin_r) / 15))
        draw.ellipse(
            [coin_cx - r, coin_cy - r, coin_cx + r, coin_cy + r],
            fill=(*cyan, alpha)
        )
    draw.ellipse(
        [coin_cx - coin_r, coin_cy - coin_r, coin_cx + coin_r, coin_cy + coin_r],
        fill=(*cyan, 255)
    )
    
    return img

def create_foreground(size=1024):
    """Create adaptive icon foreground (transparent background, just the S logo)"""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    purple = (108, 99, 255)
    cyan = (0, 217, 255)
    
    cx, cy = size // 2, size // 2
    
    # S shape parameters (slightly smaller for adaptive icon safe zone)
    s_width = int(size * 0.32)
    s_height = int(size * 0.40)
    stroke = int(size * 0.075)
    
    s_cx = cx
    s_top = cy - s_height // 2
    s_bot = cy + s_height // 2
    
    arc_radius = s_width // 2
    
    steps = 120
    for i in range(steps):
        t = i / steps
        color = lerp_color(purple, cyan, t)
        
        if t < 0.5:
            angle = math.pi * (1 - t * 2)
            x = s_cx + int(arc_radius * 0.9 * math.cos(angle))
            y = s_top + arc_radius + int(arc_radius * 0.85 * math.sin(angle))
        else:
            angle = math.pi * ((t - 0.5) * 2)
            x = s_cx - int(arc_radius * 0.9 * math.cos(angle))
            y = s_bot - arc_radius - int(arc_radius * 0.85 * math.sin(angle))
        
        draw.ellipse(
            [x - stroke//2, y - stroke//2, x + stroke//2, y + stroke//2],
            fill=(*color, 255)
        )
    
    # Coin accent
    coin_r = int(size * 0.05)
    coin_cx = cx + int(size * 0.20)
    coin_cy = cy - int(size * 0.22)
    draw.ellipse(
        [coin_cx - coin_r, coin_cy - coin_r, coin_cx + coin_r, coin_cy + coin_r],
        fill=(*cyan, 255)
    )
    
    return img

if __name__ == '__main__':
    os.makedirs('assets/icon', exist_ok=True)
    
    icon = create_icon(1024)
    icon.save('assets/icon/icon.png')
    print('Created assets/icon/icon.png')
    
    fg = create_foreground(1024)
    fg.save('assets/icon/icon_foreground.png')
    print('Created assets/icon/icon_foreground.png')

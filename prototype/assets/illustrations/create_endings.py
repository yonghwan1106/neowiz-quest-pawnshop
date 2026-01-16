"""
Neon Memoria - Ending Illustrations Generator
Creates 3 ending illustrations for "기억의 전당포" (Memory Pawnshop)
"""

from PIL import Image, ImageDraw, ImageFilter, ImageFont
import math
import random
import os

# Set seed for reproducibility
random.seed(42)

# Output directory
OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__))
WIDTH, HEIGHT = 1920, 1080

def create_radial_gradient(width, height, center, colors, radius_factor=1.0):
    """Create a radial gradient image"""
    img = Image.new('RGBA', (width, height), (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)

    cx, cy = center
    max_radius = max(width, height) * radius_factor

    for i in range(int(max_radius), 0, -2):
        ratio = i / max_radius
        # Interpolate between colors
        r = int(colors[0][0] * ratio + colors[1][0] * (1 - ratio))
        g = int(colors[0][1] * ratio + colors[1][1] * (1 - ratio))
        b = int(colors[0][2] * ratio + colors[1][2] * (1 - ratio))

        draw.ellipse([cx - i, cy - i, cx + i, cy + i], fill=(r, g, b, 255))

    return img

def draw_silhouette(draw, base_x, base_y, scale=1.0, color=(0, 0, 0)):
    """Draw a standing figure silhouette"""
    # Head
    head_radius = int(35 * scale)
    head_y = base_y - int(280 * scale)
    draw.ellipse([base_x - head_radius, head_y - head_radius,
                  base_x + head_radius, head_y + head_radius], fill=color)

    # Neck
    neck_width = int(15 * scale)
    neck_top = head_y + head_radius - 5
    neck_bottom = neck_top + int(25 * scale)
    draw.rectangle([base_x - neck_width, neck_top, base_x + neck_width, neck_bottom], fill=color)

    # Torso (coat/jacket shape)
    torso_top = neck_bottom - 5
    torso_bottom = base_y - int(80 * scale)
    shoulder_width = int(70 * scale)
    waist_width = int(50 * scale)

    # Shoulders and torso polygon
    torso_points = [
        (base_x - shoulder_width, torso_top + int(20 * scale)),  # Left shoulder
        (base_x - shoulder_width - int(15 * scale), torso_top + int(40 * scale)),  # Left arm start
        (base_x - waist_width - int(10 * scale), torso_bottom),  # Left waist
        (base_x + waist_width + int(10 * scale), torso_bottom),  # Right waist
        (base_x + shoulder_width + int(15 * scale), torso_top + int(40 * scale)),  # Right arm start
        (base_x + shoulder_width, torso_top + int(20 * scale)),  # Right shoulder
        (base_x + neck_width + 5, torso_top),  # Right neck
        (base_x - neck_width - 5, torso_top),  # Left neck
    ]
    draw.polygon(torso_points, fill=color)

    # Coat tails / Lower body
    coat_bottom = base_y
    draw.polygon([
        (base_x - waist_width - int(10 * scale), torso_bottom),
        (base_x - int(40 * scale), coat_bottom),
        (base_x + int(40 * scale), coat_bottom),
        (base_x + waist_width + int(10 * scale), torso_bottom),
    ], fill=color)

    # Legs (subtle separation)
    leg_width = int(18 * scale)
    draw.rectangle([base_x - int(25 * scale), torso_bottom, base_x - int(8 * scale), base_y], fill=color)
    draw.rectangle([base_x + int(8 * scale), torso_bottom, base_x + int(25 * scale), base_y], fill=color)

def draw_memory_orb(draw, x, y, radius, color, glow_color, alpha=200):
    """Draw a glowing memory orb"""
    # Outer glow
    for i in range(3, 0, -1):
        glow_radius = radius + i * 4
        glow_alpha = int(alpha / (i + 1))
        # Create glow effect
        draw.ellipse([x - glow_radius, y - glow_radius,
                     x + glow_radius, y + glow_radius],
                    fill=(*glow_color, glow_alpha))

    # Core
    draw.ellipse([x - radius, y - radius, x + radius, y + radius],
                fill=(*color, alpha))

    # Highlight
    highlight_offset = radius // 3
    highlight_radius = radius // 4
    draw.ellipse([x - highlight_offset - highlight_radius,
                 y - highlight_offset - highlight_radius,
                 x - highlight_offset + highlight_radius,
                 y - highlight_offset + highlight_radius],
                fill=(255, 255, 255, 150))

def add_light_rays(img, center, color, num_rays=12, length=400):
    """Add subtle light rays from a center point"""
    overlay = Image.new('RGBA', img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    cx, cy = center
    for i in range(num_rays):
        angle = (2 * math.pi * i / num_rays) + random.uniform(-0.1, 0.1)
        end_x = cx + int(length * math.cos(angle))
        end_y = cy + int(length * math.sin(angle))

        # Draw tapered line
        for j in range(10):
            ratio = j / 10
            alpha = int(30 * (1 - ratio))
            width = int(20 * (1 - ratio)) + 1
            mid_x = int(cx + (end_x - cx) * ratio)
            mid_y = int(cy + (end_y - cy) * ratio)
            draw.ellipse([mid_x - width, mid_y - width, mid_x + width, mid_y + width],
                        fill=(*color, alpha))

    return Image.alpha_composite(img, overlay)

def create_ending_mercy():
    """Create the Mercy Ending illustration - warm, hopeful"""
    print("Creating ending_mercy.png...")

    # Base - deep dark blue transitioning to warm
    img = Image.new('RGBA', (WIDTH, HEIGHT), (10, 8, 20, 255))
    draw = ImageDraw.Draw(img)

    # Warm light source from behind figure (sunrise effect)
    center = (WIDTH // 2, HEIGHT // 2 + 100)

    # Background gradient - warm golden light
    for radius in range(800, 0, -5):
        ratio = radius / 800
        # Warm colors: gold -> soft orange -> white center
        r = int(255 - (255 - 255) * ratio)
        g = int(220 - (220 - 180) * ratio)
        b = int(150 - (150 - 80) * ratio)
        alpha = int(180 * (1 - ratio * 0.7))

        draw.ellipse([center[0] - radius, center[1] - radius - 200,
                     center[0] + radius, center[1] + radius - 200],
                    fill=(r, g, b, min(255, alpha)))

    # Add light rays
    img = add_light_rays(img, (WIDTH // 2, HEIGHT // 2 - 100), (255, 230, 180), num_rays=16, length=600)
    draw = ImageDraw.Draw(img)

    # Draw floating memory orbs (warm, gentle)
    orb_positions = [
        (300, 200, 12), (450, 350, 8), (250, 500, 10),
        (1620, 180, 11), (1500, 400, 9), (1700, 550, 7),
        (600, 150, 6), (1300, 200, 8), (400, 650, 9),
        (1550, 650, 10), (800, 100, 7), (1100, 120, 6),
        (200, 350, 5), (1750, 350, 6), (550, 500, 7),
        (1400, 500, 5), (700, 280, 8), (1200, 350, 7),
    ]

    for x, y, r in orb_positions:
        # Warm colors: gold, amber, soft white
        color_choice = random.choice([
            ((255, 220, 150), (255, 200, 100)),
            ((255, 240, 200), (255, 220, 150)),
            ((255, 200, 120), (255, 180, 80)),
        ])
        draw_memory_orb(draw, x, y, r, color_choice[0], color_choice[1], alpha=random.randint(150, 220))

    # Draw the silhouette (figure standing in light)
    silhouette_x = WIDTH // 2
    silhouette_y = HEIGHT - 150
    draw_silhouette(draw, silhouette_x, silhouette_y, scale=1.3, color=(5, 5, 15))

    # Add subtle floor reflection
    for i in range(50):
        y = HEIGHT - 100 + i
        alpha = int(30 * (1 - i / 50))
        draw.line([(silhouette_x - 80, y), (silhouette_x + 80, y)],
                 fill=(255, 220, 150, alpha), width=2)

    # Add subtle vignette
    vignette = Image.new('RGBA', (WIDTH, HEIGHT), (0, 0, 0, 0))
    vignette_draw = ImageDraw.Draw(vignette)
    for i in range(200):
        alpha = int(i * 0.4)
        # Top and bottom vignette
        vignette_draw.rectangle([0, i, WIDTH, i + 1], fill=(10, 8, 20, alpha))
        vignette_draw.rectangle([0, HEIGHT - i - 1, WIDTH, HEIGHT - i], fill=(10, 8, 20, alpha))
        # Side vignette
        vignette_draw.rectangle([i, 0, i + 1, HEIGHT], fill=(10, 8, 20, int(alpha * 0.5)))
        vignette_draw.rectangle([WIDTH - i - 1, 0, WIDTH - i, HEIGHT], fill=(10, 8, 20, int(alpha * 0.5)))

    img = Image.alpha_composite(img, vignette)

    # Add title text
    draw = ImageDraw.Draw(img)
    try:
        font_path = "C:/Users/user/.claude/skills/canvas-design/canvas-fonts/Jura-Light.ttf"
        title_font = ImageFont.truetype(font_path, 28)
        subtitle_font = ImageFont.truetype(font_path, 18)
    except:
        title_font = ImageFont.load_default()
        subtitle_font = ImageFont.load_default()

    # Korean title at bottom
    draw.text((WIDTH // 2, HEIGHT - 50), "자 비", font=title_font, fill=(255, 230, 180, 200), anchor="mm")
    draw.text((WIDTH // 2, HEIGHT - 25), "MERCY", font=subtitle_font, fill=(255, 230, 180, 150), anchor="mm")

    # Save
    img = img.convert('RGB')
    img.save(os.path.join(OUTPUT_DIR, 'ending_mercy.png'), 'PNG', quality=95)
    print("  -> ending_mercy.png saved!")

def create_ending_justice():
    """Create the Justice Ending illustration - cold, resolute"""
    print("Creating ending_justice.png...")

    # Base - cold deep blue/black
    img = Image.new('RGBA', (WIDTH, HEIGHT), (5, 10, 25, 255))
    draw = ImageDraw.Draw(img)

    # Cold light source - cyan/blue
    center = (WIDTH // 2, HEIGHT // 2)

    # Background gradient - cold cyan light
    for radius in range(700, 0, -5):
        ratio = radius / 700
        r = int(30 * (1 - ratio))
        g = int(180 * (1 - ratio))
        b = int(220 * (1 - ratio))
        alpha = int(150 * (1 - ratio * 0.6))

        draw.ellipse([center[0] - radius, center[1] - radius - 100,
                     center[0] + radius, center[1] + radius - 100],
                    fill=(r, g, b, min(255, alpha)))

    # Draw scales of justice symbol (cracked)
    scale_center_x = WIDTH // 2
    scale_center_y = HEIGHT // 3

    # Main beam
    beam_width = 300
    beam_color = (0, 200, 255, 180)
    draw.line([(scale_center_x - beam_width, scale_center_y),
               (scale_center_x + beam_width, scale_center_y)],
              fill=beam_color, width=4)

    # Center pillar
    draw.line([(scale_center_x, scale_center_y),
               (scale_center_x, scale_center_y + 80)],
              fill=beam_color, width=4)

    # Left pan
    draw.line([(scale_center_x - beam_width, scale_center_y),
               (scale_center_x - beam_width, scale_center_y + 100)],
              fill=beam_color, width=2)
    draw.arc([scale_center_x - beam_width - 60, scale_center_y + 80,
              scale_center_x - beam_width + 60, scale_center_y + 140],
             0, 180, fill=beam_color, width=3)

    # Right pan
    draw.line([(scale_center_x + beam_width, scale_center_y),
               (scale_center_x + beam_width, scale_center_y + 100)],
              fill=beam_color, width=2)
    draw.arc([scale_center_x + beam_width - 60, scale_center_y + 80,
              scale_center_x + beam_width + 60, scale_center_y + 140],
             0, 180, fill=beam_color, width=3)

    # Crack in the scales
    crack_points = [
        (scale_center_x - 20, scale_center_y - 10),
        (scale_center_x - 5, scale_center_y + 5),
        (scale_center_x + 15, scale_center_y - 5),
        (scale_center_x + 5, scale_center_y + 15),
        (scale_center_x + 25, scale_center_y + 10),
    ]
    for i in range(len(crack_points) - 1):
        draw.line([crack_points[i], crack_points[i + 1]], fill=(0, 255, 255, 200), width=2)

    # Add glow to scales
    for _ in range(3):
        img = img.filter(ImageFilter.GaussianBlur(1))
        draw = ImageDraw.Draw(img)

    # Redraw on blurred image for glow effect
    img2 = Image.new('RGBA', (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw2 = ImageDraw.Draw(img2)

    # Angular shadow patterns (harsh, geometric)
    for i in range(0, WIDTH, 80):
        alpha = random.randint(10, 30)
        draw2.polygon([
            (i, 0),
            (i + 40, 0),
            (i + 200, HEIGHT),
            (i + 160, HEIGHT),
        ], fill=(0, 50, 80, alpha))

    img = Image.alpha_composite(img, img2)
    draw = ImageDraw.Draw(img)

    # Draw floating memory orbs (cold, precise)
    orb_positions = [
        (280, 250, 10), (400, 400, 7), (200, 600, 9),
        (1640, 220, 9), (1520, 450, 8), (1720, 600, 6),
        (550, 200, 5), (1350, 180, 7), (350, 700, 8),
        (1600, 700, 7), (750, 150, 6), (1150, 130, 5),
    ]

    for x, y, r in orb_positions:
        color_choice = random.choice([
            ((0, 200, 255), (0, 150, 200)),
            ((100, 220, 255), (50, 180, 220)),
            ((150, 230, 255), (100, 200, 240)),
        ])
        draw_memory_orb(draw, x, y, r, color_choice[0], color_choice[1], alpha=random.randint(120, 180))

    # Draw the silhouette (standing firm)
    silhouette_x = WIDTH // 2
    silhouette_y = HEIGHT - 120
    draw_silhouette(draw, silhouette_x, silhouette_y, scale=1.35, color=(0, 5, 15))

    # Cold floor reflection
    for i in range(40):
        y = HEIGHT - 80 + i
        alpha = int(40 * (1 - i / 40))
        draw.line([(silhouette_x - 90, y), (silhouette_x + 90, y)],
                 fill=(0, 180, 220, alpha), width=2)

    # Strong vignette
    vignette = Image.new('RGBA', (WIDTH, HEIGHT), (0, 0, 0, 0))
    vignette_draw = ImageDraw.Draw(vignette)
    for i in range(250):
        alpha = int(i * 0.5)
        vignette_draw.rectangle([0, i, WIDTH, i + 1], fill=(5, 10, 25, alpha))
        vignette_draw.rectangle([0, HEIGHT - i - 1, WIDTH, HEIGHT - i], fill=(5, 10, 25, alpha))
        vignette_draw.rectangle([i, 0, i + 1, HEIGHT], fill=(5, 10, 25, int(alpha * 0.6)))
        vignette_draw.rectangle([WIDTH - i - 1, 0, WIDTH - i, HEIGHT], fill=(5, 10, 25, int(alpha * 0.6)))

    img = Image.alpha_composite(img, vignette)

    # Add title
    draw = ImageDraw.Draw(img)
    try:
        font_path = "C:/Users/user/.claude/skills/canvas-design/canvas-fonts/Jura-Light.ttf"
        title_font = ImageFont.truetype(font_path, 28)
        subtitle_font = ImageFont.truetype(font_path, 18)
    except:
        title_font = ImageFont.load_default()
        subtitle_font = ImageFont.load_default()

    draw.text((WIDTH // 2, HEIGHT - 50), "정 의", font=title_font, fill=(0, 220, 255, 200), anchor="mm")
    draw.text((WIDTH // 2, HEIGHT - 25), "JUSTICE", font=subtitle_font, fill=(0, 220, 255, 150), anchor="mm")

    img = img.convert('RGB')
    img.save(os.path.join(OUTPUT_DIR, 'ending_justice.png'), 'PNG', quality=95)
    print("  -> ending_justice.png saved!")

def create_ending_profit():
    """Create the Profit Ending illustration - golden but lonely"""
    print("Creating ending_profit.png...")

    # Base - very dark, almost black
    img = Image.new('RGBA', (WIDTH, HEIGHT), (8, 5, 10, 255))
    draw = ImageDraw.Draw(img)

    # Minimal golden light - isolated pools
    center = (WIDTH // 2, HEIGHT - 200)

    # Dim golden glow around figure only
    for radius in range(400, 0, -5):
        ratio = radius / 400
        r = int(180 * (1 - ratio * 0.5))
        g = int(140 * (1 - ratio * 0.6))
        b = int(40 * (1 - ratio * 0.8))
        alpha = int(80 * (1 - ratio * 0.7))

        draw.ellipse([center[0] - radius, center[1] - radius,
                     center[0] + radius, center[1] + radius],
                    fill=(r, g, b, min(255, alpha)))

    # Draw coins scattered around
    coin_positions = [
        (400, 750, 25), (500, 800, 20), (350, 850, 18),
        (1520, 780, 22), (1400, 830, 19), (1600, 870, 16),
        (600, 820, 15), (1300, 790, 17), (450, 900, 14),
        (1550, 900, 13), (700, 870, 12), (1200, 850, 15),
        (300, 800, 12), (1700, 820, 14), (550, 880, 11),
        # More coins near the figure
        (850, 850, 20), (1070, 860, 18), (920, 890, 16),
        (1000, 880, 15), (880, 920, 14), (1050, 910, 13),
    ]

    for x, y, r in coin_positions:
        # Golden coin
        gold_color = (200, 160, 50)
        highlight = (255, 220, 100)
        shadow = (120, 90, 20)

        # Coin shadow
        draw.ellipse([x - r - 3, y - r//3 + 3, x + r + 3, y + r//3 + 6],
                    fill=(20, 15, 5, 100))

        # Coin body (ellipse for perspective)
        draw.ellipse([x - r, y - r//3, x + r, y + r//3],
                    fill=(*gold_color, 220))

        # Coin highlight
        draw.ellipse([x - r//2, y - r//4, x, y],
                    fill=(*highlight, 150))

        # Coin edge detail
        draw.arc([x - r, y - r//3, x + r, y + r//3], 0, 180,
                fill=(*shadow, 200), width=2)

    # Floating memory orbs (golden but dim, fewer)
    orb_positions = [
        (350, 300, 8), (1600, 350, 7), (280, 550, 6),
        (1680, 500, 5), (500, 450, 5), (1450, 420, 6),
        (420, 600, 4), (1550, 580, 5),
    ]

    for x, y, r in orb_positions:
        color_choice = random.choice([
            ((200, 160, 60), (150, 120, 30)),
            ((180, 140, 40), (130, 100, 20)),
        ])
        draw_memory_orb(draw, x, y, r, color_choice[0], color_choice[1], alpha=random.randint(80, 130))

    # Draw the silhouette (alone, surrounded by wealth)
    silhouette_x = WIDTH // 2
    silhouette_y = HEIGHT - 100
    draw_silhouette(draw, silhouette_x, silhouette_y, scale=1.25, color=(3, 2, 5))

    # Minimal golden reflection
    for i in range(30):
        y = HEIGHT - 60 + i
        alpha = int(25 * (1 - i / 30))
        draw.line([(silhouette_x - 70, y), (silhouette_x + 70, y)],
                 fill=(180, 140, 50, alpha), width=2)

    # Heavy vignette (emphasize isolation)
    vignette = Image.new('RGBA', (WIDTH, HEIGHT), (0, 0, 0, 0))
    vignette_draw = ImageDraw.Draw(vignette)
    for i in range(350):
        alpha = int(i * 0.6)
        vignette_draw.rectangle([0, i, WIDTH, i + 1], fill=(8, 5, 10, min(255, alpha)))
        vignette_draw.rectangle([0, HEIGHT - i - 1, WIDTH, HEIGHT - i], fill=(8, 5, 10, min(255, alpha)))
        vignette_draw.rectangle([i, 0, i + 1, HEIGHT], fill=(8, 5, 10, min(255, int(alpha * 0.8))))
        vignette_draw.rectangle([WIDTH - i - 1, 0, WIDTH - i, HEIGHT], fill=(8, 5, 10, min(255, int(alpha * 0.8))))

    img = Image.alpha_composite(img, vignette)

    # Add title
    draw = ImageDraw.Draw(img)
    try:
        font_path = "C:/Users/user/.claude/skills/canvas-design/canvas-fonts/Jura-Light.ttf"
        title_font = ImageFont.truetype(font_path, 28)
        subtitle_font = ImageFont.truetype(font_path, 18)
    except:
        title_font = ImageFont.load_default()
        subtitle_font = ImageFont.load_default()

    draw.text((WIDTH // 2, HEIGHT - 50), "이 익", font=title_font, fill=(200, 160, 60, 180), anchor="mm")
    draw.text((WIDTH // 2, HEIGHT - 25), "PROFIT", font=subtitle_font, fill=(200, 160, 60, 130), anchor="mm")

    img = img.convert('RGB')
    img.save(os.path.join(OUTPUT_DIR, 'ending_profit.png'), 'PNG', quality=95)
    print("  -> ending_profit.png saved!")

if __name__ == "__main__":
    print("=" * 50)
    print("Neon Memoria - Ending Illustrations Generator")
    print("기억의 전당포 (Memory Pawnshop)")
    print("=" * 50)
    print()

    create_ending_mercy()
    create_ending_justice()
    create_ending_profit()

    print()
    print("=" * 50)
    print("All illustrations created successfully!")
    print(f"Output directory: {OUTPUT_DIR}")
    print("=" * 50)

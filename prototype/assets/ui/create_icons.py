"""
Neon Memoria - UI Icons Generator
Creates 4 UI icons for "기억의 전당포" (Memory Pawnshop)
Minimalist neon line art style
"""

from PIL import Image, ImageDraw, ImageFilter
import math
import os

OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__))
SIZE = 64

def create_glow_effect(img, glow_color, intensity=2):
    """Add glow effect to an image"""
    # Create a blurred version for glow
    glow = img.copy()
    for _ in range(intensity):
        glow = glow.filter(ImageFilter.GaussianBlur(2))

    # Composite the glow under the original
    result = Image.new('RGBA', img.size, (0, 0, 0, 0))
    result = Image.alpha_composite(result, glow)
    result = Image.alpha_composite(result, img)
    return result

def create_icon_mercy():
    """Create Mercy icon - heart with soft glow (amber/gold)"""
    print("Creating icon_mercy.png...")

    img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    cx, cy = SIZE // 2, SIZE // 2 + 2
    color = (255, 200, 100)  # Warm amber

    # Draw heart shape using bezier-like approach
    # Heart is made of two arcs and a point at bottom
    heart_size = 22

    # Left arc
    draw.arc([cx - heart_size, cy - heart_size//2 - 5,
              cx, cy + heart_size//3],
             90, 220, fill=(*color, 255), width=2)

    # Right arc
    draw.arc([cx, cy - heart_size//2 - 5,
              cx + heart_size, cy + heart_size//3],
             -40, 90, fill=(*color, 255), width=2)

    # Bottom point lines
    draw.line([(cx - heart_size//2 + 2, cy + heart_size//4 - 2),
               (cx, cy + heart_size//2 + 5)], fill=(*color, 255), width=2)
    draw.line([(cx + heart_size//2 - 2, cy + heart_size//4 - 2),
               (cx, cy + heart_size//2 + 5)], fill=(*color, 255), width=2)

    # Inner glow dot
    draw.ellipse([cx - 3, cy - 3, cx + 3, cy + 3], fill=(*color, 150))

    # Add glow
    img = create_glow_effect(img, color, intensity=3)

    img.save(os.path.join(OUTPUT_DIR, 'icon_mercy.png'), 'PNG')
    print("  -> icon_mercy.png saved!")

def create_icon_justice():
    """Create Justice icon - scales with cold glow (cyan)"""
    print("Creating icon_justice.png...")

    img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    cx, cy = SIZE // 2, SIZE // 2
    color = (0, 220, 255)  # Cold cyan

    # Main balance beam
    beam_width = 22
    draw.line([(cx - beam_width, cy - 5), (cx + beam_width, cy - 5)],
              fill=(*color, 255), width=2)

    # Center pillar
    draw.line([(cx, cy - 5), (cx, cy + 12)], fill=(*color, 255), width=2)

    # Base
    draw.line([(cx - 8, cy + 12), (cx + 8, cy + 12)], fill=(*color, 255), width=2)

    # Left pan chain
    draw.line([(cx - beam_width, cy - 5), (cx - beam_width, cy + 8)],
              fill=(*color, 200), width=1)
    # Left pan (arc)
    draw.arc([cx - beam_width - 8, cy + 5, cx - beam_width + 8, cy + 15],
             0, 180, fill=(*color, 255), width=2)

    # Right pan chain
    draw.line([(cx + beam_width, cy - 5), (cx + beam_width, cy + 8)],
              fill=(*color, 200), width=1)
    # Right pan (arc)
    draw.arc([cx + beam_width - 8, cy + 5, cx + beam_width + 8, cy + 15],
             0, 180, fill=(*color, 255), width=2)

    # Center decoration
    draw.ellipse([cx - 2, cy - 7, cx + 2, cy - 3], fill=(*color, 200))

    # Add glow
    img = create_glow_effect(img, color, intensity=3)

    img.save(os.path.join(OUTPUT_DIR, 'icon_justice.png'), 'PNG')
    print("  -> icon_justice.png saved!")

def create_icon_profit():
    """Create Profit icon - coin/money with golden glow"""
    print("Creating icon_profit.png...")

    img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    cx, cy = SIZE // 2, SIZE // 2
    color = (255, 180, 50)  # Gold

    # Main coin circle
    radius = 20
    draw.ellipse([cx - radius, cy - radius, cx + radius, cy + radius],
                 outline=(*color, 255), width=2)

    # Inner circle
    inner_radius = 14
    draw.ellipse([cx - inner_radius, cy - inner_radius,
                  cx + inner_radius, cy + inner_radius],
                 outline=(*color, 180), width=1)

    # Currency symbol (stylized)
    # Vertical line
    draw.line([(cx, cy - 10), (cx, cy + 10)], fill=(*color, 255), width=2)

    # Horizontal lines
    draw.line([(cx - 6, cy - 4), (cx + 6, cy - 4)], fill=(*color, 255), width=2)
    draw.line([(cx - 6, cy + 4), (cx + 6, cy + 4)], fill=(*color, 255), width=2)

    # Small decorative dots at corners (suggesting coins stacked)
    draw.ellipse([cx + 15, cy - 20, cx + 21, cy - 14], outline=(*color, 100), width=1)
    draw.ellipse([cx - 21, cy + 14, cx - 15, cy + 20], outline=(*color, 100), width=1)

    # Add glow
    img = create_glow_effect(img, color, intensity=3)

    img.save(os.path.join(OUTPUT_DIR, 'icon_profit.png'), 'PNG')
    print("  -> icon_profit.png saved!")

def create_icon_memory():
    """Create Memory orb icon - glowing orb with particles (magenta/purple)"""
    print("Creating icon_memory.png...")

    img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    cx, cy = SIZE // 2, SIZE // 2
    color = (200, 100, 255)  # Purple/magenta

    # Outer glow circles
    for i in range(3, 0, -1):
        alpha = 50 + i * 20
        r = 18 + i * 4
        draw.ellipse([cx - r, cy - r, cx + r, cy + r],
                     outline=(*color, alpha), width=1)

    # Main orb outline
    radius = 16
    draw.ellipse([cx - radius, cy - radius, cx + radius, cy + radius],
                 outline=(*color, 255), width=2)

    # Inner glow
    inner_radius = 8
    draw.ellipse([cx - inner_radius, cy - inner_radius,
                  cx + inner_radius, cy + inner_radius],
                 fill=(*color, 100))

    # Highlight
    draw.ellipse([cx - 5, cy - 8, cx - 1, cy - 4], fill=(255, 255, 255, 180))

    # Small floating particles around
    particles = [
        (cx - 22, cy - 10, 2),
        (cx + 20, cy - 8, 2),
        (cx - 18, cy + 15, 2),
        (cx + 22, cy + 12, 2),
        (cx + 5, cy - 24, 2),
        (cx - 8, cy + 22, 2),
    ]

    for px, py, pr in particles:
        draw.ellipse([px - pr, py - pr, px + pr, py + pr],
                     fill=(*color, 150))

    # Add glow
    img = create_glow_effect(img, color, intensity=3)

    img.save(os.path.join(OUTPUT_DIR, 'icon_memory.png'), 'PNG')
    print("  -> icon_memory.png saved!")

if __name__ == "__main__":
    print("=" * 40)
    print("Neon Memoria - UI Icons Generator")
    print("64x64 Minimalist Neon Line Art")
    print("=" * 40)
    print()

    create_icon_mercy()
    create_icon_justice()
    create_icon_profit()
    create_icon_memory()

    print()
    print("=" * 40)
    print("All icons created successfully!")
    print(f"Output directory: {OUTPUT_DIR}")
    print("=" * 40)

"""
Neo-Noir Character Portrait Generator
Spectral Emergence Design Philosophy
For 기억의 전당포 (Memory Pawnshop)
"""

from PIL import Image, ImageDraw, ImageFilter, ImageFont
import math
import random
import os

# Set seed for reproducibility
random.seed(42)

def hex_to_rgb(hex_color):
    """Convert hex color to RGB tuple"""
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

def create_radial_gradient(size, center, color, intensity=1.0):
    """Create a radial gradient for glow effects"""
    img = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    cx, cy = center
    max_radius = int(math.sqrt(size[0]**2 + size[1]**2) / 2)

    for r in range(max_radius, 0, -2):
        alpha = int(255 * (1 - r/max_radius) * intensity * 0.3)
        alpha = max(0, min(255, alpha))
        c = (*color, alpha)
        draw.ellipse([cx-r, cy-r, cx+r, cy+r], fill=c)

    return img

def draw_silhouette(draw, size, character_type, accent_color):
    """Draw a stylized silhouette based on character type"""
    w, h = size
    cx, cy = w // 2, h // 2

    # Base silhouette parameters based on character
    if character_type == "soldier":
        # Military bearing, straight posture
        head_y = int(h * 0.22)
        shoulder_width = int(w * 0.38)
        head_size = int(w * 0.18)
        neck_width = int(w * 0.08)
    elif character_type == "idol":
        # Youthful, slender
        head_y = int(h * 0.20)
        shoulder_width = int(w * 0.30)
        head_size = int(w * 0.16)
        neck_width = int(w * 0.06)
    elif character_type == "professor":
        # Intellectual, slightly hunched
        head_y = int(h * 0.24)
        shoulder_width = int(w * 0.35)
        head_size = int(w * 0.17)
        neck_width = int(w * 0.07)
    elif character_type == "gang":
        # Menacing, broad
        head_y = int(h * 0.23)
        shoulder_width = int(w * 0.42)
        head_size = int(w * 0.19)
        neck_width = int(w * 0.09)
    elif character_type == "mother":
        # Gentle, caring posture
        head_y = int(h * 0.21)
        shoulder_width = int(w * 0.32)
        head_size = int(w * 0.16)
        neck_width = int(w * 0.06)
    else:  # sister
        # Hopeful, youthful
        head_y = int(h * 0.20)
        shoulder_width = int(w * 0.28)
        head_size = int(w * 0.15)
        neck_width = int(w * 0.055)

    # Draw body silhouette (dark with slight color tint)
    body_color = (15, 15, 20)

    # Shoulders and torso
    points = [
        (cx - shoulder_width, int(h * 0.45)),
        (cx - shoulder_width + 20, int(h * 0.35)),
        (cx - neck_width, head_y + head_size),
        (cx + neck_width, head_y + head_size),
        (cx + shoulder_width - 20, int(h * 0.35)),
        (cx + shoulder_width, int(h * 0.45)),
        (cx + shoulder_width + 30, h + 50),
        (cx - shoulder_width - 30, h + 50),
    ]
    draw.polygon(points, fill=body_color)

    # Head
    draw.ellipse([
        cx - head_size, head_y - head_size,
        cx + head_size, head_y + head_size
    ], fill=body_color)

    return head_y, head_size, shoulder_width

def add_facial_features(draw, cx, head_y, head_size, accent_color, character_type):
    """Add minimal, stylized facial features"""
    # Very subtle eye highlight
    eye_y = head_y - int(head_size * 0.1)
    eye_spacing = int(head_size * 0.35)

    # Different eye expressions per character
    if character_type == "soldier":
        # Haunted, thousand-yard stare
        for ex in [-eye_spacing, eye_spacing]:
            draw.ellipse([
                cx + ex - 4, eye_y - 2,
                cx + ex + 4, eye_y + 2
            ], fill=(*accent_color, 80))
    elif character_type == "idol":
        # Wide, hopeful but sad
        for ex in [-eye_spacing, eye_spacing]:
            draw.ellipse([
                cx + ex - 5, eye_y - 3,
                cx + ex + 5, eye_y + 3
            ], fill=(*accent_color, 90))
    elif character_type == "professor":
        # Wise but fading
        for ex in [-eye_spacing, eye_spacing]:
            draw.ellipse([
                cx + ex - 3, eye_y - 2,
                cx + ex + 3, eye_y + 2
            ], fill=(*accent_color, 60))
    elif character_type == "gang":
        # Piercing, cold
        for ex in [-eye_spacing, eye_spacing]:
            draw.line([
                (cx + ex - 6, eye_y),
                (cx + ex + 6, eye_y)
            ], fill=(*accent_color, 120), width=2)
    elif character_type == "mother":
        # Warm, worried
        for ex in [-eye_spacing, eye_spacing]:
            draw.ellipse([
                cx + ex - 4, eye_y - 3,
                cx + ex + 4, eye_y + 3
            ], fill=(*accent_color, 85))
    else:  # sister
        # Hopeful, bright
        for ex in [-eye_spacing, eye_spacing]:
            draw.ellipse([
                cx + ex - 5, eye_y - 4,
                cx + ex + 5, eye_y + 4
            ], fill=(*accent_color, 100))

def add_memory_particles(img, accent_color, density=30):
    """Add floating memory particles"""
    draw = ImageDraw.Draw(img)
    w, h = img.size

    for _ in range(density):
        x = random.randint(0, w)
        y = random.randint(0, h)
        size = random.randint(1, 4)
        alpha = random.randint(30, 120)

        draw.ellipse([
            x - size, y - size,
            x + size, y + size
        ], fill=(*accent_color, alpha))

    return img

def add_edge_glow(img, accent_color, side='right'):
    """Add neon edge glow effect"""
    w, h = img.size
    glow = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(glow)

    if side == 'right':
        for i in range(50):
            alpha = int(80 * (1 - i/50))
            x = w - i
            draw.line([(x, 0), (x, h)], fill=(*accent_color, alpha))
    elif side == 'left':
        for i in range(50):
            alpha = int(80 * (1 - i/50))
            x = i
            draw.line([(x, 0), (x, h)], fill=(*accent_color, alpha))
    elif side == 'both':
        for i in range(40):
            alpha = int(60 * (1 - i/40))
            draw.line([(i, 0), (i, h)], fill=(*accent_color, alpha))
            draw.line([(w-i, 0), (w-i, h)], fill=(*accent_color, alpha))

    glow = glow.filter(ImageFilter.GaussianBlur(10))
    img = Image.alpha_composite(img, glow)
    return img

def create_portrait(character_name, character_type, accent_hex, output_path):
    """Create a single character portrait"""
    size = (512, 512)
    accent_color = hex_to_rgb(accent_hex)

    # Create base image with dark gradient background
    img = Image.new('RGBA', size, (8, 8, 12, 255))
    draw = ImageDraw.Draw(img)

    # Add subtle background gradient
    for y in range(size[1]):
        darkness = int(8 + (y / size[1]) * 10)
        draw.line([(0, y), (size[0], y)], fill=(darkness, darkness, darkness + 4, 255))

    # Add ambient glow from accent color
    glow = create_radial_gradient(size, (size[0]//2, size[1]//3), accent_color, 0.6)
    glow = glow.filter(ImageFilter.GaussianBlur(80))
    img = Image.alpha_composite(img, glow)

    # Redraw after composite
    draw = ImageDraw.Draw(img)

    # Draw silhouette
    head_y, head_size, shoulder_width = draw_silhouette(draw, size, character_type, accent_color)

    # Add facial features
    add_facial_features(draw, size[0]//2, head_y, head_size, accent_color, character_type)

    # Add memory particles
    img = add_memory_particles(img, accent_color, density=40)

    # Add edge glow
    img = add_edge_glow(img, accent_color, 'both')

    # Add subtle vignette
    vignette = Image.new('RGBA', size, (0, 0, 0, 0))
    vdraw = ImageDraw.Draw(vignette)
    for i in range(100):
        alpha = int(150 * (i / 100))
        vdraw.ellipse([
            -size[0]//2 + i*3, -size[1]//2 + i*3,
            size[0]*1.5 - i*3, size[1]*1.5 - i*3
        ], outline=(0, 0, 0, alpha))
    vignette = vignette.filter(ImageFilter.GaussianBlur(30))

    # Invert vignette (darker at edges)
    img_array = list(img.getdata())
    vig_array = list(vignette.getdata())
    result = []
    for i in range(len(img_array)):
        r, g, b, a = img_array[i]
        vr, vg, vb, va = vig_array[i]
        factor = 1 - (va / 255) * 0.5
        result.append((int(r * factor), int(g * factor), int(b * factor), a))
    img.putdata(result)

    # Add subtle noise texture
    for _ in range(2000):
        x = random.randint(0, size[0]-1)
        y = random.randint(0, size[1]-1)
        pixel = img.getpixel((x, y))
        noise = random.randint(-10, 10)
        new_pixel = (
            max(0, min(255, pixel[0] + noise)),
            max(0, min(255, pixel[1] + noise)),
            max(0, min(255, pixel[2] + noise)),
            pixel[3]
        )
        img.putpixel((x, y), new_pixel)

    # Convert to RGB for saving as PNG
    final = Image.new('RGB', size, (8, 8, 12))
    final.paste(img, mask=img.split()[3] if img.mode == 'RGBA' else None)

    # Add character name subtly at bottom
    draw_final = ImageDraw.Draw(final)

    # Try to use a nice font, fallback to default
    try:
        font = ImageFont.truetype("arial.ttf", 14)
    except:
        font = ImageFont.load_default()

    # Draw name with glow effect
    name_y = size[1] - 35
    text_color = (*accent_color,)

    # Glow behind text
    for offset in range(3, 0, -1):
        glow_alpha = 100 - offset * 30
        glow_color = (accent_color[0], accent_color[1], accent_color[2])
        draw_final.text((size[0]//2 - offset, name_y), character_name,
                       font=font, fill=glow_color, anchor="mm")
        draw_final.text((size[0]//2 + offset, name_y), character_name,
                       font=font, fill=glow_color, anchor="mm")

    draw_final.text((size[0]//2, name_y), character_name,
                   font=font, fill=text_color, anchor="mm")

    # Save
    final.save(output_path, 'PNG')
    print(f"Created: {output_path}")

def main():
    output_dir = r"C:\Users\user\projects\2026_active\neowiz_quest\prototype\assets\portraits"

    # Ensure directory exists
    os.makedirs(output_dir, exist_ok=True)

    # Character definitions
    characters = [
        ("김 상병", "soldier", "#6B7280", "portrait_soldier_kim.png"),
        ("하늘", "idol", "#F472B6", "portrait_haneul.png"),
        ("이 교수", "professor", "#3B82F6", "portrait_professor_lee.png"),
        ("강 회장", "gang", "#8B5CF6", "portrait_gang.png"),
        ("민지 어머니", "mother", "#F5B700", "portrait_minji_mother.png"),
        ("김수연", "sister", "#00D4FF", "portrait_suyeon.png"),
    ]

    for name, char_type, color, filename in characters:
        output_path = os.path.join(output_dir, filename)
        create_portrait(name, char_type, color, output_path)

    print("\nAll portraits generated successfully!")

if __name__ == "__main__":
    main()

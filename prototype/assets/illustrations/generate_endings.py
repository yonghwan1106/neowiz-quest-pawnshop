"""
Neo-Noir Ending Illustration Generator
Spectral Emergence Design Philosophy
For 기억의 전당포 (Memory Pawnshop)
"""

from PIL import Image, ImageDraw, ImageFilter, ImageFont
import math
import random
import os

random.seed(42)

def hex_to_rgb(hex_color):
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

def create_gradient_background(size, colors, direction='vertical'):
    """Create smooth gradient background"""
    img = Image.new('RGB', size, colors[0])
    draw = ImageDraw.Draw(img)

    if direction == 'vertical':
        for y in range(size[1]):
            ratio = y / size[1]
            r = int(colors[0][0] * (1-ratio) + colors[1][0] * ratio)
            g = int(colors[0][1] * (1-ratio) + colors[1][1] * ratio)
            b = int(colors[0][2] * (1-ratio) + colors[1][2] * ratio)
            draw.line([(0, y), (size[0], y)], fill=(r, g, b))
    else:
        for x in range(size[0]):
            ratio = x / size[0]
            r = int(colors[0][0] * (1-ratio) + colors[1][0] * ratio)
            g = int(colors[0][1] * (1-ratio) + colors[1][1] * ratio)
            b = int(colors[0][2] * (1-ratio) + colors[1][2] * ratio)
            draw.line([(x, 0), (x, size[1])], fill=(r, g, b))

    return img

def draw_silhouette_figure(draw, cx, cy, scale, color):
    """Draw a single standing figure silhouette"""
    # Head
    head_r = int(20 * scale)
    draw.ellipse([cx - head_r, cy - 100*scale - head_r,
                  cx + head_r, cy - 100*scale + head_r], fill=color)

    # Body
    body_points = [
        (cx - 25*scale, cy - 80*scale),
        (cx + 25*scale, cy - 80*scale),
        (cx + 35*scale, cy + 50*scale),
        (cx - 35*scale, cy + 50*scale),
    ]
    draw.polygon(body_points, fill=color)

def add_light_rays(img, center, color, num_rays=12, length=400):
    """Add dramatic light rays"""
    draw = ImageDraw.Draw(img, 'RGBA')
    cx, cy = center

    for i in range(num_rays):
        angle = (i / num_rays) * 2 * math.pi + random.uniform(-0.1, 0.1)
        end_x = cx + int(math.cos(angle) * length)
        end_y = cy + int(math.sin(angle) * length)

        # Draw ray with gradient alpha
        for w in range(30, 0, -1):
            alpha = int(30 * (w / 30))
            ray_color = (*color, alpha)
            draw.line([(cx, cy), (end_x, end_y)], fill=ray_color, width=w)

    return img

def add_particles(draw, size, color, density=100, particle_size=3):
    """Add floating particles/memories"""
    for _ in range(density):
        x = random.randint(0, size[0])
        y = random.randint(0, size[1])
        s = random.randint(1, particle_size)
        alpha = random.randint(50, 200)
        draw.ellipse([x-s, y-s, x+s, y+s], fill=(*color, alpha))

def create_ending_liberator(output_path):
    """Liberator ending - exposing the truth"""
    size = (1920, 1080)
    # Dark red/crimson theme
    img = create_gradient_background(size, [(20, 8, 8), (50, 15, 20)])
    img = img.convert('RGBA')
    draw = ImageDraw.Draw(img, 'RGBA')

    # Add dramatic red light from center
    cx, cy = size[0]//2, size[1]//2
    color = hex_to_rgb("#FF4444")

    # Light burst effect
    for r in range(500, 0, -5):
        alpha = int(30 * (1 - r/500))
        draw.ellipse([cx-r, cy-r, cx+r, cy+r], fill=(*color, alpha))

    # Two silhouettes standing together (protagonist and sister)
    draw_silhouette_figure(draw, cx - 80, cy + 100, 1.0, (15, 10, 10, 255))
    draw_silhouette_figure(draw, cx + 80, cy + 100, 0.9, (15, 10, 10, 255))

    # Add broken chain/shattered glass effect
    for _ in range(50):
        x = random.randint(cx-300, cx+300)
        y = random.randint(cy-200, cy+100)
        size_s = random.randint(5, 20)
        points = [
            (x, y - size_s),
            (x + size_s, y),
            (x, y + size_s),
            (x - size_s, y),
        ]
        alpha = random.randint(100, 200)
        draw.polygon(points, fill=(200, 50, 50, alpha))

    # Add particles
    add_particles(draw, size, color, 150)

    # Add subtle vignette
    for i in range(200):
        alpha = int(200 * (i/200))
        draw.rectangle([i, i, size[0]-i, size[1]-i], outline=(0, 0, 0, alpha))

    img = img.convert('RGB')
    img.save(output_path, 'PNG')
    print(f"Created: {output_path}")

def create_ending_forgotten(output_path):
    """Forgotten ending - erased memories, solitude"""
    size = (1920, 1080)
    # Muted purple/gray theme
    img = create_gradient_background(size, [(15, 15, 25), (40, 35, 55)])
    img = img.convert('RGBA')
    draw = ImageDraw.Draw(img, 'RGBA')

    color = hex_to_rgb("#9999BB")
    cx, cy = size[0]//2, size[1]//2

    # Single solitary figure, fading
    for fade in range(5, 0, -1):
        alpha = int(50 * fade)
        offset = (5 - fade) * 10
        draw_silhouette_figure(draw, cx + offset, cy + 100, 1.0, (20, 18, 30, alpha))

    # Fading/dissolving particles rising upward
    for _ in range(200):
        x = random.randint(cx-150, cx+150)
        y = random.randint(0, size[1])
        s = random.randint(1, 4)
        alpha = int(150 * (1 - y/size[1]))
        draw.ellipse([x-s, y-s, x+s, y+s], fill=(*color, alpha))

    # Fog/mist effect at bottom
    for y in range(size[1]//2, size[1]):
        alpha = int(80 * ((y - size[1]//2) / (size[1]//2)))
        draw.line([(0, y), (size[0], y)], fill=(100, 95, 120, alpha))

    # Add vignette
    for i in range(250):
        alpha = int(220 * (i/250))
        draw.rectangle([i, i, size[0]-i, size[1]-i], outline=(0, 0, 0, alpha))

    img = img.convert('RGB')
    img.save(output_path, 'PNG')
    print(f"Created: {output_path}")

def create_ending_return(output_path):
    """Returner ending - family reunion, warm"""
    size = (1920, 1080)
    # Warm gold/amber theme
    img = create_gradient_background(size, [(25, 18, 10), (60, 45, 25)])
    img = img.convert('RGBA')
    draw = ImageDraw.Draw(img, 'RGBA')

    color = hex_to_rgb("#FFD700")
    cx, cy = size[0]//2, size[1]//2

    # Warm light glow from behind figures
    for r in range(400, 0, -4):
        alpha = int(40 * (1 - r/400))
        draw.ellipse([cx-r, cy-50-r, cx+r, cy-50+r], fill=(*color, alpha))

    # Two figures close together (reunion)
    draw_silhouette_figure(draw, cx - 50, cy + 100, 1.0, (20, 15, 8, 255))
    draw_silhouette_figure(draw, cx + 50, cy + 100, 0.9, (20, 15, 8, 255))

    # Warm floating particles (memories returning)
    for _ in range(120):
        x = random.randint(0, size[0])
        y = random.randint(0, size[1])
        s = random.randint(2, 5)
        alpha = random.randint(80, 180)
        # Gold to orange variation
        r_var = random.randint(200, 255)
        g_var = random.randint(150, 220)
        draw.ellipse([x-s, y-s, x+s, y+s], fill=(r_var, g_var, 50, alpha))

    # Subtle light rays from top
    for i in range(8):
        angle = math.pi/2 + (i - 4) * 0.1
        x1 = cx + int(math.cos(angle + math.pi) * 600)
        y1 = 0
        for w in range(20, 0, -1):
            alpha = int(20 * (w/20))
            draw.line([(cx, cy-100), (x1, y1)], fill=(255, 220, 100, alpha), width=w)

    # Vignette
    for i in range(200):
        alpha = int(180 * (i/200))
        draw.rectangle([i, i, size[0]-i, size[1]-i], outline=(0, 0, 0, alpha))

    img = img.convert('RGB')
    img.save(output_path, 'PNG')
    print(f"Created: {output_path}")

def create_ending_perfect(output_path):
    """Perfect ending - golden, harmonious"""
    size = (1920, 1080)
    # Bright gold/white theme
    img = create_gradient_background(size, [(30, 28, 20), (80, 70, 50)])
    img = img.convert('RGBA')
    draw = ImageDraw.Draw(img, 'RGBA')

    color = hex_to_rgb("#FFFACD")
    cx, cy = size[0]//2, size[1]//2

    # Radiant light burst
    img = add_light_rays(img, (cx, cy-100), (255, 250, 200), 16, 600)
    draw = ImageDraw.Draw(img, 'RGBA')

    # Bright center glow
    for r in range(350, 0, -3):
        alpha = int(60 * (1 - r/350))
        draw.ellipse([cx-r, cy-100-r, cx+r, cy-100+r], fill=(255, 250, 220, alpha))

    # Single confident figure in light
    draw_silhouette_figure(draw, cx, cy + 100, 1.1, (25, 22, 15, 255))

    # Many bright particles (all memories aligned)
    for _ in range(200):
        x = random.randint(0, size[0])
        y = random.randint(0, size[1])
        s = random.randint(2, 6)
        alpha = random.randint(100, 220)
        draw.ellipse([x-s, y-s, x+s, y+s], fill=(255, 250, 200, alpha))

    # Circular halo effect
    for r in range(280, 320):
        alpha = 255 - int(abs(r - 300) * 12)
        draw.ellipse([cx-r, cy-100-r, cx+r, cy-100+r], outline=(255, 240, 180, max(0, alpha)))

    # Light vignette
    for i in range(150):
        alpha = int(120 * (i/150))
        draw.rectangle([i, i, size[0]-i, size[1]-i], outline=(0, 0, 0, alpha))

    img = img.convert('RGB')
    img.save(output_path, 'PNG')
    print(f"Created: {output_path}")

def create_ending_new_start(output_path):
    """New start ending - fresh, sky blue, hopeful"""
    size = (1920, 1080)
    # Sky blue/cyan theme
    img = create_gradient_background(size, [(15, 25, 35), (40, 70, 90)])
    img = img.convert('RGBA')
    draw = ImageDraw.Draw(img, 'RGBA')

    color = hex_to_rgb("#87CEEB")
    cx, cy = size[0]//2, size[1]//2

    # Soft light from horizon
    for r in range(600, 0, -5):
        alpha = int(25 * (1 - r/600))
        draw.ellipse([cx-r, size[1]-r//2, cx+r, size[1]+r], fill=(135, 206, 235, alpha))

    # Single figure walking toward horizon (back view)
    figure_y = cy + 150
    draw_silhouette_figure(draw, cx, figure_y, 0.8, (10, 15, 20, 255))

    # Path/road leading to horizon
    road_points = [
        (cx - 200, size[1]),
        (cx + 200, size[1]),
        (cx + 20, cy + 200),
        (cx - 20, cy + 200),
    ]
    draw.polygon(road_points, fill=(20, 30, 40, 100))

    # Soft particles rising (new memories forming)
    for _ in range(100):
        x = random.randint(0, size[0])
        y = random.randint(cy, size[1])
        s = random.randint(1, 4)
        alpha = int(120 * (1 - (y - cy)/(size[1] - cy)))
        draw.ellipse([x-s, y-s, x+s, y+s], fill=(*color, alpha))

    # Horizon line glow
    for y in range(cy + 180, cy + 220):
        alpha = int(100 * (1 - abs(y - cy - 200)/20))
        draw.line([(0, y), (size[0], y)], fill=(135, 206, 235, max(0, alpha)))

    # Vignette
    for i in range(200):
        alpha = int(160 * (i/200))
        draw.rectangle([i, i, size[0]-i, size[1]-i], outline=(0, 0, 0, alpha))

    img = img.convert('RGB')
    img.save(output_path, 'PNG')
    print(f"Created: {output_path}")

def main():
    output_dir = r"C:\Users\user\projects\2026_active\neowiz_quest\prototype\assets\illustrations"
    os.makedirs(output_dir, exist_ok=True)

    # Generate each ending illustration
    create_ending_liberator(os.path.join(output_dir, "ending_liberator.png"))
    create_ending_forgotten(os.path.join(output_dir, "ending_forgotten.png"))
    create_ending_return(os.path.join(output_dir, "ending_return.png"))
    create_ending_perfect(os.path.join(output_dir, "ending_perfect.png"))
    create_ending_new_start(os.path.join(output_dir, "ending_new_start.png"))

    print("\nAll ending illustrations generated successfully!")

if __name__ == "__main__":
    main()

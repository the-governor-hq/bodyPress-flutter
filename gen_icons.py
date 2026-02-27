"""Generate bodypress app icons - retro-future newspaper vibe, large serif 'B'."""

import os
from PIL import Image, ImageDraw, ImageFont

# ── Design tokens ──────────────────────────────────────────────────────────────
BG_COLOR   = (8, 8, 8)          # near-black ink background
FG_COLOR   = (240, 234, 218)    # warm newsprint off-white
PADDING    = 0.11               # fraction of size to keep clear around edge

# Windows system fonts to try in order (bold serif → newspaper feel)
FONT_CANDIDATES = [
    r"C:\Windows\Fonts\garabd.ttf",       # Garamond Bold
    r"C:\Windows\Fonts\timesbd.ttf",      # Times New Roman Bold
    r"C:\Windows\Fonts\georgiab.ttf",     # Georgia Bold
    r"C:\Windows\Fonts\georgia.ttf",      # Georgia Regular
    r"C:\Windows\Fonts\times.ttf",        # Times New Roman
]

# ── Icon sets ─────────────────────────────────────────────────────────────────
ANDROID_ICONS = {
    r"android\app\src\main\res\mipmap-mdpi\ic_launcher.png":    48,
    r"android\app\src\main\res\mipmap-hdpi\ic_launcher.png":    72,
    r"android\app\src\main\res\mipmap-xhdpi\ic_launcher.png":   96,
    r"android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png":  144,
    r"android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png": 192,
}

IOS_ICONS = {
    r"ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-20x20@1x.png":     20,
    r"ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-20x20@2x.png":     40,
    r"ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-20x20@3x.png":     60,
    r"ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-29x29@1x.png":     29,
    r"ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-29x29@2x.png":     58,
    r"ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-29x29@3x.png":     87,
    r"ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-40x40@1x.png":     40,
    r"ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-40x40@2x.png":     80,
    r"ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-40x40@3x.png":     120,
    r"ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-60x60@2x.png":     120,
    r"ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-60x60@3x.png":     180,
    r"ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-76x76@1x.png":     76,
    r"ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-76x76@2x.png":     152,
    r"ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-83.5x83.5@2x.png": 167,
    r"ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-1024x1024@1x.png": 1024,
}

BASE_DIR = os.path.dirname(os.path.abspath(__file__))


def load_font(size: int) -> ImageFont.FreeTypeFont:
    """Load best available serif font at given size."""
    for path in FONT_CANDIDATES:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except Exception:
                continue
    return ImageFont.load_default()


def make_icon(px: int) -> Image.Image:
    """Create a square icon of size px with a large centred 'B'."""
    img = Image.new("RGB", (px, px), BG_COLOR)
    draw = ImageDraw.Draw(img)

    # Aim for the 'B' to fill most of the canvas minus padding
    target_height = px * (1.0 - PADDING * 2)
    font_size = int(target_height * 1.05)   # overshoot, then clamp

    font = load_font(font_size)

    # Measure bounding box and shrink until it fits
    for _ in range(40):
        bbox = draw.textbbox((0, 0), "B", font=font)
        w = bbox[2] - bbox[0]
        h = bbox[3] - bbox[1]
        if w <= target_height and h <= target_height:
            break
        font_size = int(font_size * 0.96)
        font = load_font(font_size)

    # Re-measure for final centering
    bbox = draw.textbbox((0, 0), "B", font=font)
    w = bbox[2] - bbox[0]
    h = bbox[3] - bbox[1]

    # Centre precisely
    x = (px - w) / 2 - bbox[0]
    y = (px - h) / 2 - bbox[1]

    # Subtle warm shadow for depth (retro print feel)
    if px >= 48:
        shadow_offset = max(1, px // 96)
        draw.text((x + shadow_offset, y + shadow_offset), "B",
                  fill=(180, 140, 80, 120), font=font)

    draw.text((x, y), "B", fill=FG_COLOR, font=font)

    return img


def generate_all():
    all_icons = {**ANDROID_ICONS, **IOS_ICONS}
    for rel_path, size in all_icons.items():
        full_path = os.path.join(BASE_DIR, rel_path)
        img = make_icon(size)
        img.save(full_path, "PNG")
        print(f"  ✓  {size:>4}px  {rel_path}")

    print("\nAll icons generated.")


if __name__ == "__main__":
    generate_all()

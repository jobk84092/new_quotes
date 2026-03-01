#!/usr/bin/env python3
"""
Generate Play Store screenshots for Daily Quotes app.
Creates phone (1080x1920) screens that match the app's design.
"""

from __future__ import annotations

from pathlib import Path


# App theme colors (from app_theme.dart)
BRAND_A = (79, 70, 229)   # #4F46E5 indigo
BRAND_B = (6, 182, 212)   # #06B6D4 cyan
WHITE = (255, 255, 255)
DARK = (30, 30, 45)
LIGHT_GRAY = (240, 240, 245)

PHONE_SIZE = (1080, 1920)


def _gradient(img, y1: int, y2: int, c1: tuple, c2: tuple) -> None:
    """Draw vertical gradient from y1 to y2."""
    px = img.load()
    h = y2 - y1
    for y in range(h):
        t = y / max(1, h - 1)
        r = int(c1[0] + (c2[0] - c1[0]) * t)
        g = int(c1[1] + (c2[1] - c1[1]) * t)
        b = int(c1[2] + (c2[2] - c1[2]) * t)
        for x in range(img.width):
            px[x, y1 + y] = (r, g, b)


def main() -> None:
    try:
        from PIL import Image, ImageDraw, ImageFont
    except ImportError:
        print("Install Pillow: pip install Pillow")
        return

    repo = Path(__file__).resolve().parents[1]
    out_dir = repo / "store_assets" / "screenshots" / "phone"
    out_dir.mkdir(parents=True, exist_ok=True)

    def font(size: int, bold: bool = False):
        candidates = [
            "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
            "/System/Library/Fonts/Helvetica.ttc",
            "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        ]
        for p in candidates:
            if Path(p).exists():
                try:
                    return ImageFont.truetype(p, size)
                except Exception:
                    pass
        return ImageFont.load_default()

    w, h = PHONE_SIZE

    # --- Screen 1: Home - Quote of the day ---
    img1 = Image.new("RGB", (w, h))
    _gradient(img1, 0, h, BRAND_A, BRAND_B)
    draw = ImageDraw.Draw(img1)

    # Status bar area
    draw.rectangle([0, 0, w, 80], fill=(0, 0, 0, 80))

    # App bar
    draw.text((w // 2 - 80, 100), "Daily Quotes", font=font(28, True), fill=WHITE)

    # Quote card
    card_margin = 60
    card_y = 220
    card_h = 320
    draw.rounded_rectangle([card_margin, card_y, w - card_margin, card_y + card_h], radius=24, fill=(255, 255, 255))
    draw.rectangle([card_margin + 20, card_y + 20, w - card_margin - 20, card_y + card_h - 60], fill=(250, 250, 252))

    quote_text = '"The only way to do great work is to love what you do."'
    draw.text((card_margin + 40, card_y + 50), quote_text, font=font(22), fill=DARK)
    draw.text((card_margin + 40, card_y + card_h - 80), "— Steve Jobs", font=font(18), fill=BRAND_A)

    # Category chips
    chips = ["Love", "Motivation", "Wisdom", "Focus", "Inspiration"]
    chip_y = card_y + card_h + 50
    chip_x = card_margin
    for name in chips:
        tw = (draw.textlength(name, font=font(16)) if hasattr(draw, 'textlength') else draw.textsize(name, font=font(16))[0]) + 40
        draw.rounded_rectangle([chip_x, chip_y, chip_x + tw, chip_y + 44], radius=22, fill=(255, 255, 255))
        draw.text((chip_x + 20, chip_y + 8), name, font=font(16), fill=DARK)
        chip_x += tw + 16

    img1.save(out_dir / "01_home.png", "PNG", optimize=True)
    print("  Wrote 01_home.png")

    # --- Screen 2: Categories ---
    img2 = Image.new("RGB", (w, h))
    _gradient(img2, 0, h, BRAND_A, BRAND_B)
    draw = ImageDraw.Draw(img2)

    draw.text((w // 2 - 60, 100), "Categories", font=font(28, True), fill=WHITE)

    categories = ["Love", "Motivation", "Wisdom", "Focus", "Inspiration", "Growth"]
    item_y = 200
    for i, name in enumerate(categories):
        box_y = item_y + i * 120
        draw.rounded_rectangle([card_margin, box_y, w - card_margin, box_y + 90], radius=16, fill=(255, 255, 255))
        draw.text((card_margin + 30, box_y + 28), name, font=font(24, True), fill=DARK)
        draw.text((w - card_margin - 80, box_y + 35), ">", font=font(24), fill=BRAND_A)

    img2.save(out_dir / "02_categories.png", "PNG", optimize=True)
    print("  Wrote 02_categories.png")

    # --- Screen 3: Quote detail ---
    img3 = Image.new("RGB", (w, h))
    _gradient(img3, 0, h, BRAND_A, BRAND_B)
    draw = ImageDraw.Draw(img3)

    draw.text((80, 80), "<", font=font(28), fill=WHITE)
    draw.text((w // 2 - 50, 80), "Quote", font=font(24, True), fill=WHITE)

    # Large quote card
    qy = 200
    qh = 500
    draw.rounded_rectangle([card_margin, qy, w - card_margin, qy + qh], radius=24, fill=(255, 255, 255))
    long_quote = '"Life is what happens when you\'re busy making other plans."'
    draw.text((card_margin + 40, qy + 60), long_quote, font=font(24), fill=DARK)
    draw.text((card_margin + 40, qy + qh - 100), "— John Lennon", font=font(20), fill=BRAND_A)

    # Action buttons
    btn_y = qy + qh + 60
    draw.rounded_rectangle([card_margin, btn_y, w // 2 - 20, btn_y + 56], radius=28, fill=WHITE)
    draw.text((card_margin + 80, btn_y + 14), "Share", font=font(18, True), fill=BRAND_A)
    draw.rounded_rectangle([w // 2 + 20, btn_y, w - card_margin, btn_y + 56], radius=28, fill=WHITE)
    draw.text((w // 2 + 100, btn_y + 14), "Copy", font=font(18, True), fill=BRAND_A)

    img3.save(out_dir / "03_quote_detail.png", "PNG", optimize=True)
    print("  Wrote 03_quote_detail.png")

    # --- Screen 4: Favorites ---
    img4 = Image.new("RGB", (w, h))
    _gradient(img4, 0, h, BRAND_A, BRAND_B)
    draw = ImageDraw.Draw(img4)

    draw.text((w // 2 - 70, 100), "Favorites", font=font(28, True), fill=WHITE)

    fav_quotes = [
        ("The best time to plant a tree was 20 years ago.", "Chinese Proverb"),
        ("It does not matter how slowly you go.", "Confucius"),
    ]
    fy = 200
    for i, (qt, au) in enumerate(fav_quotes):
        box_y = fy + i * 200
        draw.rounded_rectangle([card_margin, box_y, w - card_margin, box_y + 160], radius=16, fill=(255, 255, 255))
        draw.text((card_margin + 30, box_y + 30), f'"{qt[:50]}..."', font=font(20), fill=DARK)
        draw.text((card_margin + 30, box_y + 100), f"— {au}", font=font(16), fill=BRAND_A)

    img4.save(out_dir / "04_favorites.png", "PNG", optimize=True)
    print("  Wrote 04_favorites.png")

    # --- Screen 5: Search ---
    img5 = Image.new("RGB", (w, h))
    _gradient(img5, 0, h, BRAND_A, BRAND_B)
    draw = ImageDraw.Draw(img5)

    draw.text((w // 2 - 50, 100), "Search", font=font(28, True), fill=WHITE)

    # Search bar
    draw.rounded_rectangle([card_margin, 200, w - card_margin, 270], radius=24, fill=WHITE)
    draw.text((card_margin + 50, 225), "Search quotes...", font=font(18), fill=(150, 150, 160))

    # Results
    for i in range(3):
        ry = 320 + i * 140
        draw.rounded_rectangle([card_margin, ry, w - card_margin, ry + 110], radius=12, fill=(255, 255, 255))
        draw.text((card_margin + 30, ry + 25), "Be the change you wish to see...", font=font(18), fill=DARK)
        draw.text((card_margin + 30, ry + 65), "— Gandhi", font=font(14), fill=BRAND_A)

    img5.save(out_dir / "05_search.png", "PNG", optimize=True)
    print("  Wrote 05_search.png")

    print(f"\nDone. Phone screenshots in {out_dir}")


if __name__ == "__main__":
    main()

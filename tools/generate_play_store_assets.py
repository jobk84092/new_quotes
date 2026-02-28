from __future__ import annotations

from pathlib import Path


def _linear_gradient(w: int, h: int, left_rgb: tuple[int, int, int], right_rgb: tuple[int, int, int]):
    # Pillow Image created lazily to avoid importing when unused.
    from PIL import Image

    img = Image.new("RGB", (w, h))
    px = img.load()
    for x in range(w):
        t = x / max(1, (w - 1))
        r = int(left_rgb[0] + (right_rgb[0] - left_rgb[0]) * t)
        g = int(left_rgb[1] + (right_rgb[1] - left_rgb[1]) * t)
        b = int(left_rgb[2] + (right_rgb[2] - left_rgb[2]) * t)
        for y in range(h):
            px[x, y] = (r, g, b)
    return img


def main():
    repo = Path(__file__).resolve().parents[1]
    src_icon = repo / "logo" / "appstore.png"
    if not src_icon.exists():
        src_icon = repo / "assets" / "logo" / "playstore.png"

    out_dir = repo / "store_assets"
    out_dir.mkdir(parents=True, exist_ok=True)

    from PIL import Image, ImageDraw, ImageFont

    icon_img = Image.open(src_icon).convert("RGBA")

    # Play Store icon (512x512)
    icon_512 = icon_img.resize((512, 512), Image.LANCZOS)
    icon_512_path = out_dir / "icon_512.png"
    icon_512.save(icon_512_path, format="PNG", optimize=True)

    # Feature graphic (1024x500)
    w, h = 1024, 500
    bg = _linear_gradient(w, h, (79, 70, 229), (236, 72, 153))  # indigo -> pink
    fg = bg.convert("RGBA")

    # Place icon
    icon_big = icon_img.resize((360, 360), Image.LANCZOS)
    fg.alpha_composite(icon_big, dest=(60, 70))

    draw = ImageDraw.Draw(fg)

    # Try to load a nicer font if available; otherwise fallback.
    def load_font(size: int, bold: bool = False):
        candidates = [
            "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
            "/System/Library/Fonts/Supplemental/Helvetica Neue Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Helvetica Neue.ttf",
        ]
        for p in candidates:
            try:
                return ImageFont.truetype(p, size=size)
            except Exception:
                continue
        return ImageFont.load_default()

    title_font = load_font(80, bold=True)
    subtitle_font = load_font(34, bold=False)

    title = "Daily Quotes"
    subtitle = "Offline inspiration • Love • Motivation • Wisdom"

    # Text shadow for readability
    tx, ty = 460, 165
    shadow = (0, 0, 0, 110)
    draw.text((tx + 3, ty + 3), title, font=title_font, fill=shadow)
    draw.text((tx, ty), title, font=title_font, fill=(255, 255, 255, 255))

    sx, sy = 460, 265
    draw.text((sx + 2, sy + 2), subtitle, font=subtitle_font, fill=shadow)
    draw.text((sx, sy), subtitle, font=subtitle_font, fill=(255, 255, 255, 235))

    feature_path = out_dir / "feature_graphic_1024x500.png"
    fg.convert("RGB").save(feature_path, format="PNG", optimize=True)

    print(f"Wrote: {icon_512_path} ({icon_512_path.stat().st_size} bytes)")
    print(f"Wrote: {feature_path} ({feature_path.stat().st_size} bytes)")


if __name__ == "__main__":
    main()


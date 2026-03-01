#!/usr/bin/env python3
"""
Generate tablet screenshots from phone screenshots for Google Play Store.

Usage:
  1. Put your phone screenshots (1080×1920 or similar) in store_assets/screenshots/phone/
  2. Run: python tools/generate_tablet_screenshots.py
  3. Find outputs in store_assets/screenshots/tablet_7in/ and tablet_10in/

Play Store requirements (large screens):
  - 9:16 portrait or 16:9 landscape
  - 1,080–7,680 px on one edge
  - Min 4 screenshots for tablets
"""

from __future__ import annotations

from pathlib import Path


# Play Store tablet dimensions (9:16 portrait)
TABLET_7IN = (1200, 2133)   # 9:16
TABLET_10IN = (1600, 2844)  # 9:16


def main() -> None:
    repo = Path(__file__).resolve().parents[1]
    phone_dir = repo / "store_assets" / "screenshots" / "phone"
    out_7 = repo / "store_assets" / "screenshots" / "tablet_7in"
    out_10 = repo / "store_assets" / "screenshots" / "tablet_10in"

    if not phone_dir.exists():
        phone_dir.mkdir(parents=True, exist_ok=True)
        print(f"Created {phone_dir}")
        print("Put 2–8 phone screenshots (1080×1920 PNG/JPG) there, then run again.")
        return

    images = list(phone_dir.glob("*.png")) + list(phone_dir.glob("*.jpg")) + list(phone_dir.glob("*.jpeg"))
    if not images:
        print(f"No images in {phone_dir}")
        print("Add phone screenshots (PNG or JPG), then run again.")
        return

    try:
        from PIL import Image
    except ImportError:
        print("Install Pillow: pip install Pillow")
        return

    out_7.mkdir(parents=True, exist_ok=True)
    out_10.mkdir(parents=True, exist_ok=True)

    w7, h7 = TABLET_7IN
    w10, h10 = TABLET_10IN

    for img_path in sorted(images):
        name = img_path.stem
        img = Image.open(img_path).convert("RGB")

        # Resize to tablet dimensions (high-quality Lanczos)
        tab7 = img.resize((w7, h7), Image.LANCZOS)
        tab10 = img.resize((w10, h10), Image.LANCZOS)

        out7_path = out_7 / f"{name}.png"
        out10_path = out_10 / f"{name}.png"

        tab7.save(out7_path, "PNG", optimize=True)
        tab10.save(out10_path, "PNG", optimize=True)

        print(f"  {img_path.name} -> 7in: {out7_path.name}, 10in: {out10_path.name}")

    print(f"\nDone. 7-inch: {out_7} | 10-inch: {out_10}")
    print("Upload these to Play Console > Store listing > Tablet screenshots.")


if __name__ == "__main__":
    main()

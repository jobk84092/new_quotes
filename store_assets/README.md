# Play Store assets

## Ready to upload
- `icon_512.png` (512×512) — App icon
- `feature_graphic_1024x500.png` (1024×500) — Feature graphic

## Screenshots (phone + tablet)

**Step 1 – Capture phone screenshots**
- Run the app on a device or emulator
- Capture 2–8 screens (home, categories, quote detail, favorites, search)
- Save as PNG/JPG in `screenshots/phone/` (1080×1920 or similar)

**Step 2 – Generate tablet screenshots**
```bash
python tools/generate_tablet_screenshots.py
```
This creates `screenshots/tablet_7in/` and `screenshots/tablet_10in/` from your phone screenshots.

**Step 3 – Upload to Play Console**
- Phone: `screenshots/phone/`
- 7-inch tablet: `screenshots/tablet_7in/`
- 10-inch tablet: `screenshots/tablet_10in/`

# Daily Quotes - Release Ready

## Version 1.0.0+1

This build is ready for Play Store. Upload the AAB from GitHub Actions to Play Console.

---

## What's Included

- **Package:** com.jobk84092.dailyquotes
- **Release signing:** Via CI (keystore in GitHub secrets)
- **Store assets:** Icon, feature graphic, phone + tablet screenshots
- **Features:** Quotes, categories, favorites, search, share, premium pack, IAP (coffee_week)

---

## Before Going Live

1. **AdMob IDs** – Replace placeholders in `AndroidManifest.xml` and `ad_banner.dart` with your real App ID and Banner ID from AdMob. See `ADMOB_SETUP.md`.

2. **Play Console** – Add the AAB to your release, then Start rollout to Production.

3. **IAP** – Create `coffee_week` product in Play Console > Monetize > Products (if not done).

---

## Build AAB

- **CI:** Push to main, or run workflow at https://github.com/jobk84092/new_quotes/actions
- **Download:** Artifacts > daily-quotes-aab

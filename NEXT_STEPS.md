## Tomorrow’s targets (Play Store + polish)

### Critical clarification
- **Google Play packaging**: Play Console typically requires **AAB** for *new* apps. If that applies, we’ll still keep **APK** for sideload/testing, but publish via **AAB**. We’ll confirm in Console first.

### Play Console setup
- Create app in Play Console (name, category, contact email, website).
- Store listing: short/long description, tags.
- Privacy policy (even for offline apps; mention no account required, offline data, ads/IAP if present).
- Content rating + target audience.

### Store assets to produce
- App icon (512×512), feature graphic (1024×500).
- Screenshots (phone: at least 2–8; optional tablet).
- Optional promo graphics.

### App UX / product work
- Implement **Share** button: share quote text + author (and category) using `share_plus`.
- Improve quote card “real app feel”: spacing, shadows/blur, consistent typography.
- Add favorites/bookmarks (persist via `shared_preferences`).
- Add copy-to-clipboard.

### Release engineering
- CI: **APK-only** artifact (single versioned file) and consistent naming.
- Release signing (keystore + `key.properties` not committed; document secure storage).
- Versioning: bump `versionCode`/`versionName` per release.

### Size budget (< 30 MB)
- Reduce/resize background images; compress PNG/JPG aggressively.
- Remove duplicate assets and any unused images.
- Measure release APK size every build and keep a running log.

### QA checklist before shipping
- Verify offline mode works on fresh install.
- Verify no crashes on missing assets.
- Smoke test: onboarding → homepage → category → quote details → share/copy.


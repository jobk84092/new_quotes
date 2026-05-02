# AdMob Production IDs

> **Not the website:** Open Our Quotes **on the web** uses Google **AdSense** with publisher **`ca-pub-9907830179614621`** (see `quotes-website/`). This file is only for the **Android / AdMob** app.

The app uses your AdMob publisher ID (`pub-2518115915091022`). **Replace the placeholder suffixes** with your real IDs from AdMob:

1. **App ID** – AdMob > Apps > Daily Quotes > App settings  
   Format: `ca-app-pub-2518115915091022~XXXXXXXX`  
   Update in: `android/app/src/main/AndroidManifest.xml` (line 11)

2. **Banner Ad Unit ID** – AdMob > Apps > Daily Quotes > Ad units > Banner  
   Format: `ca-app-pub-2518115915091022/XXXXXXXX`  
   Update in: `lib/widgets/ad_banner.dart` (line 16)

If the app is not in AdMob yet: Apps > Add app > Android > Package `com.jobk84092.dailyquotes` > Create Banner ad unit.

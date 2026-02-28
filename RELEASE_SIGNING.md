# Release signing for Google Play

To build a release-signed AAB for Google Play, you need a keystore and `key.properties`.

## 1. Generate a keystore (one-time)

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

- Use a strong password and **store it safely** (you need it for every future release).
- Keep the `.jks` file secure and backed up. If you lose it, you cannot update your app on Play Store.

## 2. Local builds

Create `android/key.properties` (already in `.gitignore`):

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=../upload-keystore.jks
```

Put `upload-keystore.jks` in the `android/` folder. Then run:

```bash
flutter build appbundle --release
```

The AAB will be at `build/app/outputs/bundle/release/app-release.aab`.

## 3. CI (GitHub Actions)

Add these **secrets** in your repo: **Settings → Secrets and variables → Actions**:

| Secret | Value |
|--------|-------|
| `ANDROID_KEYSTORE_BASE64` | Base64 of your `.jks` file: `base64 -i upload-keystore.jks | pbcopy` (macOS) |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_ALIAS` | `upload` (or your alias) |
| `ANDROID_KEY_PASSWORD` | Key password |

The workflow will use these to sign the AAB before uploading the artifact.

# URL to App

Turn any website into a native Android/iOS app.

<<<<<<< HEAD
## Setup

```bash
flutter pub get
dart run scripts/config.dart https://example.com "My App"
=======
## Quick Guide

```bash
# Clone the repo
git clone "https://github.com/ameerhamzasaifi/Url_to_App.git"

cd url_to_app

# Set URL and app name (automatically updates pubspec.yaml)
dart run scripts/config.dart https://example.com "My App"

# Run the app (pls note only run in andriod and ios dives)
>>>>>>> 98db420acee77ba501211f81010295ae88c228cd
flutter run
```

## Config Options

```bash
# Set URL + app name (fetches favicon, regenerates icons)
dart run scripts/config.dart https://example.com "My App"

# Change app name only
dart run scripts/config.dart --launchername "New Name"

# Change package ID
dart run scripts/config.dart --package com.example.myapp
```

## Structure

```
lib/main.dart          - WebView app
scripts/config.dart    - Config script (URL, name, icon, package ID)
assets/icon/icon.png   - App icon (auto-fetched or manual)
```
<<<<<<< HEAD
=======

## Notes

- The script automatically converts app names to valid Dart package names (e.g., "My App" → "my_app")
- Reserved package names (flutter, flutter_test, etc.) are automatically suffixed with "_app"
- Screen rotation is handled gracefully without errors
- After updating package ID, run `flutter clean` before rebuilding

## Star History

<a href="https://www.star-history.com/?repos=ameerhamzasaifi%2FUrl_to_App&type=date&legend=bottom-right">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/image?repos=ameerhamzasaifi/Url_to_App&type=date&theme=dark&legend=bottom-right" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/image?repos=ameerhamzasaifi/Url_to_App&type=date&legend=bottom-right" />
   <img alt="Star History Chart" src="https://api.star-history.com/image?repos=ameerhamzasaifi/Url_to_App&type=date&legend=bottom-right" />
 </picture>
</a>
>>>>>>> 98db420acee77ba501211f81010295ae88c228cd

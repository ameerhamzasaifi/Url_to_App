# URL to App

Turn any website into a native Android/iOS app.

## Setup

```bash
flutter pub get
dart run scripts/config.dart https://example.com "My App"
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
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/image?repos=ameerhamzasaifi/Url_to_App&type=date&theme=dark&legend=bottom-right" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/image?repos=ameerhamzasaifi/Url_to_App&type=date&legend=bottom-right" />
   <img alt="Star History Chart" src="https://api.star-history.com/image?repos=ameerhamzasaifi/Url_to_App&type=date&legend=bottom-right" />
 </picture>
</a>

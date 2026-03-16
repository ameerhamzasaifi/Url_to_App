# URL to App

Converts any URL into a native iOS and Android app using Flutter's WebView.

## Quick Start

```bash
# Set URL and app name (automatically updates pubspec.yaml)
dart run scripts/config.dart https://example.com "My App"

# Run the app
flutter run
```

## Configuration Commands

### Set URL with App Name
```bash
dart run scripts/config.dart https://flutter.dev "Flutter"
```
Updates:
- ✅ Home URL in `lib/main.dart`
- ✅ App name (launcher display name)
- ✅ `pubspec.yaml` package name
- ✅ Android/iOS configs
- ✅ Downloads favicon and regenerates launcher icons

### Update App Name (Launcher Name)
```bash
# Interactive mode
dart run scripts/config.dart --launchername

# Direct mode
dart run scripts/config.dart --launchername "My Custom App"
```
Updates:
- ✅ `pubspec.yaml` name
- ✅ `lib/main.dart` kAppName
- ✅ Android app label
- ✅ iOS CFBundleDisplayName

### Update Package ID (Android/iOS Bundle)
```bash
# Interactive mode
dart run scripts/config.dart --package

# Direct mode
dart run scripts/config.dart --package com.example.myapp
```
Updates:
- ✅ Android `applicationId`
- ✅ iOS `PRODUCT_BUNDLE_IDENTIFIER`

## Features

- 🌐 Wraps any website as a native app
- 📱 Works on both iOS and Android
- 🎨 Automatic icon generation from website favicon
- 📛 Customizable app name and package ID
- 🔄 Easy reconfiguration with simple commands
- ⚡ Handles screen rotation without errors
- 🔴 Error handling with retry functionality

## Requirements

- Flutter SDK (3.11.1+)
- Dart 3.11.1+
- Android SDK / Xcode (for building)

## Installation

1. Clone or download this project
2. Run `flutter pub get` (required before first configuration)
3. Configure with your URL: `dart run scripts/config.dart https://yoursite.com "Your App"`
4. Run with `flutter run`

## File Structure

```
lib/main.dart              - Main app code, WebView setup
scripts/config.dart        - Configuration script
pubspec.yaml              - Package configuration
android/                  - Android native files
ios/                      - iOS native files
assets/icon/icon.png      - App icon (auto-downloaded)
```

## Notes

- The script automatically converts app names to valid Dart package names (e.g., "My App" → "my_app")
- Reserved package names (flutter, flutter_test, etc.) are automatically suffixed with "_app"
- Screen rotation is handled gracefully without errors
- After updating package ID, run `flutter clean` before rebuilding

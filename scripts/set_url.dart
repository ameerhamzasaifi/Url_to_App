#!/usr/bin/env dart
// scripts/set_url.dart
//
// Usage:
//   dart run scripts/set_url.dart https://flutter.dev
//
// What it does:
//   1. Updates the kHomeUrl constant inside lib/main.dart
//   2. Downloads the site's favicon and saves it to assets/icon/icon.png
//   3. Runs `dart run flutter_launcher_icons` to regenerate launcher icons
//
// Requirements:
//   flutter pub get   (must be run once first)

import 'dart:io';

import 'package:http/http.dart' as http;

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run scripts/set_url.dart <url> [app name]');
    stderr.writeln(
      'Example: dart run scripts/set_url.dart https://flutter.dev "Flutter"',
    );
    exit(1);
  }

  final rawUrl = args.first.trim();
  final appName = args.length > 1 ? args.skip(1).join(' ') : null;

  Uri uri;
  try {
    uri = Uri.parse(rawUrl);
    if (!uri.hasScheme) {
      uri = Uri.parse('https://$rawUrl');
    }
  } catch (e) {
    stderr.writeln('Invalid URL: $rawUrl');
    exit(1);
  }

  final url = uri.toString();
  print('📌 Setting home URL → $url');
  if (appName != null) print('📛 Setting app name → $appName');

  // ── 1. Patch lib/main.dart ───────────────────────────────────────────────
  final mainFile = File('lib/main.dart');
  if (!await mainFile.exists()) {
    stderr.writeln(
      'lib/main.dart not found. Run this script from the project root.',
    );
    exit(1);
  }

  var source = await mainFile.readAsString();
  final urlPattern = RegExp(r"const String kHomeUrl = '.*?';");
  if (!urlPattern.hasMatch(source)) {
    stderr.writeln('Could not find kHomeUrl in lib/main.dart');
    exit(1);
  }
  source = source.replaceFirst(urlPattern, "const String kHomeUrl = '$url';");

  if (appName != null) {
    final namePattern = RegExp(r"const String kAppName = '.*?';");
    if (namePattern.hasMatch(source)) {
      source = source.replaceFirst(
        namePattern,
        "const String kAppName = '$appName';",
      );
    }
  }

  await mainFile.writeAsString(source);
  print('✅ lib/main.dart updated');

  // ── 1b. Patch Android app label ──────────────────────────────────────────
  if (appName != null) {
    // Android: android/app/src/main/AndroidManifest.xml  android:label="..."
    final manifestFile = File('android/app/src/main/AndroidManifest.xml');
    if (await manifestFile.exists()) {
      var manifest = await manifestFile.readAsString();
      manifest = manifest.replaceFirst(
        RegExp(r'android:label="[^"]*"'),
        'android:label="$appName"',
      );
      await manifestFile.writeAsString(manifest);
      print('✅ AndroidManifest.xml label updated');
    }

    // iOS: ios/Runner/Info.plist  CFBundleDisplayName
    final plistFile = File('ios/Runner/Info.plist');
    if (await plistFile.exists()) {
      var plist = await plistFile.readAsString();
      plist = plist.replaceFirst(
        RegExp(r'(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)'),
        '\${1}$appName\${2}',
      );
      await plistFile.writeAsString(plist);
      print('✅ iOS Info.plist CFBundleDisplayName updated');
    }
  }

  // ── 2. Fetch favicon ─────────────────────────────────────────────────────
  await Directory('assets/icon').create(recursive: true);
  final iconPath = 'assets/icon/icon.png';

  bool iconSaved = false;

  // Try /favicon.ico → convert via Google's favicon service for a PNG
  // Prefer Google's high-res favicon API
  final googleFaviconUrl =
      'https://www.google.com/s2/favicons?domain=${uri.host}&sz=256';

  try {
    print('🌐 Fetching favicon from Google S2 service…');
    final response = await http
        .get(Uri.parse(googleFaviconUrl))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
      await File(iconPath).writeAsBytes(response.bodyBytes);
      print('✅ Favicon saved → $iconPath');
      iconSaved = true;
    }
  } catch (e) {
    print('⚠️  Google favicon fetch failed: $e');
  }

  if (!iconSaved) {
    // Try fetching the HTML and parsing <link rel="icon"> tags
    try {
      print('🌐 Trying HTML favicon discovery…');
      final pageResp = await http.get(uri).timeout(const Duration(seconds: 10));
      if (pageResp.statusCode == 200) {
        final html = pageResp.body;
        final iconLinks = RegExp(
          r'<link[^>]*rel=[\'
          "](.*?icon.*?)[\'"
          '][^>]*href=[\'"]([^"\']+)[\'"]',
          caseSensitive: false,
        ).allMatches(html);

        for (final match in iconLinks) {
          var href = match.group(1)!;
          if (href.startsWith('//')) href = '${uri.scheme}:$href';
          if (!href.startsWith('http')) {
            href = '${uri.scheme}://${uri.host}$href';
          }
          try {
            final r = await http
                .get(Uri.parse(href))
                .timeout(const Duration(seconds: 8));
            if (r.statusCode == 200) {
              await File(iconPath).writeAsBytes(r.bodyBytes);
              print('✅ Favicon saved from HTML → $iconPath');
              iconSaved = true;
              break;
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      print('⚠️  HTML favicon discovery failed: $e');
    }
  }

  if (!iconSaved) {
    print('⚠️  Could not fetch favicon. Using default icon.');
    print('   You can manually place a PNG at: assets/icon/icon.png');
  }

  // ── 3. Regenerate launcher icons ─────────────────────────────────────────
  if (iconSaved) {
    print('\n🔨 Regenerating launcher icons…');
    final result = await Process.run('dart', [
      'run',
      'flutter_launcher_icons',
    ], runInShell: true);
    if (result.exitCode == 0) {
      print('✅ Launcher icons regenerated');
    } else {
      stderr.writeln('⚠️  flutter_launcher_icons failed:');
      stderr.writeln(result.stderr);
    }
  }

  print('\n🚀 Done! Now run:  flutter run');
}

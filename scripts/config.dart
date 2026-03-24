#!/usr/bin/env dart

import 'dart:io';

import 'package:http/http.dart' as http;

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run scripts/config.dart [options]');
    stderr.writeln('');
    stderr.writeln('Options:');
    stderr.writeln('  <url> [app name]        Set URL and optional app name');
    stderr.writeln('  --launchername <name>   Set or edit app name');
    stderr.writeln('  --launchername          Interactive app name editor');
    stderr.writeln(
      '  --package <id>          Set or edit package ID (com.example.app)',
    );
    stderr.writeln('  --package               Interactive package ID editor');
    stderr.writeln('');
    stderr.writeln('Examples:');
    stderr.writeln(
      '  dart run scripts/config.dart https://flutter.dev "Flutter"',
    );
    stderr.writeln('  dart run scripts/config.dart --launchername "My App"');
    stderr.writeln('  dart run scripts/config.dart --launchername');
    stderr.writeln('  dart run scripts/config.dart --package com.example.app');
    stderr.writeln('  dart run scripts/config.dart --package');
    exit(1);
  }

  // Handle --package flag (package ID)
  if (args.first == '--package') {
    String? packageId;
    if (args.length > 1) {
      packageId = args[1];
    } else {
      // Interactive mode
      packageId = await _promptForPackageId();
    }
    if (packageId != null) {
      await _updatePackageId(packageId);
    }
    return;
  }

  // Handle --launchername flag (app name)
  if (args.first == '--launchername') {
    String? appName;
    if (args.length > 1) {
      appName = args.skip(1).join(' ');
    } else {
      // Interactive mode
      appName = await _promptForAppName();
    }
    if (appName != null) {
      await _updateAppName(appName);
    }
    return;
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

  // ── 1. Patch lib/main.dart ────────────────────────────────────────────
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

  // ── 1a. Update pubspec.yaml ─────────────────────────────────────────
  if (appName != null) {
    // Generate Dart package name from app name
    final packageName = appName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (packageName.isNotEmpty) {
      final pubspecFile = File('pubspec.yaml');
      if (await pubspecFile.exists()) {
        var pubspec = await pubspecFile.readAsString();
        pubspec = pubspec.replaceFirst(
          RegExp(r'name:\s*\S+'),
          'name: $packageName',
        );
        await pubspecFile.writeAsString(pubspec);
        print('✅ pubspec.yaml name updated → $packageName');
      }
    }
  }

  // ── 1b. Patch Android app label ─────────────────────────────────────
  if (appName != null) {
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

    // iOS: Info.plist CFBundleDisplayName
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

  // ── 2. Fetch favicon ─────────────────────────────────────────────────
  await Directory('assets/icon').create(recursive: true);
  const iconPath = 'assets/icon/icon.png';

  bool iconSaved = false;

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
    try {
      print('🌐 Trying HTML favicon discovery…');
      final pageResp = await http.get(uri).timeout(const Duration(seconds: 10));
      if (pageResp.statusCode == 200) {
        final html = pageResp.body;
        final iconLinks = RegExp(r"""<link[^>]*rel=['"]([^'"]*icon[^'"]*)['"
][^>]*href=['"]([^'"]+)['"]""", caseSensitive: false).allMatches(html);

        for (final match in iconLinks) {
          var href = match.group(2)!;
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

  // ── 3. Regenerate launcher icons ─────────────────────────────────────
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

Future<String?> _promptForAppName() async {
  stdout.write('📛 Enter app name: ');
  final input = stdin.readLineSync()?.trim();

  if (input == null || input.isEmpty) {
    stderr.writeln('Cancelled: No app name provided');
    return null;
  }

  return input;
}

Future<void> _updateAppName(String appName) async {
  print('📛 Updating app name → $appName');

  var packageName = appName
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');

  const reservedNames = {
    'flutter',
    'flutter_test',
    'flutter_lints',
    'flutter_launcher_icons',
    'webview_flutter',
    'webview_flutter_android',
    'webview_flutter_wkwebview',
    'cupertino_icons',
    'http',
  };

  if (reservedNames.contains(packageName)) {
    packageName += '_app';
    print('ℹ️  Reserved name detected, renaming to: $packageName');
  }

  if (packageName.isEmpty) {
    stderr.writeln('Invalid app name format');
    exit(1);
  }

  print('   Dart package name → $packageName');

  // ── 1. Update pubspec.yaml ──────────────────────────────────────────
  final pubspecFile = File('pubspec.yaml');
  if (!await pubspecFile.exists()) {
    stderr.writeln(
      'pubspec.yaml not found. Run this script from the project root.',
    );
    exit(1);
  }

  var pubspec = await pubspecFile.readAsString();
  pubspec = pubspec.replaceFirst(RegExp(r'name:\s*\S+'), 'name: $packageName');
  await pubspecFile.writeAsString(pubspec);
  print('✅ pubspec.yaml name updated');

  // ── 2. Update lib/main.dart ─────────────────────────────────────────
  final mainFile = File('lib/main.dart');
  if (await mainFile.exists()) {
    var source = await mainFile.readAsString();
    final namePattern = RegExp(r"const String kAppName = '.*?';");
    if (namePattern.hasMatch(source)) {
      source = source.replaceFirst(
        namePattern,
        "const String kAppName = '$appName';",
      );
      await mainFile.writeAsString(source);
      print('✅ lib/main.dart kAppName updated');
    }
  }

  // ── 3. Update Android app label ─────────────────────────────────────
  final manifestFile = File('android/app/src/main/AndroidManifest.xml');
  if (await manifestFile.exists()) {
    var manifest = await manifestFile.readAsString();
    manifest = manifest.replaceFirst(
      RegExp(r'android:label="[^"]*"'),
      'android:label="$appName"',
    );
    await manifestFile.writeAsString(manifest);
    print('✅ Android app label updated');
  }

  // ── 4. Update iOS app name ──────────────────────────────────────────
  final plistFile = File('ios/Runner/Info.plist');
  if (await plistFile.exists()) {
    var plist = await plistFile.readAsString();
    plist = plist.replaceFirst(
      RegExp(r'(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)'),
      '\${1}$appName\${2}',
    );
    await plistFile.writeAsString(plist);
    print('✅ iOS CFBundleDisplayName updated');
  }

  print('\n✨ App name updated successfully!');
}

Future<String?> _promptForPackageId() async {
  stdout.write('📦 Enter package ID (e.g., com.example.app): ');
  final input = stdin.readLineSync()?.trim();

  if (input == null || input.isEmpty) {
    stderr.writeln('Cancelled: No package ID provided');
    return null;
  }

  // Validate package ID format
  if (!RegExp(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)*$').hasMatch(input)) {
    stderr.writeln(
      'Invalid package ID format. Use lowercase letters, numbers, and dots (e.g., com.example.app)',
    );
    return null;
  }

  return input;
}

Future<void> _updatePackageId(String packageId) async {
  print('📦 Updating package ID → $packageId');

  // ── Update Android package ID ───────────────────────────────────────
  final androidBuildFile = File('android/app/build.gradle.kts');
  if (await androidBuildFile.exists()) {
    var androidBuild = await androidBuildFile.readAsString();
    androidBuild = androidBuild.replaceFirst(
      RegExp(r'applicationId\s*=\s*"[^"]+"'),
      'applicationId = "$packageId"',
    );
    await androidBuildFile.writeAsString(androidBuild);
    print('✅ Android applicationId updated');
  }

  // ── Update iOS package ID ───────────────────────────────────────────
  final iosPbxprojFile = File('ios/Runner.xcodeproj/project.pbxproj');
  if (await iosPbxprojFile.exists()) {
    var pbxproj = await iosPbxprojFile.readAsString();
    pbxproj = pbxproj.replaceAll(
      RegExp(r'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*[^;]+;'),
      'PRODUCT_BUNDLE_IDENTIFIER = $packageId;',
    );
    await iosPbxprojFile.writeAsString(pbxproj);
    print('✅ iOS PRODUCT_BUNDLE_IDENTIFIER updated');
  }

  print('\n✨ Package ID updated successfully!');
  print('   Note: You may need to clean the build folder:');
  print('   flutter clean');
}

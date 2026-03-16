import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:flutter/foundation.dart';

// ─8─8─8─8─8─8─8─8─8─8─8─8─8─8─8─8─8─8─8─8─8─8─8─8─8─8─8─8─8─8─8─8─8─8─8─8─8─8─8─8─8─8─8
//  CONFIGURE YOUR URL HERE
//  Or run:  dart run scripts/set_url.dart https://example.com
// ─*─*─*─*─*─*─*─*─*─*─*─*─*─*─*─*─*─*─*─*─*─*─*─*─*─*─*─*─*─*─*─*─*─*─*─*─*─*─*─*─*─*─*
const String kHomeUrl = 'https://flutter.dev';
// ─────────────────────────────────────────────

// if you bore i am recommending a good anime to watch "Link click" very interesting anime about a guy who can enter photos and experience the moment when the photo was taken, it has 12 episodes and is very emotional and has a good story, i really recommend it to everyone who loves anime with good story and emotional moments

//  APP LAUNCHER NAME — shown under the icon on the home screen
const String kAppName = 'Flutter';
// ─────────────────────────────────────────────

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Register the correct WebView platform implementation for Android and iOS
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      WebViewPlatform.instance = AndroidWebViewPlatform();
      break;
    case TargetPlatform.iOS:
      WebViewPlatform.instance = WebKitWebViewPlatform();
      break;
    default:
      break;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const WebAppShell(),
    );
  }
}

class WebAppShell extends StatefulWidget {
  const WebAppShell({super.key});

  @override
  State<WebAppShell> createState() => _WebAppShellState();
}

class _WebAppShellState extends State<WebAppShell> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _currentUrl = kHomeUrl;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              _currentUrl = url;
              _errorMessage = null;
            });
          },
          onPageFinished: (url) {
            setState(() {
              _isLoading = false;
              _currentUrl = url;
            });
          },
          onWebResourceError: (error) {
            setState(() {
              _isLoading = false;
              _errorMessage = error.description;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(kHomeUrl));
  }

  /// Returns true if [url] is considered the "home" — i.e. it points to the
  /// same origin root as [kHomeUrl] (with or without trailing slash).
  bool _isHomePage(String url) {
    try {
      final home = Uri.parse(kHomeUrl);
      final current = Uri.parse(url);

      // Same scheme + host + port?
      if (home.scheme != current.scheme) return false;
      if (home.host != current.host) return false;
      if (home.port != current.port) return false;

      // The home URL's path defines the "root" for this app.
      // Normalise by stripping trailing slashes.
      String normHome = home.path.replaceAll(RegExp(r'/+$'), '');
      String normCurrent = current.path.replaceAll(RegExp(r'/+$'), '');
      if (normHome.isEmpty) normHome = '';
      if (normCurrent.isEmpty) normCurrent = '';

      return normHome == normCurrent;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _onWillPop() async {
    // If we can go back in webview history → go back.
    if (await _controller.canGoBack()) {
      // But only if going back doesn't take us *off* the home page.
      // We let the WebView go back; if the resulting page is home and the
      // user presses back again, we'll then show the exit dialog.
      _controller.goBack();
      return false; // don't pop the Flutter route
    }

    // We're at the top of the webview history.
    // If current page is (or is below) home → prompt exit.
    if (_isHomePage(_currentUrl)) {
      return await _showExitDialog();
    }

    // Somehow at top of history but not on home (e.g. navigated away with
    // JS replace). Load home instead of exiting.
    _controller.loadRequest(Uri.parse(kHomeUrl));
    return false;
  }

  Future<bool> _showExitDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit App?'),
        content: const Text('Do you want to exit the application?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldExit = await _onWillPop();
        if (shouldExit && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              if (_errorMessage != null)
                _ErrorView(
                  message: _errorMessage!,
                  onRetry: () {
                    setState(() => _errorMessage = null);
                    _controller.reload();
                  },
                )
              else
                WebViewWidget(controller: _controller),
              if (_isLoading)
                const LinearProgressIndicator(
                  minHeight: 3,
                  backgroundColor: Colors.transparent,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Could not load page',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'home_screen.dart';
import 'services/backend_discovery.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const ChipLensApp());
}

class ChipLensApp extends StatefulWidget {
  const ChipLensApp({super.key});

  @override
  State<ChipLensApp> createState() => _ChipLensAppState();
}

class _ChipLensAppState extends State<ChipLensApp> {
  // Runs once — discovers the backend IP before showing the home screen.
  // Times out after 4 s so the app always launches even on slow networks.
  late final Future<void> _discovery = BackendDiscovery.discover()
      .timeout(const Duration(seconds: 4), onTimeout: () => null)
      .then((_) {});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, _) => MaterialApp(
        title: 'ChipLens',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        home: FutureBuilder<void>(
          future: _discovery,
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const _SplashScreen();
            }
            return const HomeScreen();
          },
        ),
      ),
    );
  }
}

// ── Splash shown while discovery runs (typically < 1 s on the same WiFi) ──────

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppShadows.glow(AppColors.primary),
              ),
              child: const Icon(
                Icons.memory_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'ChipLens',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Locating backend…',
              style: TextStyle(color: context.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 180,
              child: LinearProgressIndicator(
                borderRadius: BorderRadius.circular(4),
                backgroundColor: context.border,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

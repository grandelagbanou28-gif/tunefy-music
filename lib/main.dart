import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:muzo/l10n/app_languages.dart';
import 'package:muzo/l10n/app_localizations.dart';
import 'package:muzo/screens/home_screen.dart';
import 'package:muzo/screens/auth_screen.dart';
import 'package:muzo/services/storage_service.dart';
import 'package:muzo/services/navigator_key.dart';
import 'package:muzo/services/notification_service.dart';

import 'package:muzo/widgets/main_layout.dart';
import 'package:muzo/providers/theme_provider.dart';
import 'package:muzo/providers/settings_provider.dart';
import 'package:muzo/services/auth_service.dart';
import 'package:muzo/providers/auth_gate_provider.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:muzo/services/artist_database_service.dart';
import 'package:muzo/services/strict_category_filter.dart';

final List<Locale> _appSupportedLocales = supportedLanguages.map((l) {
  if (l.code.contains('_')) {
    final parts = l.code.split('_');
    return Locale(parts[0], parts.length > 1 ? parts[1] : null);
  }
  return Locale(l.code);
}).toList();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch all framework errors instead of showing grey screen
  FlutterError.onError = (details) {
    debugPrint('FlutterError: ${details.exceptionAsString()}');
    FlutterError.presentError(details);
  };

  // Catch all async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PlatformDispatcher error: $error');
    return true;
  };

  // Replace grey ErrorWidget with a safe black fallback
  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint('ErrorWidget: ${details.exceptionAsString()}');
    return Material(
      color: Colors.black,
      child: Center(
        child: Text(
          'Something went wrong',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ),
    );
  };

  // Set system UI overlay style for transparent nav bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarColor: Colors.transparent,
    ),
  );

  // Enable edge-to-edge
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final container = ProviderContainer();

  // Parallelize initialization. Skipping web-incompatible plugins on the web
  // (just_audio_background / flutter_local_notifications have no web support);
  // each future is guarded so one failure never blocks the app from starting.
  final initFutures = <Future<void>>[
    _safeInitializer(container.read(storageServiceProvider).init()),
  ];
  if (!kIsWeb) {
    initFutures.addAll([
      _safeInitializer(JustAudioBackground.init(
        androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
        androidNotificationChannelName: 'Audio playback',
        androidNotificationOngoing: true,
        androidNotificationIcon: 'drawable/ic_notification',
      )),
      _safeInitializer(NotificationService().init()),
    ]);
  }
  await Future.wait(initFutures);

  // Initialize artist database and set global reference for strict_category_filter
  try {
    final artistDbService = await container.read(artistDatabaseServiceProvider.future);
    setArtistDatabaseService(artistDbService);
  } catch (e) {
    debugPrint('Artist database init failed (using fallback): $e');
  }

  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
}

Future<void> _safeInitializer(Future<void> future) async {
  try {
    await future;
  } catch (e) {
    debugPrint('Init warning (non-fatal): $e');
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final themeType = ref.watch(settingsProvider).themeType;
        final platformBrightness = MediaQuery.platformBrightnessOf(context);
        final effectiveBrightness = themeType == ThemeType.auto
            ? platformBrightness
            : (themeType == ThemeType.light ? Brightness.light : Brightness.dark);
        final selectedDynamic = effectiveBrightness == Brightness.light ? lightDynamic : darkDynamic;
        
        // Use Future.microtask to avoid set during build error
        Future.microtask(() {
          if (ref.read(dynamicColorSchemeProvider) != selectedDynamic) {
            ref.read(dynamicColorSchemeProvider.notifier).state = selectedDynamic;
          }
        });

        final theme = ref.watch(themeProvider);
        final locale = ref.watch(localeProvider);

        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Tunefy',
          debugShowCheckedModeBanner: false,
          theme: theme,
          locale: locale,
          supportedLocales: _appSupportedLocales,
          localizationsDelegates: appLocalizationsDelegates,
          // No builder wrapping here — MainLayout is only applied inside AuthGate
          // for authenticated / guest sessions. This prevents the navbar and
          // mini player from ever rendering on top of the auth screen.
          home: const AuthGate(),
        );
      },
    );
  }
}

/// Reactive gate that decides whether to show the auth screen or the main app.
///
/// - Authenticated user  → [MainLayout] wrapping [HomeScreen]
/// - Guest mode active   → [MainLayout] wrapping [HomeScreen]
/// - Unauthenticated     → [AuthScreen] (standalone, no navbar/miniplayer)
///
/// Using a dedicated widget (instead of MaterialApp.builder) ensures
/// [MainLayout] is only ever instantiated once per session and is never
/// accidentally wrapped around [AuthScreen].
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(authServiceProvider).isAuthenticated;
    final isGuest = ref.watch(isGuestModeProvider);

    if (isAuthenticated || isGuest) {
      return const MainLayout(
        key: ValueKey('main_layout_shell'),
        child: HomeScreen(),
      );
    }

    return const AuthScreen();
  }
}

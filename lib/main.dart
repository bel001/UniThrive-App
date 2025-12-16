import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme.dart';
import 'state/app_state.dart';
import 'screens/root/root_shell.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  await NotificationService.initialize();
  final appState = AppState();
  await appState.initialize();

  // Global Error Handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // Here you could log to a service like Sentry or Crashlytics
    debugPrint('Flutter Error: ${details.exception}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Async Error: $error');
    return true;
  };

  runApp(AppStateProvider(appState: appState, child: const UniThriveApp()));
}

class UniThriveApp extends StatelessWidget {
  const UniThriveApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        return MaterialApp(
          title: 'UniThrive',
          debugShowCheckedModeBanner: false,
          theme: UniThriveTheme.light,
          darkTheme: UniThriveTheme.dark,
          themeMode: appState.themeMode,
          builder: (context, child) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(appState.textScale),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: appState.hasCompletedOnboarding
                ? const RootShell(key: ValueKey('root-shell'))
                : const WelcomeScreen(key: ValueKey('welcome-screen')),
          ),
        );
      },
    );
  }
}

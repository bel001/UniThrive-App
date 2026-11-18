import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme.dart';
import 'state/app_state.dart';
import 'screens/root/root_shell.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'services/crash_log_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  // No bloquea: servicios pesados inicializan dentro de AppState.initialize diferido
  await NotificationService.initialize();
  final appState = AppState();
  // Arranca UI inmediato con skeleton, carga diferida
  CrashLogService.install();
  runApp(AppStateProvider(appState: appState, child: const UniThriveApp()));
  // Inicialización asíncrona tras primer frame
  unawaited(appState.initialize());
}

void unawaited(Future<void> f) {}

class UniThriveApp extends StatelessWidget {
  const UniThriveApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        if (!appState.isInitialized) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: UniThriveTheme.light,
            darkTheme: UniThriveTheme.dark,
            themeMode: appState.themeMode,
            home: const Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Cargando UniThrive...'),
                  ],
                ),
              ),
            ),
          );
        }
        return MaterialApp(
          title: 'UniThrive',
          debugShowCheckedModeBanner: false,
          theme: UniThriveTheme.light,
          darkTheme: UniThriveTheme.dark,
          themeMode: appState.themeMode,
          builder: (context, child) {
            final media = MediaQuery.of(context);
            final systemScale = media.textScaler.scale(16) / 16;
            return MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(systemScale * appState.textScale),
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

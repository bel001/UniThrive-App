# AGENTS.md — UniThrive-App

App Flutter (Material 3, paquete `uni_thrive`, SDK Dart `^3.9.2`) offline-first para estudiantes: tareas/proyectos, horario por dictado de voz **100% local**, calendario, alarmas, foco/Pomodoro y gamificación con mascota. UI y tests **en español**. Plataformas: `android/`, `linux/`, `web/` (sin ios/macos/windows). Sin backend.

## Comandos (verificados)

```bash
flutter pub get
flutter analyze   # limpio en 2026-09-06; config: flutter_lints ^5, excluye packages/**
flutter test      # solo flutter_test, sin mocks externos
flutter test test/voice_task_parser_test.dart   # un archivo
flutter build apk --debug   # salida: build/app/outputs/flutter-apk/
```

Tras cada cambio: `flutter analyze` + `flutter test`.

## Arquitectura

- Estado hand-rolled, sin provider/riverpod/bloc: `AppState extends ChangeNotifier` (`lib/state/app_state.dart`) compone 5 sub-estados (`settings`, `user`, `gamification`, `data`, `alarms`), reenvía sus `notifyListeners` y delega getters/métodos (fachada). Inyección vía `AppStateProvider.of(context)` (`InheritedWidget` al final de `app_state.dart`); `main.dart` reconstruye con `AnimatedBuilder` y arranca con skeleton: `runApp(...)` primero, `unawaited(appState.initialize())` después — no volver bloqueante el `initialize()`.
- **Regla crítica**: toda mutación de estado termina en `_persist()`. Persistencia = un blob JSON bajo key `'unithrive_state_v2'` en SharedPreferences (`lib/services/app_state_repository.dart`, escrituras serializadas en `_writeQueue`). Export/import total reemplaza todo (con confirmación). Multi-perfil = snapshots JSON dentro del mismo blob.
- Efectos junto a la mutación: programar/cancelar notificaciones y `AlarmService.reconcile()` ocurren en el mismo método del estado (p.ej. `addScheduleBlock`, `toggleTask`). IDs vía `AppState._nextId()` (timestamp+random).
- Servicios (`lib/services/`): `alarm_service` (paquete `alarm`, ids nativos deterministas hash FNV-1a, ventana 30 días), `notification_service`, `permission_service`, `calendar_sync_service` (exporta `.ics`), `smart_planner` + `mascot_service` + `support_coach_service` (lógica pura, testeable), `voice_task_capture_service` (wrapper `speech_to_text`) + `voice_task_parser` / `voice_schedule_parser` (regex/NLP español → drafts editables), `crash_log_service` (log local rotado a 64 KB). Los servicios nunca importan estado ni UI.
- Voz sin red: no hay `voice_ai_parse_service` ni proxy (eliminados del árbol). Degradación por plataforma en `lib/utils/platform_capabilities.dart`: voz, alarmas nativas y notificaciones solo en móvil (`isMobile`); en web/linux mostrar aviso, no llamar al plugin.

## Convenciones

- Idioma del archivo que se edita; no introducir paquetes de estado sin consultar; servicios estáticos salvo repositorio; `// ignore:` puntual, nunca desactivar lints globalmente.
- UI por feature en `lib/screens/<feature>/` (root: `root_shell.dart`, 4 tabs en `IndexedStack`); reutilizables prefijados `Uni*` en `lib/widgets/`; componentes supervisuales compartidos en `lib/widgets/uni_supervisual.dart` (`UniRingProgress`, `UniGradientMetricCard`, `UniMiniBarChart`). Tema en `lib/core/theme.dart` + tokens en `lib/core/design_tokens.dart`; lenguaje "Vivid Academic": fuente Lexend empaquetada en `assets/fonts/` (offline-first, no usar google_fonts por red), primario índigo (`#4F46E5`/`#6366F1`, profundo `#2A2090`), menta `#49FFBD`/`#08E1A2`, lila `#C3C0FF`, radios 24px, botones chunky con borde inferior 4px (`UniPrimaryButton`, `DesignTokens.pressableDepth`), barras con gloss (`ProgressBar`). Fondo oscuro `#13131B`, cards `#1C1C26`; claro adaptado (`#F8F9FA`, cards blancas con borde índigo pálido). Mockups de referencia en `../EJEMPLOVISTAS/` (fuera del repo); escala de texto vía `MediaQuery.textScaler` en `main.dart` (respetarla, no hardcodear tamaños fijos que la rompan; los tests `responsive_views_test.dart` fallan con overflows — toda fila con texto en `Row` necesita `Flexible`+ellipsis).
- Adjuntos en dir privado (`attachments/`), borrar archivo al borrar la tarea (`AttachmentPicker.deleteStoredFile`).

## Notas operativas

- `dependency_overrides` apunta `flutter_native_timezone_updated_gradle` al fork vendoreado en `packages/` (fix Gradle); no tocar sin motivo.
- Assets declarados en `pubspec.yaml`: `assets/icon/app_icon.png`, `assets/mascot/`, `assets/alarm/` (iconos launcher vía `flutter_launcher_icons`).
- `docs/SYSTEM_DESIGN.md` está desactualizado: aún describe el proxy IA (`tools/openai_voice_proxy.py`, puerto 8787) y `voice_ai_parse_service`, ambos eliminados. Ante conflicto, manda el código (`lib/services/`, `lib/widgets/voice_*_sheet.dart`).

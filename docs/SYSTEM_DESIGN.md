# UniThrive — System Design

> Documento de arquitectura y diseño del sistema. Última actualización: 2026-08.

## 1. Visión general

UniThrive es una app **offline-first** para estudiantes universitarios: tareas, proyectos,
horario por dictado de voz (con mejora opcional vía IA), calendario, alarmas, modo foco
(Pomodoro), gamificación y mascota virtual. Todo el estado vive en el dispositivo; no hay
backend propio. El único componente externo opcional es un **proxy HTTP** que habla con la
API de OpenAI para refinar dictados complejos, manteniendo la API key fuera de la app.

| Aspecto | Decisión |
|---|---|
| Plataforma | Flutter 3.41+ / Dart ^3.9.2 (Android primero; linux/web presentes) |
| Estado | Hand-rolled `ChangeNotifier` + `InheritedWidget` (sin provider/riverpod/bloc) |
| Persistencia | SharedPreferences: un blob JSON versionado (`unithrive_state_v2`) |
| Idioma | UI y tests en español |
| Backend | Ninguno. Proxy IA opcional (`tools/openai_voice_proxy.py`, puerto 8787) |

## 2. Arquitectura por capas

```
┌───────────────────────────────────────────────────────────────┐
│                            UI                                 │
│  lib/screens/<feature>/   lib/widgets/Uni*   lib/core/theme   │
│  (root_shell · dashboard · calendar · projects · tasks ·      │
│   focus · alarms · stats · supervisual · achievements ·       │
│   profile · settings · notifications · onboarding)            │
└──────────────▲────────────────────────────▲───────────────────┘
               │ AppStateProvider.of(ctx)   │ modelos inmutables
┌──────────────┴────────────────────────────┴───────────────────┐
│                        ESTADO (lib/state/)                    │
│                AppState extends ChangeNotifier                │
│   ┌─────────┬──────────┬──────────────┬────────┬──────────┐   │
│   │settings │  user    │ gamification │  data  │  alarms  │   │
│   └─────────┴──────────┴──────────────┴────────┴──────────┘   │
│   AppState reenvía los notifyListeners de sus hijos → UI      │
└──────────────▲────────────────────────────▲───────────────────┘
               │ _persist() tras mutación   │ wrappers estáticos
┌──────────────┴────────────────────────────┴───────────────────┐
│                     SERVICIOS (lib/services/)                 │
│  app_state_repository (persistencia)                          │
│  alarm_service · notification_service · permission_service    │
│  voice_task_capture · voice_task_parser · voice_schedule_…    │
│  voice_ai_parse_service ──HTTP──▶ tools/openai_voice_proxy    │
│  smart_planner · mascot_service · support_coach_service       │
│  calendar_sync_service (.ics) · crash_log_service             │
└───────────────────────────────────────────────────────────────┘
```

### Reglas de dependencia (unidireccionales)

- `UI → State → Services`. Los servicios nunca importan estado ni UI.
- Los servicios son **estáticos o singletons sin ciclo de vida** salvo repositorio.
- La lógica pura (parsers, planner, insights, mascota) vive en funciones/clases sin I/O
  → testeable con `flutter_test` puro.

## 3. Diseño de estado

### 3.1 AppState como fachada

`AppState` compone cinco sub-estados y reenvía sus notificaciones:

| Sub-estado | Responsabilidad |
|---|---|
| `SettingsState` | tema, escala de texto, recordatorios, sonido alarma/Pomodoro, config IA de voz |
| `UserState` | onboarding, perfil activo, multi-perfil con snapshots |
| `GamificationState` | XP, nivel, logros, rachas, ánimo de mascota |
| `DataState` | proyectos, tareas (+subtareas, adjuntos, pomodoros), bloques de horario, sesiones de foco |
| `AlarmState` | AlarmSchedules + mapeo a ids nativos + snooze |

Patrones clave:

- **Fachada**: getters/métodos delegan a los hijos para mantener estable la API pública.
- **Persistencia explícita**: toda mutación termina en `_persist()`; las escrituras se
  serializan en una cola de futures (`AppStateRepository._writeQueue`).
- **Efectos secundarios junto a la mutación**: programar/cancelar notificaciones y
  reconciliar alarmas ocurre en el mismo método del estado (p.ej. `addScheduleBlock`,
  `toggleTask`, `deleteTask`).
- **IDs**: `AppState._nextId()` = timestamp + random.
- **Multi-perfil**: snapshots JSON por perfil dentro del mismo blob (`_profileSnapshots`).

### 3.2 Inyección

```dart
runApp(AppStateProvider(appState, child: UniThriveApp()));
// acceso:
final appState = AppStateProvider.of(context);
```

`main.dart` reconstruye el `MaterialApp` con `AnimatedBuilder(animation: appState)`.

### 3.3 Modelo de datos (resumen)

```
Project 1─* Task 1─* Subtask
              ├─* PomodoroSession
              └─* attachments[]        (rutas locales o enlaces)
ScheduleBlock (recurrence: none/daily/weekly/monthly/yearly/custom,
               recurrenceInterval, recurrenceEndDate, customWeekDays[])
FocusSession  ·  AlarmSchedule  ·  Achievement  ·  MascotState
ProfileSnapshot (por cada perfil además del activo)
```

Todos los modelos exponen `toJson/fromJson`; el blob completo se exporta/importa vía
`exportToJson()` / `importFromJson()`.

## 4. Flujos principales

### 4.1 Dictado de voz (tarea u horario)

```
Mic ▶ speech_to_text ▶ transcript
      ├─▶ Parser local NLP español (voice_task_parser / voice_schedule_parser)
      │     ├─ Normalización de números escritos ("ocho" → 8, "dieciocho" → 18)
      │     ├─ Corrección fuzzy de días (STT errors: "marque" → martes, "juebes" → jueves)
      │     ├─ Extracción tolerante de horarios ("de las ocho a las diez", "2 a 4 de la tarde")
      │     ├─ Múltiples patrones de título ("mi clase de X", "tengo X los lunes", título antes de día)
      │     ├─ Ubicación extendida ("aula", "salón", "edificio", "laboratorio", "bloque")
      │     └─▶ VoiceTaskDraft / VoiceScheduleDraft (editable, con notas de lo inferido)
      └─▶ [opcional] voice_ai_parse_service ─HTTP▶ proxy :8787 ─OpenAI─▶ JSON estricto
                 (config endpoint+token en Ajustes; nunca viaja una API key)
Draft confirmado ─▶ AppState.addTask / addScheduleBlock ─▶ _persist + recordatorios
```

Degradación: sin red/sin proxy se usa siempre el parser local; en plataformas sin voz
(`PlatformCapabilities.supportsVoiceInput == false`) los accesos muestran un aviso.

### 4.2 Alarmas nativas

```
AlarmSchedule ─▶ AlarmService.reconcile()
   ├─ detiene ids nativos previos
   ├─ expande ocurrencias (ventana 30 días)
   └─ Alarm.set(AlarmSettings(id=nativeIdFor(...), assetAudioPath=…))
Snooze/omitir/pausar mutan el schedule ─▶ reconcile de nuevo.
```

Los ids nativos se recalculan de forma determinista (hash FNV-1a de id+fecha+salt).

### 4.3 Gamificación

Completar tarea / sesión de foco / Pomodoro → `addXP()` → nivel + logros + racha →
`MascotService` mapea estado → ánimo de mascota (assets PNG + animaciones).

### 4.4 Crash reporting local

`CrashLogService.install()` engancha `FlutterError.onError` y
`PlatformDispatcher.onError` → escribe en `<docs>/logs/crash_log.txt`
(rotación simple a 64 KB). Sin dependencias externas.

## 5. Pantallas

Navegación raíz: 4 tabs en `IndexedStack` (`RootShell`): Inicio, Calendario, Proyectos,
Perfil. El resto se apila con `SoftPageRoute`.

| Ruta/pantalla | Contenido |
|---|---|
| `dashboard_screen` | resumen del día con anillo de progreso, accesos rápidos, carruseles Hoy/Próximo, pull-to-refresh real |
| **`supervisual_screen`** | **panel supervisual premium: header con gradiente decorativo, banner motivacional contextual (adapta mensaje al progreso/racha), anillo del día, métricas en gradiente (racha, nivel, foco), gráfica semanal, próxima clase/tarea con tiempo relativo ("en 2h"), acciones rápidas** |
| `calendar_screen` | semana/mes, franja "carga de la semana", recurrencia con intervalo N, conflictos, .ics, auto-plan |
| `projects_screen` / `project_detail` | grid/lista, overview en gradiente con anillo de avance global, checklist reordenable, generar plan |
| `task_detail` | subtareas, adjuntos múltiples, Pomodoro, recordatorios |
| `focus_session/focus_timer` | preparación → temporizador con anillo configurable 25'/5' |
| `alarm_screen` | alarmas exactas, snooze, pausar, sonido por alarma |
| `statistics_screen` | héroe con anillo de completado + histórico Semana/Mes × Tareas/Foco |
| `achievements_screen` | logros con rareza y progreso |
| `profile_screen` / `settings_screen` | preferencias, anillo de nivel, multi-perfil, export/import JSON, IA de voz |

### Lenguaje visual compartido ("supervisual")

Los componentes visuales viven en `lib/widgets/uni_supervisual.dart` y se reutilizan
en todas las vistas principales:

- `UniRingProgress`: anillo circular de progreso (Inicio, Calendario no aplica, Proyectos,
  Perfil, Estadísticas, Supervisual).
- `UniGradientMetricCard`: tarjetas métricas con gradiente (Supervisual; gradientes
  reutilizables `fireGradient`, `purpleGradient`, `greenGradient`).
- `UniMiniBarChart`: mini gráfica de barras (Supervisual: tareas/semana;
  Calendario: carga de bloques/día).

## 6. Decisiones de diseño y trade-offs

| Decisión | Razón | Trade-off aceptado |
|---|---|---|
| Blob JSON único en SharedPreferences | simplicidad, export/import trivial | escalable hasta ~miles de tareas; migración = nueva key (`v2`) |
| ChangeNotifier manual | cero dependencias, control total | boilerplate de fachada; sin granularidad fina de rebuilds |
| Efectos (notificaciones/alarmas) en el estado | imposible olvidar re-programar | estado acoplado a plugins; mitigado con guards de plataforma |
| Parsers locales antes que IA | funciona offline y gratis | precisión menor en frases complejas; IA opcional detrás de proxy |
| Proxy para IA (no key en app) | seguridad | requiere correr un servicio propio |
| Sin backend/cloud sync | privacidad total, costo 0 | backup manual; sincronización entre dispositivos pendiente |

## 7. Seguridad

- API key de OpenAI **nunca** en la app: solo URL+token del proxy configurables.
- Adjuntos copiados a directorio privado de la app (`<docs>/attachments/`); limpieza
  al borrar la tarea (`AttachmentPicker.deleteStoredFile`).
- Borrado destructivo (perfil, datos totales) siempre con confirmación.
- Import de datos reemplaza todo tras diálogo explícito.

## 8. Observabilidad y calidad

- `flutter analyze` (flutter_lints ^5) y `flutter test` tras cada cambio.
- Tests unitarios de parsers/planner/serialización + widget tests de vistas críticas.
- Crash log local revisable en dispositivo.

## 9. Roadmap técnico sugerido

1. Sincronización cifrada opcional (cuenta o WebDAV) sobre `exportToJson`.
2. Migrar persistencia a SQLite si el blob supera ~1 MB.
3. Gráficas más ricas (fl_chart) y objetivos semanales.
4. Notificaciones accionables (completar desde la notificación).
5. i18n formal (arb) partiendo de los strings centralizados.

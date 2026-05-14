# UniThrive - Tu Compañero Universitario Inteligente 🎓🚀

UniThrive es una aplicación móvil diseñada específicamente para estudiantes universitarios que buscan organizar su vida académica con estilo, eficiencia y tecnología de vanguardia.

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-v3.22+-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-v3.0+-0175C2?logo=dart)

## ✨ Características Principales

### 🎙️ Dictado Inteligente por Voz
Olvida escribir largos horarios. Con UniThrive puedes dictar tus clases y tareas de forma natural:
- *"Clase de Física los lunes y miércoles de 8 a 10 am en el aula B203"*
- El sistema procesa la frase, identifica días, horas y ubicación automáticamente.
- Opción de mejora mediante IA para una precisión superior.

### 📅 Calendario Premium
- **Vistas Flexibles:** Cambia instantáneamente entre vista Semanal y Mensual con transiciones fluidas.
- **Control Segmentado:** Interfaz moderna para filtrar información.
- **Acceso Rápido:** Botón "Hoy" para volver al presente con un toque.

### 📂 Gestión de Proyectos y Tareas
- **Vistas Personalizadas:** Elige entre lista detallada o cuadrícula (Grid) para visualizar tus proyectos.
- **Gestos Táctiles:** Desliza para completar tareas o eliminar proyectos con animaciones suaves.
- **Seguimiento de Progreso:** Barras de progreso visuales y estadísticas por proyecto.

### 🎯 Enfoque y Gamificación
- **Modo Foco:** Temporizador integrado para sesiones de estudio productivas.
- **Logros:** Sistema de medallas y logros por completar tareas y mantener rachas.
- **Estadísticas:** Visualiza tu rendimiento académico con gráficos intuitivos.

## 🎨 Diseño Visual (UX/UI)
UniThrive utiliza una estética **Premium Dark Mode** con:
- **Glassmorphism:** Efectos de desenfoque y transparencia en barras de navegación.
- **Micro-animaciones:** Transiciones suaves de 60fps usando `AnimatedSwitcher` y `AnimatedContainer`.
- **Paleta de Colores Curada:** Tonos esmeralda y violeta para una experiencia visual relajante y moderna.

## 🚀 Instalación y Desarrollo

### Requisitos
- Flutter SDK (v3.22 o superior)
- Dart SDK (v3.0 o superior)
- Android Studio / VS Code

### Configuración local
1. Clona el repositorio:
   ```bash
   git clone https://github.com/bel001/UniThrive-App.git
   ```
2. Obtén las dependencias:
   ```bash
   flutter pub get
   ```
3. Ejecuta la aplicación:
   ```bash
   flutter run
   ```

## 📱 Generar APK para celular
Para generar una versión instalable en cualquier dispositivo Android (5.0+):
```bash
flutter build apk --debug
```
El archivo se encontrará en: `build/app/outputs/flutter-apk/app-debug.apk`

---
Desarrollado con ❤️ para mejorar la productividad universitaria.

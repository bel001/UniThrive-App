import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../widgets/uni_primary_button.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      _HeroIllustration(size: 220),
                      const SizedBox(height: 32),
                      Text(
                        '¡Hola! 🌟\nBienvenido a UniThrive',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: 30,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aquí convertimos metas enormes en pasos pequeños. Respira, organiza y deja que la app te acompañe a tu ritmo.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _nameController,
                        onChanged: (_) {
                          if (_error != null) setState(() => _error = null);
                        },
                        decoration: InputDecoration(
                          labelText: 'Ingresa tu nombre',
                          hintText: 'Ej. Sofía',
                          errorText: _error,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),
                      UniPrimaryButton(
                        label: '¡Crear mi espacio de estudio!',
                        onPressed: () {
                          final name = _nameController.text.trim();
                          if (name.isEmpty) {
                            setState(
                              () => _error =
                                  'Necesitamos tu nombre para personalizar tu experiencia',
                            );
                            return;
                          }
                          appState.updateUserProfile(name);
                          appState.completeOnboarding();
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Promesa UniThrive: enfocarte sólo en avanzar, nosotros nos ocupamos del resto.',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HeroIllustration extends StatelessWidget {
  final double size;
  const _HeroIllustration({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF9FCFBB), Color(0xFF7FB5A0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9FCFBB).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Center(child: Text('🦉', style: TextStyle(fontSize: 100))),
    );
  }
}

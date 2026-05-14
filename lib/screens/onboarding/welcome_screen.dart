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
              padding: const EdgeInsets.fromLTRB(28, 18, 28, 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 46,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 22),
                    Center(child: _WelcomeOrb(theme: theme)),
                    const SizedBox(height: 32),
                    Text(
                      'Estudia con foco,\nsin ruido.',
                      style: theme.textTheme.displayLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'UniThrive organiza tu día, protege tu energía y convierte metas grandes en pasos claros.',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Antes de empezar',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '¿Cómo quieres que te llamemos dentro de la app?',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 18),
                          TextField(
                            controller: _nameController,
                            onChanged: (_) {
                              if (_error != null) setState(() => _error = null);
                            },
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              labelText: 'Tu nombre',
                              hintText: 'Ej. Sofía',
                              errorText: _error,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),
                    UniPrimaryButton(
                      label: 'Continuar',
                      onPressed: () {
                        final name = _nameController.text.trim();
                        if (name.isEmpty) {
                          setState(
                            () => _error =
                                'Necesitamos tu nombre para personalizar tu espacio.',
                          );
                          return;
                        }
                        appState.updateUserProfile(name);
                        appState.completeOnboarding();
                      },
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Todo queda guardado localmente en tu dispositivo.',
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WelcomeOrb extends StatelessWidget {
  final ThemeData theme;

  const _WelcomeOrb({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.surfaceContainerHighest,
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 142,
            height: 142,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow.withValues(
                alpha: 0.82,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.16),
              ),
            ),
          ),
          ClipOval(
            child: Image.asset(
              'assets/mascot/mascot_happy.png',
              width: 128,
              height: 128,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                Icons.auto_awesome_rounded,
                size: 58,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Positioned(
            bottom: 26,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Text(
                'Organiza. Respira. Avanza.',
                style: theme.textTheme.labelMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

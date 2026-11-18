import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../state/app_state.dart';
import '../../../widgets/uni_primary_button.dart';
import '../../../widgets/project_card.dart';
import '../../../core/design_tokens.dart';
import '../../../models/project.dart';

/// Paleta del mockup "Nuevo Proyecto" (Vivid Academic Night).
const _projectColors = <Color>[
  Color(0xFFFF5E5B),
  Color(0xFFFFB347),
  Color(0xFFFFDE59),
  Color(0xFF00E676),
  Color(0xFF00B4D8),
  Color(0xFF9D4EDD),
  Color(0xFFFF70A6),
];

Future<void> showProjectCreationSheet({
  required BuildContext context,
  required AppState appState,
}) async {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final objectiveControllers = <TextEditingController>[
    TextEditingController(),
    TextEditingController(),
  ];
  final objectiveDone = <bool>[false, false];
  DateTime? dueDate;
  int selectedColor = 0;
  ProjectType selectedType = ProjectType.general;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (modalContext) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withValues(alpha: 0.92),
            ),
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
            ),
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                final theme = Theme.of(context);
                final isDark = theme.brightness == Brightness.dark;
                final fieldBg = isDark
                    ? DesignTokens.cardDarkAlt
                    : theme.colorScheme.surfaceContainer;
                final cardBg = isDark
                    ? DesignTokens.cardDark
                    : theme.colorScheme.surfaceContainerLow;
                final muted = theme.colorScheme.onSurfaceVariant;
                final accent = isDark
                    ? DesignTokens.lilac
                    : theme.colorScheme.primary;
                final fieldBorder = isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : DesignTokens.divider;

                InputDecoration fieldDecoration(String hint) {
                  return InputDecoration(
                    hintText: hint,
                    filled: true,
                    fillColor: fieldBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusMedium,
                      ),
                      borderSide: BorderSide(color: fieldBorder, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusMedium,
                      ),
                      borderSide: BorderSide(color: fieldBorder, width: 2),
                    ),
                  );
                }

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header glass + close.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Nuevo Proyecto',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: fieldBg,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                color: muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Nombre.
                      Text(
                        'Nombre del Proyecto',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: nameController,
                        style: theme.textTheme.bodyLarge,
                        decoration: fieldDecoration(
                          'Ej. Investigación de Biología',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Descripción.
                      RichText(
                        text: TextSpan(
                          style: theme.textTheme.titleSmall,
                          children: [
                            const TextSpan(text: 'Descripción '),
                            TextSpan(
                              text: '(Opcional)',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        minLines: 2,
                        style: theme.textTheme.bodyMedium,
                        decoration: fieldDecoration(
                          '¿De qué trata este proyecto?',
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Color del proyecto: 7 dots.
                      Text(
                        'Color del Proyecto',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 56,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _projectColors.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: 16),
                          itemBuilder: (context, index) {
                            final selected = selectedColor == index;
                            return GestureDetector(
                              onTap: () => setSheetState(
                                () => selectedColor = index,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _projectColors[index],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selected
                                        ? theme.colorScheme.onSurface
                                        : Colors.transparent,
                                    width: 4,
                                  ),
                                  boxShadow: selected
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.3,
                                            ),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : [],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tipo de proyecto: chips con icono.
                      Text(
                        'Tipo de Proyecto',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          itemCount: ProjectType.values.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final type = ProjectType.values[index];
                            final selected = selectedType == type;
                            return ChoiceChip(
                              label: Text(_typeLabel(type)),
                              avatar: Icon(
                                ProjectCard.iconForType(type),
                                size: 18,
                              ),
                              selected: selected,
                              onSelected: (_) => setSheetState(
                                () => selectedType = type,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Fecha de entrega: card con chevron.
                      Text(
                        'Fecha de Entrega',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: dueDate ??
                                DateTime.now().add(
                                  const Duration(days: 7),
                                ),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setSheetState(() => dueDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(
                              DesignTokens.radiusLarge,
                            ),
                            border: Border.all(
                              color: fieldBorder,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.20,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.calendar_today_outlined,
                                  color: accent,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dueDate == null
                                          ? 'Sin fecha de entrega'
                                          : DateFormat.yMMMMd(
                                              'es',
                                            ).format(dueDate!),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleSmall,
                                    ),
                                    Text(
                                      'Toca para seleccionar',
                                      style: theme.textTheme.labelSmall,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: muted,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Objetivos iniciales editables inline.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Objetivos Iniciales',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => setSheetState(() {
                              objectiveControllers.add(
                                TextEditingController(),
                              );
                              objectiveDone.add(false);
                            }),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Agregar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: [
                          for (
                            var i = 0;
                            i < objectiveControllers.length;
                            i++
                          )
                            Padding(
                              padding: EdgeInsets.only(
                                bottom:
                                    i == objectiveControllers.length - 1
                                        ? 0
                                        : 12,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(
                                    DesignTokens.radiusMedium,
                                  ),
                                  border: Border.all(
                                    color: fieldBorder,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: objectiveDone[i],
                                      onChanged: (value) => setSheetState(
                                        () => objectiveDone[i] =
                                            value ?? false,
                                      ),
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller:
                                            objectiveControllers[i],
                                        style: theme.textTheme.bodyMedium,
                                        decoration: const InputDecoration(
                                          hintText:
                                              'Ej. Recopilar fuentes bibliográficas',
                                          border: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                    if (objectiveControllers.length > 1)
                                      IconButton(
                                        icon: Icon(
                                          Icons.close_rounded,
                                          color: muted,
                                        ),
                                        tooltip: 'Quitar objetivo',
                                        onPressed: () => setSheetState(() {
                                          objectiveControllers.removeAt(i);
                                          objectiveDone.removeAt(i);
                                        }),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // CTA flotante chunky compartido.
                      UniPrimaryButton(
                        label: 'Crear Proyecto',
                        onPressed: () {
                          if (nameController.text.trim().isEmpty ||
                              dueDate == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Completa nombre y fecha de entrega.',
                                ),
                              ),
                            );
                            return;
                          }
                          final objectives = objectiveControllers
                              .map((c) => c.text.trim())
                              .where((text) => text.isNotEmpty)
                              .toList();
                          final tag = objectives.length <= 4
                              ? 'Pequeño'
                              : objectives.length <= 6
                                  ? 'Mediano'
                                  : 'Grande';
                          final description =
                              descriptionController.text.trim().isEmpty
                                  ? 'Proyecto ${tag.toLowerCase()} creado con IA'
                                  : descriptionController.text.trim();
                          final project = appState.addProject(
                            name: nameController.text.trim(),
                            dueDate: dueDate!,
                            color: _projectColors[selectedColor],
                            tag: tag,
                            type: selectedType,
                            autoPlan: objectives.isEmpty,
                            description: description,
                          );
                          for (final objective in objectives) {
                            appState.addTask(
                              projectId: project.id,
                              title: objective,
                              dueDate: dueDate,
                              silent: true,
                            );
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                objectives.isEmpty
                                    ? 'Plan inteligente generado con IA.'
                                    : 'Proyecto creado con ${objectives.length} objetivo(s).',
                              ),
                            ),
                          );
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    },
  );
}

String _typeLabel(ProjectType type) => switch (type) {
      ProjectType.essay => 'Ensayo',
      ProjectType.presentation => 'Presentación',
      ProjectType.development => 'Desarrollo',
      ProjectType.study => 'Estudio',
      ProjectType.creative => 'Creativo',
      ProjectType.general => 'General',
    };

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../state/app_state.dart';
import '../../../widgets/uni_primary_button.dart';
import '../../../models/project.dart';

Future<void> showProjectCreationSheet({
  required BuildContext context,
  required AppState appState,
}) async {
  final nameController = TextEditingController();
  DateTime? dueDate;
  final sizes = ['Pequeño', 'Mediano', 'Grande'];
  int selectedSize = 0;
  ProjectType selectedType = ProjectType.general;
  final sizeColors = [
    const Color(0xFF42C57A),
    const Color(0xFF9FCFBB),
    const Color(0xFFFF5A5F),
  ];

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
              color: Theme.of(context).cardColor.withValues(alpha: 0.85),
            ),
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
            ),
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Text(
                          'Nuevo Proyecto Inteligente',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.info_outline,
                          color: Colors.grey,
                        ),
                        onPressed: () => _showAIInfo(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      hintText: 'Ej. Ensayo de historia moderna',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(
                          const Duration(days: 7),
                        ),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setSheetState(() => dueDate = picked);
                      }
                    },
                    child: Container(
                      height: 62,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              dueDate == null
                                  ? 'Selecciona una fecha'
                                  : DateFormat.yMMMMd('es').format(dueDate!),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.calendar_month_outlined,
                            color: Color(0xFF9FCFBB),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Tipo de proyecto',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _TypeChip(
                        label: 'Ensayo',
                        icon: Icons.article_outlined,
                        selected: selectedType == ProjectType.essay,
                        onTap: () => setSheetState(
                          () => selectedType = ProjectType.essay,
                        ),
                      ),
                      _TypeChip(
                        label: 'Presentación',
                        icon: Icons.slideshow_outlined,
                        selected: selectedType == ProjectType.presentation,
                        onTap: () => setSheetState(
                          () => selectedType = ProjectType.presentation,
                        ),
                      ),
                      _TypeChip(
                        label: 'Desarrollo',
                        icon: Icons.code_outlined,
                        selected: selectedType == ProjectType.development,
                        onTap: () => setSheetState(
                          () => selectedType = ProjectType.development,
                        ),
                      ),
                      _TypeChip(
                        label: 'Estudio',
                        icon: Icons.school_outlined,
                        selected: selectedType == ProjectType.study,
                        onTap: () => setSheetState(
                          () => selectedType = ProjectType.study,
                        ),
                      ),
                      _TypeChip(
                        label: 'Creativo',
                        icon: Icons.palette_outlined,
                        selected: selectedType == ProjectType.creative,
                        onTap: () => setSheetState(
                          () => selectedType = ProjectType.creative,
                        ),
                      ),
                      _TypeChip(
                        label: 'General',
                        icon: Icons.folder_outlined,
                        selected: selectedType == ProjectType.general,
                        onTap: () => setSheetState(
                          () => selectedType = ProjectType.general,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Tamaño del proyecto',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 320;
                      final cards = List.generate(sizes.length, (index) {
                        final active = selectedSize == index;
                        final card = GestureDetector(
                          onTap: () =>
                              setSheetState(() => selectedSize = index),
                          child: Container(
                            height: 90,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: active
                                    ? sizeColors[index]
                                    : const Color(0xFFE2E8F0),
                              ),
                              color: active
                                  ? sizeColors[index].withValues(alpha: 0.12)
                                  : const Color(0xFFF8F8FC),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _sizeIcon(index),
                                  color: sizeColors[index],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  sizes[index],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: sizeColors[index],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );

                        if (compact) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == sizes.length - 1 ? 0 : 12,
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: card,
                            ),
                          );
                        }

                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: index == sizes.length - 1 ? 0 : 12,
                            ),
                            child: card,
                          ),
                        );
                      });

                      if (compact) {
                        return Column(children: cards);
                      }

                      return Row(children: cards);
                    },
                  ),
                  const SizedBox(height: 24),
                  UniPrimaryButton(
                    backgroundColor: Colors.red,
                    label: '✨ Crear Mi Plan Inteligente',
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
                      appState.addProject(
                        name: nameController.text.trim(),
                        dueDate: dueDate!,
                        color: sizeColors[selectedSize],
                        tag: sizes[selectedSize],
                        autoPlan: true,
                        type: selectedType,
                        description:
                            'Proyecto ${sizes[selectedSize].toLowerCase()} creado con IA',
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Plan inteligente generado con IA.'),
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
      )));
    },
  );
}

IconData _sizeIcon(int index) {
  switch (index) {
    case 0:
      return Icons.spa_outlined;
    case 1:
      return Icons.eco_outlined;
    default:
      return Icons.park_outlined;
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF6C63FF) : Colors.grey.shade600;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF6C63FF).withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF6C63FF) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showAIInfo(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('¿Cómo funciona nuestra IA?'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Nuestra IA es real y funciona sobre una base de planificación por reglas inteligentes, que es nuestro punto de partida. No es una 'caja negra' incomprensible.",
                style: TextStyle(height: 1.5),
              ),
              SizedBox(height: 12),
              Text(
                "En la versión actual, el motor realiza tres tareas clave:",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                "• Analiza la disponibilidad del usuario basándose en el horario que nos proporciona.",
              ),
              SizedBox(height: 4),
              Text(
                "• Desglosa el proyecto en 'micro-tareas' según la dificultad que el usuario estima.",
              ),
              SizedBox(height: 4),
              Text(
                "• Y lo más importante, asigna esas tareas de forma equilibrada en el tiempo para evitar la acumulación y el estrés.",
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      );
    },
  );
}

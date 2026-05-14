import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/schedule.dart';
import '../models/task.dart';
import '../screens/projects/project_detail_screen.dart';
import '../screens/tasks/task_detail_screen.dart';
import '../state/app_state.dart';
import 'empty_state_widget.dart';
import 'soft_page_route.dart';

Future<void> showGlobalSearchSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _GlobalSearchSheet(),
  );
}

class _GlobalSearchSheet extends StatefulWidget {
  const _GlobalSearchSheet();

  @override
  State<_GlobalSearchSheet> createState() => _GlobalSearchSheetState();
}

class _GlobalSearchSheetState extends State<_GlobalSearchSheet> {
  late final TextEditingController _controller;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final theme = Theme.of(context);
    final query = _normalize(_query);
    final projects = appState.projects.where((project) {
      if (query.isEmpty) return true;
      return _matches(query, project.name) ||
          _matches(query, project.description);
    }).toList();
    final tasks =
        appState.allTasks.where((task) {
          if (query.isEmpty) return true;
          final projectName = appState.projectById(task.projectId)?.name ?? '';
          return _matches(query, task.title) ||
              _matches(query, task.description ?? '') ||
              _matches(query, projectName) ||
              task.labels.any((label) => _matches(query, label));
        }).toList()..sort((a, b) {
          if (a.completed != b.completed) return a.completed ? 1 : -1;
          final aDate = a.dueDate ?? DateTime(2100);
          final bDate = b.dueDate ?? DateTime(2100);
          return aDate.compareTo(bDate);
        });
    final blocks = appState.scheduleBlocks.where((block) {
      if (query.isEmpty) return true;
      return _matches(query, block.title) || _matches(query, block.location);
    }).toList()..sort((a, b) => a.start.compareTo(b.start));

    final hasResults =
        projects.isNotEmpty || tasks.isNotEmpty || blocks.isNotEmpty;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.85),
          ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Buscar tareas, cursos o clases',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: !hasResults
                  ? EmptyStates.noSearch(context)
                  : ListView(
                      children: [
                        if (tasks.isNotEmpty) ...[
                          _SectionTitle(title: 'Tareas'),
                          const SizedBox(height: 8),
                          ...tasks
                              .take(8)
                              .map(
                                (task) => _SearchTile(
                                  icon: task.completed
                                      ? Icons.task_alt_rounded
                                      : Icons.checklist_rtl_rounded,
                                  title: task.title,
                                  subtitle: _taskSubtitle(appState, task),
                                  accent: task.isOverdue
                                      ? theme.colorScheme.error
                                      : theme.colorScheme.primary,
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    Navigator.of(context).push(
                                      SoftPageRoute(
                                        builder: (_) =>
                                            TaskDetailScreen(task: task),
                                      ),
                                    );
                                  },
                                ),
                              ),
                          const SizedBox(height: 18),
                        ],
                        if (projects.isNotEmpty) ...[
                          _SectionTitle(title: 'Proyectos'),
                          const SizedBox(height: 8),
                          ...projects
                              .take(6)
                              .map(
                                (project) => _SearchTile(
                                  icon: Icons.folder_copy_rounded,
                                  title: project.name,
                                  subtitle: project.description.isEmpty
                                      ? 'Entrega ${DateFormat('d MMM', 'es').format(project.dueDate)}'
                                      : project.description,
                                  accent: project.color,
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    Navigator.of(context).push(
                                      SoftPageRoute(
                                        builder: (_) => ProjectDetailScreen(
                                          project: project,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                          const SizedBox(height: 18),
                        ],
                        if (blocks.isNotEmpty) ...[
                          _SectionTitle(title: 'Clases y bloques'),
                          const SizedBox(height: 8),
                          ...blocks
                              .take(8)
                              .map(
                                (block) => _SearchTile(
                                  icon: Icons.calendar_month_rounded,
                                  title: block.title,
                                  subtitle:
                                      '${DateFormat('EEE d MMM · HH:mm', 'es').format(block.start)}${block.location.isEmpty ? '' : ' · ${block.location}'}',
                                  accent: block.color,
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    _showScheduleDetail(context, block);
                                  },
                                ),
                              ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    )));
  }

  String _taskSubtitle(AppState appState, Task task) {
    final projectName =
        appState.projectById(task.projectId)?.name ?? 'Tarea rápida';
    final due = task.dueDate == null
        ? 'Sin fecha'
        : DateFormat('d MMM · HH:mm', 'es').format(task.dueDate!);
    return '$projectName · $due';
  }

  bool _matches(String query, String value) =>
      _normalize(value).contains(query);

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll('ñ', 'n');
  }

  void _showScheduleDetail(BuildContext context, ScheduleBlock block) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(block.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(DateFormat('EEEE d MMMM · HH:mm', 'es').format(block.start)),
              if (block.location.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(block.location),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _SearchTile extends StatelessWidget {
  const _SearchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: accent),
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

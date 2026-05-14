import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import '../../models/project.dart';
import '../../state/app_state.dart';
import '../../widgets/project_card.dart';
import '../../widgets/soft_page_route.dart';
import '../../widgets/uni_primary_button.dart';
import '../projects/project_detail_screen.dart';
import 'widgets/project_creation_sheet.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  int _selectedTab = 0;
  bool _isGridView = true;

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final theme = Theme.of(context);
    final activeProjects = appState.activeProjects;
    final completedProjects = appState.completedProjects;
    final projects = _selectedTab == 0 ? activeProjects : completedProjects;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.screenHorizontal,
            12,
            DesignTokens.screenHorizontal,
            132,
          ),
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 460;
                final summary = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Proyectos', style: theme.textTheme.displayLarge),
                        IconButton(
                          onPressed: () => setState(() => _isGridView = !_isGridView),
                          icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
                          tooltip: _isGridView ? 'Ver como lista' : 'Ver como cuadrícula',
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Mantén tus entregas claras, ordenadas y visibles.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                );
                final action = SizedBox(
                  width: compact ? double.infinity : 146,
                  child: UniPrimaryButton(
                    label: 'Agregar',
                    icon: Icons.add_rounded,
                    onPressed: () => showProjectCreationSheet(
                      context: context,
                      appState: appState,
                    ),
                  ),
                );

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [summary, const SizedBox(height: 16), action],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: summary),
                    const SizedBox(width: 16),
                    action,
                  ],
                );
              },
            ),
            const SizedBox(height: 22),
            _ProjectsOverview(
              activeCount: activeProjects.length,
              completedCount: completedProjects.length,
            ),
            const SizedBox(height: 18),
            _SegmentedProjectsTabs(
              selectedIndex: _selectedTab,
              onChanged: (index) => setState(() => _selectedTab = index),
              activeCount: activeProjects.length,
              completedCount: completedProjects.length,
            ),
            const SizedBox(height: 22),
            if (projects.isEmpty)
              _ProjectsEmptyState(selectedTab: _selectedTab)
            else if (_isGridView)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.65,
                ),
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  final project = projects[index];
                  return ProjectCard(
                    project: project,
                    onTap: () => Navigator.of(context).push(
                      SoftPageRoute(
                        builder: (_) => ProjectDetailScreen(project: project),
                      ),
                    ),
                    onDelete: () => _confirmDeleteProject(context, appState, project),
                  );
                },
              )
            else
              ...projects.map(
                (project) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: ProjectCard(
                    project: project,
                    onTap: () => Navigator.of(context).push(
                      SoftPageRoute(
                        builder: (_) => ProjectDetailScreen(project: project),
                      ),
                    ),
                    onDelete: () =>
                        _confirmDeleteProject(context, appState, project),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteProject(
    BuildContext context,
    AppState appState,
    Project project,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar proyecto'),
          content: Text(
            '¿Seguro que deseas borrar "${project.name}" y todos sus pasos?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      appState.removeProject(project.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Proyecto "${project.name}" eliminado.')),
        );
      }
    }
  }
}

class _ProjectsOverview extends StatelessWidget {
  final int activeCount;
  final int completedCount;

  const _ProjectsOverview({
    required this.activeCount,
    required this.completedCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 340;
          if (compact) {
            return Column(
              children: [
                _OverviewMetric(
                  label: 'En curso',
                  value: '$activeCount',
                  accentColor: theme.colorScheme.primary,
                  tone: theme.colorScheme.primaryContainer,
                ),
                const SizedBox(height: 12),
                _OverviewMetric(
                  label: 'Completados',
                  value: '$completedCount',
                  accentColor: theme.colorScheme.onSurface,
                  tone: theme.colorScheme.surfaceContainerHighest,
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: _OverviewMetric(
                  label: 'En curso',
                  value: '$activeCount',
                  accentColor: theme.colorScheme.primary,
                  tone: theme.colorScheme.primaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OverviewMetric(
                  label: 'Completados',
                  value: '$completedCount',
                  accentColor: theme.colorScheme.onSurface,
                  tone: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;
  final Color tone;

  const _OverviewMetric({
    required this.label,
    required this.value,
    required this.accentColor,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(color: accentColor),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(color: accentColor),
          ),
        ],
      ),
    );
  }
}

class _SegmentedProjectsTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final int activeCount;
  final int completedCount;

  const _SegmentedProjectsTabs({
    required this.selectedIndex,
    required this.onChanged,
    required this.activeCount,
    required this.completedCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = ['En curso ($activeCount)', 'Completados ($completedCount)'];

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;
          final children = List.generate(labels.length, (index) {
            final isSelected = index == selectedIndex;
            final tab = GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.surfaceContainerLow
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      labels[index],
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            );

            if (compact) return tab;
            return Expanded(child: tab);
          });

          if (compact) {
            return Column(
              children: [children[0], const SizedBox(height: 8), children[1]],
            );
          }

          return Row(children: children);
        },
      ),
    );
  }
}

class _ProjectsEmptyState extends StatelessWidget {
  final int selectedTab;

  const _ProjectsEmptyState({required this.selectedTab});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = selectedTab == 0
        ? 'Todavía no tienes proyectos activos.'
        : 'Aún no has cerrado ningún proyecto.';
    final subtitle = selectedTab == 0
        ? 'Crea uno nuevo y convierte una meta grande en pasos manejables.'
        : 'Cuando completes uno, aparecerá aquí como historial ordenado.';

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                selectedTab == 0
                    ? Icons.folder_open_rounded
                    : Icons.task_alt_rounded,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

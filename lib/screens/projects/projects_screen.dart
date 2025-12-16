import 'package:flutter/material.dart';
import '../../models/project.dart';
import '../../state/app_state.dart';
import '../../widgets/project_card.dart';
import '../../widgets/soft_page_route.dart';
import '../projects/project_detail_screen.dart';
import 'widgets/project_creation_sheet.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final projects = _selectedTab == 0
        ? appState.activeProjects
        : appState.completedProjects;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Proyectos')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTabSelector(theme),
            const SizedBox(height: 16),
            Expanded(
              child: projects.isEmpty
                  ? Center(
                      child: Text(
                        'No hay proyectos aquí todavía. Pulsa “Agregar” para comenzar.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : ListView.builder(
                      itemCount: projects.length,
                      itemBuilder: (context, index) {
                        final project = projects[index];
                        return ProjectCard(
                          project: project,
                          onTap: () => Navigator.of(context).push(
                            SoftPageRoute(
                              builder: (_) =>
                                  ProjectDetailScreen(project: project),
                            ),
                          ),
                          onDelete: () =>
                              _confirmDeleteProject(context, appState, project),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 130), // Avoid bottom nav bar
        child: FloatingActionButton.extended(
          onPressed: () =>
              showProjectCreationSheet(context: context, appState: appState),
          label: const Text('Agregar'),
          icon: const Icon(Icons.add),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildTabSelector(ThemeData theme) {
    final labels = ['En curso', 'Completados'];
    final isDark = theme.brightness == Brightness.dark;
    return Row(
      children: List.generate(labels.length, (index) {
        final isActive = _selectedTab == index;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedTab = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(
                right: index == labels.length - 1 ? 0 : 10,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF9FCFBB)
                    : (isDark
                          ? const Color(0xFF1E2236)
                          : const Color(0xFFF4F4FB)),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  labels[index],
                  style: TextStyle(
                    color: isActive
                        ? Colors.white
                        : (isDark ? Colors.white70 : const Color(0xFF475569)),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
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

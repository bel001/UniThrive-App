import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import 'package:flutter/services.dart';
import '../../models/task.dart';
import '../../widgets/mascot_widget.dart';
import '../../widgets/quick_task_form.dart';
import '../../widgets/soft_page_route.dart';

import '../achievements/achievements_screen.dart';
import '../tasks/task_detail_screen.dart';
import '../../core/design_tokens.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);

    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: appState,
          builder: (context, _) {
            final todayTasks = _getTodayTasks(appState);
            final completedToday = todayTasks.where((t) => t.completed).length;
            final totalToday = todayTasks.length;
            final overdueTasks = _getOverdueTasks(appState);

            return Stack(
              children: [
                RefreshIndicator(
                  onRefresh: () async {
                    await Future.delayed(const Duration(milliseconds: 600));
                  },
                  color: const Color.fromARGB(255, 159, 207, 187),
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      // 1. Header
                      SliverToBoxAdapter(
                        child: _buildMinimalistHeader(context, appState),
                      ),

                      // 2. Daily Progress Card (Hero)
                      SliverToBoxAdapter(
                        child: _buildDailyProgressCard(
                          context,
                          appState,
                          completedToday,
                          totalToday,
                        ),
                      ),

                      // 3. Overdue Alert (New Independent Widget)
                      if (overdueTasks.isNotEmpty)
                        SliverToBoxAdapter(
                          child: _buildOverdueAlert(
                            context,
                            appState,
                            overdueTasks,
                          ),
                        ),

                      // 3.5 Quick overview of today and próximas
                      SliverToBoxAdapter(
                        child: _buildQuickTodayPreview(context, appState),
                      ),

                      // Bottom spacing
                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMinimalistHeader(BuildContext context, AppState appState) {
    final theme = Theme.of(context);
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? '¡Buenos días!'
        : hour < 19
        ? '¡Buenas tardes!'
        : '¡Buenas noches!';

    return Padding(
      padding: EdgeInsets.all(DesignTokens.screenHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Mascot avatar
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/mascot/mascot_happy.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: theme.colorScheme.primary,
                          child: const Center(
                            child: Text('🦉', style: TextStyle(fontSize: 24)),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(width: DesignTokens.itemGap),

              // Streak
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(
                      '${appState.streakDays}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.orange,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Level badge
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  SoftPageRoute(builder: (_) => const AchievementsScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusLarge,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Nv ${appState.level}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.cardPadding),
          // Improved greeting hierarchy
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hola, ${appState.userName.isNotEmpty ? appState.userName.split(' ').first : 'Usuario'}',
                      style: TextStyle(
                        fontSize: 16,
                        color: DesignTokens.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      greeting,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Persistent Add Task Button (replaces FAB)
              ElevatedButton.icon(
                onPressed: () => showQuickTaskForm(context),
                icon: const Icon(Icons.add, size: 20),
                label: const Text(
                  'Nueva',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9FCFBB),
                  foregroundColor: DesignTokens.textPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusMedium,
                    ),
                  ),
                  elevation: DesignTokens.cardElevation,
                  minimumSize: const Size(
                    0,
                    48,
                  ), // Fix: Override global infinite width
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyProgressCard(
    BuildContext context,
    AppState appState,
    int completed,
    int total,
  ) {
    final progress = total > 0 ? completed / total : 0.0;

    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9FCFBB), Color(0xFF7FB5A0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9FCFBB).withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mascot
                MascotWidget(
                  state: appState.mascotState,
                  size: 80,
                  showMessage: false,
                ),
                const SizedBox(width: 16),

                // Message and progress
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appState.mascotState.message.isEmpty
                            ? '¡Hola, ${appState.userName}!'
                            : appState.mascotState.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Progress bar
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: FractionallySizedBox(
                          widthFactor: progress.clamp(0.0, 1.0),
                          alignment: Alignment.centerLeft,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        total > 0
                            ? '$completed de $total tareas'
                            : 'Sin tareas para hoy',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTodayPreview(BuildContext context, AppState appState) {
    final todayTasks = _getTodayTasks(appState).take(3).toList();
    final nextTasks = _getUpcomingTasks(appState).take(3).toList();
    final theme = Theme.of(context);

    Widget buildTile(Task task) {
      final project = appState.projectById(task.projectId);
      final xp = task.energy == EnergyLevel.high
          ? 25
          : (task.energy == EnergyLevel.medium ? 15 : 10);
      final energyCount = task.energy == EnergyLevel.high
          ? 3
          : (task.energy == EnergyLevel.medium ? 2 : 1);

      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Checkbox(
          value: task.completed,
          onChanged: (_) => appState.toggleTask(task.id),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                // XP Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 10)),
                      const SizedBox(width: 2),
                      Text(
                        '+$xp XP',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFF9900),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Energy Stars
                ...List.generate(
                  3,
                  (index) => Icon(
                    index < energyCount ? Icons.bolt : Icons.bolt_outlined,
                    size: 14,
                    color: index < energyCount
                        ? const Color(0xFFFF6B35)
                        : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            project?.name ?? 'Tarea rápida',
            style: theme.textTheme.bodySmall,
          ),
        ),
        trailing: Text(task.dueLabel, style: theme.textTheme.bodySmall),
        onTap: () => _showTaskDetail(context, task),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.screenHorizontal,
        8,
        DesignTokens.screenHorizontal,
        16,
      ),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.flash_on, color: Color(0xFF9FCFBB)),
                  const SizedBox(width: 8),
                  Text(
                    'Tareas rápidas de hoy',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (todayTasks.isEmpty)
                Text(
                  'No hay pendientes hoy. ¡Crea una tarea rápida!',
                  style: theme.textTheme.bodyMedium,
                )
              else
                ...todayTasks.map(
                  (task) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: buildTile(task),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showTasksSheet(
                        context,
                        appState: appState,
                        title: 'Tareas de hoy',
                        tasks: _getTodayTasks(appState),
                      ),
                      child: const Text('Ver más de hoy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showTasksSheet(
                        context,
                        appState: appState,
                        title: 'Próximas tareas',
                        tasks: _getUpcomingTasks(appState),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9FCFBB),
                        foregroundColor: DesignTokens.textPrimary,
                      ),
                      child: const Text('Ver próximas'),
                    ),
                  ),
                ],
              ),
              if (nextTasks.isNotEmpty) ...[
                const Divider(height: 24),
                Text(
                  'Próximas 24-72h',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ...nextTasks.map(
                  (task) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: buildTile(task),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Task> _getTodayTasks(AppState appState) {
    final today = DateTime.now();
    return appState.allTasks.where((task) {
      if (task.dueDate == null) return false;
      final dueDate = task.dueDate!;
      return dueDate.year == today.year &&
          dueDate.month == today.month &&
          dueDate.day == today.day;
    }).toList()..sort((a, b) {
      if (a.completed != b.completed) {
        return a.completed ? 1 : -1;
      }
      return (a.dueDate ?? DateTime.now()).compareTo(
        b.dueDate ?? DateTime.now(),
      );
    });
  }

  void _showTaskDetail(BuildContext context, Task task) {
    Navigator.of(
      context,
    ).push(SoftPageRoute(builder: (_) => TaskDetailScreen(task: task)));
  }

  Widget _buildOverdueAlert(
    BuildContext context,
    AppState appState,
    List<Task> overdueTasks,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.screenHorizontal,
        8,
        DesignTokens.screenHorizontal,
        12,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showOverdueTasks(context, appState),
            borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange.shade800,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Atención necesaria',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${overdueTasks.length} Tarea${overdueTasks.length != 1 ? 's' : ''} Faltante${overdueTasks.length != 1 ? 's' : ''}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: const Color(0xFF0F172A),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.orange.shade400,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Task> _getOverdueTasks(AppState appState) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return appState.allTasks
        .where(
          (task) =>
              !task.completed &&
              task.dueDate != null &&
              DateTime(
                task.dueDate!.year,
                task.dueDate!.month,
                task.dueDate!.day,
              ).isBefore(today),
        )
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
  }

  List<Task> _getUpcomingTasks(AppState appState) {
    final now = DateTime.now();
    final horizon = now.add(const Duration(days: 3));
    return appState.allTasks
        .where(
          (task) =>
              !task.completed &&
              task.dueDate != null &&
              task.dueDate!.isAfter(now) &&
              task.dueDate!.isBefore(horizon),
        )
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
  }

  Future<void> _showTasksSheet(
    BuildContext context, {
    required AppState appState,
    required String title,
    required List<Task> tasks,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            padding: EdgeInsets.only(
              top: 16,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.view_list_rounded),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (tasks.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text('Sin tareas para mostrar.'),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        final project = appState.projectById(task.projectId);
                        return ListTile(
                          leading: Checkbox(
                            value: task.completed,
                            onChanged: (_) {
                              appState.toggleTask(task.id);
                              setSheetState(() {}); // Refresh sheet
                            },
                          ),
                          title: Text(
                            task.title,
                            style: TextStyle(
                              decoration: task.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          subtitle: Text(project?.name ?? 'Tarea'),
                          trailing: Text(task.dueLabel),
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            _showTaskDetail(context, task);
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showOverdueTasks(BuildContext context, AppState appState) {
    final messenger = ScaffoldMessenger.of(context);
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // We need to keep track of tasks that are animating out
          // This set should be persistent across rebuilds of the modal content
          // However, StatefulBuilder rebuilds its child, but the state is preserved
          // if we define the variable outside? No, StatefulBuilder doesn't hold state like that.
          // We need a way to store this state.
          // Actually, since we are inside a function, we can't easily persist state
          // across rebuilds triggered by appState changes if we re-fetch overdueTasks.
          // But wait, we only trigger rebuilds via setModalState or appState listeners.

          // To properly handle animations, we might need a local StatefulWidget wrapper
          // instead of just StatefulBuilder if we want complex state.
          // But for simple "animate then delete", we can do:

          return _OverdueTasksModalContent(
            appState: appState,
            messenger: messenger,
          );
        },
      ),
    );
  }
}

class _OverdueTasksModalContent extends StatefulWidget {
  final AppState appState;
  final ScaffoldMessengerState messenger;
  const _OverdueTasksModalContent({
    required this.appState,
    required this.messenger,
  });

  @override
  State<_OverdueTasksModalContent> createState() =>
      _OverdueTasksModalContentState();
}

class _OverdueTasksModalContentState extends State<_OverdueTasksModalContent> {
  List<Task> _getOverdueTasks(AppState appState) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return appState.allTasks
        .where(
          (task) =>
              !task.completed &&
              task.dueDate != null &&
              DateTime(
                task.dueDate!.year,
                task.dueDate!.month,
                task.dueDate!.day,
              ).isBefore(today),
        )
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
  }

  @override
  Widget build(BuildContext context) {
    final overdueTasks = _getOverdueTasks(widget.appState);
    final totalOverdue = overdueTasks.length;

    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade700,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Tareas Faltantes',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (totalOverdue > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    '$totalOverdue',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Marca o reprograma para limpiar las tareas atrasadas.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          if (overdueTasks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('¡No hay tareas faltantes! 🎉')),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: overdueTasks.length,
              itemBuilder: (itemContext, index) {
                final task = overdueTasks[index];

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    key: ValueKey('overdue-${task.id}'),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    leading: Checkbox(
                      checkColor: Colors.black,
                      fillColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.greenAccent.shade200;
                        }
                        return Colors.white24;
                      }),
                      side: const BorderSide(color: Colors.white54),
                      value: task.completed,
                      onChanged: (_) async {
                        HapticFeedback.lightImpact();
                        final navigator = Navigator.of(context);

                        // Immediately toggle the task
                        widget.appState.toggleTask(task.id);

                        // Show feedback
                        widget.messenger.showSnackBar(
                          SnackBar(
                            content: Text('¡Completaste "${task.title}"!'),
                            duration: const Duration(seconds: 2),
                          ),
                        );

                        // Small delay for visual feedback
                        await Future.delayed(const Duration(milliseconds: 150));

                        // Check if we should close
                        if (mounted &&
                            _getOverdueTasks(widget.appState).isEmpty) {
                          navigator.pop();
                        }
                      },
                    ),
                    title: Text(
                      task.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        decoration: task.completed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: Text(
                      'Vencida: ${task.dueDate!.day}/${task.dueDate!.month}',
                      style: TextStyle(color: Colors.orange.shade700),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.schedule),
                      tooltip: 'Reprogramar',
                      onPressed: () async {
                        HapticFeedback.selectionClick();
                        final messenger = widget.messenger;
                        final navigator = Navigator.of(context);

                        final newDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );

                        if (!mounted) return;
                        if (newDate == null) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Reprogramación cancelada'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }

                        // Immediately update the task
                        widget.appState.updateTask(
                          taskId: task.id,
                          dueDate: newDate,
                        );

                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Tarea reprogramada para ${newDate.day}/${newDate.month}/${newDate.year}',
                            ),
                            duration: const Duration(seconds: 3),
                          ),
                        );

                        // Small delay for visual feedback
                        await Future.delayed(const Duration(milliseconds: 150));

                        // Check if we should close
                        if (mounted &&
                            _getOverdueTasks(widget.appState).isEmpty) {
                          navigator.pop();
                        }
                      },
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

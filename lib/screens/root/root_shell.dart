import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../calendar/calendar_screen.dart';
import '../home/dashboard_screen.dart';
import '../profile/profile_screen.dart';
import '../projects/projects_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _selectedIndex = 0;

  late final List<Widget> _screens = const [
    DashboardScreen(key: ValueKey('screen-dashboard')),
    CalendarScreen(key: ValueKey('screen-calendar')),
    ProjectsScreen(key: ValueKey('screen-projects')),
    ProfileScreen(key: ValueKey('screen-profile')),
  ];

  static const _items = <_RootItem>[
    _RootItem(label: 'Inicio', icon: Icons.home_filled),
    _RootItem(label: 'Calendario', icon: Icons.calendar_month_rounded),
    _RootItem(label: 'Proyectos', icon: Icons.folder_copy_rounded),
    _RootItem(label: 'Perfil', icon: Icons.person_rounded),
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: 82,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow.withValues(
                  alpha: isDark ? 0.86 : 0.78,
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.white.withValues(alpha: 0.72),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: List.generate(_items.length, (index) {
                  final item = _items[index];
                  final isSelected = index == _selectedIndex;
                  final color = isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant;

                  return Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => _onItemTapped(index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              width: isSelected ? 30 : 18,
                              height: 2,
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            Icon(item.icon, color: color, size: 22),
                            const SizedBox(height: 3),
                            Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textScaler: TextScaler.noScaling,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: color,
                                fontSize: 11,
                                height: 1,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RootItem {
  final String label;
  final IconData icon;

  const _RootItem({required this.label, required this.icon});
}

import 'package:flutter/material.dart';
import '../../widgets/empty_state_widget.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas'), centerTitle: true),
      body: EmptyStates.noAchievements(
        context,
        message: 'Próximamente podrás ver tu progreso detallado aquí.',
      ),
    );
  }
}

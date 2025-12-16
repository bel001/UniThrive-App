import 'package:flutter/material.dart';

class ProgressBar extends StatelessWidget {
  final double value;
  const ProgressBar({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: LinearProgressIndicator(
        minHeight: 8,
        value: value.clamp(0.0, 1.0),
        color: Theme.of(context).colorScheme.primary,
        backgroundColor: Colors.grey.shade200,
      ),
    );
  }
}

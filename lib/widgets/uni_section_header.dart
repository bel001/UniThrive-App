import 'package:flutter/material.dart';

class UniSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final String? actionLabel;
  const UniSectionHeader({super.key, required this.title, this.onTap, this.actionLabel});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        if (actionLabel != null)
          TextButton(onPressed: onTap, child: Text(actionLabel!, style: const TextStyle(color: Color(0xFF6F4CFF))))
      ],
    );
  }
}

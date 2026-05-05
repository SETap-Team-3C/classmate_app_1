import 'package:flutter/material.dart';

class OnlineIndicator extends StatelessWidget {
  final bool isOnline;
  final double size;

  const OnlineIndicator({super.key, required this.isOnline, this.size = 12});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.scaffoldBackgroundColor;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOnline ? Colors.green : theme.colorScheme.onSurface.withOpacity(0.4),
        border: Border.all(color: borderColor, width: (size / 8).clamp(1.0, 4.0)),
      ),
    );
  }
}

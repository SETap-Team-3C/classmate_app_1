import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.iconSize = 30,
    this.gap = 8,
    this.textStyle,
    this.showText = true,
    this.iconColor,
  });

  final double iconSize;
  final double gap;
  final TextStyle? textStyle;
  final bool showText;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final defaultTextStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.bold,
      letterSpacing: 0.2,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.school_rounded,
          size: iconSize,
          color: iconColor ?? Theme.of(context).colorScheme.primary,
        ),
        if (showText) ...[
          SizedBox(width: gap),
          Text('Classmate', style: textStyle ?? defaultTextStyle),
        ],
      ],
    );
  }
}

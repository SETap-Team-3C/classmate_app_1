import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.iconSize = 30,
    this.gap = 8,
    this.textStyle,
    this.showText = true,
    this.iconColor,
    this.useImage = false,
    this.imagePath,
  });

  final double iconSize;
  final double gap;
  final TextStyle? textStyle;
  final bool showText;
  final Color? iconColor;
  final bool useImage;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final defaultTextStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.bold,
      letterSpacing: 0.2,
    );

    Widget leading;
    if (useImage && imagePath != null) {
      leading = Image.asset(
        imagePath!,
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
      );
    } else {
      leading = Icon(
        Icons.school_rounded,
        size: iconSize,
        color: iconColor ?? Theme.of(context).colorScheme.primary,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        leading,
        if (showText) ...[
          SizedBox(width: gap),
          Text('Classmate', style: textStyle ?? defaultTextStyle),
        ],
      ],
    );
  }
}

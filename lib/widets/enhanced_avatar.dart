import 'package:flutter/material.dart';

class EnhancedAvatar extends StatelessWidget {
  final String name;
  final double radius;
  final String? backgroundColor;

  const EnhancedAvatar({
    super.key,
    required this.name,
    this.radius = 24,
    this.backgroundColor,
  });

  static Color getColorForInitial(String initial) {
    final hash = initial.hashCode;
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.pink,
      Colors.orange,
      Colors.teal,
      Colors.cyan,
      Colors.indigo,
      Colors.amber,
      Colors.lime,
      Colors.red,
    ];
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
    final bgColor = getColorForInitial(initial);

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

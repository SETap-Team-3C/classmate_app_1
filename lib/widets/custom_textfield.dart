import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.label,
    required this.onChanged,
    required this.validator,
    this.obscureText = false,
  });

  final String label;
  final bool obscureText;
  final ValueChanged<String> onChanged;
  final String? Function(String?) validator;

  final String label;
  final bool obscureText;
  final Function(String) onChanged;
  final String? Function(String?) validator;

  const CustomTextField({
    required this.label,
    this.obscureText = false,
    required this.onChanged,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onChanged: onChanged,
      validator: validator,
    );
  }
}

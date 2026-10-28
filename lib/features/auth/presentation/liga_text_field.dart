import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// Campo de texto no visual da Liga (contas e logins).
class LigaTextField extends StatelessWidget {
  const LigaTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      onChanged: onChanged,
      style: const TextStyle(
        color: LigaColors.ink,
        fontWeight: FontWeight.w800,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: LigaColors.primaryBlue),
      ),
    );
  }
}

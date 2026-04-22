import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final int? maxLength;
  final int? maxLines;
  final void Function(String)? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;

  const AppTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.maxLength,
    this.maxLines = 1,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.grey900;
    final secondaryColor = isDark
        ? Colors.white.withValues(alpha: 0.65)
        : AppTheme.grey400;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      maxLength: maxLength,
      maxLines: obscureText ? 1 : maxLines,
      onChanged: onChanged,
      readOnly: readOnly,
      onTap: onTap,
      style: TextStyle(
        fontFamily: 'BeVietnamPro',
        fontSize: 15,
        color: textColor,
      ),
      decoration: InputDecoration(
        // Prefer hint text to avoid floating label overlap in compact auth forms.
        hintText: hint ?? label,
        floatingLabelBehavior: FloatingLabelBehavior.never,
        hintStyle: TextStyle(
          color: secondaryColor,
          fontFamily: 'BeVietnamPro',
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: secondaryColor, size: 20)
            : null,
        suffixIcon: suffixIcon,
        counterText: '',
      ),
    );
  }
}

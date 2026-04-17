import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isDark;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final void Function(String)? onChanged;
  final String? errorText;
  final bool autofocus;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.isDark = false,
    this.keyboardType,
    this.validator,
    this.obscureText = false,
    this.suffixIcon,
    this.inputFormatters,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
    this.onChanged,
    this.errorText,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          obscureText: obscureText,
          inputFormatters: inputFormatters,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          onChanged: onChanged,
          autofocus: autofocus,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: hasError
                  ? Colors.red.shade400
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
            prefixIcon: Icon(
              icon,
              color: hasError
                  ? Colors.red.shade400
                  : (isDark ? Colors.grey[400] : AppColors.primary),
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: hasError
                ? Colors.red.shade50.withValues(alpha: isDark ? 0.1 : 1.0)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey[100]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: hasError
                  ? BorderSide(color: Colors.red.shade400, width: 1.5)
                  : BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? Colors.red.shade400 : AppColors.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
            ),
          ),
          validator: validator,
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 14, color: Colors.red.shade400),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    errorText!,
                    style: TextStyle(
                      color: Colors.red.shade400,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

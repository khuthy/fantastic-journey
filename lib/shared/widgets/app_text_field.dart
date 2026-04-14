import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.textCapitalization = TextCapitalization.none,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.onChanged,
    this.onFieldSubmitted,
    this.onTap,
    this.inputFormatters,
    this.autofillHints,
    this.focusNode,
    this.helperText,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppDimensions.spaceXS),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          maxLines: obscureText ? 1 : maxLines,
          minLines: minLines,
          maxLength: maxLength,
          enabled: enabled,
          readOnly: readOnly,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          onTap: onTap,
          inputFormatters: inputFormatters,
          autofillHints: autofillHints,
          focusNode: focusNode,
          validator: validator,
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            helperText: helperText,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 20, color: AppColors.textHint)
                : null,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}

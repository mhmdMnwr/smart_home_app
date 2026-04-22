import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../constants/login_ui_values.dart';

class LoginInputField extends StatelessWidget {
  const LoginInputField({
    super.key,
    required this.label,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    required this.validator,
    required this.onChanged,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final String? Function(String?) validator;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: AppColors.labelText),
        ),
        const SizedBox(height: LoginUiValues.spacingXs),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: const SizedBox.shrink(),
            suffixIcon: suffixIcon,
          ).copyWith(
            prefixIcon: Icon(prefixIcon, size: 18, color: AppColors.hint),
          ),
        ),
      ],
    );
  }
}

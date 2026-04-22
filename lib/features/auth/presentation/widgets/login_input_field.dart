import 'package:flutter/material.dart';

import '../constants/login_ui_values.dart';

class LoginInputField extends StatelessWidget {
  const LoginInputField({
    super.key,
    required this.label,
    required this.controller,
    required this.hintText,
    required this.prefixImageAsset,
    required this.validator,
    required this.onChanged,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final String prefixImageAsset;
  final String? Function(String?) validator;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant),
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
            prefixIcon: Padding(
              padding: const EdgeInsets.all(14),
              child: Image.asset(
                prefixImageAsset,
                width: 18,
                height: 18,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.image_not_supported_outlined,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  );
                },
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 46,
              minHeight: 46,
            ),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}

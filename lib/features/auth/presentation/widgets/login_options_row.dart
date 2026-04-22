import 'package:flutter/material.dart';

import '../constants/login_strings.dart';

class LoginOptionsRow extends StatelessWidget {
  const LoginOptionsRow({
    super.key,
    required this.rememberMe,
    required this.onRememberChanged,
  });

  final bool rememberMe;
  final ValueChanged<bool?> onRememberChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: <Widget>[
        Expanded(
          child: Row(
            children: <Widget>[
              Checkbox(
                value: rememberMe,
                visualDensity: VisualDensity.compact,
                onChanged: onRememberChanged,
              ),
              Flexible(
                child: Text(
                  LoginStrings.rememberMe,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          child: Text(
            LoginStrings.forgotPassword,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

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
              const Flexible(
                child: Text(
                  LoginStrings.rememberMe,
                  style: TextStyle(fontSize: 12),
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
          child: const Text(
            LoginStrings.forgotPassword,
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}

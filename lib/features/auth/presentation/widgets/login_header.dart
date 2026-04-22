import 'package:flutter/material.dart';

import '../constants/login_strings.dart';
import '../constants/login_ui_values.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: <Widget>[
        
        const SizedBox(height: LoginUiValues.spacingMd),
        Text(
          LoginStrings.title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
            height: 1.1,
          ),
        ),
        const SizedBox(height: LoginUiValues.spacingXs),
        Text(
          LoginStrings.subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

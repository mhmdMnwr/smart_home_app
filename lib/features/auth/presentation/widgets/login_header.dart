import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../constants/login_strings.dart';
import '../constants/login_ui_values.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        
        const SizedBox(height: LoginUiValues.spacingMd),
        Text(
          LoginStrings.title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primaryText,
            height: 1.1,
          ),
        ),
        const SizedBox(height: LoginUiValues.spacingXs),
        Text(
          LoginStrings.subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }
}

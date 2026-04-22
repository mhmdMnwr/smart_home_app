import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../constants/login_strings.dart';
import '../constants/login_ui_values.dart';

class LoginSubmitButton extends StatelessWidget {
  const LoginSubmitButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: LoginUiValues.submitButtonHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: <Color>[
              AppColors.submitGradientStart,
              AppColors.submitGradientEnd,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(LoginUiValues.inputRadius),
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.transparent,
            disabledBackgroundColor: AppColors.transparent,
            shadowColor: AppColors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(LoginUiValues.inputRadius),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.loadingIndicator,
                  ),
                )
              : const Text(
                  LoginStrings.loginAction,
                  style: TextStyle(
                    color: AppColors.submitText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}

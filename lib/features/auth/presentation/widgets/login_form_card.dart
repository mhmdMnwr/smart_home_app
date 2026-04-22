import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../constants/login_strings.dart';
import '../constants/login_ui_values.dart';
import 'login_input_field.dart';
import 'login_options_row.dart';
import 'login_submit_button.dart';

class LoginFormCard extends StatelessWidget {
  const LoginFormCard({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.rememberMe,
    required this.isLoading,
    required this.errorMessage,
    required this.onEmailChanged,
    required this.onPasswordChanged,
    required this.onRememberChanged,
    required this.onTogglePasswordVisibility,
    required this.onSubmit,
    required this.emailValidator,
    required this.passwordValidator,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool rememberMe;
  final bool isLoading;
  final String? errorMessage;

  final ValueChanged<String> onEmailChanged;
  final ValueChanged<String> onPasswordChanged;
  final ValueChanged<bool?> onRememberChanged;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onSubmit;

  final String? Function(String?) emailValidator;
  final String? Function(String?) passwordValidator;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(LoginUiValues.formCardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(LoginUiValues.formCardPadding),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: LoginUiValues.formCardMinHeight,
          ),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const SizedBox(height: LoginUiValues.spacingXs),
                    LoginInputField(
                      label: LoginStrings.emailLabel,
                      controller: emailController,
                      hintText: LoginStrings.emailHint,
                      prefixIcon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      validator: emailValidator,
                      onChanged: onEmailChanged,
                    ),
                    const SizedBox(height: LoginUiValues.spacingMd),
                    LoginInputField(
                      label: LoginStrings.passwordLabel,
                      controller: passwordController,
                      hintText: LoginStrings.passwordHint,
                      prefixIcon: Icons.lock_outline,
                      obscureText: obscurePassword,
                      validator: passwordValidator,
                      onChanged: onPasswordChanged,
                      suffixIcon: IconButton(
                        onPressed: onTogglePasswordVisibility,
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.hint,
                        ),
                      ),
                    ),
                    const SizedBox(height: LoginUiValues.spacingSm),
                    LoginOptionsRow(
                      rememberMe: rememberMe,
                      onRememberChanged: onRememberChanged,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    LoginSubmitButton(isLoading: isLoading, onPressed: onSubmit),
                    if (errorMessage != null && errorMessage!.isNotEmpty)
                      ...<Widget>[
                        const SizedBox(height: 14),
                        Text(
                          errorMessage!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.errorText),
                        ),
                      ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../constants/login_strings.dart';
import '../constants/login_ui_values.dart';
import '../widgets/login_form_card.dart';
import '../widgets/login_header.dart';

import '../cubit/login_cubit.dart';
import '../cubit/login_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    await context.read<LoginCubit>().login(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginCubit, LoginState>(
      listenWhen: (previous, current) =>
          previous.user != current.user && current.user != null,
      listener: (context, state) {
        final rawName = state.user?.name.trim() ?? '';
        final username = rawName.isNotEmpty ? rawName : 'User';
        context.goNamed(AppRoutes.homeName, extra: username);
      },
      builder: (context, state) {
        final error = state.errorMessage;

        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: LoginUiValues.pagePadding, vertical: 0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: LoginUiValues.maxContentWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Align(child: LoginHeader()),
                      const SizedBox(height: LoginUiValues.spacingLg),
                      LoginFormCard(
                        formKey: _formKey,
                        emailController: _emailController,
                        passwordController: _passwordController,
                        obscurePassword: _obscurePassword,
                        rememberMe: _rememberMe,
                        isLoading: state.isLoading,
                        errorMessage: error,
                        onEmailChanged: (_) =>
                            context.read<LoginCubit>().clearError(),
                        onPasswordChanged: (_) =>
                            context.read<LoginCubit>().clearError(),
                        onRememberChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                        onTogglePasswordVisibility: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        onSubmit: _submit,
                        emailValidator: _validateEmail,
                        passwordValidator: _validatePassword,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return LoginStrings.emailRequired;
    }

    final hasAtSign = email.contains('@');
    final parts = email.split('@');
    final hasSingleAtSign = parts.length == 2;
    final hasValidDomain = hasSingleAtSign && parts[1].contains('.');

    if (!hasAtSign || !hasSingleAtSign || !hasValidDomain) {
      return LoginStrings.emailInvalid;
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return LoginStrings.passwordRequired;
    }

    if (password.length < 6) {
      return LoginStrings.passwordTooShort;
    }

    return null;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_home_app/features/auth/data/models/user_model.dart';
import 'package:smart_home_app/features/auth/data/repositories/auth_repository.dart';
import 'package:smart_home_app/features/auth/presentation/cubit/login_cubit.dart';
import 'package:smart_home_app/features/auth/presentation/pages/login_page.dart';

void main() {
  testWidgets('Login page renders expected fields', (
    WidgetTester tester,
  ) async {
    final cubit = LoginCubit(authRepository: _FakeAuthRepository());
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<LoginCubit>.value(
          value: cubit,
          child: const LoginPage(),
        ),
      ),
    );

    expect(find.text('Smart Home'), findsOneWidget);
    expect(find.text('Welcome back! Please login to continue'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
    expect(find.text('Biometric Login'), findsNothing);
    expect(find.text("Don't have an account?"), findsNothing);
  });
}

class _FakeAuthRepository implements AuthRepository {
  @override
  String? get accessToken => null;

  @override
  String? get refreshToken => null;

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    return const UserModel(
      name: 'Tester',
      email: 'tester@example.com',
      phoneNumber: '0000000000',
      role: UserRole.user,
    );
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> refreshSession() async {}
}

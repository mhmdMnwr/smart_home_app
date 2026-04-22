import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/app_exception.dart';
import '../constants/login_strings.dart';
import '../../data/repositories/auth_repository.dart';
import 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const LoginState());

  final AuthRepository _authRepository;

  Future<void> login({required String email, required String password}) async {
    if (state.isLoading) {
      return;
    }

    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final user = await _authRepository.login(
        email: email.trim(),
        password: password,
      );

      emit(state.copyWith(isLoading: false, user: user, errorMessage: null));
    } on AppException catch (error) {
      final errorMessage = error.statusCode == 401
          ? LoginStrings.invalidCredentials
          : error.message;
      emit(state.copyWith(isLoading: false, errorMessage: errorMessage));
    } catch (_) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: AppStrings.genericError,
        ),
      );
    }
  }

  Future<void> refreshSession() async {
    try {
      await _authRepository.refreshSession();
      emit(state.copyWith(errorMessage: null));
    } on AppException catch (error) {
      emit(state.copyWith(errorMessage: error.message));
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    emit(const LoginState());
  }

  void clearError() {
    if (state.errorMessage == null) {
      return;
    }

    emit(state.copyWith(errorMessage: null));
  }
}

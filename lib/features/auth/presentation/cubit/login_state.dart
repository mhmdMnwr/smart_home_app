import '../../data/models/user_model.dart';

class LoginState {
  const LoginState({this.isLoading = false, this.errorMessage, this.user});

  final bool isLoading;
  final String? errorMessage;
  final UserModel? user;

  static const Object _unset = Object();

  LoginState copyWith({
    bool? isLoading,
    Object? errorMessage = _unset,
    Object? user = _unset,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      user: identical(user, _unset) ? this.user : user as UserModel?,
    );
  }
}

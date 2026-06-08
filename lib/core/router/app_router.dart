import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/cubit/login_cubit.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/devices/presentation/cubit/devices_cubit.dart';
import '../../features/home/presentation/pages/home_shell_page.dart';
import '../di/injection_container.dart';
import '../storage/token_storage.dart';
import 'app_routes.dart';

class AppRouter {
  const AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.loginPath,
    redirect: (context, state) {
      final tokenStorage = getIt<TokenStorage>();
      final isLoggedIn = tokenStorage.hasTokens;
      final isGoingToLogin = state.matchedLocation == AppRoutes.loginPath;

      if (isLoggedIn && isGoingToLogin) {
        return AppRoutes.homePath;
      }
      if (!isLoggedIn && !isGoingToLogin) {
        return AppRoutes.loginPath;
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.loginPath,
        name: AppRoutes.loginName,
        builder: (context, state) {
          return BlocProvider<LoginCubit>(
            create: (_) => getIt<LoginCubit>(),
            child: const LoginPage(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.homePath,
        name: AppRoutes.homeName,
        builder: (context, state) {
          final rawUsername = state.extra;
          final tokenStorage = getIt<TokenStorage>();
          final username = rawUsername is String && rawUsername.trim().isNotEmpty
              ? rawUsername.trim()
              : tokenStorage.cachedUsername ?? 'User';

          return BlocProvider<DevicesCubit>(
            create: (_) => getIt<DevicesCubit>()..loadDevicesStatus(),
            child: HomeShellPage(username: username),
          );
        },
      ),
    ],
  );
}

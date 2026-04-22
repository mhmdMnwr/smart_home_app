import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/cubit/login_cubit.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/home/presentation/cubit/home_cubit.dart';
import '../../features/home/presentation/pages/home_shell_page.dart';
import '../di/injection_container.dart';
import 'app_routes.dart';

class AppRouter {
  const AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.loginPath,
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
          final username = rawUsername is String && rawUsername.trim().isNotEmpty
              ? rawUsername.trim()
              : 'User';

          return BlocProvider<HomeCubit>(
            create: (_) => getIt<HomeCubit>()..loadDevicesStatus(),
            child: HomeShellPage(username: username),
          );
        },
      ),
    ],
  );
}

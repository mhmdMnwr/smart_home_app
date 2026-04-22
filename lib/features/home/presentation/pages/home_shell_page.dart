import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../sensors/presentation/cubit/sensors_cubit.dart';
import '../../../sensors/presentation/pages/sensors_page.dart';
import '../constants/home_strings.dart';
import 'home_page.dart';

class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key, required this.username});

  final String username;

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>() ??
        AppColors.darkTokens;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: <Widget>[
          HomePage(username: widget.username),
          BlocProvider<SensorsCubit>(
            create: (_) => getIt<SensorsCubit>()..loadInitial(),
            child: const SensorsPage(),
          ),
          _EmptyTabPage(tokens: tokens),
          _EmptyTabPage(tokens: tokens),
          _EmptyTabPage(tokens: tokens),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                tokens.navBarSurface.withValues(alpha: 0.96),
                tokens.navBarSurface,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: tokens.notificationBorder.withValues(alpha: 0.62),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                backgroundColor: Colors.transparent,
                indicatorColor: tokens.navBarIndicator,
                iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
                  (states) {
                    final selected = states.contains(WidgetState.selected);
                    return IconThemeData(
                      color: selected ? Colors.white : tokens.navBarUnselected,
                      size: 22,
                    );
                  },
                ),
                labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
                  (states) {
                    final isSelected = states.contains(WidgetState.selected);
                    return TextStyle(
                      color:
                          isSelected ? Colors.white : tokens.navBarUnselected,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    );
                  },
                ),
              ),
              child: NavigationBar(
                height: 72,
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                destinations: const <NavigationDestination>[
                  NavigationDestination(
                    icon: Icon(Icons.house_outlined),
                    selectedIcon: Icon(Icons.house_rounded),
                    label: HomeStrings.navHome,
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.thermostat_outlined),
                    selectedIcon: Icon(Icons.thermostat_rounded),
                    label: HomeStrings.navSensors,
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.precision_manufacturing_outlined),
                    selectedIcon: Icon(Icons.smart_toy_rounded),
                    label: HomeStrings.navRobot,
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.library_books_outlined),
                    selectedIcon: Icon(Icons.library_books_rounded),
                    label: HomeStrings.navLogs,
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.tune_outlined),
                    selectedIcon: Icon(Icons.tune_rounded),
                    label: HomeStrings.navSettings,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyTabPage extends StatelessWidget {
  const _EmptyTabPage({required this.tokens});

  final AppColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            tokens.pageGradientTop,
            tokens.pageGradientMiddle,
            tokens.pageGradientBottom,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}

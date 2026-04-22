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
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                tokens.navBarSurface.withValues(alpha: 0.95),
                const Color(0xFF0B1E4E).withValues(alpha: 0.98),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: tokens.navBarIndicator.withValues(alpha: 0.15),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: tokens.navBarIndicator.withValues(alpha: 0.08),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(5, (index) {
                return _NavBarItem(
                  index: index,
                  isSelected: _selectedIndex == index,
                  tokens: tokens,
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.index,
    required this.isSelected,
    required this.tokens,
    required this.onTap,
  });

  final int index;
  final bool isSelected;
  final AppColorTokens tokens;
  final VoidCallback onTap;

  static const List<IconData> _icons = [
    Icons.house_outlined,
    Icons.thermostat_outlined,
    Icons.precision_manufacturing_outlined,
    Icons.library_books_outlined,
    Icons.tune_outlined,
  ];

  static const List<IconData> _selectedIcons = [
    Icons.house_rounded,
    Icons.thermostat_rounded,
    Icons.smart_toy_rounded,
    Icons.library_books_rounded,
    Icons.tune_rounded,
  ];

  static const List<String> _labels = [
    HomeStrings.navHome,
    HomeStrings.navSensors,
    HomeStrings.navRobot,
    HomeStrings.navLogs,
    HomeStrings.navSettings,
  ];

  @override
  Widget build(BuildContext context) {
    final icon = isSelected ? _selectedIcons[index] : _icons[index];
    final label = _labels[index];
    final selectedColor = tokens.navBarIndicator;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Glow dot above icon
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isSelected ? 24 : 0,
                height: 3,
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: isSelected ? selectedColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: selectedColor.withValues(alpha: 0.6),
                            blurRadius: 8,
                          ),
                        ]
                      : [],
                ),
              ),
              Icon(
                icon,
                size: 22,
                color: isSelected ? Colors.white : tokens.navBarUnselected,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : tokens.navBarUnselected,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
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

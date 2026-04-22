import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../constants/app_strings.dart';
import '../theme/theme_mode_cubit.dart';

class ThemeModeToggleButton extends StatelessWidget {
  const ThemeModeToggleButton({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    final ThemeMode mode = context.watch<ThemeModeCubit>().state;
    final bool isDark = mode == ThemeMode.dark;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: isDark
          ? AppStrings.switchToLightMode
          : AppStrings.switchToDarkMode,
      child: IconButton(
        onPressed: () => context.read<ThemeModeCubit>().toggleTheme(),
        icon: Icon(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          color: colorScheme.onSurface,
          size: size * 0.52,
        ),
        splashRadius: size * 0.5,
        padding: EdgeInsets.zero,
        constraints: BoxConstraints.tightFor(width: size, height: size),
      ),
    );
  }
}

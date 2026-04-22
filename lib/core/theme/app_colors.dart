import 'package:flutter/material.dart';

@immutable
class AppColorTokens extends ThemeExtension<AppColorTokens> {
  const AppColorTokens({
    required this.pageGradientTop,
    required this.pageGradientMiddle,
    required this.pageGradientBottom,
    required this.deviceCardSurface,
    required this.deviceCardBorder,
    required this.deviceCardTitle,
    required this.deviceCardSubtitle,
    required this.iconBadgeSurface,
    required this.navBarSurface,
    required this.navBarIndicator,
    required this.navBarUnselected,
    required this.notificationSurface,
    required this.notificationBorder,
    required this.dialogSurface,
  });

  final Color pageGradientTop;
  final Color pageGradientMiddle;
  final Color pageGradientBottom;
  final Color deviceCardSurface;
  final Color deviceCardBorder;
  final Color deviceCardTitle;
  final Color deviceCardSubtitle;
  final Color iconBadgeSurface;
  final Color navBarSurface;
  final Color navBarIndicator;
  final Color navBarUnselected;
  final Color notificationSurface;
  final Color notificationBorder;
  final Color dialogSurface;

  @override
  AppColorTokens copyWith({
    Color? pageGradientTop,
    Color? pageGradientMiddle,
    Color? pageGradientBottom,
    Color? deviceCardSurface,
    Color? deviceCardBorder,
    Color? deviceCardTitle,
    Color? deviceCardSubtitle,
    Color? iconBadgeSurface,
    Color? navBarSurface,
    Color? navBarIndicator,
    Color? navBarUnselected,
    Color? notificationSurface,
    Color? notificationBorder,
    Color? dialogSurface,
  }) {
    return AppColorTokens(
      pageGradientTop: pageGradientTop ?? this.pageGradientTop,
      pageGradientMiddle: pageGradientMiddle ?? this.pageGradientMiddle,
      pageGradientBottom: pageGradientBottom ?? this.pageGradientBottom,
      deviceCardSurface: deviceCardSurface ?? this.deviceCardSurface,
      deviceCardBorder: deviceCardBorder ?? this.deviceCardBorder,
      deviceCardTitle: deviceCardTitle ?? this.deviceCardTitle,
      deviceCardSubtitle: deviceCardSubtitle ?? this.deviceCardSubtitle,
      iconBadgeSurface: iconBadgeSurface ?? this.iconBadgeSurface,
      navBarSurface: navBarSurface ?? this.navBarSurface,
      navBarIndicator: navBarIndicator ?? this.navBarIndicator,
      navBarUnselected: navBarUnselected ?? this.navBarUnselected,
      notificationSurface: notificationSurface ?? this.notificationSurface,
      notificationBorder: notificationBorder ?? this.notificationBorder,
      dialogSurface: dialogSurface ?? this.dialogSurface,
    );
  }

  @override
  AppColorTokens lerp(ThemeExtension<AppColorTokens>? other, double t) {
    if (other is! AppColorTokens) {
      return this;
    }

    return AppColorTokens(
      pageGradientTop: Color.lerp(pageGradientTop, other.pageGradientTop, t)!,
      pageGradientMiddle: Color.lerp(
        pageGradientMiddle,
        other.pageGradientMiddle,
        t,
      )!,
      pageGradientBottom: Color.lerp(
        pageGradientBottom,
        other.pageGradientBottom,
        t,
      )!,
      deviceCardSurface: Color.lerp(
        deviceCardSurface,
        other.deviceCardSurface,
        t,
      )!,
      deviceCardBorder: Color.lerp(deviceCardBorder, other.deviceCardBorder, t)!,
      deviceCardTitle: Color.lerp(deviceCardTitle, other.deviceCardTitle, t)!,
      deviceCardSubtitle: Color.lerp(
        deviceCardSubtitle,
        other.deviceCardSubtitle,
        t,
      )!,
      iconBadgeSurface: Color.lerp(iconBadgeSurface, other.iconBadgeSurface, t)!,
      navBarSurface: Color.lerp(navBarSurface, other.navBarSurface, t)!,
      navBarIndicator: Color.lerp(navBarIndicator, other.navBarIndicator, t)!,
      navBarUnselected: Color.lerp(navBarUnselected, other.navBarUnselected, t)!,
      notificationSurface: Color.lerp(
        notificationSurface,
        other.notificationSurface,
        t,
      )!,
      notificationBorder: Color.lerp(
        notificationBorder,
        other.notificationBorder,
        t,
      )!,
      dialogSurface: Color.lerp(dialogSurface, other.dialogSurface, t)!,
    );
  }
}

class AppColors {
  const AppColors._();

  static const Color seed = Color(0xFF4F46E5);
  static const Color neonCyan = Color(0xFF22D3EE);
  static const Color neonViolet = Color(0xFFA855F7);
  static const Color neonMint = Color(0xFF2DD4BF);

  static const AppColorTokens darkTokens = AppColorTokens(
    pageGradientTop: Color(0xFF040B1D),
    pageGradientMiddle: Color(0xFF071738),
    pageGradientBottom: Color(0xFF040E24),
    deviceCardSurface: Color(0xFF0C2457),
    deviceCardBorder: Color(0xFF2D67C2),
    deviceCardTitle: Color(0xFFEAF2FF),
    deviceCardSubtitle: Color(0xFFAAC2EC),
    iconBadgeSurface: Color(0xFF15356F),
    navBarSurface: Color(0xFF081A3D),
    navBarIndicator: Color(0xFF1F78FF),
    navBarUnselected: Color(0xFF7A98CE),
    notificationSurface: Color(0xFF10306A),
    notificationBorder: Color(0xFF366FC9),
    dialogSurface: Color(0xFF0A1E4A),
  );
}

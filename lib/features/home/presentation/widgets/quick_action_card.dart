import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class QuickActionCard extends StatelessWidget {
  const QuickActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    this.onTap,
    this.imageAsset,
    this.deviceLabels,
    this.deviceStates,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback? onTap;
  final String? imageAsset;
  final List<String>? deviceLabels; // e.g., ['Lamp 1', 'Lamp 2']
  final List<bool>? deviceStates; // e.g., [true, false] for on/off

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).extension<AppColorTokens>() ??
        AppColors.darkTokens;

    // Check if we should show device list
    final showDeviceList =
        deviceLabels != null && deviceStates != null && deviceLabels!.isNotEmpty;

    return Material(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        splashColor: gradient.first.withValues(alpha: isDark ? 0.22 : 0.14),
        highlightColor: gradient.last.withValues(alpha: isDark ? 0.14 : 0.08),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                Color.alphaBlend(
                  gradient.first.withValues(alpha: isDark ? 0.28 : 0.18),
                  tokens.deviceCardSurface,
                ),
                Color.alphaBlend(
                  gradient.last.withValues(alpha: isDark ? 0.2 : 0.12),
                  tokens.deviceCardSurface,
                ),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Color.alphaBlend(
                gradient.last.withValues(alpha: isDark ? 0.26 : 0.12),
                tokens.deviceCardBorder,
              ),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: gradient.first.withValues(alpha: isDark ? 0.3 : 0.16),
                blurRadius: 24,
                spreadRadius: -5,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.26 : 0.08),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
              if (isDark)
                BoxShadow(
                  color: gradient.last.withValues(alpha: 0.14),
                  blurRadius: 30,
                  spreadRadius: -10,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      imageAsset != null
                          ? Image.asset(
                              imageAsset!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  icon,
                                  color: gradient.first,
                                  size: 36,
                                );
                              },
                            )
                          : Icon(
                              icon,
                              color: gradient.first,
                              size: 36,
                            ),
                      const SizedBox(height: 10),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: tokens.deviceCardTitle,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (showDeviceList)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(
                      deviceLabels!.length,
                      (index) {
                        final label = deviceLabels![index];
                        final isOn = deviceStates![index];
                        final ledColor = isOn
                            ? const Color(0xFF22C55E) // Green
                            : const Color(0xFFEF4444); // Red

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: <Widget>[
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: ledColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  label,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: tokens.deviceCardSubtitle,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  )
                else
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: tokens.deviceCardSubtitle,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

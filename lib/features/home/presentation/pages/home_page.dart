import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/device_status_model.dart';
import '../constants/home_strings.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../widgets/device_control_sheet.dart';
import '../widgets/home_error_view.dart';
import '../widgets/quick_action_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(HomeStrings.homePageTitle),
        actions: <Widget>[
          IconButton(
            tooltip: HomeStrings.refresh,
            onPressed: () => context.read<HomeCubit>().loadDevicesStatus(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state.isLoading && state.devices == null) {
            return const _HomeLoadingView();
          }

          final devices = state.devices;
          if (devices == null) {
            return HomeErrorView(
              message: state.errorMessage ?? HomeStrings.failedToLoadDevices,
              onRetry: () => context.read<HomeCubit>().loadDevicesStatus(),
            );
          }

          final onlineCount = _onlineDevicesCount(devices);
          final offlineCount = _offlineDevicesCount(devices);

          return RefreshIndicator(
            onRefresh: () => context.read<HomeCubit>().loadDevicesStatus(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              children: <Widget>[
                _HomeOverviewCard(
                  onlineCount: onlineCount,
                  offlineCount: offlineCount,
                ),
                const SizedBox(height: 22),
                Text(
                  HomeStrings.quickActions,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  HomeStrings.pullToRefresh,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.05,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: <Widget>[
                    QuickActionCard(
                      title: HomeStrings.lights,
                      subtitle: devices.lightsSummary,
                      icon: Icons.lightbulb_outline,
                      gradient: const <Color>[
                        Color(0xFFFF9F0A),
                        Color(0xFFF76680),
                      ],
                      onTap: () => _showControlSheet(
                        context: context,
                        title: HomeStrings.lights,
                        firstLabel: HomeStrings.lamp1,
                        firstKey: 'lamp1',
                        secondLabel: HomeStrings.lamp2,
                        secondKey: 'lamp2',
                        devices: devices,
                      ),
                    ),
                    QuickActionCard(
                      title: HomeStrings.fans,
                      subtitle: devices.fansSummary,
                      icon: Icons.toys_outlined,
                      gradient: const <Color>[
                        Color(0xFF00C2A8),
                        Color(0xFF0EA5E9),
                      ],
                      onTap: () => _showControlSheet(
                        context: context,
                        title: HomeStrings.fans,
                        firstLabel: HomeStrings.fan1,
                        firstKey: 'fan1',
                        secondLabel: HomeStrings.fan2,
                        secondKey: 'fan2',
                        devices: devices,
                      ),
                    ),
                    QuickActionCard(
                      title: HomeStrings.openDoor,
                      subtitle: HomeStrings.alarmNotConnected,
                      icon: Icons.lock_open_rounded,
                      gradient: const <Color>[
                        Color(0xFF94A3B8),
                        Color(0xFF64748B),
                      ],
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  int _onlineDevicesCount(HomeDevicesStatusModel devices) {
    return <DeviceStatusModel>[
      devices.lamp1,
      devices.lamp2,
      devices.fan1,
      devices.fan2,
    ].where((device) => device.isOnline).length;
  }

  int _offlineDevicesCount(HomeDevicesStatusModel devices) {
    return <DeviceStatusModel>[
      devices.lamp1,
      devices.lamp2,
      devices.fan1,
      devices.fan2,
    ].where((device) => device.isOffline).length;
  }

  void _showControlSheet({
    required BuildContext context,
    required String title,
    required String firstLabel,
    required String firstKey,
    required String secondLabel,
    required String secondKey,
    required HomeDevicesStatusModel devices,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return DeviceControlSheet(
          title: title,
          firstLabel: firstLabel,
          firstKey: firstKey,
          firstStatus: devices.deviceByKey(firstKey),
          secondLabel: secondLabel,
          secondKey: secondKey,
          secondStatus: devices.deviceByKey(secondKey),
          onToggle: (deviceKey, isOn) {
            context.read<HomeCubit>().setDevicePower(
              deviceKey: deviceKey,
              isOn: isOn,
            );
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}

class _HomeLoadingView extends StatelessWidget {
  const _HomeLoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(
            HomeStrings.loadingDevices,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeOverviewCard extends StatelessWidget {
  const _HomeOverviewCard({
    required this.onlineCount,
    required this.offlineCount,
  });

  final int onlineCount;
  final int offlineCount;

  @override
  Widget build(BuildContext context) {
    final totalDevices = onlineCount + offlineCount;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF0EA5E9), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x260E7490),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              HomeStrings.homeTagline,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$totalDevices devices connected',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: _StatusCountPill(
                    label: HomeStrings.active,
                    count: onlineCount,
                    icon: Icons.bolt_rounded,
                    tint: const Color(0xFFDCFCE7),
                    textColor: const Color(0xFF14532D),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatusCountPill(
                    label: HomeStrings.inactive,
                    count: offlineCount,
                    icon: Icons.power_settings_new_rounded,
                    tint: const Color(0xFFFFEDD5),
                    textColor: const Color(0xFF9A3412),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCountPill extends StatelessWidget {
  const _StatusCountPill({
    required this.label,
    required this.count,
    required this.icon,
    required this.tint,
    required this.textColor,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color tint;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: <Widget>[
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: textColor.withValues(alpha: 0.88),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$count',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

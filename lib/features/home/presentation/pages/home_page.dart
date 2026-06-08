import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../devices/data/models/device_status_model.dart';
import '../../../devices/presentation/cubit/devices_cubit.dart';
import '../../../devices/presentation/cubit/devices_state.dart';
import '../../../devices/presentation/widgets/device_control_sheet.dart';
import '../../../devices/presentation/widgets/devices_error_view.dart';
import '../../../devices/presentation/widgets/quick_action_card.dart';
import '../../../notifications/presentation/cubit/notifications_cubit.dart';
import '../../../notifications/presentation/cubit/notifications_state.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../constants/home_strings.dart';
import '../widgets/weather_widget.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppColorTokens>() ??
        AppColors.darkTokens;

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
      child: SafeArea(
        child: BlocBuilder<DevicesCubit, DevicesState>(
          builder: (context, state) {
            if (state.isLoading && state.devices == null) {
              return const _HomeLoadingView();
            }

            final devices = state.devices;
            if (devices == null) {
              return DevicesErrorView(
                message: state.errorMessage ?? HomeStrings.failedToLoadDevices,
                onRetry: () => context.read<DevicesCubit>().loadDevicesStatus(),
              );
            }

            return RefreshIndicator(
              onRefresh: () => context.read<DevicesCubit>().loadDevicesStatus(),
              color: colorScheme.primary,
              backgroundColor: tokens.deviceCardSurface,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          '${HomeStrings.hello}, $username',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      BlocBuilder<NotificationsCubit, NotificationsState>(
                        builder: (context, notifState) {
                          return _NotificationButton(
                            unreadCount: notifState.unreadCount,
                            onTap: () {
                              final cubit = context.read<NotificationsCubit>();
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => BlocProvider<NotificationsCubit>.value(
                                    value: cubit,
                                    child: const NotificationsPage(),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ── Weather widget ──
                  const WeatherWidget(),
                  const SizedBox(height: 20),
                  Text(
                    HomeStrings.devices,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.9,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: <Widget>[
                      QuickActionCard(
                        title: HomeStrings.lights,
                        subtitle: devices.lightsSummary,
                        icon: Icons.wb_incandescent_rounded,
                        imageAsset: 'assets/images/smart_light.png',
                        gradient: const <Color>[
                          Color(0xFF276BFF),
                          Color(0xFF33A4FF),
                        ],
                        deviceLabels: <String>[
                          HomeStrings.lamp1,
                          HomeStrings.lamp2,
                        ],
                        deviceStates: <bool>[
                          devices.lamp1.isOnline,
                          devices.lamp2.isOnline,
                        ],
                        onTap: () => _showControlSheet(
                          context: context,
                          title: HomeStrings.lights,
                          firstLabel: HomeStrings.lamp1,
                          firstKey: 'lamp1',
                          secondLabel: HomeStrings.lamp2,
                          secondKey: 'lamp2',
                          devices: devices,
                          showThresholdControl: false,
                        ),
                      ),
                      QuickActionCard(
                        title: HomeStrings.fans,
                        subtitle: devices.fansSummary,
                        icon: Icons.air_rounded,
                        imageAsset: 'assets/images/smart_fan.png',
                        gradient: const <Color>[
                          Color(0xFF1F61F4),
                          Color(0xFF2CC9FF),
                        ],
                        deviceLabels: <String>[
                          HomeStrings.fan1,
                          HomeStrings.fan2,
                        ],
                        deviceStates: <bool>[
                          devices.fan1.isOnline,
                          devices.fan2.isOnline,
                        ],
                        onTap: () => _showControlSheet(
                          context: context,
                          title: HomeStrings.fans,
                          firstLabel: HomeStrings.fan1,
                          firstKey: 'fan1',
                          secondLabel: HomeStrings.fan2,
                          secondKey: 'fan2',
                          devices: devices,
                          showThresholdControl: true,
                        ),
                      ),
                      QuickActionCard(
                        title: HomeStrings.door,
                        subtitle: devices.door.isOnline
                            ? '${HomeStrings.doorOpen} · ${HomeStrings.doorTapToToggle}'
                            : '${HomeStrings.doorClosed} · ${HomeStrings.doorTapToToggle}',
                        icon: Icons.lock_open_rounded,
                        imageAsset: 'assets/images/smart_lock.png',
                        gradient: const <Color>[
                          Color(0xFF2B6EFF),
                          Color(0xFF5E8FFF),
                        ],
                        deviceLabels: const <String>[HomeStrings.door],
                        deviceStates: <bool>[devices.door.isOnline],
                        onTap: () => _showDoorControlSheet(context, devices.door.isOnline),
                      ),
                      QuickActionCard(
                        title: HomeStrings.alarm,
                        subtitle: devices.alarm.isOnline
                            ? '${HomeStrings.alarmOn} · ${HomeStrings.alarmTapToToggle}'
                            : '${HomeStrings.alarmOff} · ${HomeStrings.alarmTapToToggle}',
                        icon: Icons.warning_amber_rounded,
                        imageAsset: 'assets/images/smart_alarm.png',
                        gradient: const <Color>[
                          Color(0xFF1C57DA),
                          Color(0xFF3F86FF),
                        ],
                        deviceLabels: const <String>[HomeStrings.alarm],
                        deviceStates: <bool>[devices.alarm.isOnline],
                        onTap: () => _showAlarmControlSheet(context, devices.alarm.isOnline),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showDoorControlSheet(BuildContext context, bool isCurrentlyOpen) async {
    final cubit = context.read<DevicesCubit>();

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  HomeStrings.doorControlTitle,
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // Current state indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isCurrentlyOpen
                            ? const Color(0xFF4CAF50)
                            : Colors.redAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isCurrentlyOpen
                                    ? const Color(0xFF4CAF50)
                                    : Colors.redAccent)
                                .withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isCurrentlyOpen
                          ? HomeStrings.doorOpen
                          : HomeStrings.doorClosed,
                      style: Theme.of(sheetContext)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color: Theme.of(sheetContext)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          cubit.setDevicePower(
                            deviceKey: 'door',
                            isOn: true,
                          );
                          Navigator.of(sheetContext).pop();
                        },
                        icon: const Icon(Icons.lock_open_rounded),
                        label: const Text(HomeStrings.doorSwitchOpen),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF388E3C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          cubit.setDevicePower(
                            deviceKey: 'door',
                            isOn: false,
                          );
                          Navigator.of(sheetContext).pop();
                        },
                        icon: const Icon(Icons.lock_rounded),
                        label: const Text(HomeStrings.doorSwitchClose),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFD32F2F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    cubit.loadDevicesStatus();
  }

  Future<void> _showAlarmControlSheet(BuildContext context, bool isCurrentlyOn) async {
    final cubit = context.read<DevicesCubit>();

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  HomeStrings.alarmControlTitle,
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // Current state indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isCurrentlyOn
                            ? const Color(0xFF4CAF50)
                            : Colors.redAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isCurrentlyOn
                                    ? const Color(0xFF4CAF50)
                                    : Colors.redAccent)
                                .withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isCurrentlyOn
                          ? HomeStrings.alarmOn
                          : HomeStrings.alarmOff,
                      style: Theme.of(sheetContext)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color: Theme.of(sheetContext)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Toggle button — shows the opposite action
                FilledButton.icon(
                  onPressed: () {
                    cubit.setDevicePower(
                      deviceKey: 'alarm',
                      isOn: !isCurrentlyOn,
                    );
                    Navigator.of(sheetContext).pop();
                  },
                  icon: Icon(
                    isCurrentlyOn
                        ? Icons.alarm_off_rounded
                        : Icons.alarm_on_rounded,
                  ),
                  label: Text(
                    isCurrentlyOn
                        ? HomeStrings.alarmSwitchOff
                        : HomeStrings.alarmSwitchOn,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: isCurrentlyOn
                        ? const Color(0xFFD32F2F)
                        : const Color(0xFF388E3C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    cubit.loadDevicesStatus();
  }

  void _showControlSheet({
    required BuildContext context,
    required String title,
    required String firstLabel,
    required String firstKey,
    required String secondLabel,
    required String secondKey,
    required HomeDevicesStatusModel devices,
    required bool showThresholdControl,
  }) {
    final cubit = context.read<DevicesCubit>();
    
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
          showThresholdControl: showThresholdControl,
          onSetThreshold: showThresholdControl
              ? (value) => cubit.setFanTempThreshold(value: value)
              : null,
          onToggle: (deviceKey, isOn) {
            cubit.setDevicePower(
              deviceKey: deviceKey,
              isOn: isOn,
            );
          },
        );
      },
    ).then((_) {
      // When the modal is dismissed, reload device status
      cubit.loadDevicesStatus();
    }).catchError((_) {
      // Ignore errors
    });
  }
}

class _HomeLoadingView extends StatelessWidget {
  const _HomeLoadingView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CircularProgressIndicator(color: colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            HomeStrings.loadingDevices,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({
    required this.onTap,
    this.unreadCount = 0,
  });

  final VoidCallback onTap;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppColorTokens>() ??
        AppColors.darkTokens;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: tokens.notificationSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: tokens.notificationBorder),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: colorScheme.onSurface,
                  size: 20,
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF5252),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

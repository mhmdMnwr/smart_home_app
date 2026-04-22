import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../devices/presentation/cubit/devices_cubit.dart';
import '../../../devices/presentation/cubit/devices_state.dart';
import '../../../devices/data/models/device_status_model.dart';
import '../../data/models/sensor_history_models.dart';
import '../constants/sensors_strings.dart';
import '../cubit/sensors_cubit.dart';
import '../cubit/sensors_state.dart';

class SensorsPage extends StatelessWidget {
  const SensorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>() ??
        AppColors.darkTokens;
    final colorScheme = Theme.of(context).colorScheme;

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
        child: BlocBuilder<SensorsCubit, SensorsState>(
          builder: (context, sensorsState) {
            final selectedType = sensorsState.selectedType;

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: <Widget>[
                Text(
                  SensorsStrings.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  SensorsStrings.subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 14),
                _SensorTypeTabs(
                  selectedType: selectedType,
                  onSelected: (type) {
                    context.read<SensorsCubit>().selectType(type);
                  },
                ),
                const SizedBox(height: 14),
                _SensorPageBody(type: selectedType),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SensorTypeTabs extends StatelessWidget {
  const _SensorTypeTabs({
    required this.selectedType,
    required this.onSelected,
  });

  final SensorType selectedType;
  final ValueChanged<SensorType> onSelected;

  @override
  Widget build(BuildContext context) {
    final tabs = <(SensorType, String)>[
      (SensorType.temperature, SensorsStrings.temperature),
      (SensorType.humidity, SensorsStrings.humidity),
      (SensorType.gas, SensorsStrings.gas),
      (SensorType.fire, SensorsStrings.fire),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs
            .map(
              (tab) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(tab.$2),
                  selected: tab.$1 == selectedType,
                  onSelected: (_) => onSelected(tab.$1),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _SensorPageBody extends StatelessWidget {
  const _SensorPageBody({required this.type});

  final SensorType type;

  @override
  Widget build(BuildContext context) {
    if (type == SensorType.fire) {
      return _FirePlaceholderCard();
    }

    return BlocBuilder<DevicesCubit, DevicesState>(
      builder: (context, devicesState) {
        final devices = devicesState.devices;
        final sensorStatus = _resolveStatus(type, devices);
        final sensorDeviceName = _resolveDeviceName(type);
        final valueUnit = _resolveUnit(type);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _SensorStatusCard(
              title: _titleForType(type),
              deviceName: sensorDeviceName,
              status: sensorStatus,
              unit: valueUnit,
            ),
            const SizedBox(height: 14),
            _SensorHistoryCard(type: type),
          ],
        );
      },
    );
  }

  String _titleForType(SensorType type) {
    switch (type) {
      case SensorType.temperature:
        return SensorsStrings.temperature;
      case SensorType.humidity:
        return SensorsStrings.humidity;
      case SensorType.gas:
        return SensorsStrings.gas;
      case SensorType.fire:
        return SensorsStrings.fire;
    }
  }

  String _resolveDeviceName(SensorType type) {
    switch (type) {
      case SensorType.temperature:
      case SensorType.humidity:
        return SensorsStrings.dht11Device;
      case SensorType.gas:
        return SensorsStrings.mq2Device;
      case SensorType.fire:
        return '-';
    }
  }

  String _resolveUnit(SensorType type) {
    switch (type) {
      case SensorType.temperature:
        return SensorsStrings.valueUnitTemp;
      case SensorType.humidity:
        return SensorsStrings.valueUnitHumidity;
      case SensorType.gas:
        return SensorsStrings.valueUnitGas;
      case SensorType.fire:
        return '';
    }
  }

  DeviceStatusModel _resolveStatus(
    SensorType type,
    HomeDevicesStatusModel? devices,
  ) {
    if (devices == null) {
      return const DeviceStatusModel.unknown();
    }

    switch (type) {
      case SensorType.temperature:
      case SensorType.humidity:
        return devices.dht11;
      case SensorType.gas:
        return devices.mq2;
      case SensorType.fire:
        return const DeviceStatusModel.unknown();
    }
  }
}

class _SensorStatusCard extends StatelessWidget {
  const _SensorStatusCard({
    required this.title,
    required this.deviceName,
    required this.status,
    required this.unit,
  });

  final String title;
  final String deviceName;
  final DeviceStatusModel status;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>() ??
        AppColors.darkTokens;
    final colorScheme = Theme.of(context).colorScheme;

    final statusLabel = status.isOnline
        ? SensorsStrings.online
        : status.isOffline
            ? SensorsStrings.offline
            : SensorsStrings.unknown;

    final statusColor = status.isOnline
        ? const Color(0xFF22C55E)
        : status.isOffline
            ? const Color(0xFFF97316)
            : colorScheme.onSurfaceVariant;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            Color.alphaBlend(
              colorScheme.primary.withValues(alpha: 0.22),
              tokens.deviceCardSurface,
            ),
            tokens.deviceCardSurface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.deviceCardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tokens.iconBadgeSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.sensors_rounded,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: tokens.deviceCardTitle,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$deviceName • $unit',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens.deviceCardSubtitle,
                        ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                statusLabel,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SensorHistoryCard extends StatelessWidget {
  const _SensorHistoryCard({required this.type});

  final SensorType type;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SensorsCubit, SensorsState>(
      builder: (context, state) {
        final historyState = state.historyStateFor(type);
        final pageData = historyState.pageData;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  SensorsStrings.history,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                if (historyState.isLoading && pageData == null)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (historyState.errorMessage != null && pageData == null)
                  Column(
                    children: <Widget>[
                      Text(
                        historyState.errorMessage!,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () {
                          context
                              .read<SensorsCubit>()
                              .loadHistory(type: type, page: 1, limit: 10);
                        },
                        child: const Text(SensorsStrings.retry),
                      ),
                    ],
                  )
                else if (pageData == null || pageData.items.isEmpty)
                  Text(
                    SensorsStrings.noHistory,
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else ...<Widget>[
                  ...pageData.items.map((item) => _HistoryItemTile(item: item)),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: pageData.page > 1
                              ? () => context
                                  .read<SensorsCubit>()
                                  .goToPreviousPage(type)
                              : null,
                          child: const Text(SensorsStrings.previous),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${SensorsStrings.page} ${pageData.page}/${pageData.totalPages}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: pageData.page < pageData.totalPages
                              ? () => context
                                  .read<SensorsCubit>()
                                  .goToNextPage(type)
                              : null,
                          child: const Text(SensorsStrings.next),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HistoryItemTile extends StatelessWidget {
  const _HistoryItemTile({required this.item});

  final SensorHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>() ??
        AppColors.darkTokens;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.deviceCardSurface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: tokens.deviceCardBorder.withValues(alpha: 0.6),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: <Widget>[
              Text(
                item.value.toStringAsFixed(2),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              Text(
                _formatDate(item.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }
}

class _FirePlaceholderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>() ??
        AppColors.darkTokens;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.deviceCardSurface.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.deviceCardBorder),
      ),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            Icon(Icons.local_fire_department_rounded, size: 42),
            SizedBox(height: 10),
            Text(
              SensorsStrings.fireComingSoon,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

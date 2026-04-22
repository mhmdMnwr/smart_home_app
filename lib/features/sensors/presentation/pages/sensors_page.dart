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
import '../widgets/sensor_gauge.dart';

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

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // ── Header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Text(
                    SensorsStrings.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 26,
                        ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Text(
                    SensorsStrings.subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Tabs ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SensorTypeTabs(
                    selectedType: selectedType,
                    onSelected: (type) {
                      context.read<SensorsCubit>().selectType(type);
                    },
                  ),
                ),
                const SizedBox(height: 8),

                // ── Body (scrollable) ──
                Expanded(
                  child: _SensorPageBody(type: selectedType),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────── Tabs ───────────────────────────

class _SensorTypeTabs extends StatelessWidget {
  const _SensorTypeTabs({
    required this.selectedType,
    required this.onSelected,
  });

  final SensorType selectedType;
  final ValueChanged<SensorType> onSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>() ??
        AppColors.darkTokens;
    final colorScheme = Theme.of(context).colorScheme;

    final tabs = <(SensorType, String, IconData)>[
      (SensorType.temperature, SensorsStrings.temperature, Icons.thermostat_rounded),
      (SensorType.humidity, SensorsStrings.humidity, Icons.water_drop_rounded),
      (SensorType.gas, SensorsStrings.gas, Icons.cloud_rounded),
      (SensorType.fire, SensorsStrings.fire, Icons.local_fire_department_rounded),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          final isSelected = tab.$1 == selectedType;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onSelected(tab.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                colorScheme.primary,
                                colorScheme.primary.withValues(alpha: 0.7),
                              ],
                            )
                          : null,
                      color: isSelected ? null : tokens.deviceCardSurface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary.withValues(alpha: 0.6)
                            : tokens.deviceCardBorder.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tab.$3,
                          size: 16,
                          color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tab.$2,
                          style: TextStyle(
                            color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}

// ─────────────────────────── Body ───────────────────────────

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
        final unit = _resolveUnit(type);
        final label = _labelForType(type);
        final gaugeMax = _gaugeMax(type);

        // Current value from latest history item
        return BlocBuilder<SensorsCubit, SensorsState>(
          builder: (context, sensorsState) {
            final historyState = sensorsState.historyStateFor(type);
            final currentValue = historyState.allItems.isNotEmpty
                ? historyState.allItems.first.value
                : 0.0;

            return _SensorScrollView(
              type: type,
              status: sensorStatus,
              currentValue: currentValue,
              unit: unit,
              label: label,
              gaugeMax: gaugeMax,
            );
          },
        );
      },
    );
  }

  String _labelForType(SensorType type) {
    switch (type) {
      case SensorType.temperature:
        return 'TEMP';
      case SensorType.humidity:
        return 'HUM';
      case SensorType.gas:
        return 'GAS';
      case SensorType.fire:
        return '';
    }
  }

  double _gaugeMax(SensorType type) {
    switch (type) {
      case SensorType.temperature:
        return 60;
      case SensorType.humidity:
        return 100;
      case SensorType.gas:
        return 1000;
      case SensorType.fire:
        return 100;
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

// ─────────────── Scrollable content with infinite scroll ───────────────

class _SensorScrollView extends StatefulWidget {
  const _SensorScrollView({
    required this.type,
    required this.status,
    required this.currentValue,
    required this.unit,
    required this.label,
    required this.gaugeMax,
  });

  final SensorType type;
  final DeviceStatusModel status;
  final double currentValue;
  final String unit;
  final String label;
  final double gaugeMax;

  @override
  State<_SensorScrollView> createState() => _SensorScrollViewState();
}

class _SensorScrollViewState extends State<_SensorScrollView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isNearBottom) {
      context.read<SensorsCubit>().loadMore(widget.type);
    }
  }

  bool get _isNearBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll - 120);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>() ??
        AppColors.darkTokens;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<SensorsCubit, SensorsState>(
      builder: (context, state) {
        final historyState = state.historyStateFor(widget.type);
        final items = historyState.allItems;
        final isLoading = historyState.isLoading;
        final hasReachedMax = historyState.hasReachedMax;
        final errorMessage = historyState.errorMessage;

        return ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: <Widget>[
            // ── Gauge ──
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    tokens.deviceCardSurface.withValues(alpha: 0.6),
                    tokens.deviceCardSurface.withValues(alpha: 0.3),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: tokens.deviceCardBorder.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  SensorGauge(
                    value: widget.currentValue,
                    unit: widget.unit,
                    label: widget.label,
                    max: widget.gaugeMax,
                  ),
                  const SizedBox(height: 12),
                  // Status pill
                  _StatusPill(status: widget.status),
                ],
              ),
            ),

            // ── History header ──
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    SensorsStrings.history,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                  ),
                  const Spacer(),
                  if (historyState.pageData != null)
                    Text(
                      '${items.length} entries',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                ],
              ),
            ),

            // ── Error on first load ──
            if (errorMessage != null && items.isEmpty)
              _ErrorCard(
                message: errorMessage,
                onRetry: () {
                  context
                      .read<SensorsCubit>()
                      .loadHistory(type: widget.type, page: 1, limit: 10);
                },
              ),

            // ── Initial loading ──
            if (isLoading && items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),

            // ── Empty state ──
            if (!isLoading && items.isEmpty && errorMessage == null)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 48,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        SensorsStrings.noHistory,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── History items ──
            ...items.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _HistoryItemTile(
                  item: entry.value,
                  index: entry.key,
                  unit: widget.unit,
                ),
              );
            }),

            // ── Bottom loading indicator ──
            if (isLoading && items.isNotEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              ),

            // ── Reached end ──
            if (hasReachedMax && items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'All history loaded',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─────────────────────── Status pill ────────────────────────

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final DeviceStatusModel status;

  @override
  Widget build(BuildContext context) {
    final statusLabel = status.isOnline
        ? SensorsStrings.online
        : status.isOffline
            ? SensorsStrings.offline
            : SensorsStrings.unknown;

    final statusColor = status.isOnline
        ? const Color(0xFF22C55E)
        : status.isOffline
            ? const Color(0xFFF97316)
            : Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            statusLabel,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── History item ────────────────────────

class _HistoryItemTile extends StatelessWidget {
  const _HistoryItemTile({
    required this.item,
    required this.index,
    required this.unit,
  });

  final SensorHistoryItem item;
  final int index;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>() ??
        AppColors.darkTokens;
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tokens.deviceCardSurface.withValues(alpha: 0.55),
            tokens.deviceCardSurface.withValues(alpha: 0.3),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tokens.deviceCardBorder.withValues(alpha: 0.25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: <Widget>[
            // Value badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${item.value.toStringAsFixed(1)} $unit',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
              ),
            ),
            const Spacer(),
            Icon(
              Icons.access_time_rounded,
              size: 14,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 6),
            Text(
              _formatDate(item.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)}  ${two(local.hour)}:${two(local.minute)}';
  }
}

// ─────────────────────── Error card ─────────────────────────

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: <Widget>[
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text(SensorsStrings.retry),
          ),
        ],
      ),
    );
  }
}

// ──────────────────── Fire placeholder ───────────────────────

class _FirePlaceholderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>() ??
        AppColors.darkTokens;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                tokens.deviceCardSurface.withValues(alpha: 0.6),
                tokens.deviceCardSurface.withValues(alpha: 0.3),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: tokens.deviceCardBorder.withValues(alpha: 0.3)),
          ),
          child: const Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.local_fire_department_rounded, size: 48, color: Color(0xFFF97316)),
                SizedBox(height: 14),
                Text(
                  SensorsStrings.fireComingSoon,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

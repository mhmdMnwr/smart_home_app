import 'package:flutter/material.dart';

import '../../data/models/device_status_model.dart';

class DeviceControlSheet extends StatelessWidget {
  const DeviceControlSheet({
    super.key,
    required this.title,
    required this.firstLabel,
    required this.firstKey,
    required this.firstStatus,
    required this.secondLabel,
    required this.secondKey,
    required this.secondStatus,
    required this.onToggle,
  });

  final String title;
  final String firstLabel;
  final String firstKey;
  final DeviceStatusModel firstStatus;
  final String secondLabel;
  final String secondKey;
  final DeviceStatusModel secondStatus;
  final void Function(String deviceKey, bool isOn) onToggle;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _DeviceControlRow(
              label: firstLabel,
              status: firstStatus.displayStatus,
              onTapOn: () => onToggle(firstKey, true),
              onTapOff: () => onToggle(firstKey, false),
            ),
            const SizedBox(height: 12),
            _DeviceControlRow(
              label: secondLabel,
              status: secondStatus.displayStatus,
              onTapOn: () => onToggle(secondKey, true),
              onTapOff: () => onToggle(secondKey, false),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceControlRow extends StatelessWidget {
  const _DeviceControlRow({
    required this.label,
    required this.status,
    required this.onTapOn,
    required this.onTapOff,
  });

  final String label;
  final String status;
  final VoidCallback onTapOn;
  final VoidCallback onTapOff;

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = status.toLowerCase();
    final isOn = normalizedStatus == 'on';
    final isOff = normalizedStatus == 'off';
    final colorScheme = Theme.of(context).colorScheme;
    final statusTint = isOn
        ? const Color(0xFFDCFCE7)
        : isOff
        ? const Color(0xFFFEE2E2)
        : const Color(0xFFE5E7EB);
    final statusTextColor = isOn
        ? const Color(0xFF166534)
        : isOff
        ? const Color(0xFF991B1B)
        : const Color(0xFF374151);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusTint,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    status,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: statusTextColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: isOn
                          ? colorScheme.primary
                          : colorScheme.primary.withValues(alpha: 0.8),
                    ),
                    onPressed: onTapOn,
                    child: const Text('On'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isOff
                            ? colorScheme.primary
                            : colorScheme.outlineVariant,
                      ),
                      foregroundColor: isOff
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    onPressed: onTapOff,
                    child: const Text('Off'),
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

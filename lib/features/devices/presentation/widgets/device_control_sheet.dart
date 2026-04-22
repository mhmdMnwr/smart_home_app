import 'package:flutter/material.dart';

import '../../data/models/device_status_model.dart';
import '../../../home/presentation/constants/home_strings.dart';

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
    this.showThresholdControl = false,
    this.initialThreshold = 28,
    this.onSetThreshold,
  });

  final String title;
  final String firstLabel;
  final String firstKey;
  final DeviceStatusModel firstStatus;
  final String secondLabel;
  final String secondKey;
  final DeviceStatusModel secondStatus;
  final void Function(String deviceKey, bool isOn) onToggle;
  final bool showThresholdControl;
  final int initialThreshold;
  final Future<bool> Function(int value)? onSetThreshold;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
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
              isOnline: firstStatus.isOnline,
              onTapOn: () => onToggle(firstKey, true),
              onTapOff: () => onToggle(firstKey, false),
            ),
            const SizedBox(height: 12),
            _DeviceControlRow(
              label: secondLabel,
              isOnline: secondStatus.isOnline,
              onTapOn: () => onToggle(secondKey, true),
              onTapOff: () => onToggle(secondKey, false),
            ),
            if (showThresholdControl) ...<Widget>[
              const SizedBox(height: 16),
              _FanThresholdControl(
                initialThreshold: initialThreshold,
                onSetThreshold: onSetThreshold,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FanThresholdControl extends StatefulWidget {
  const _FanThresholdControl({
    required this.initialThreshold,
    required this.onSetThreshold,
  });

  final int initialThreshold;
  final Future<bool> Function(int value)? onSetThreshold;

  @override
  State<_FanThresholdControl> createState() => _FanThresholdControlState();
}

class _FanThresholdControlState extends State<_FanThresholdControl> {
  late final TextEditingController _thresholdController;
  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _thresholdController = TextEditingController(
      text: widget.initialThreshold.toString(),
    );
  }

  @override
  void dispose() {
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _submitThreshold() async {
    final value = int.tryParse(_thresholdController.text.trim());
    if (value == null) {
      setState(() {
        _errorText = HomeStrings.fanThresholdInvalid;
      });
      return;
    }

    final callback = widget.onSetThreshold;
    if (callback == null) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    final success = await callback(value);
    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
      _errorText = success ? null : HomeStrings.fanThresholdUpdateFailed;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(HomeStrings.fanThresholdUpdated)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              HomeStrings.fanThresholdTitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _thresholdController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: HomeStrings.fanThresholdHint,
                      errorText: _errorText,
                    ),
                    onChanged: (_) {
                      if (_errorText == null) {
                        return;
                      }

                      setState(() {
                        _errorText = null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: _isSaving ? null : _submitThreshold,
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(HomeStrings.fanThresholdSave),
                ),
              ],
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
    required this.isOnline,
    required this.onTapOn,
    required this.onTapOff,
  });

  final String label;
  final bool isOnline;
  final VoidCallback onTapOn;
  final VoidCallback onTapOff;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(
          alpha: isOnline ? 1.0 : 0.5,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOnline
              ? colorScheme.outlineVariant.withValues(alpha: 0.45)
              : colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.16 : 0.04,
            ),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        label,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isOnline ? null : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (!isOnline)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Device offline',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.error,
                            ),
                          ),
                        ),
                    ],
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
                      backgroundColor: colorScheme.primary,
                      disabledBackgroundColor: colorScheme.primary,
                      disabledForegroundColor: Colors.white,
                    ),
                    onPressed: onTapOn,
                    child: const Text('On'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      disabledBackgroundColor: colorScheme.primary,
                      disabledForegroundColor: Colors.white,
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

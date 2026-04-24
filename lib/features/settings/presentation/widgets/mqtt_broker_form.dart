import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/settings_cubit.dart';

class MqttBrokerForm extends StatefulWidget {
  const MqttBrokerForm({
    super.key,
    required this.currentHost,
    required this.isSaving,
  });

  final String? currentHost;
  final bool isSaving;

  @override
  State<MqttBrokerForm> createState() => _MqttBrokerFormState();
}

class _MqttBrokerFormState extends State<MqttBrokerForm> {
  late final TextEditingController _hostController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _hostController = TextEditingController(text: widget.currentHost ?? '');
  }

  @override
  void dispose() {
    _hostController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final current = (widget.currentHost ?? '').trim();
    final changed = _hostController.text.trim().isNotEmpty &&
        _hostController.text.trim() != current;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current: ${current.isEmpty ? 'Not set' : '$current : 1883'}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _hostController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Broker IP / Hostname',
            hintText: 'e.g. 192.168.1.100',
            filled: true,
            fillColor: const Color(0xFF141824),
            errorText: _error,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.isSaving
                    ? null
                    : () => context.read<SettingsCubit>().resetMqttBrokerHost(),
                child: const Text('Reset'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: (widget.isSaving || !changed)
                    ? null
                    : () async {
                        final host = _hostController.text.trim();
                        if (host.isEmpty) {
                          setState(() => _error = 'Broker host cannot be empty');
                          return;
                        }
                        setState(() => _error = null);
                        final ok =
                            await context.read<SettingsCubit>().updateMqttBrokerHost(host);
                        if (!context.mounted || !ok) return;
                        Navigator.of(context).pop();
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4F8EF7),
                  foregroundColor: Colors.white,
                ),
                child: widget.isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}


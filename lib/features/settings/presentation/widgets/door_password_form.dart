import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/settings_cubit.dart';

class DoorPasswordForm extends StatefulWidget {
  const DoorPasswordForm({
    super.key,
    required this.isSaving,
  });

  final bool isSaving;

  @override
  State<DoorPasswordForm> createState() => _DoorPasswordFormState();
}

class _DoorPasswordFormState extends State<DoorPasswordForm> {
  final TextEditingController _oldCodeController = TextEditingController();
  final TextEditingController _newCodeController = TextEditingController();
  bool _obscureOld = true;
  bool _obscureNew = true;

  @override
  void dispose() {
    _oldCodeController.dispose();
    _newCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        TextField(
          controller: _oldCodeController,
          obscureText: _obscureOld,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          decoration: InputDecoration(
            labelText: 'Current 4-digit code',
            filled: true,
            fillColor: const Color(0xFF141824),
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscureOld = !_obscureOld),
              icon: Icon(_obscureOld ? Icons.visibility_off : Icons.visibility),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _newCodeController,
          obscureText: _obscureNew,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          decoration: InputDecoration(
            labelText: 'New 4-digit code',
            filled: true,
            fillColor: const Color(0xFF141824),
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
              icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: widget.isSaving
                ? null
                : () async {
                    final oldCode = _oldCodeController.text.trim();
                    final newCode = _newCodeController.text.trim();
                    if (oldCode.length != 4 || newCode.length != 4) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Both codes must be exactly 4 digits'),
                          backgroundColor: colorScheme.error,
                        ),
                      );
                      return;
                    }
                    final ok = await context
                        .read<SettingsCubit>()
                        .changeDoorPassword(
                          oldPassword: oldCode,
                          newPassword: newCode,
                        );
                    if (!context.mounted || !ok) return;
                    Navigator.of(context).pop();
                  },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4F8EF7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: widget.isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Update'),
          ),
        ),
      ],
    );
  }
}

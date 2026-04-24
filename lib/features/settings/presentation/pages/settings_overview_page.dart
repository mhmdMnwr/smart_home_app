import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/settings_cubit.dart';
import '../cubit/settings_state.dart';
import '../widgets/door_password_form.dart';
import '../widgets/mqtt_broker_form.dart';
import '../widgets/profile_editor_form.dart';
import '../widgets/settings_action_tile.dart';
import '../widgets/settings_group_card.dart';
import 'family_members_page.dart';

class SettingsOverviewPage extends StatelessWidget {
  const SettingsOverviewPage({super.key});

  Future<void> _openPopup(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsCubit = context.read<SettingsCubit>();
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return BlocProvider<SettingsCubit>.value(
          value: settingsCubit,
          child: Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2130),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 10, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: Icon(
                            Icons.close_rounded,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        20,
                        20,
                        MediaQuery.of(dialogContext).viewInsets.bottom + 20,
                      ),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFF0F1117)),
      child: SafeArea(
        child: BlocConsumer<SettingsCubit, SettingsState>(
          listenWhen: (previous, current) =>
              previous.successMessage != current.successMessage ||
              previous.errorMessage != current.errorMessage,
          listener: (context, state) {
            final message = state.successMessage ?? state.errorMessage;
            if (message == null) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: state.errorMessage == null
                      ? const Color(0xFF22C55E)
                      : colorScheme.error,
                ),
              );
            context.read<SettingsCubit>().clearMessages();
          },
          builder: (context, state) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 26,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your account and smart home preferences.',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                SettingsGroupCard(
                  title: 'Account',
                  children: [
                    SettingsActionTile(
                      title: 'Profile',
                      subtitle: state.currentUser == null
                          ? (state.isLoadingProfile ? 'Loading…' : 'Not available')
                          : '${state.currentUser!.name} • ${state.currentUser!.email}',
                      trailingText: 'Edit',
                      enabled:
                          state.currentUser != null && !state.isLoadingProfile,
                      onTap: () {
                        final user = state.currentUser;
                        if (user == null) return;
                        _openPopup(
                          context,
                          title: 'Edit Profile',
                          child: ProfileEditorForm(user: user, state: state),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SettingsGroupCard(
                  title: 'Network',
                  children: [
                    SettingsActionTile(
                      title: 'MQTT Broker',
                      subtitle: (state.mqttBrokerHost ?? '').trim().isEmpty
                          ? 'Not set'
                          : '${state.mqttBrokerHost!.trim()} : 1883',
                      trailingText: 'Change',
                      onTap: () => _openPopup(
                        context,
                        title: 'MQTT Broker',
                        child: MqttBrokerForm(
                          currentHost: state.mqttBrokerHost,
                          isSaving: state.isSavingMqttBrokerHost,
                        ),
                      ),
                    ),
                  ],
                ),
                if (state.isAdmin) ...[
                  const SizedBox(height: 12),
                  SettingsGroupCard(
                    title: 'Admin',
                    children: [
                      SettingsActionTile(
                        title: 'Family Members',
                        subtitle: 'View all users, add, and delete members',
                        trailingText: 'Open',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => BlocProvider<SettingsCubit>.value(
                                value: context.read<SettingsCubit>(),
                                child: const FamilyMembersPage(),
                              ),
                            ),
                          );
                        },
                      ),
                      Divider(
                        height: 1,
                        color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                      ),
                      SettingsActionTile(
                        title: 'Door Password',
                        subtitle: 'Change the 4-digit door code',
                        trailingText: 'Update',
                        onTap: () => _openPopup(
                          context,
                          title: 'Door Password',
                          child: DoorPasswordForm(
                            isSaving: state.isChangingDoorPassword,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}


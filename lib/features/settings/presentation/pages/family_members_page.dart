import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';

import '../../../auth/data/models/user_model.dart';
import '../../data/models/family_member_model.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/settings_state.dart';

class FamilyMembersPage extends StatefulWidget {
  const FamilyMembersPage({super.key});

  @override
  State<FamilyMembersPage> createState() => _FamilyMembersPageState();
}

class _FamilyMembersPageState extends State<FamilyMembersPage> {
  @override
  void initState() {
    super.initState();
    context.read<SettingsCubit>().loadFamilyMembers();
  }

  void _showAddMemberSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<SettingsCubit>(),
        child: const _AddMemberSheet(),
      ),
    );
  }

  void _showAssignTagSheet(FamilyMemberModel member) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<SettingsCubit>(),
        child: _AssignTagSheet(member: member),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        title: const Text('Family Members'),
        backgroundColor: const Color(0xFF0F1117),
        actions: [
          IconButton(
            onPressed: _showAddMemberSheet,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: 'Add Member',
            style: IconButton.styleFrom(
              foregroundColor: const Color(0xFF4F8EF7),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: BlocConsumer<SettingsCubit, SettingsState>(
        listenWhen: (p, c) =>
            p.successMessage != c.successMessage ||
            p.errorMessage != c.errorMessage,
        listener: (context, state) {
          final msg = state.successMessage ?? state.errorMessage;
          if (msg == null) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(msg),
              backgroundColor: state.errorMessage == null
                  ? const Color(0xFF22C55E)
                  : colorScheme.error,
            ));
          context.read<SettingsCubit>().clearMessages();
        },
        builder: (context, state) {
          final currentEmail = state.currentUser?.email.toLowerCase();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1D27),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                  ),
                ),
                child: state.isLoadingFamilyMembers
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : Column(
                        children: [
                          for (var i = 0; i < state.familyMembers.length; i++) ...[
                            if (i != 0)
                              Divider(
                                height: 1,
                                color: colorScheme.outlineVariant
                                    .withValues(alpha: 0.35),
                              ),
                            _FamilyMemberTile(
                              member: state.familyMembers[i],
                              isSelf: currentEmail != null &&
                                  state.familyMembers[i]
                                          .email
                                          .toLowerCase() ==
                                      currentEmail,
                              isDeleting: state.deletingUserId ==
                                  state.familyMembers[i].id,
                              onDelete: () => context
                                  .read<SettingsCubit>()
                                  .deleteUser(
                                      userId: state.familyMembers[i].id),
                              onAssignTag: () =>
                                  _showAssignTagSheet(state.familyMembers[i]),
                            ),
                          ],
                          if (state.familyMembers.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(18),
                              child: Text(
                                'No family members yet.',
                                style: TextStyle(
                                    color: colorScheme.onSurfaceVariant),
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper: convert Uint8List to uppercase hex string
// ---------------------------------------------------------------------------
String _bytesToHex(Uint8List bytes) {
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join('');
}

// ---------------------------------------------------------------------------
// Bottom-sheet to assign an NFC card tag
// ---------------------------------------------------------------------------
class _AssignTagSheet extends StatefulWidget {
  const _AssignTagSheet({required this.member});
  final FamilyMemberModel member;

  @override
  State<_AssignTagSheet> createState() => _AssignTagSheetState();
}

class _AssignTagSheetState extends State<_AssignTagSheet> {
  final _tagController = TextEditingController();
  bool _isScanning = false;
  String? _scanError;

  @override
  void initState() {
    super.initState();
    if (widget.member.cardTag != null) {
      _tagController.text = widget.member.cardTag!;
    }
  }

  @override
  void dispose() {
    if (_isScanning) NfcManager.instance.stopSession();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _startNfcScan() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      setState(() => _scanError = 'NFC is not supported on this platform.');
      return;
    }

    final availability = await NfcManager.instance.checkAvailability();
    if (availability != NfcAvailability.enabled) {
      setState(() => _scanError = availability == NfcAvailability.disabled
          ? 'NFC is disabled. Please enable it in settings.'
          : 'NFC is not available on this device.');
      return;
    }

    setState(() {
      _isScanning = true;
      _scanError = null;
    });

    NfcManager.instance.startSession(
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
      },
      alertMessageIos: 'Hold your RFID card near the phone',
      onDiscovered: (NfcTag tag) async {
        String? uid;

        // Android: use NfcTagAndroid to get the UID
        if (Platform.isAndroid) {
          final androidTag = NfcTagAndroid.from(tag);
          if (androidTag != null) {
            uid = _bytesToHex(androidTag.id);
          }
        }

        await NfcManager.instance.stopSession(
          alertMessageIos: uid != null ? 'Card read!' : null,
          errorMessageIos: uid == null ? 'Could not read tag' : null,
        );

        if (!mounted) return;

        if (uid != null && uid.isNotEmpty) {
          setState(() {
            _tagController.text = uid!;
            _isScanning = false;
            _scanError = null;
          });
        } else {
          setState(() {
            _isScanning = false;
            _scanError = 'Could not read tag UID. Try again.';
          });
        }
      },
    );
  }

  void _stopNfcScan() {
    NfcManager.instance.stopSession();
    setState(() => _isScanning = false);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1D27),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'ASSIGN RFID CARD',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.member.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                if (widget.member.cardTag != null)
                  Row(
                    children: [
                      const Icon(Icons.credit_card_rounded,
                          size: 14, color: Color(0xFF4F8EF7)),
                      const SizedBox(width: 6),
                      Text(
                        'Current: ${widget.member.cardTag}',
                        style: const TextStyle(
                          color: Color(0xFF4F8EF7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                // NFC Scan button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isScanning ? _stopNfcScan : _startNfcScan,
                    icon: Icon(
                      _isScanning ? Icons.stop_rounded : Icons.nfc_rounded,
                      size: 20,
                    ),
                    label: Text(
                      _isScanning ? 'Stop Scanning' : 'Scan NFC Card',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          _isScanning ? Colors.redAccent : const Color(0xFF4F8EF7),
                      side: BorderSide(
                        color: _isScanning
                            ? Colors.redAccent.withValues(alpha: 0.5)
                            : const Color(0xFF4F8EF7).withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                if (_isScanning)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF4F8EF7),
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Waiting for NFC card…',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                if (_scanError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _scanError!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(child: Divider(color: Colors.white12)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or enter manually',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: Colors.white12)),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tagController,
                  style: const TextStyle(
                    color: Colors.white,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Card Tag ID',
                    hintText: 'e.g. A1B2C3D4',
                    filled: true,
                    fillColor: const Color(0xFF141824),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: state.isAssigningTag
                        ? null
                        : () async {
                            final tag = _tagController.text.trim();
                            if (tag.isEmpty) return;
                            final ok = await context
                                .read<SettingsCubit>()
                                .assignTag(
                                  userId: widget.member.id,
                                  cardTag: tag,
                                );
                            if (!ok || !mounted) return;
                            Navigator.of(context).pop();
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4F8EF7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: state.isAssigningTag
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Assign Card'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom-sheet form to add a new family member
// ---------------------------------------------------------------------------
class _AddMemberSheet extends StatefulWidget {
  const _AddMemberSheet();

  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<_AddMemberSheet> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  UserRole _role = UserRole.user;
  bool _obscure = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1D27),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'ADD FAMILY MEMBER',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                _field(_nameController, 'Name'),
                const SizedBox(height: 10),
                _field(_emailController, 'Email'),
                const SizedBox(height: 10),
                _field(
                  _passwordController,
                  'Password',
                  obscure: _obscure,
                  suffix: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _field(_phoneController, 'Phone (optional)'),
                const SizedBox(height: 10),
                DropdownButtonFormField<UserRole>(
                  initialValue: _role,
                  dropdownColor: const Color(0xFF1E2130),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Role',
                    filled: true,
                    fillColor: const Color(0xFF141824),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: UserRole.user, child: Text('User')),
                    DropdownMenuItem(
                      value: UserRole.admin,
                      child: Text('Admin'),
                    ),
                  ],
                  onChanged: (r) =>
                      setState(() => _role = r ?? UserRole.user),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: state.isCreatingUser
                        ? null
                        : () async {
                            if (_nameController.text.trim().isEmpty ||
                                _emailController.text.trim().isEmpty ||
                                _passwordController.text.trim().isEmpty) {
                              return;
                            }
                            final ok =
                                await context.read<SettingsCubit>().createUser(
                                      name: _nameController.text,
                                      email: _emailController.text,
                                      password: _passwordController.text,
                                      phoneNumber: _phoneController.text,
                                      role: _role,
                                    );
                            if (!ok || !mounted) return;
                            Navigator.of(context).pop();
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4F8EF7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: state.isCreatingUser
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Create'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFF141824),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tile for each family member
// ---------------------------------------------------------------------------
class _FamilyMemberTile extends StatelessWidget {
  const _FamilyMemberTile({
    required this.member,
    required this.isSelf,
    required this.isDeleting,
    required this.onDelete,
    required this.onAssignTag,
  });

  final FamilyMemberModel member;
  final bool isSelf;
  final bool isDeleting;
  final VoidCallback onDelete;
  final VoidCallback onAssignTag;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasTag = member.cardTag != null && member.cardTag!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isSelf
                  ? const Color(0xFF34C759)
                  : const Color(0xFF4F8EF7),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isSelf) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF34C759)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'You',
                          style: TextStyle(
                            color: Color(0xFF34C759),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${member.email} • ${member.role.name.toUpperCase()}',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                // Card tag badge
                Row(
                  children: [
                    Icon(
                      hasTag
                          ? Icons.credit_card_rounded
                          : Icons.credit_card_off_rounded,
                      size: 13,
                      color: hasTag
                          ? const Color(0xFF4F8EF7)
                          : Colors.white38,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      hasTag ? member.cardTag! : 'No card assigned',
                      style: TextStyle(
                        color: hasTag
                            ? const Color(0xFF4F8EF7)
                            : Colors.white38,
                        fontSize: 11,
                        fontWeight:
                            hasTag ? FontWeight.w600 : FontWeight.w400,
                        letterSpacing: hasTag ? 1.2 : 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Assign tag button
          IconButton(
            onPressed: onAssignTag,
            icon: const Icon(Icons.nfc_rounded, size: 20),
            tooltip: 'Assign Card Tag',
            style: IconButton.styleFrom(
              foregroundColor: const Color(0xFF4F8EF7),
            ),
          ),
          // Hide delete button for your own account
          if (!isSelf)
            TextButton(
              onPressed: isDeleting ? null : onDelete,
              child: isDeleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Delete',
                      style: TextStyle(color: Color(0xFF4F8EF7)),
                    ),
            ),
        ],
      ),
    );
  }
}

import '../../../auth/data/models/user_model.dart';
import '../../data/models/family_member_model.dart';

class SettingsState {
  const SettingsState({
    this.currentUser,
    this.isLoadingProfile = false,
    this.isSavingProfile = false,
    this.isCreatingUser = false,
    this.isChangingDoorPassword = false,
    this.familyMembers = const <FamilyMemberModel>[],
    this.isLoadingFamilyMembers = false,
    this.deletingUserId,
    this.mqttBrokerHost,
    this.isSavingMqttBrokerHost = false,
    this.errorMessage,
    this.successMessage,
  });

  final UserModel? currentUser;
  final bool isLoadingProfile;
  final bool isSavingProfile;
  final bool isCreatingUser;
  final bool isChangingDoorPassword;
  final List<FamilyMemberModel> familyMembers;
  final bool isLoadingFamilyMembers;
  final String? deletingUserId;
  final String? mqttBrokerHost;
  final bool isSavingMqttBrokerHost;
  final String? errorMessage;
  final String? successMessage;

  bool get isAdmin => currentUser?.role == UserRole.admin;

  static const Object _unset = Object();

  SettingsState copyWith({
    Object? currentUser = _unset,
    bool? isLoadingProfile,
    bool? isSavingProfile,
    bool? isCreatingUser,
    bool? isChangingDoorPassword,
    List<FamilyMemberModel>? familyMembers,
    bool? isLoadingFamilyMembers,
    Object? deletingUserId = _unset,
    Object? mqttBrokerHost = _unset,
    bool? isSavingMqttBrokerHost,
    Object? errorMessage = _unset,
    Object? successMessage = _unset,
  }) {
    return SettingsState(
      currentUser: identical(currentUser, _unset)
          ? this.currentUser
          : currentUser as UserModel?,
      isLoadingProfile: isLoadingProfile ?? this.isLoadingProfile,
      isSavingProfile: isSavingProfile ?? this.isSavingProfile,
      isCreatingUser: isCreatingUser ?? this.isCreatingUser,
      isChangingDoorPassword:
          isChangingDoorPassword ?? this.isChangingDoorPassword,
      familyMembers: familyMembers ?? this.familyMembers,
      isLoadingFamilyMembers:
          isLoadingFamilyMembers ?? this.isLoadingFamilyMembers,
      deletingUserId: identical(deletingUserId, _unset)
          ? this.deletingUserId
          : deletingUserId as String?,
      mqttBrokerHost: identical(mqttBrokerHost, _unset)
          ? this.mqttBrokerHost
          : mqttBrokerHost as String?,
      isSavingMqttBrokerHost:
          isSavingMqttBrokerHost ?? this.isSavingMqttBrokerHost,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      successMessage: identical(successMessage, _unset)
          ? this.successMessage
          : successMessage as String?,
    );
  }
}

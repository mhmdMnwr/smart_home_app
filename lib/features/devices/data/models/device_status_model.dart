class HomeDevicesStatusModel {
  const HomeDevicesStatusModel({
    required this.lamp1,
    required this.lamp2,
    required this.fan1,
    required this.fan2,
    this.dht11 = const DeviceStatusModel.unknown(),
    this.mq2 = const DeviceStatusModel.unknown(),
    this.alarm = const DeviceStatusModel.unknown(),
  });

  final DeviceStatusModel lamp1;
  final DeviceStatusModel lamp2;
  final DeviceStatusModel fan1;
  final DeviceStatusModel fan2;
  final DeviceStatusModel dht11;
  final DeviceStatusModel mq2;
  final DeviceStatusModel alarm;

  factory HomeDevicesStatusModel.fromApi(Map<String, dynamic> data) {
    return HomeDevicesStatusModel(
      lamp1: DeviceStatusModel.fromApi(data['lamp1']),
      lamp2: DeviceStatusModel.fromApi(data['lamp2']),
      fan1: DeviceStatusModel.fromApi(data['fan1']),
      fan2: DeviceStatusModel.fromApi(data['fan2']),
      dht11: DeviceStatusModel.fromApi(
        data['dht11'] ?? data['tempHumid'] ?? data['temp_humid'],
      ),
      mq2: DeviceStatusModel.fromApi(data['mq2'] ?? data['gas']),
      alarm: DeviceStatusModel.fromApi(
        data['alarm'] ?? data['alram'] ?? data['setAlarm'],
      ),
    );
  }

  String get lightsSummary =>
      'L1 ${lamp1.displayStatus} • L2 ${lamp2.displayStatus}';

  String get fansSummary => 'F1 ${fan1.displayStatus} • F2 ${fan2.displayStatus}';

  HomeDevicesStatusModel copyWith({
    DeviceStatusModel? lamp1,
    DeviceStatusModel? lamp2,
    DeviceStatusModel? fan1,
    DeviceStatusModel? fan2,
    DeviceStatusModel? dht11,
    DeviceStatusModel? mq2,
    DeviceStatusModel? alarm,
  }) {
    return HomeDevicesStatusModel(
      lamp1: lamp1 ?? this.lamp1,
      lamp2: lamp2 ?? this.lamp2,
      fan1: fan1 ?? this.fan1,
      fan2: fan2 ?? this.fan2,
      dht11: dht11 ?? this.dht11,
      mq2: mq2 ?? this.mq2,
      alarm: alarm ?? this.alarm,
    );
  }

  DeviceStatusModel deviceByKey(String key) {
    switch (key) {
      case 'lamp1':
        return lamp1;
      case 'lamp2':
        return lamp2;
      case 'fan1':
        return fan1;
      case 'fan2':
        return fan2;
      case 'dht11':
        return dht11;
      case 'mq2':
        return mq2;
      case 'alarm':
        return alarm;
      default:
        return const DeviceStatusModel.unknown();
    }
  }

  HomeDevicesStatusModel updateDeviceStatus({
    required String deviceKey,
    required bool isOn,
  }) {
    final nextStatus = DeviceStatusModel.fromPower(isOn);

    switch (deviceKey) {
      case 'lamp1':
        return copyWith(lamp1: nextStatus);
      case 'lamp2':
        return copyWith(lamp2: nextStatus);
      case 'fan1':
        return copyWith(fan1: nextStatus);
      case 'fan2':
        return copyWith(fan2: nextStatus);
      case 'alarm':
        return copyWith(alarm: nextStatus);
      default:
        return this;
    }
  }
}

class DeviceStatusModel {
  const DeviceStatusModel({required this.status, required this.updatedAt});

  const DeviceStatusModel.unknown() : status = null, updatedAt = null;

  final String? status;
  final DateTime? updatedAt;

  bool get isOnline => status?.toLowerCase() == 'online';
  bool get isOffline => status?.toLowerCase() == 'offline';

  String get displayStatus {
    if (isOnline) {
      return 'On';
    }

    if (isOffline) {
      return 'Off';
    }

    return 'Unknown';
  }

  factory DeviceStatusModel.fromApi(dynamic value) {
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'online' || normalized == 'on' || normalized == 'true') {
        return DeviceStatusModel(status: 'online', updatedAt: null);
      }

      if (normalized == 'offline' || normalized == 'off' || normalized == 'false') {
        return DeviceStatusModel(status: 'offline', updatedAt: null);
      }
    }

    if (value is bool) {
      return DeviceStatusModel(
        status: value ? 'online' : 'offline',
        updatedAt: null,
      );
    }

    if (value is! Map<String, dynamic>) {
      return const DeviceStatusModel.unknown();
    }

    final rawStatus = value['status'];
    final rawUpdatedAt = value['updatedAt'];

    DateTime? parsedUpdatedAt;
    if (rawUpdatedAt is String && rawUpdatedAt.trim().isNotEmpty) {
      parsedUpdatedAt = DateTime.tryParse(rawUpdatedAt);
    }

    return DeviceStatusModel(
      status: rawStatus?.toString(),
      updatedAt: parsedUpdatedAt,
    );
  }

  static DeviceStatusModel fromPower(bool isOn) {
    return DeviceStatusModel(
      status: isOn ? 'online' : 'offline',
      updatedAt: DateTime.now(),
    );
  }
}

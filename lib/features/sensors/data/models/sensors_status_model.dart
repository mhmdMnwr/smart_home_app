import '../../../devices/data/models/device_status_model.dart';

/// Status response from GET /status/sensors
/// Response shape: { data: { dht11: {...}, mq2: {...} } }
class SensorsStatusModel {
  const SensorsStatusModel({
    required this.dht11,
    required this.mq2,
  });

  final DeviceStatusModel dht11;
  final DeviceStatusModel mq2;

  factory SensorsStatusModel.fromApi(Map<String, dynamic> data) {
    return SensorsStatusModel(
      dht11: DeviceStatusModel.fromApi(data['dht11']),
      mq2: DeviceStatusModel.fromApi(data['mq2']),
    );
  }

  DeviceStatusModel statusFor(String sensorType) {
    switch (sensorType) {
      case 'temperature':
      case 'humidity':
        return dht11;
      case 'gas':
        return mq2;
      default:
        return const DeviceStatusModel.unknown();
    }
  }
}

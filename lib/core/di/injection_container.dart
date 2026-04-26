import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/presentation/cubit/login_cubit.dart';
import '../../features/devices/data/datasources/devices_remote_data_source.dart';
import '../../features/devices/data/repositories/devices_repository.dart';
import '../../features/devices/presentation/cubit/devices_cubit.dart';
import '../../features/logs/data/datasources/logs_remote_data_source.dart';
import '../../features/logs/data/repositories/logs_repository.dart';
import '../../features/logs/presentation/cubit/logs_cubit.dart';
import '../../features/sensors/data/datasources/sensors_remote_data_source.dart';
import '../../features/notifications/data/datasources/notifications_remote_data_source.dart';
import '../../features/notifications/data/repositories/notifications_repository.dart';
import '../../features/notifications/presentation/cubit/notifications_cubit.dart';
import '../../features/sensors/data/repositories/sensors_repository.dart';
import '../../features/sensors/presentation/cubit/sensors_cubit.dart';
import '../../features/settings/data/datasources/settings_remote_data_source.dart';
import '../../features/settings/data/repositories/settings_repository.dart';
import '../../features/settings/presentation/cubit/settings_cubit.dart';
import '../config/app_config.dart';
import '../network/api_client.dart';
import '../network/auth_interceptor.dart';
import '../network/mqtt_client.dart';
import '../network/mqtt_live_service.dart';
import '../storage/mqtt_broker_storage.dart';
import '../storage/token_storage.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  if (getIt.isRegistered<AuthRepository>()) {
    return;
  }

  final sharedPreferences = await SharedPreferences.getInstance();

  getIt.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  getIt.registerLazySingleton<MqttBrokerStorage>(
    () => MqttBrokerStorage(getIt<SharedPreferences>()),
  );
  getIt.registerLazySingleton<TokenStorage>(
    () => TokenStorage(getIt<SharedPreferences>()),
  );
  getIt.registerLazySingleton<Dio>(() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: const <String, dynamic>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      AuthInterceptor(dio: dio, tokenStorage: getIt<TokenStorage>()),
    );
    dio.interceptors.add(
  PrettyDioLogger(
    requestHeader: true,
    requestBody: true,
    responseBody: true,
    responseHeader: false,
    error: true,
    compact: true,
  ),
);

    return dio;
  });
  getIt.registerLazySingleton<ApiClient>(() => ApiClient(dio: getIt<Dio>()));
  getIt.registerLazySingleton<MqttClient>(() => MqttClient(dio: getIt<Dio>()));
  getIt.registerLazySingleton<MqttLiveService>(
    () => MqttLiveService(brokerStorage: getIt<MqttBrokerStorage>()),
  );
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: getIt<AuthRemoteDataSource>(),
      tokenStorage: getIt<TokenStorage>(),
    ),
  );
  getIt.registerLazySingleton<DevicesRemoteDataSource>(
    () => DevicesRemoteDataSourceImpl(
      apiClient: getIt<ApiClient>(),
      mqttClient: getIt<MqttClient>(),
    ),
  );
  getIt.registerLazySingleton<DevicesRepository>(
    () => DevicesRepositoryImpl(
      remoteDataSource: getIt<DevicesRemoteDataSource>(),
    ),
  );
  getIt.registerLazySingleton<SensorsRemoteDataSource>(
    () => SensorsRemoteDataSourceImpl(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<SensorsRepository>(
    () => SensorsRepositoryImpl(
      remoteDataSource: getIt<SensorsRemoteDataSource>(),
    ),
  );
  getIt.registerLazySingleton<SettingsRemoteDataSource>(
    () => SettingsRemoteDataSourceImpl(
      apiClient: getIt<ApiClient>(),
      mqttClient: getIt<MqttClient>(),
    ),
  );
  getIt.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(
      remoteDataSource: getIt<SettingsRemoteDataSource>(),
    ),
  );

  getIt.registerLazySingleton<NotificationsRemoteDataSource>(
    () => NotificationsRemoteDataSourceImpl(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<NotificationsRepository>(
    () => NotificationsRepositoryImpl(
      remoteDataSource: getIt<NotificationsRemoteDataSource>(),
    ),
  );
  getIt.registerLazySingleton<LogsRemoteDataSource>(
    () => LogsRemoteDataSourceImpl(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<LogsRepository>(
    () => LogsRepositoryImpl(
      remoteDataSource: getIt<LogsRemoteDataSource>(),
    ),
  );

  // Cubit remains a factory so each provider gets a fresh lifecycle instance.
  getIt.registerFactory<LoginCubit>(
    () => LoginCubit(authRepository: getIt<AuthRepository>()),
  );
  getIt.registerFactory<DevicesCubit>(
    () => DevicesCubit(devicesRepository: getIt<DevicesRepository>()),
  );
  getIt.registerFactory<SensorsCubit>(
    () => SensorsCubit(
      sensorsRepository: getIt<SensorsRepository>(),
      mqttLiveService: getIt<MqttLiveService>(),
    ),
  );
  getIt.registerFactory<SettingsCubit>(
    () => SettingsCubit(
      settingsRepository: getIt<SettingsRepository>(),
      mqttBrokerStorage: getIt<MqttBrokerStorage>(),
      mqttLiveService: getIt<MqttLiveService>(),
    ),
  );
  getIt.registerFactory<NotificationsCubit>(
    () => NotificationsCubit(
      notificationsRepository: getIt<NotificationsRepository>(),
    ),
  );
  getIt.registerFactory<LogsCubit>(
    () => LogsCubit(
      logsRepository: getIt<LogsRepository>(),
    ),
  );
}

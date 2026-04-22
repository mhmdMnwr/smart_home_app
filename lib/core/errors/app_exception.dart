class AppException implements Exception {
  const AppException({required this.message, this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException(String message) : super(message: message);
}

class ServerException extends AppException {
  const ServerException({required super.message, super.statusCode});
}

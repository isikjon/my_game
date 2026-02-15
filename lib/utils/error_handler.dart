import 'package:dio/dio.dart';

class AppException implements Exception {
  final String message;
  final int? statusCode;

  AppException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ErrorHandler {
  static AppException handleError(dynamic error) {
    if (error is DioException) {
      return handleDioError(error);
    } else if (error is AppException) {
      return error;
    } else {
      return AppException('Произошла неизвестная ошибка');
    }
  }

  static DioException handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return DioException(
          requestOptions: error.requestOptions,
          error: AppException('Превышено время ожидания'),
          type: error.type,
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ?? 
                       error.response?.data?['detail'] ?? 
                       'Ошибка сервера';
        return DioException(
          requestOptions: error.requestOptions,
          response: error.response,
          error: AppException(message, statusCode),
          type: error.type,
        );
      case DioExceptionType.cancel:
        return DioException(
          requestOptions: error.requestOptions,
          error: AppException('Запрос отменен'),
          type: error.type,
        );
      case DioExceptionType.connectionError:
        return DioException(
          requestOptions: error.requestOptions,
          error: AppException('Ошибка подключения к серверу'),
          type: error.type,
        );
      default:
        return DioException(
          requestOptions: error.requestOptions,
          error: AppException('Произошла ошибка при выполнении запроса'),
          type: error.type,
        );
    }
  }
}


/// Базовый URL продакшн-сервера викторины.
class ServerConfig {
  ServerConfig._();

  static const String baseUrl = 'http://159.194.220.7:3000';

  static Uri uri(String path) {
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$p');
  }
}

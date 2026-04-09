/// Базовый URL продакшн-сервера викторины.
class ServerConfig {
  ServerConfig._();

  static const String baseUrl = 'https://kwork.wazir.kg';

  static Uri uri(String path) {
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$p');
  }
}

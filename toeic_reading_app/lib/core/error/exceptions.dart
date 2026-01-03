// lib/core/error/exceptions.dart

// Exception cơ bản cho lỗi Server (Lỗi 4xx, 5xx)
class ServerException implements Exception {
  final String message;
  const ServerException({this.message = 'Lỗi máy chủ.'});

  @override
  String toString() => 'ServerException: $message';
}

// Exception cho lỗi Cache/Local DB
class CacheException implements Exception {
  final String message;
  const CacheException({this.message = 'Lỗi bộ nhớ đệm.'});
}

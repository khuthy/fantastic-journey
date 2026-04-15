import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
// Import from neon_db_service.dart
import 'neon_db_service.dart' show dioProvider;
/// Cloudflare R2 client.
///
/// R2 exposes an S3-compatible API. All requests use presigned URLs that are
/// generated server-side and returned by your API so that R2 credentials never
/// touch the client.
///
/// Presigned-URL pattern:
///   1. Client calls your API: GET /r2/presign?key=cameras/cam1/2024-01-01.mp4&operation=upload
///   2. API returns a short-lived URL signed with your R2 credentials
///   3. Client uploads/downloads directly to R2 using that URL
class R2StorageService {
  R2StorageService({required Dio dio}) : _dio = dio;

  final Dio _dio;

  // ---------------------------------------------------------------------------
  // Presigned URL helpers
  // ---------------------------------------------------------------------------

  Future<String> _getPresignedUrl({
    required String key,
    required String operation, // 'upload' | 'download'
    Duration expiry = const Duration(hours: 1),
  }) async {
    final response = await _dio.get('/r2/presign', queryParameters: {
      'key': key,
      'operation': operation,
      'expiry_seconds': expiry.inSeconds,
    });
    return (response.data as Map<String, dynamic>)['url'] as String;
  }

  // ---------------------------------------------------------------------------
  // Footage upload (used by security desktop app or edge worker)
  // ---------------------------------------------------------------------------

  /// Upload a local video file to R2.
  /// Returns the R2 object key on success.
  Future<String> uploadFootage({
    required File file,
    required String cameraId,
    required DateTime recordedAt,
    void Function(int sent, int total)? onProgress,
  }) async {
    final ext = file.path.split('.').last;
    final key = _footageKey(cameraId: cameraId, recordedAt: recordedAt, ext: ext);
    final presignedUrl = await _getPresignedUrl(key: key, operation: 'upload');

    final bytes = await file.readAsBytes();
    await _dio.put(
      presignedUrl,
      data: bytes,
      options: Options(
        headers: {
          'Content-Type': 'video/$ext',
          'Content-Length': bytes.length,
        },
      ),
      onSendProgress: onProgress,
    );
    return key;
  }

  /// Upload raw bytes (e.g. from camera stream buffer).
  Future<String> uploadFootageBytes({
    required Uint8List bytes,
    required String cameraId,
    required DateTime recordedAt,
    String ext = 'mp4',
    void Function(int sent, int total)? onProgress,
  }) async {
    final key = _footageKey(cameraId: cameraId, recordedAt: recordedAt, ext: ext);
    final presignedUrl = await _getPresignedUrl(key: key, operation: 'upload');

    await _dio.put(
      presignedUrl,
      data: bytes,
      options: Options(
        headers: {
          'Content-Type': 'video/$ext',
          'Content-Length': bytes.length,
        },
      ),
      onSendProgress: onProgress,
    );
    return key;
  }

  // ---------------------------------------------------------------------------
  // Footage download / streaming
  // ---------------------------------------------------------------------------

  /// Get a short-lived download URL for a footage clip.
  Future<String> getFootageUrl(
    String r2Key, {
    Duration expiry = const Duration(hours: 2),
  }) async {
    return _getPresignedUrl(
      key: r2Key,
      operation: 'download',
      expiry: expiry,
    );
  }

  /// Download a footage clip to device storage and return the local path.
  Future<String> downloadFootage(
    String r2Key, {
    void Function(int received, int total)? onProgress,
  }) async {
    final url = await getFootageUrl(r2Key);
    final dir = await getTemporaryDirectory();
    final filename = r2Key.replaceAll('/', '_');
    final savePath = '${dir.path}/$filename';

    await _dio.download(
      url,
      savePath,
      onReceiveProgress: onProgress,
    );
    return savePath;
  }

  // ---------------------------------------------------------------------------
  // Thumbnails
  // ---------------------------------------------------------------------------

  Future<String> uploadThumbnail({
    required File file,
    required String cameraId,
    required DateTime recordedAt,
  }) async {
    final key =
        'cameras/$cameraId/thumbnails/${recordedAt.millisecondsSinceEpoch}.jpg';
    final presignedUrl = await _getPresignedUrl(key: key, operation: 'upload');

    final bytes = await file.readAsBytes();
    await _dio.put(
      presignedUrl,
      data: bytes,
      options: Options(
        headers: {
          'Content-Type': 'image/jpeg',
          'Content-Length': bytes.length,
        },
      ),
    );
    return key;
  }

  Future<String> getThumbnailUrl(String key) async =>
      _getPresignedUrl(key: key, operation: 'download', expiry: const Duration(days: 1));

  // ---------------------------------------------------------------------------
  // Object management
  // ---------------------------------------------------------------------------

  Future<void> deleteObject(String key) async {
    await _dio.delete('/r2/object', queryParameters: {'key': key});
  }

  Future<List<Map<String, dynamic>>> listObjects({
    required String prefix,
    int? maxKeys,
    String? continuationToken,
  }) async {
    final response = await _dio.get('/r2/list', queryParameters: {
      'prefix': prefix,
      if (maxKeys != null) 'max_keys': maxKeys,
      if (continuationToken != null) 'continuation_token': continuationToken,
    });
    return (response.data as Map<String, dynamic>)['objects'] as List<Map<String, dynamic>>;
  }

  // ---------------------------------------------------------------------------
  // Key builder
  // ---------------------------------------------------------------------------

  static String _footageKey({
    required String cameraId,
    required DateTime recordedAt,
    required String ext,
  }) {
    final date = '${recordedAt.year.toString().padLeft(4, '0')}'
        '-${recordedAt.month.toString().padLeft(2, '0')}'
        '-${recordedAt.day.toString().padLeft(2, '0')}';
    final time = '${recordedAt.hour.toString().padLeft(2, '0')}'
        '${recordedAt.minute.toString().padLeft(2, '0')}'
        '${recordedAt.second.toString().padLeft(2, '0')}';
    return 'cameras/$cameraId/$date/${time}.$ext';
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final r2StorageServiceProvider = Provider<R2StorageService>((ref) {
  // Reuse the same Dio instance (already has auth interceptor)
  final dio = ref.watch(dioProvider);
  return R2StorageService(dio: dio);
});



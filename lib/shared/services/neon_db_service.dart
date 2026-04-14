import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin REST client that communicates with a serverless Neon Postgres endpoint.
///
/// All DB mutations go through your own edge/serverless function (e.g.
/// Cloudflare Workers, Vercel, or a small Node/Go API). This keeps Neon
/// credentials server-side and never exposes them to the Flutter client.
///
/// Configure the base URL via the NEON_API_URL environment variable or by
/// updating the constant below.
class NeonDbService {
  NeonDbService({required Dio dio, required FlutterSecureStorage storage})
      : _dio = dio,
        _storage = storage;

  final Dio _dio;
  final FlutterSecureStorage _storage;

  static const String _tokenKey = 'auth_token';
  static const String _refreshKey = 'refresh_token';

  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/sign-in',
      data: {'email': email, 'password': password},
    );
    final data = response.data as Map<String, dynamic>;
    await _saveTokens(
      token: data['access_token'] as String,
      refresh: data['refresh_token'] as String?,
    );
    return data;
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String unitNumber,
    String? idNumber,
    String? vehicleRegistration,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'full_name': fullName,
      'phone': phone,
      'unit_number': unitNumber,
      if (idNumber != null) 'id_number': idNumber,
      if (vehicleRegistration != null)
        'vehicle_registration': vehicleRegistration,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<void> signOut() async {
    try {
      await _dio.post('/auth/sign-out');
    } catch (_) {}
    await _clearTokens();
  }

  Future<Map<String, dynamic>?> refreshToken() async {
    final refresh = await _storage.read(key: _refreshKey);
    if (refresh == null) return null;
    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': refresh},
      );
      final data = response.data as Map<String, dynamic>;
      await _saveTokens(
        token: data['access_token'] as String,
        refresh: data['refresh_token'] as String?,
      );
      return data;
    } catch (_) {
      await _clearTokens();
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Residents / Users
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get('/users/me');
    return response.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getResidents({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final response = await _dio.get('/users', queryParameters: {
      'role': 'resident',
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> updateProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.patch('/users/$userId', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deactivateResident(String userId) async {
    await _dio.patch('/users/$userId', data: {'is_active': false});
  }

  // ---------------------------------------------------------------------------
  // Visitor passes
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> createVisitorPass({
    required String residentId,
    required String visitorName,
    required String visitorPhone,
    required String passType,   // 'qr' or 'otp'
    required DateTime expiresAt,
    String? vehicleRegistration,
    String? purpose,
    int maxUses = 1,
    String? notes,
  }) async {
    final response = await _dio.post('/passes', data: {
      'resident_id': residentId,
      'visitor_name': visitorName,
      'visitor_phone': visitorPhone,
      'pass_type': passType,
      'expires_at': expiresAt.toIso8601String(),
      if (vehicleRegistration != null)
        'vehicle_registration': vehicleRegistration,
      if (purpose != null) 'purpose': purpose,
      'max_uses': maxUses,
      if (notes != null) 'notes': notes,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getPassesForResident(
    String residentId, {
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      '/passes',
      queryParameters: {
        'resident_id': residentId,
        if (status != null) 'status': status,
        'page': page,
        'limit': limit,
      },
    );
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> validatePass(String token) async {
    final response = await _dio.post('/passes/validate', data: {'token': token});
    return response.data as Map<String, dynamic>;
  }

  Future<void> revokePass(String passId) async {
    await _dio.patch('/passes/$passId', data: {'status': 'revoked'});
  }

  // ---------------------------------------------------------------------------
  // Entry log
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getEntryLog({
    DateTime? from,
    DateTime? to,
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _dio.get('/entry-log', queryParameters: {
      if (from != null) 'from': from.toIso8601String(),
      if (to != null) 'to': to.toIso8601String(),
      'page': page,
      'limit': limit,
    });
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  // ---------------------------------------------------------------------------
  // Announcements
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getAnnouncements({
    String? targetRole,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get('/announcements', queryParameters: {
      if (targetRole != null) 'target_role': targetRole,
      'page': page,
      'limit': limit,
    });
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createAnnouncement({
    required String title,
    required String body,
    required String priority,
    DateTime? expiresAt,
    String? imageUrl,
    bool isPinned = false,
    List<String>? targetRoles,
  }) async {
    final response = await _dio.post('/announcements', data: {
      'title': title,
      'body': body,
      'priority': priority,
      if (expiresAt != null) 'expires_at': expiresAt.toIso8601String(),
      if (imageUrl != null) 'image_url': imageUrl,
      'is_pinned': isPinned,
      if (targetRoles != null) 'target_roles': targetRoles,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteAnnouncement(String announcementId) async {
    await _dio.delete('/announcements/$announcementId');
  }

  // ---------------------------------------------------------------------------
  // Cameras
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getCameras() async {
    final response = await _dio.get('/cameras');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getFootageRecords({
    required String cameraId,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int limit = 30,
  }) async {
    final response = await _dio.get('/cameras/$cameraId/footage',
        queryParameters: {
          if (from != null) 'from': from.toIso8601String(),
          if (to != null) 'to': to.toIso8601String(),
          'page': page,
          'limit': limit,
        });
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<void> _saveTokens({
    required String token,
    String? refresh,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    if (refresh != null) {
      await _storage.write(key: _refreshKey, value: refresh);
    }
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshKey);
  }

  Future<String?> get accessToken => _storage.read(key: _tokenKey);
}

// ---------------------------------------------------------------------------
// Dio factory with interceptors
// ---------------------------------------------------------------------------

Dio createDio({
  required String baseUrl,
  required FlutterSecureStorage storage,
}) {
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        // Surface readable error messages
        if (error.response != null) {
          final data = error.response!.data;
          String message = 'An error occurred';
          if (data is Map && data.containsKey('message')) {
            message = data['message'] as String;
          }
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              message: message,
              type: error.type,
            ),
          );
          return;
        }
        handler.next(error);
      },
    ),
  );

  return dio;
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final _secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  ),
);

/// Override [neonApiUrlProvider] in your app's ProviderScope with the real URL.
final neonApiUrlProvider = Provider<String>(
  (_) => const String.fromEnvironment(
    'NEON_API_URL',
    defaultValue: 'https://api.proteaglen.local',
  ),
);

final dioProvider = Provider<Dio>((ref) {
  final baseUrl = ref.watch(neonApiUrlProvider);
  final storage = ref.watch(_secureStorageProvider);
  return createDio(baseUrl: baseUrl, storage: storage);
});

final neonDbServiceProvider = Provider<NeonDbService>((ref) {
  return NeonDbService(
    dio: ref.watch(dioProvider),
    storage: ref.watch(_secureStorageProvider),
  );
});

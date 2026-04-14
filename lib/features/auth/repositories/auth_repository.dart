import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../../../shared/services/neon_db_service.dart';

class AuthRepository {
  AuthRepository(this._db);
  final NeonDbService _db;

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final data = await _db.signIn(email: email, password: password);
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String unitNumber,
    String? idNumber,
    String? vehicleRegistration,
  }) async {
    final data = await _db.register(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
      unitNumber: unitNumber,
      idNumber: idNumber,
      vehicleRegistration: vehicleRegistration,
    );
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> signOut() => _db.signOut();

  Future<UserModel?> getCurrentUser() async {
    try {
      final data = await _db.getMe();
      return UserModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<bool> get isAuthenticated async {
    final token = await _db.accessToken;
    return token != null;
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(neonDbServiceProvider));
});

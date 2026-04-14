import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final UserModel user;
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo) : super(const AuthInitial()) {
    _init();
  }

  final AuthRepository _repo;

  Future<void> _init() async {
    state = const AuthLoading();
    try {
      final user = await _repo.getCurrentUser();
      state = user != null
          ? AuthAuthenticated(user)
          : const AuthUnauthenticated();
    } catch (_) {
      state = const AuthUnauthenticated();
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();
    try {
      final user = await _repo.signIn(email: email, password: password);
      state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthError(_extractMessage(e));
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String unitNumber,
    String? idNumber,
    String? vehicleRegistration,
  }) async {
    state = const AuthLoading();
    try {
      final user = await _repo.register(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        unitNumber: unitNumber,
        idNumber: idNumber,
        vehicleRegistration: vehicleRegistration,
      );
      state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthError(_extractMessage(e));
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AuthUnauthenticated();
  }

  void clearError() {
    if (state is AuthError) state = const AuthUnauthenticated();
  }

  static String _extractMessage(Object e) {
    if (e is Exception) return e.toString().replaceAll('Exception: ', '');
    return 'An unexpected error occurred';
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

final currentUserProvider = Provider<UserModel?>((ref) {
  final state = ref.watch(authProvider);
  if (state is AuthAuthenticated) return state.user;
  return null;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider) is AuthAuthenticated;
});

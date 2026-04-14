import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/services/neon_db_service.dart';

final recentPassesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final db = ref.watch(neonDbServiceProvider);
  return db.getPassesForResident(user.id, limit: 10);
});

final activePassesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final db = ref.watch(neonDbServiceProvider);
  return db.getPassesForResident(user.id, status: 'active', limit: 50);
});

final recentAnnouncementsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = ref.watch(neonDbServiceProvider);
  return db.getAnnouncements(limit: 10);
});

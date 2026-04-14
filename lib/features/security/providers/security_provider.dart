import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/neon_db_service.dart';

final recentEntryLogProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = ref.watch(neonDbServiceProvider);
  return db.getEntryLog(limit: 50);
});

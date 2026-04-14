import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/neon_db_service.dart';

final adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final db = ref.watch(neonDbServiceProvider);
  // Fetch in parallel
  final results = await Future.wait([
    db.getResidents(limit: 1000),
    db.getPassesForResident('all', status: 'active', limit: 1000),
    db.getEntryLog(limit: 1000),
    db.getCameras(),
  ]);

  final residents = results[0] as List;
  final passes = results[1] as List;
  final entries = results[2] as List;
  final cameras = results[3] as List;

  final today = DateTime.now();
  final todayEntries = entries.where((e) {
    final d = DateTime.tryParse(e['created_at'] as String? ?? '');
    return d != null &&
        d.year == today.year &&
        d.month == today.month &&
        d.day == today.day;
  }).length;

  final camerasOnline =
      cameras.where((c) => c['status'] == 'online').length;

  return {
    'total_residents': residents.length,
    'active_passes': passes.length,
    'today_entries': todayEntries,
    'cameras_online': camerasOnline,
    'total_cameras': cameras.length,
  };
});

final allResidentsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = ref.watch(neonDbServiceProvider);
  return db.getResidents(limit: 200);
});

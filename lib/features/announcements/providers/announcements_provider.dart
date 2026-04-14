import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/announcement_model.dart';
import '../../../shared/services/neon_db_service.dart';

final announcementsListProvider =
    FutureProvider<List<AnnouncementModel>>((ref) async {
  final db = ref.watch(neonDbServiceProvider);
  final data = await db.getAnnouncements(limit: 50);
  return data.map(AnnouncementModel.fromJson).toList();
});

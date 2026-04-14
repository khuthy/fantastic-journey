import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/camera_model.dart';
import '../../../shared/services/neon_db_service.dart';

final cameraListProvider = FutureProvider<List<CameraModel>>((ref) async {
  final db = ref.watch(neonDbServiceProvider);
  final data = await db.getCameras();
  return data.map(CameraModel.fromJson).toList();
});

final footageProvider = FutureProviderFamily<List<FootageRecord>, String>(
  (ref, cameraId) async {
    final db = ref.watch(neonDbServiceProvider);
    final data = await db.getFootageRecords(cameraId: cameraId);
    return data.map(FootageRecord.fromJson).toList();
  },
);

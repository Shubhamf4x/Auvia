import '../data/models.dart';
import 'ai_service.dart' show ScanAnalysis;

abstract class CloudGateway {
  Future<String> complete({
    required String userId,
    required List<Map<String, dynamic>> messages,
    String? model,
  });

  Future<ScanAnalysis?> analyzeImage({
    required String userId,
    required List<int> imageBytes,
    String? hint,
  });

  Future<List<LifeItem>> fetchDelta({
    required String userId,
    required int sinceEpochMs,
  });

  Future<void> push({
    required String userId,
    required List<LifeItem> items,
  });
}

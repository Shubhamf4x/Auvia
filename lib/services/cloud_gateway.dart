import '../data/models.dart';
import 'ai_service.dart' show ScanAnalysis;

/// Abstract gateway for remote services (AI, sync, accounts).
///
/// Auvia is currently local-first and anonymous. This interface exists so a
/// future backend can be introduced WITHOUT restructuring the app:
///
///     UI
///      ↓
///     AiService / Repositories      (today: direct AI providers)
///      ↓
///     CloudGateway                  (this interface)
///      ↓
///     Backend (future)              (auth, validation, rate limits,
///      ↓                             secrets, provider rotation)
///     AI / Cloud services
///
/// Contract for the future implementation:
///  * The backend authenticates the user (token in Authorization header).
///  * The backend owns provider credentials — the app never receives or
///    stores AI provider keys.
///  * Every payload is scoped to an owner: userId is part of each request
///    and the backend enforces that the token matches the record owner
///    (never trust client-provided authorization).
abstract class CloudGateway {
  /// Sends a chat/analysis request through the backend gateway.
  /// Implementations must attach the session token and enforce limits
  /// server-side (frequency, payload size, conversation length).
  Future<String> complete({
    required String userId,
    required List<Map<String, dynamic>> messages,
    String? model,
  });

  /// Analyzes an image via the backend (vision pipeline stays server-side).
  Future<ScanAnalysis?> analyzeImage({
    required String userId,
    required List<int> imageBytes,
    String? hint,
  });

  /// Pulls incremental changes for [userId] since [sinceEpochMs].
  /// Only ever returns records owned by the authenticated user.
  Future<List<LifeItem>> fetchDelta({
    required String userId,
    required int sinceEpochMs,
  });

  /// Pushes local changes, tagged with the owner identity.
  Future<void> push({
    required String userId,
    required List<LifeItem> items,
  });
}

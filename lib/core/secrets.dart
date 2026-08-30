/// Central place for every credential the app ships with.
///
/// Priority:
///   1. Value stored by the user in secure storage (Keystore-backed).
///   2. Build-time override via `--dart-define=AUVIA_AI_KEY=...` or
///      `--dart-define-from-file=config/auvia.local.json` (gitignored).
///   3. Empty default — the app then runs on the keyless fallback AI and
///      on-device heuristics.
///
/// NEVER commit a real key here. This repository is public and GitHub
/// push protection (correctly) blocks secrets in source.
///
/// When Auvia later moves AI behind a backend
/// (see lib/services/cloud_gateway.dart), this constant should be removed
/// entirely and the app should call the gateway instead.
class Secrets {
  Secrets._();

  /// AI gateway key. Provide at build time:
  ///   --dart-define=AUVIA_AI_KEY=sk-or-v1-...
  /// or run `build_local.ps1`, which reads config/auvia.local.json.
  static const String compiledAiKey = String.fromEnvironment('AUVIA_AI_KEY');

  /// Default model used until the user picks another one.
  static const String compiledAiModel =
      'nvidia/nemotron-3-ultra-550b-a55b:free';
}

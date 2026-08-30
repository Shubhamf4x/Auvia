class Secrets {
  Secrets._();

  static const String compiledAiKey = String.fromEnvironment('AUVIA_AI_KEY');

  static const String compiledAiModel =
      'nvidia/nemotron-3-ultra-550b-a55b:free';
}

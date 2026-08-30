import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'data/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Color(0xFFF6F7FB),
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  // Global error hardening: log sanitized errors instead of crashing
  // silently. Never log user content or credentials.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      debugPrint('Auvia error: ${details.exception}');
    }
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      debugPrint('Auvia uncaught: $error');
    }
    return true;
  };

  final state = AppState();
  runApp(AppRoot(state: state));
}

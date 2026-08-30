import 'package:flutter/material.dart';
import 'app_state.dart';

class AppScope extends InheritedWidget {
  final AppState state;
  const AppScope({super.key, required this.state, required super.child});

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.state;

  @override
  bool updateShouldNotify(AppScope oldWidget) => true;
}

class StateRefresher extends StatelessWidget {
  final Widget Function(BuildContext, AppState) builder;
  const StateRefresher({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) => builder(context, state),
    );
  }
}

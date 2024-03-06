import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum ScreenState { sleep, awaked, locked, unlocked }

class DesktopScreenState {
  static const MethodChannel _channel = MethodChannel('screenstate');

  static DesktopScreenState? _instance;

  static DesktopScreenState get instance {
    if (_instance == null) {
      _instance = DesktopScreenState._();
      _channel.setMethodCallHandler(_instance!._handleMethodCall);
    }
    return _instance!;
  }

  DesktopScreenState._();

  final ValueNotifier<ScreenState> _activeState =
      ValueNotifier(ScreenState.awaked);

  ValueListenable<ScreenState> get isActive {
    return _activeState;
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case "onScreenStateChange":
        _onApplicationFocusChange(call.arguments as String);
        break;
      default:
        break;
    }
  }

  void _onApplicationFocusChange(String active) {
    _activeState.value = ScreenState.values.firstWhere(
      (e) => e.toString().split('.').last == active,
      orElse: () => ScreenState.awaked,
    );
  }
}

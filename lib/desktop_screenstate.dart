import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DesktopScreenState {
  static const MethodChannel _channel = MethodChannel('screenstate');

  static DesktopScreenState? _instance;

  static DesktopScreenState get instance {
    if (_instance == null) {
      _instance = DesktopScreenState._();
      _channel.setMethodCallHandler(_instance!._handleMethodCall);
      _channel.invokeMethod("init");
    }
    return _instance!;
  }

  DesktopScreenState._();

  final ValueNotifier<bool> _activeState = ValueNotifier(false);

  ValueListenable<bool> get isActive {
    return _activeState;
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case "onScreenStateChange":
        _onApplicationFocusChange(call.arguments as bool);
        break;
      default:
        break;
    }
  }

  void _onApplicationFocusChange(bool active) {
    _activeState.value = active;
  }
}

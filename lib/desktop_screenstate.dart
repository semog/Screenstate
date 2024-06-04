import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum ScreenState { sleep, awaked, locked, unlocked }

class DesktopScreenState {
  static const MethodChannel _channel = MethodChannel('screenstate');

  static DesktopScreenState? _instance;

  static DesktopScreenState get instance {
    if (_instance == null) {
      _instance = DesktopScreenState._();
      if (Platform.isWindows || Platform.isMacOS) {
        _channel.setMethodCallHandler(_instance!._handleMethodCall);
      } else if (Platform.isLinux) {
        linuxCode();
      }
    }
    return _instance!;
  }

  static void linuxCode() {
    Process.start('dbus-monitor', [
      '--session',
      "type='signal',interface='org.gnome.ScreenSaver'"
    ]).then((Process process) {
      // Capture stdout and stderr streams
      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((String line) {
        // Filter lines containing "boolean true" or "boolean false"
        if (line.contains(RegExp(r"boolean true|boolean false"))) {
          if (line.trim() == "boolean true") {
            _activeState.value = ScreenState.locked;
          } else {
            _activeState.value = ScreenState.unlocked;
          }
          // Handle the output as needed
        }
      });

      // Listen for process exit
      process.exitCode.then((int code) {
        debugPrint('Process exited with code $code');
        // Handle process exit, if needed
      });
    }).catchError((error) {
      debugPrint('Error starting process: $error');
      // Handle any errors that occur during process startup
    });
  }

  DesktopScreenState._();

  static final ValueNotifier<ScreenState> _activeState =
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

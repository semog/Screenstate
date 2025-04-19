import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum ScreenState { sleep, awaked, locked, unlocked }

/// Which screen state monitor to use on Linux
enum ScreenStateMonitor { dbus, gdbus }

class DesktopScreenState {
  static const _channel = MethodChannel('screenstate');

  /// Set the screen state monitor to use on Linux
  static var linuxMonitor = ScreenStateMonitor.dbus;

  static bool _disposing = false;
  static int _dbusPid = 0;
  static int _gdbusPid = 0;

  /// Singleton instance of DesktopScreenState
  static DesktopScreenState? _instance;
  static DesktopScreenState get instance => _instance ??= _createInstance();

  static DesktopScreenState _createInstance() {
    final instance = DesktopScreenState._();

    if (Platform.isWindows || Platform.isMacOS) {
      _channel.setMethodCallHandler(instance._handleMethodCall);
    } else if (Platform.isLinux) {
      switch (linuxMonitor) {
        case ScreenStateMonitor.gdbus:
          _runGdbusLinuxMonitor();
          break;
        case ScreenStateMonitor.dbus:
          _runDbusLinuxMonitor();
          break;
      }
    }

    return instance;
  }

  static void dispose() {
    _disposing = true;
    _stopDbusLinuxMonitor();
    _stopGdbusLinuxMonitor();
  }

  static void _runDbusLinuxMonitor() async {
    if (_disposing) {
      return;
    }

    _stopDbusLinuxMonitor();
    Process.start('dbus-monitor', [
      '--session',
      "type='signal',interface='org.gnome.ScreenSaver'"
    ]).then((Process process) {
      _dbusPid = process.pid;
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
        debugPrint('dbus-monitor exited with code $code');
        _dbusPid = 0;
        // Handle process exit, if needed
      });
    }).catchError((error) {
      debugPrint('Error starting dbus-monitor: $error');
      // Handle any errors that occur during process startup
    });
  }

  static void _stopDbusLinuxMonitor() {
    _killPid(_dbusPid);
    _dbusPid = 0;
  }

  // Regex to find the Session IdleHint property and capture its boolean value
  static final _idleHintRegex =
      RegExp(r"Session.*'IdleHint'\s*:\s*<(?<value>true|false)>");

  static void _runGdbusLinuxMonitor() async {
    if (_disposing) {
      return;
    }

    _stopGdbusLinuxMonitor();
    Process.start(
            'gdbus', ['monitor', '--system', '--dest=org.freedesktop.login1'])
        .then((Process process) {
      _gdbusPid = process.pid;
      // Capture stdout and stderr streams
      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((String line) {
        // Check if the line contains the IdleHint property change
        final match = _idleHintRegex.firstMatch(line);

        if (match == null) {
          return;
        }

        // Extract the captured boolean value ('true' or 'false')
        final valueString = match.namedGroup('value')?.toLowerCase() ?? 'false';

        _activeState.value =
            valueString == 'true' ? ScreenState.locked : ScreenState.unlocked;
      });

      // Listen for process exit
      process.exitCode.then((int code) {
        debugPrint('gdbus exited with code $code');
        _gdbusPid = 0;
        // Restart the monitor
        _runGdbusLinuxMonitor();
      });
    }).catchError((error) {
      debugPrint('Error starting gdbus: $error');
      // Handle any errors that occur during process startup
    });
  }

  static void _stopGdbusLinuxMonitor() {
    _killPid(_gdbusPid);
    _gdbusPid = 0;
  }

  DesktopScreenState._();

  static final _activeState = ValueNotifier(ScreenState.awaked);

  ValueListenable<ScreenState> get isActive => _activeState;

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

void _killPid(int pid) {
  if (pid <= 0) {
    return;
  }

  try {
    Process.killPid(pid, ProcessSignal.sigint);
    Process.killPid(pid, ProcessSignal.sigterm);
    Process.killPid(pid, ProcessSignal.sigkill);
  } catch (e) {
    debugPrint('Error killing process $pid: $e');
  }
}

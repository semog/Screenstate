import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:desktop_screenstate/desktop_screenstate_method_channel.dart';

void main() {
  MethodChannelDesktopScreenstate platform = MethodChannelDesktopScreenstate();
  const MethodChannel channel = MethodChannel('desktop_screenstate');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}

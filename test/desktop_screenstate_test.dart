import 'package:flutter_test/flutter_test.dart';
import 'package:desktop_screenstate/desktop_screenstate.dart';
import 'package:desktop_screenstate/desktop_screenstate_platform_interface.dart';
import 'package:desktop_screenstate/desktop_screenstate_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockDesktopScreenstatePlatform
    with MockPlatformInterfaceMixin
    implements DesktopScreenstatePlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final DesktopScreenstatePlatform initialPlatform = DesktopScreenstatePlatform.instance;

  test('$MethodChannelDesktopScreenstate is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelDesktopScreenstate>());
  });

  test('getPlatformVersion', () async {
    DesktopScreenstate desktopScreenstatePlugin = DesktopScreenstate();
    MockDesktopScreenstatePlatform fakePlatform = MockDesktopScreenstatePlatform();
    DesktopScreenstatePlatform.instance = fakePlatform;

    expect(await desktopScreenstatePlugin.getPlatformVersion(), '42');
  });
}

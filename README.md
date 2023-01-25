# desktop_screenstate
(https://pub.dev/packages/desktop_screenstate)

Allow your flutter desktop application to check whether the screen is on or off.

## Getting Started

1. Add `desktop_screenstate` to your `pubspec.yaml`.

```yaml
  desktop_screenstate: $latest_version
```

2. Then you can use `DesktopScreenState.instance.isActive` to listen window active event.

```dart
final ValueListenable<bool> event = DesktopScreenState.instance.isActive;

final bool active = event.value;

event.addListener(() {
  debugPrint("screen is on or off: ${event.value}");
});

```
value false means screen is on and value true means screen is off

## LICENSE

see LICENSE file
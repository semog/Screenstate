# Desktop ScreenState

**Desktop ScreenState** is a Flutter desktop plugin that provides functionality for your application to accurately determine whether the screen is on or off, as well as to detect if it's locked or unlocked.

## Platform Support

|   Linux   |   macOS   |  Windows  |
| :-------: | :-------: | :-------: |
|     ✅     |     ✅     |     ✅     |

### macOS

No changes are required.

### Windows

Make the following changes to the respective files:

#### `windows/runner/flutter_window.h`

```diff
#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
+ #include <winuser.h>
#include <memory>

#include "win32_window.h"

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  // The project to run.
  flutter::DartProject project_;
+ HPOWERNOTIFY power_notification_handle_ = nullptr;
  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_


```
#### `windows/runner/flutter_window.cpp`
```diff
#include "flutter_window.h"

#include <optional>
+ #include <wtsapi32.h>
#include "flutter/generated_plugin_registrant.h"
+ #pragma comment( lib, "wtsapi32.lib" )

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {
+ if (power_notification_handle_) {
+ UnregisterPowerSettingNotification(power_notification_handle_);
+ }
}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());
+ power_notification_handle_ = RegisterPowerSettingNotification(GetHandle(), &GUID_CONSOLE_DISPLAY_STATE, DEVICE_NOTIFY_WINDOW_HANDLE);
+ WTSRegisterSessionNotification(GetHandle(),NOTIFY_FOR_THIS_SESSION);
  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
```
### Linux
This plugin relies on the gnome-screensaver to provide screen state information.

#### Linux Important Note:
If gnome-screensaver is not installed on your Linux system, please install it before using this plugin. The functionality of the plugin depends on the presence of gnome-screensaver.
```
sudo apt-get install gnome-screensaver
```

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
2. You can now utilize `DesktopScreenState.instance.state` to get the current state of the screen:

```dart
final ScreenState state = DesktopScreenState.instance.state;

switch (state) {
  case ScreenState.awaked:
    debugPrint("Screen is on");
    break;
  case ScreenState.sleep:
    debugPrint("Screen is sleep");
    break;
  case ScreenState.locked:
    debugPrint("Screen is locked");
    break;
  case ScreenState.unlocked:
    debugPrint("Screen is unlocked");
    break;
}
The DesktopScreenState instance provides an enum ScreenState with the following possible values:



```

see LICENSE file
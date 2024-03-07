#include "include/desktop_screenstate/desktop_screenstate_plugin.h"

#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>
#include <powrprof.h> 
#include <optional>

#include <map>
#include <memory>
#include <sstream>

#include <flutter/event_channel.h>
#include <flutter/event_sink.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/method_channel.h>

namespace {

class DesktopScreenstatePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  explicit DesktopScreenstatePlugin(
      flutter::PluginRegistrarWindows *registrar,
      std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel);

  ~DesktopScreenstatePlugin() override;

 private:
  bool isScreenLocked = false;  
  flutter::PluginRegistrarWindows *registrar_;

  int proc_id_;

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;

  

  std::optional<HRESULT> HandleWindowProc(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam);



};

// static
void DesktopScreenstatePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), "screenstate",
      &flutter::StandardMethodCodec::GetInstance());

  HWND hwnd = nullptr;
  if (registrar->GetView()) {
    hwnd = registrar->GetView()->GetNativeWindow();
  }
  if (!hwnd) {
    std::cerr << "DesktopScreenstatePlugin: no flutter window." << std::endl;
    return;
  }

  auto plugin = std::make_unique<DesktopScreenstatePlugin>(registrar, std::move(channel));
  registrar->AddPlugin(std::move(plugin));
}

DesktopScreenstatePlugin::DesktopScreenstatePlugin(
    flutter::PluginRegistrarWindows *registrar,
    std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel
) : registrar_(registrar), channel_(std::move(channel)) {

  proc_id_ = registrar_->RegisterTopLevelWindowProcDelegate(
      [this](HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
       
        return this->HandleWindowProc(hwnd, message, wparam, lparam);
      });


 
}

DesktopScreenstatePlugin::~DesktopScreenstatePlugin() {
   
  registrar_->UnregisterTopLevelWindowProcDelegate(proc_id_);
}

std::optional<HRESULT> DesktopScreenstatePlugin::HandleWindowProc(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
 
  switch (message) {
   
      case WM_POWERBROADCAST:
            if (wparam == PBT_POWERSETTINGCHANGE) {
                POWERBROADCAST_SETTING *setting = (POWERBROADCAST_SETTING *)lparam;
                if (IsEqualGUID(setting->PowerSetting, GUID_CONSOLE_DISPLAY_STATE)) {
                    DWORD consoleDisplayState = *(DWORD*)setting->Data;
                     
                    if (consoleDisplayState == 0) {
                         channel_->InvokeMethod(
        "onScreenStateChange",
        std::make_unique<flutter::EncodableValue>("sleep"));
                        // Display is off
                    } else if (consoleDisplayState == 1) {
                       if (!isScreenLocked) {
                         channel_->InvokeMethod(
        "onScreenStateChange",
        std::make_unique<flutter::EncodableValue>("awaked"));
                       }
                        // Display is on
                    } 
        //             else if (consoleDisplayState == 2) {
        //                channel_->InvokeMethod(
        // "onScreenStateChange",
        // std::make_unique<flutter::EncodableValue>("dimm"));
        //                 // Display is dimmed
        //             }
                      }
                
            }
            break;

      case WM_WTSSESSION_CHANGE:
            switch (wparam) {
                case WTS_SESSION_LOCK:
                isScreenLocked = true; 
                  channel_->InvokeMethod(
        "onScreenStateChange",
        std::make_unique<flutter::EncodableValue>("locked"));
                    break;
                case WTS_SESSION_UNLOCK:
                isScreenLocked = false; 
                  channel_->InvokeMethod(
        "onScreenStateChange",
        std::make_unique<flutter::EncodableValue>("unlocked"));
                    // Windows is unlocked
                     
                    break;
            }
            break;
  }

  // return null to allow the default window proc to handle the message
  return std::nullopt;
}



}  // namespace

void DesktopScreenstatePluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  DesktopScreenstatePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}

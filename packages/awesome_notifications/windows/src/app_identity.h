#pragma once

#include <windows.h>

#include <filesystem>
#include <string>

namespace awesome_notifications {

/// Who the app is to the Windows notification platform.
///
/// An unpackaged (plain .exe) app has no identity, so toasts need an
/// AppUserModelID registered under HKCU\Software\Classes\AppUserModelId with a
/// display name and a COM activator CLSID — the same registration the Windows
/// Community Toolkit's DesktopNotificationManagerCompat does, without requiring
/// the Windows App SDK. A packaged (MSIX) app already has an identity.
struct AppIdentity {
  bool packaged = false;
  /// "AwesomeNotifications.<exe name>.<hash of the exe path>"; empty when packaged.
  std::wstring aumid;
  std::wstring displayName;
  std::wstring executablePath;
  /// The COM class Windows starts / calls when a toast is activated.
  GUID activatorClsid{};
  /// Per-app folder for the notification store and downloaded images.
  std::filesystem::path dataDirectory;

  static AppIdentity Resolve();

  /// Writes the AUMID + COM server registration (idempotent). No-op if packaged.
  bool RegisterInRegistry() const;

  /// True when Windows started this process to deliver a toast activation.
  static bool LaunchedByToast();
};

/// A name-based (deterministic) GUID: the same `name` always yields the same id.
GUID NameBasedGuid(const std::wstring& name);
std::wstring GuidToString(const GUID& guid);

}  // namespace awesome_notifications

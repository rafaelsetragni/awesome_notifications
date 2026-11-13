#include "app_identity.h"

#include <appmodel.h>
#include <shlobj.h>

#include <cwchar>
#include <cwctype>
#include <vector>

#include "win_utils.h"

#pragma comment(lib, "version.lib")

namespace awesome_notifications {

namespace {

constexpr wchar_t kToastActivatedArg[] = L"-ToastActivated";

uint64_t Fnv1a(const std::wstring& text, uint64_t basis) {
  uint64_t hash = basis;
  for (wchar_t c : text) {
    hash ^= static_cast<uint64_t>(c);
    hash *= 1099511628211ULL;
  }
  return hash;
}

std::wstring Lower(std::wstring text) {
  for (auto& c : text) c = static_cast<wchar_t>(std::towlower(c));
  return text;
}

/// Keeps characters valid in an AUMID segment.
std::wstring Sanitize(const std::wstring& text) {
  std::wstring out;
  for (wchar_t c : text) {
    if ((c >= L'a' && c <= L'z') || (c >= L'A' && c <= L'Z') || (c >= L'0' && c <= L'9') ||
        c == L'-' || c == L'_')
      out += c;
  }
  return out.empty() ? L"App" : out;
}

/// ProductName from the executable's version resource (Runner.rc), if any.
std::wstring ProductName(const std::wstring& exe) {
  DWORD handle = 0;
  DWORD size = ::GetFileVersionInfoSizeW(exe.c_str(), &handle);
  if (size == 0) return {};
  std::vector<BYTE> data(size);
  if (!::GetFileVersionInfoW(exe.c_str(), 0, size, data.data())) return {};

  struct Translation {
    WORD language;
    WORD codePage;
  }* translations = nullptr;
  UINT length = 0;
  if (!::VerQueryValueW(data.data(), L"\\VarFileInfo\\Translation",
                        reinterpret_cast<void**>(&translations), &length) ||
      length < sizeof(Translation))
    return {};

  wchar_t query[64];
  swprintf_s(query, L"\\StringFileInfo\\%04x%04x\\ProductName", translations[0].language,
             translations[0].codePage);
  wchar_t* value = nullptr;
  if (!::VerQueryValueW(data.data(), query, reinterpret_cast<void**>(&value), &length) ||
      length == 0)
    return {};
  return std::wstring(value);
}

std::filesystem::path LocalAppData() {
  PWSTR path = nullptr;
  std::filesystem::path result;
  if (SUCCEEDED(::SHGetKnownFolderPath(FOLDERID_LocalAppData, 0, nullptr, &path)))
    result = path;
  ::CoTaskMemFree(path);
  if (result.empty()) result = std::filesystem::temp_directory_path();
  return result;
}

bool SetString(HKEY root, const std::wstring& subKey, const wchar_t* name,
               const std::wstring& value) {
  HKEY key = nullptr;
  if (::RegCreateKeyExW(root, subKey.c_str(), 0, nullptr, 0, KEY_SET_VALUE, nullptr, &key,
                        nullptr) != ERROR_SUCCESS)
    return false;
  LSTATUS status = ::RegSetValueExW(
      key, name, 0, REG_SZ, reinterpret_cast<const BYTE*>(value.c_str()),
      static_cast<DWORD>((value.size() + 1) * sizeof(wchar_t)));
  ::RegCloseKey(key);
  return status == ERROR_SUCCESS;
}

}  // namespace

GUID NameBasedGuid(const std::wstring& name) {
  uint64_t high = Fnv1a(name, 14695981039346656037ULL);
  uint64_t low = Fnv1a(name, 0x84222325CBF29CE4ULL);
  GUID guid{};
  guid.Data1 = static_cast<unsigned long>(high >> 32);
  guid.Data2 = static_cast<unsigned short>(high >> 16);
  guid.Data3 = static_cast<unsigned short>((high & 0x0FFF) | 0x5000);  // version 5 style
  for (int i = 0; i < 8; ++i) guid.Data4[i] = static_cast<unsigned char>(low >> (56 - 8 * i));
  guid.Data4[0] = static_cast<unsigned char>((guid.Data4[0] & 0x3F) | 0x80);  // RFC 4122 variant
  return guid;
}

std::wstring GuidToString(const GUID& guid) {
  wchar_t buffer[64];
  ::StringFromGUID2(guid, buffer, 64);
  return buffer;
}

AppIdentity AppIdentity::Resolve() {
  AppIdentity identity;
  identity.executablePath = ExecutablePath();

  UINT32 length = 0;
  identity.packaged =
      ::GetCurrentPackageFullName(&length, nullptr) != APPMODEL_ERROR_NO_PACKAGE;

  std::filesystem::path exe(identity.executablePath);
  std::wstring stem = exe.stem().wstring();
  std::wstring product = ProductName(identity.executablePath);
  identity.displayName = product.empty() ? stem : product;

  // The exe path is part of the id, so two builds of the same app (debug /
  // release / installed) never steal each other's toast activations.
  wchar_t hash[17];
  swprintf_s(hash, L"%08llx",
             static_cast<unsigned long long>(Fnv1a(Lower(identity.executablePath),
                                                   14695981039346656037ULL) &
                                             0xFFFFFFFFULL));
  std::wstring id = L"AwesomeNotifications." + Sanitize(stem) + L"." + hash;
  if (!identity.packaged) identity.aumid = id;
  identity.activatorClsid = NameBasedGuid(id);
  identity.dataDirectory = LocalAppData() / L"AwesomeNotifications" / id;
  return identity;
}

bool AppIdentity::RegisterInRegistry() const {
  if (packaged) return true;
  std::wstring clsid = GuidToString(activatorClsid);
  bool ok = true;
  std::wstring appKey = L"Software\\Classes\\AppUserModelId\\" + aumid;
  ok = SetString(HKEY_CURRENT_USER, appKey, L"DisplayName", displayName) && ok;
  ok = SetString(HKEY_CURRENT_USER, appKey, L"CustomActivator", clsid) && ok;
  std::wstring serverKey = L"Software\\Classes\\CLSID\\" + clsid + L"\\LocalServer32";
  ok = SetString(HKEY_CURRENT_USER, serverKey, nullptr,
                  L"\"" + executablePath + L"\" " + kToastActivatedArg) && ok;
  return ok;
}

bool AppIdentity::LaunchedByToast() {
  const wchar_t* commandLine = ::GetCommandLineW();
  return commandLine != nullptr && std::wcsstr(commandLine, kToastActivatedArg) != nullptr;
}

}  // namespace awesome_notifications

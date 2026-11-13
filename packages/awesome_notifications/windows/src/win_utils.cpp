#include "win_utils.h"

#include <vector>

namespace awesome_notifications {

std::wstring Utf8ToWide(const std::string& text) {
  if (text.empty()) return {};
  int size = ::MultiByteToWideChar(CP_UTF8, 0, text.data(), static_cast<int>(text.size()),
                                   nullptr, 0);
  if (size <= 0) return {};
  std::wstring out(static_cast<size_t>(size), L'\0');
  ::MultiByteToWideChar(CP_UTF8, 0, text.data(), static_cast<int>(text.size()), out.data(),
                        size);
  return out;
}

std::string WideToUtf8(const std::wstring& text) {
  if (text.empty()) return {};
  int size = ::WideCharToMultiByte(CP_UTF8, 0, text.data(), static_cast<int>(text.size()),
                                   nullptr, 0, nullptr, nullptr);
  if (size <= 0) return {};
  std::string out(static_cast<size_t>(size), '\0');
  ::WideCharToMultiByte(CP_UTF8, 0, text.data(), static_cast<int>(text.size()), out.data(),
                        size, nullptr, nullptr);
  return out;
}

std::wstring ExecutablePath() {
  std::vector<wchar_t> buffer(MAX_PATH);
  while (true) {
    DWORD length = ::GetModuleFileNameW(nullptr, buffer.data(), static_cast<DWORD>(buffer.size()));
    if (length == 0) return {};
    if (length < buffer.size()) return std::wstring(buffer.data(), length);
    buffer.resize(buffer.size() * 2);
  }
}

std::wstring ExecutableDirectory() {
  std::wstring path = ExecutablePath();
  size_t slash = path.find_last_of(L"\\/");
  return slash == std::wstring::npos ? path : path.substr(0, slash);
}

}  // namespace awesome_notifications

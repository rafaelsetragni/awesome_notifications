#pragma once

#include <windows.h>

#include <string>

namespace awesome_notifications {

std::wstring Utf8ToWide(const std::string& text);
std::string WideToUtf8(const std::wstring& text);

/// Full path of the running executable.
std::wstring ExecutablePath();
/// Directory of the running executable (no trailing separator).
std::wstring ExecutableDirectory();

}  // namespace awesome_notifications

#include "image_resolver.h"

#include <windows.h>
#include <urlmon.h>

#include <algorithm>
#include <cctype>
#include <cstdio>
#include <cstring>
#include <system_error>

#include "awn/definitions.h"
#include "win_utils.h"

#pragma comment(lib, "urlmon.lib")

namespace awesome_notifications {

namespace {

bool StartsWith(const std::string& text, const char* prefix) {
  return text.rfind(prefix, 0) == 0;
}

bool IsFile(const std::filesystem::path& path) {
  std::error_code ec;
  return std::filesystem::is_regular_file(path, ec) && std::filesystem::file_size(path, ec) > 0;
}

/// Decodes %XX escapes of a file URI path.
std::string PercentDecode(const std::string& text) {
  std::string out;
  for (size_t i = 0; i < text.size(); ++i) {
    if (text[i] == '%' && i + 2 < text.size() && std::isxdigit(static_cast<unsigned char>(text[i + 1])) &&
        std::isxdigit(static_cast<unsigned char>(text[i + 2]))) {
      out += static_cast<char>(std::stoi(text.substr(i + 1, 2), nullptr, 16));
      i += 2;
    } else {
      out += text[i];
    }
  }
  return out;
}

}  // namespace

ImageResolver::ImageResolver(std::filesystem::path cacheDirectory)
    : cacheDirectory_(std::move(cacheDirectory)) {}

std::wstring ImageResolver::Resolve(const std::string& source) const {
  if (source.empty() || StartsWith(source, awn::media::RESOURCE)) return {};

  if (StartsWith(source, awn::media::HTTPS) || StartsWith(source, awn::media::HTTP))
    return Download(source);

  std::filesystem::path path;
  if (StartsWith(source, awn::media::FILE)) {
    std::string local = PercentDecode(source.substr(std::strlen(awn::media::FILE)));
    // file:///C:/x -> C:/x
    if (local.size() > 2 && local[0] == '/' && local[2] == ':') local.erase(0, 1);
    path = Utf8ToWide(local);
  } else {
    std::string asset = StartsWith(source, awn::media::ASSET)
                            ? source.substr(std::strlen(awn::media::ASSET))
                            : source;
    std::filesystem::path direct(Utf8ToWide(asset));
    path = direct.is_absolute()
               ? direct
               : std::filesystem::path(ExecutableDirectory()) / L"data" / L"flutter_assets" /
                     direct;
  }
  path = path.make_preferred();
  return IsFile(path) ? path.wstring() : std::wstring();
}

std::wstring ImageResolver::Download(const std::string& url) const {
  // Cache by URL: the same image is fetched once.
  uint64_t hash = 14695981039346656037ULL;
  for (unsigned char c : url) {
    hash ^= c;
    hash *= 1099511628211ULL;
  }
  std::string extension = ".png";
  std::string lower = url.substr(0, url.find_first_of("?#"));
  std::transform(lower.begin(), lower.end(), lower.begin(),
                 [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
  for (const char* candidate : {".jpg", ".jpeg", ".gif", ".png", ".bmp"}) {
    size_t n = std::strlen(candidate);
    if (lower.size() >= n && lower.compare(lower.size() - n, n, candidate) == 0) {
      extension = candidate;
      break;
    }
  }

  char name[32];
  std::snprintf(name, sizeof(name), "%016llx", static_cast<unsigned long long>(hash));
  std::filesystem::path target = cacheDirectory_ / (Utf8ToWide(name) + Utf8ToWide(extension));
  if (IsFile(target)) return target.wstring();

  std::error_code ec;
  std::filesystem::create_directories(cacheDirectory_, ec);
  std::filesystem::path partial = target;
  partial += L".part";
  HRESULT hr = ::URLDownloadToFileW(nullptr, Utf8ToWide(url).c_str(), partial.c_str(), 0, nullptr);
  if (FAILED(hr) || !IsFile(partial)) {
    std::filesystem::remove(partial, ec);
    return {};
  }
  std::filesystem::rename(partial, target, ec);
  return ec ? std::wstring() : target.wstring();
}

}  // namespace awesome_notifications

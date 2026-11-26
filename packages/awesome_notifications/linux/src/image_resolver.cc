#include "image_resolver.h"

#include <dlfcn.h>
#include <gio/gio.h>

#include <algorithm>
#include <cctype>
#include <cstdio>
#include <cstring>
#include <system_error>

#include "awn/definitions.h"
#include "linux_platform.h"

namespace awesome_notifications {

namespace {

bool StartsWith(const std::string& text, const char* prefix) { return text.rfind(prefix, 0) == 0; }

bool IsFile(const std::filesystem::path& path) {
  std::error_code ec;
  return std::filesystem::is_regular_file(path, ec) && std::filesystem::file_size(path, ec) > 0;
}

std::string PercentDecode(const std::string& text) {
  std::string out;
  for (size_t i = 0; i < text.size(); ++i) {
    if (text[i] == '%' && i + 2 < text.size() &&
        std::isxdigit(static_cast<unsigned char>(text[i + 1])) &&
        std::isxdigit(static_cast<unsigned char>(text[i + 2]))) {
      out += static_cast<char>(std::stoi(text.substr(i + 1, 2), nullptr, 16));
      i += 2;
    } else {
      out += text[i];
    }
  }
  return out;
}

/// libcurl, loaded at run time (every desktop distribution ships libcurl.so.4),
/// so building the plugin needs no curl headers. Option ids are part of
/// libcurl's stable ABI.
class Curl {
 public:
  static const Curl& Get() {
    static const Curl curl;
    return curl;
  }

  bool Download(const std::string& url, const std::filesystem::path& target) const {
    if (!init_) return false;
    FILE* file = std::fopen(target.c_str(), "wb");
    if (!file) return false;
    void* handle = init_();
    bool ok = false;
    if (handle) {
      setopt_(handle, kUrl, url.c_str());
      setopt_(handle, kWriteData, file);
      setopt_(handle, kFollowLocation, 1L);
      setopt_(handle, kFailOnError, 1L);
      setopt_(handle, kNoSignal, 1L);
      setopt_(handle, kTimeout, 30L);
      ok = perform_(handle) == 0;
      cleanup_(handle);
    }
    std::fclose(file);
    return ok;
  }

 private:
  static constexpr int kWriteData = 10001;
  static constexpr int kUrl = 10002;
  static constexpr int kTimeout = 13;
  static constexpr int kFailOnError = 45;
  static constexpr int kFollowLocation = 52;
  static constexpr int kNoSignal = 99;

  using InitFn = void* (*)();
  using SetoptFn = int (*)(void*, int, ...);
  using PerformFn = int (*)(void*);
  using CleanupFn = void (*)(void*);

  Curl() {
    void* lib = dlopen("libcurl.so.4", RTLD_NOW | RTLD_LOCAL);
    if (!lib) lib = dlopen("libcurl-gnutls.so.4", RTLD_NOW | RTLD_LOCAL);
    if (!lib) return;
    auto init = reinterpret_cast<InitFn>(dlsym(lib, "curl_easy_init"));
    setopt_ = reinterpret_cast<SetoptFn>(dlsym(lib, "curl_easy_setopt"));
    perform_ = reinterpret_cast<PerformFn>(dlsym(lib, "curl_easy_perform"));
    cleanup_ = reinterpret_cast<CleanupFn>(dlsym(lib, "curl_easy_cleanup"));
    if (init && setopt_ && perform_ && cleanup_) init_ = init;
  }

  InitFn init_ = nullptr;
  SetoptFn setopt_ = nullptr;
  PerformFn perform_ = nullptr;
  CleanupFn cleanup_ = nullptr;
};

/// Without libcurl, GIO can still fetch http(s) where gvfs is installed.
bool DownloadWithGio(const std::string& url, const std::filesystem::path& target) {
  GFile* source = g_file_new_for_uri(url.c_str());
  GFile* destination = g_file_new_for_path(target.c_str());
  gboolean ok = g_file_copy(source, destination, G_FILE_COPY_OVERWRITE, nullptr, nullptr,
                            nullptr, nullptr);
  g_object_unref(source);
  g_object_unref(destination);
  return ok;
}

}  // namespace

ImageResolver::ImageResolver(std::filesystem::path cacheDirectory)
    : cacheDirectory_(std::move(cacheDirectory)) {}

std::string ImageResolver::Resolve(const std::string& source) const {
  if (source.empty() || StartsWith(source, awn::media::RESOURCE)) return {};
  if (StartsWith(source, awn::media::HTTPS) || StartsWith(source, awn::media::HTTP))
    return Download(source);

  std::filesystem::path path;
  if (StartsWith(source, awn::media::FILE)) {
    path = PercentDecode(source.substr(std::strlen(awn::media::FILE)));
  } else {
    std::string asset =
        StartsWith(source, awn::media::ASSET) ? source.substr(std::strlen(awn::media::ASSET)) : source;
    std::filesystem::path direct(asset);
    path = direct.is_absolute()
               ? direct
               : linux_platform::ExecutableDirectory() / "data" / "flutter_assets" / direct;
  }
  return IsFile(path) ? path.string() : std::string();
}

std::string ImageResolver::Download(const std::string& url) const {
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
  for (const char* candidate : {".jpg", ".jpeg", ".gif", ".png", ".bmp", ".webp"}) {
    size_t n = std::strlen(candidate);
    if (lower.size() >= n && lower.compare(lower.size() - n, n, candidate) == 0) {
      extension = candidate;
      break;
    }
  }

  char name[32];
  std::snprintf(name, sizeof(name), "%016llx", static_cast<unsigned long long>(hash));
  std::filesystem::path target = cacheDirectory_ / (std::string(name) + extension);
  if (IsFile(target)) return target.string();

  std::error_code ec;
  std::filesystem::create_directories(cacheDirectory_, ec);
  std::filesystem::path partial = target;
  partial += ".part";
  bool ok = Curl::Get().Download(url, partial) || DownloadWithGio(url, partial);
  if (!ok || !IsFile(partial)) {
    std::filesystem::remove(partial, ec);
    return {};
  }
  std::filesystem::rename(partial, target, ec);
  return ec ? std::string() : target.string();
}

}  // namespace awesome_notifications

#pragma once

#include <filesystem>
#include <string>

namespace awesome_notifications {

/// Turns a notification image source into a local file a toast can show —
/// unpackaged apps can't point a toast at http(s) or app resources directly.
///   https://… / http://…  downloaded once into `cacheDirectory`
///   asset://path / path    <exe dir>\data\flutter_assets\path
///   file://path / C:\…     used as is
///   resource://…           no Windows equivalent (skipped)
/// Blocking (downloads): call it off the platform thread.
class ImageResolver {
 public:
  explicit ImageResolver(std::filesystem::path cacheDirectory);

  /// Local path, or empty when the source is empty / can't be resolved.
  std::wstring Resolve(const std::string& source) const;

 private:
  std::wstring Download(const std::string& url) const;
  std::filesystem::path cacheDirectory_;
};

}  // namespace awesome_notifications

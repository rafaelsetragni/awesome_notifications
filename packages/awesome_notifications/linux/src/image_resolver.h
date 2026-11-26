#pragma once

#include <filesystem>
#include <string>

namespace awesome_notifications {

/// Turns a notification image source into a local file a freedesktop
/// notification can show:
///   https://… / http://…  downloaded once into `cacheDirectory` (libcurl,
///                         loaded at run time: no build dependency)
///   asset://path / path    <exe dir>/data/flutter_assets/path
///   file://path / /abs     used as is
///   resource://…           no Linux equivalent (skipped)
/// Blocking (downloads): call it off the platform thread.
class ImageResolver {
 public:
  explicit ImageResolver(std::filesystem::path cacheDirectory);

  /// Local path, or empty when the source is empty / can't be resolved.
  std::string Resolve(const std::string& source) const;

 private:
  std::string Download(const std::string& url) const;
  std::filesystem::path cacheDirectory_;
};

}  // namespace awesome_notifications

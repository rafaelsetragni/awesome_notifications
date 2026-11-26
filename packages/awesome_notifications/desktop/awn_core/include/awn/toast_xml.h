#pragma once

#include <string>

#include "awn/export.h"
#include "awn/value.h"

namespace awn {

/// Local files a toast may show; the Windows presenter downloads / resolves the
/// model's image sources into these (unpackaged apps can only show local files).
struct ToastImages {
  std::string largeIcon;   // local file path, or empty
  std::string bigPicture;  // local file path, or empty
};

/// Renders a notification model into Windows toast XML (ToastGeneric). Pure
/// string generation, so it is unit-tested on every platform.
class AWN_API ToastXml {
 public:
  /// Windows shows at most 5 buttons on a toast.
  static constexpr size_t kMaxButtons = 5;

  static std::string render(const ValueMap& model, const ToastImages& images, bool silent);

  static std::string escape(const std::string& text);
  /// "C:\a b\c.png" -> "file:///C:/a%20b/c.png"
  static std::string fileUri(const std::string& path);
};

}  // namespace awn

#pragma once

#include <set>
#include <string>
#include <utility>
#include <vector>

#include "awn/export.h"
#include "awn/value.h"

namespace awn {

/// Local files a freedesktop notification may show (the Linux presenter
/// downloads / resolves the model's image sources into these).
struct FreedesktopImages {
  std::string largeIcon;   // local file path, or empty
  std::string bigPicture;  // local file path, or empty
};

/// A notification as the Desktop Notifications Specification
/// (org.freedesktop.Notifications.Notify) takes it.
struct FreedesktopNotification {
  std::string appIcon;
  std::string summary;
  std::string body;
  /// (action key, label) pairs, flattened into Notify's `actions` array. The
  /// content tap is the spec's "default" action; a button's key is its
  /// LaunchArgs activation string.
  std::vector<std::pair<std::string, std::string>> actions;

  // Hints
  int urgency = 1;  // 0 low, 1 normal, 2 critical
  std::string imagePath;  // file:// URI
  std::string category;
  bool suppressSound = false;
  /// Stays on screen after an action is invoked (KeepOnTop / locked).
  bool resident = false;
  /// The button whose text is typed in place (servers with "inline-reply").
  std::string inlineReplyAction;
  std::string inlineReplyPlaceholder;
};

/// Renders a notification model into a freedesktop notification. Pure, so it
/// is unit-tested on every platform.
class AWN_API Freedesktop {
 public:
  /// The spec's action key of a click on the notification itself.
  static constexpr const char* kDefaultAction = "default";
  /// The action key KDE reports typed text for (NotificationReplied).
  static constexpr const char* kInlineReplyAction = "inline-reply";

  /// `capabilities` are the server's (GetCapabilities): "actions",
  /// "body-markup", "inline-reply", … Unsupported features are left out.
  /// `importance` is the channel's (None/Min/Low/Default/High/Max).
  static FreedesktopNotification render(const ValueMap& model, const FreedesktopImages& images,
                                        bool silent, const std::string& importance,
                                        const std::set<std::string>& capabilities);

  /// Urgency of a channel importance: None/Min/Low → low, Default/High →
  /// normal, Max → critical.
  static int urgencyOf(const std::string& importance);
  /// Removes every tag and decodes the basic entities (servers without
  /// "body-markup").
  static std::string plainText(const std::string& html);
  /// Keeps <b>, <i> and <u> (the markup every "body-markup" server knows),
  /// escaping everything else.
  static std::string basicMarkup(const std::string& html);
  /// "/a b/c.png" -> "file:///a%20b/c.png"
  static std::string fileUri(const std::string& path);
};

}  // namespace awn

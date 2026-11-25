#pragma once

#include <gio/gio.h>

#include <filesystem>
#include <functional>
#include <memory>
#include <optional>
#include <string>

#include "media_model.h"

namespace awn_media {

/// The app's MPRIS 2 player on the session bus (GNOME, KDE, playerctl, …):
/// owns org.mpris.MediaPlayer2.<app id>.instance<pid> and exports
/// /org/mpris/MediaPlayer2 (org.mpris.MediaPlayer2 + .Player). The name is
/// taken at the first session, then kept for the app's life. Platform thread.
class MprisPlayer : public Player, public std::enable_shared_from_this<MprisPlayer> {
 public:
  struct Callbacks {
    /// A Player method call: returns whether it became a command.
    std::function<bool(const std::string& method, int64_t offsetUs, const std::string& trackId,
                       int64_t positionUs)>
        onMethod;
    /// The active session's position now, in ms.
    std::function<int64_t()> position;
    /// Brings the app's window forward (MediaPlayer2.Raise).
    std::function<void()> raise;
  };

  MprisPlayer(std::string appId, std::string identity, std::filesystem::path cacheDirectory,
              Callbacks callbacks);
  ~MprisPlayer() override;

  // Player
  void show(const Session& session) override;
  void seeked(const Session& session, int64_t positionMs) override;
  void clear() override;

  /// The bus name, once requested.
  const std::string& busName() const { return busName_; }

  // GDBus vtable entry points.
  void OnMethodCall(const gchar* interface, const gchar* method, GVariant* parameters,
                    GDBusMethodInvocation* invocation);
  GVariant* OnGetProperty(const gchar* interface, const gchar* property);

 private:
  bool Export();
  GVariant* Metadata() const;
  void EmitPlayerChanged(bool metadataOnly = false);
  /// Turns the artwork source into a file:// URL, downloading http(s) off the
  /// platform thread (then updates the metadata).
  void ResolveArtwork(const std::string& source);

  std::string appId_;
  std::string identity_;
  std::filesystem::path cacheDirectory_;
  Callbacks callbacks_;

  GDBusConnection* connection_ = nullptr;
  guint ownerId_ = 0;
  guint rootId_ = 0;
  guint playerId_ = 0;
  std::string busName_;

  std::optional<Session> session_;
  std::string artworkSource_;
  std::string artUrl_;
};

/// Local file of an artwork source: asset:// (or a relative path) under the
/// bundle's flutter_assets, file://, an absolute path; https:// and http://
/// downloaded once into `cacheDirectory` (blocking). Empty when unresolvable
/// (resource:// has no Linux equivalent).
std::string ResolveArtworkFile(const std::string& source,
                               const std::filesystem::path& cacheDirectory);

}  // namespace awn_media

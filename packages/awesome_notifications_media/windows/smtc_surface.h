#pragma once

// Unknwn.h before the C++/WinRT headers: classic COM interop (the SMTC interop
// interface) needs winrt to know ::IUnknown.
#include <windows.h>
#include <unknwn.h>

#include <cstdint>
#include <functional>
#include <memory>
#include <string>

#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Media.h>

#include "awn_media/media.h"
#include "smtc_mapping.h"

namespace awesome_notifications_media {

/// The app window's SystemMediaTransportControls (the Windows media flyout,
/// the lock screen and the media keys). One session per window. Platform
/// thread only; the system's events are posted back to it through `post`.
class SmtcSurface : public awn_media::MediaSurface,
                    public std::enable_shared_from_this<SmtcSurface> {
 public:
  using Post = std::function<void(std::function<void()>)>;
  /// The app's top-level window. Resolved at the first show: while plugins
  /// register, the Flutter view is not yet inside it.
  using Window = std::function<HWND()>;
  struct Callbacks {
    std::function<void(awn_media::Button)> onButton;
    /// The requested position, in milliseconds.
    std::function<void(int64_t)> onSeek;
  };

  SmtcSurface(Window window, Post post);
  ~SmtcSurface() override;

  void SetCallbacks(Callbacks callbacks) { callbacks_ = std::move(callbacks); }

  bool show(const awn_media::Session& session) override;
  void positionChanged(const awn_media::Session& session, bool jump) override;
  void clear() override;

 private:
  /// Gets the window's controls and subscribes to their events (once).
  bool Ensure();
  void UpdateTimeline(const awn_media::MediaModel& media);
  /// Resolves (downloads) the artwork off the platform thread, then sets it
  /// unless another artwork or session replaced it meanwhile.
  void LoadArtwork(const std::string& source, uint64_t generation);

  Window window_;
  Post post_;
  Callbacks callbacks_;
  winrt::Windows::Media::SystemMediaTransportControls smtc_{nullptr};
  winrt::event_token buttonToken_{};
  winrt::event_token seekToken_{};
  std::string sessionId_;
  std::string artwork_;
  uint64_t generation_ = 0;
};

}  // namespace awesome_notifications_media

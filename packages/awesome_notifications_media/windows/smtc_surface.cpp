#include "smtc_surface.h"

#include <systemmediatransportcontrolsinterop.h>
#include <urlmon.h>

#include <chrono>
#include <filesystem>
#include <optional>
#include <system_error>
#include <thread>
#include <vector>

#include <winrt/Windows.Storage.Streams.h>
#include <winrt/Windows.Storage.h>

#pragma comment(lib, "urlmon.lib")

namespace awesome_notifications_media {

using awn_media::ArtworkSource;
using awn_media::Button;
using awn_media::MediaModel;
using awn_media::Session;
using awn_media::SmtcStatus;
using winrt::Windows::Foundation::TimeSpan;
using winrt::Windows::Media::MediaPlaybackStatus;
using winrt::Windows::Media::MediaPlaybackType;
using winrt::Windows::Media::PlaybackPositionChangeRequestedEventArgs;
using winrt::Windows::Media::SystemMediaTransportControls;
using winrt::Windows::Media::SystemMediaTransportControlsButton;
using winrt::Windows::Media::SystemMediaTransportControlsButtonPressedEventArgs;
using winrt::Windows::Media::SystemMediaTransportControlsTimelineProperties;
using winrt::Windows::Storage::StorageFile;
using winrt::Windows::Storage::Streams::RandomAccessStreamReference;

namespace {

TimeSpan Milliseconds(int64_t ms) {
  return std::chrono::duration_cast<TimeSpan>(std::chrono::milliseconds(ms));
}

std::optional<Button> ButtonOf(SystemMediaTransportControlsButton button) {
  switch (button) {
    case SystemMediaTransportControlsButton::Play: return Button::Play;
    case SystemMediaTransportControlsButton::Pause: return Button::Pause;
    case SystemMediaTransportControlsButton::Stop: return Button::Stop;
    case SystemMediaTransportControlsButton::Next: return Button::Next;
    case SystemMediaTransportControlsButton::Previous: return Button::Previous;
    case SystemMediaTransportControlsButton::FastForward: return Button::FastForward;
    case SystemMediaTransportControlsButton::Rewind: return Button::Rewind;
    default: return std::nullopt;
  }
}

MediaPlaybackStatus StatusOf(SmtcStatus status) {
  switch (status) {
    case SmtcStatus::Closed: return MediaPlaybackStatus::Closed;
    case SmtcStatus::Changing: return MediaPlaybackStatus::Changing;
    case SmtcStatus::Playing: return MediaPlaybackStatus::Playing;
    case SmtcStatus::Paused: return MediaPlaybackStatus::Paused;
    case SmtcStatus::Stopped: break;
  }
  return MediaPlaybackStatus::Stopped;
}

std::wstring Wide(const std::string& utf8) { return std::wstring(winrt::to_hstring(utf8)); }

bool IsFile(const std::filesystem::path& path) {
  std::error_code ec;
  return std::filesystem::is_regular_file(path, ec) && std::filesystem::file_size(path, ec) > 0;
}

std::filesystem::path ExecutableDirectory() {
  std::vector<wchar_t> buffer(MAX_PATH);
  while (true) {
    DWORD length = ::GetModuleFileNameW(nullptr, buffer.data(), static_cast<DWORD>(buffer.size()));
    if (length == 0) return {};
    if (length < buffer.size())
      return std::filesystem::path(std::wstring(buffer.data(), length)).parent_path();
    buffer.resize(buffer.size() * 2);
  }
}

/// A local file for the artwork (an https one is downloaded once into the temp
/// folder), or empty. Blocking: off the platform thread.
std::filesystem::path ResolveArtwork(const ArtworkSource& artwork) {
  std::filesystem::path path;
  switch (artwork.kind) {
    case ArtworkSource::Kind::None:
      return {};
    case ArtworkSource::Kind::File:
      path = Wide(artwork.path);
      break;
    case ArtworkSource::Kind::Asset:
      path = ExecutableDirectory() / L"data" / L"flutter_assets" / Wide(artwork.path);
      break;
    case ArtworkSource::Kind::Remote: {
      std::error_code ec;
      std::filesystem::path folder =
          std::filesystem::temp_directory_path(ec) / L"awesome_notifications_media";
      if (ec) return {};
      path = folder / Wide(awn_media::artworkCacheName(artwork.path));
      if (IsFile(path)) return path;
      std::filesystem::create_directories(folder, ec);
      std::filesystem::path partial = path;
      partial += L".part";
      HRESULT hr =
          ::URLDownloadToFileW(nullptr, Wide(artwork.path).c_str(), partial.c_str(), 0, nullptr);
      if (FAILED(hr) || !IsFile(partial)) {
        std::filesystem::remove(partial, ec);
        return {};
      }
      std::filesystem::rename(partial, path, ec);
      if (ec) return {};
      break;
    }
  }
  path = path.make_preferred();
  return IsFile(path) ? path : std::filesystem::path();
}

}  // namespace

SmtcSurface::SmtcSurface(Window window, Post post)
    : window_(std::move(window)), post_(std::move(post)) {}

SmtcSurface::~SmtcSurface() {
  if (!smtc_) return;
  try {
    smtc_.ButtonPressed(buttonToken_);
    smtc_.PlaybackPositionChangeRequested(seekToken_);
  } catch (const winrt::hresult_error&) {
  }
}

bool SmtcSurface::Ensure() {
  if (smtc_) return true;
  HWND window = window_ ? window_() : nullptr;
  if (!window) return false;
  try {
    auto interop = winrt::get_activation_factory<SystemMediaTransportControls,
                                                 ISystemMediaTransportControlsInterop>();
    SystemMediaTransportControls smtc{nullptr};
    winrt::check_hresult(interop->GetForWindow(
        window,
        reinterpret_cast<const IID&>(
            winrt::guid_of<winrt::Windows::Media::ISystemMediaTransportControls>()),
        winrt::put_abi(smtc)));

    // Raised on a background thread: handled on the platform thread.
    std::weak_ptr<SmtcSurface> weak = weak_from_this();
    buttonToken_ = smtc.ButtonPressed(
        [weak](const SystemMediaTransportControls&,
               const SystemMediaTransportControlsButtonPressedEventArgs& args) {
          auto button = ButtonOf(args.Button());
          auto self = weak.lock();
          if (!button || !self) return;
          self->post_([weak, pressed = *button] {
            auto surface = weak.lock();
            if (surface && surface->callbacks_.onButton) surface->callbacks_.onButton(pressed);
          });
        });
    seekToken_ = smtc.PlaybackPositionChangeRequested(
        [weak](const SystemMediaTransportControls&,
               const PlaybackPositionChangeRequestedEventArgs& args) {
          int64_t position =
              std::chrono::duration_cast<std::chrono::milliseconds>(args.RequestedPlaybackPosition())
                  .count();
          auto self = weak.lock();
          if (!self) return;
          self->post_([weak, position] {
            auto surface = weak.lock();
            if (surface && surface->callbacks_.onSeek) surface->callbacks_.onSeek(position);
          });
        });
    smtc_ = smtc;
    return true;
  } catch (const winrt::hresult_error&) {
    return false;
  }
}

bool SmtcSurface::show(const Session& shown) {
  if (!Ensure()) return false;
  const MediaModel& session = shown.media;
  try {
    auto buttons = awn_media::buttonStatesOf(session);
    smtc_.IsEnabled(true);
    smtc_.IsPlayEnabled(buttons.play);
    smtc_.IsPauseEnabled(buttons.pause);
    smtc_.IsStopEnabled(buttons.stop);
    smtc_.IsNextEnabled(buttons.next);
    smtc_.IsPreviousEnabled(buttons.previous);
    smtc_.IsFastForwardEnabled(buttons.fastForward);
    smtc_.IsRewindEnabled(buttons.rewind);
    smtc_.PlaybackStatus(StatusOf(awn_media::smtcStatusOf(session.playback())));
    if (session.speed > 0) smtc_.PlaybackRate(session.speed);

    bool newSession = session.sessionId != sessionId_;
    bool newArtwork = newSession || session.artwork != artwork_;
    auto updater = smtc_.DisplayUpdater();
    if (newSession) updater.ClearAll();
    updater.Type(MediaPlaybackType::Music);
    auto music = updater.MusicProperties();
    music.Title(winrt::to_hstring(session.title));
    music.Artist(winrt::to_hstring(session.artist));
    music.AlbumTitle(winrt::to_hstring(session.album));
    if (newArtwork) updater.Thumbnail(nullptr);
    updater.Update();
    UpdateTimeline(session);

    sessionId_ = session.sessionId;
    if (newArtwork) {
      artwork_ = session.artwork;
      LoadArtwork(session.artwork, ++generation_);
    }
    return true;
  } catch (const winrt::hresult_error&) {
    return false;
  }
}

void SmtcSurface::positionChanged(const Session& session, bool) {
  if (!smtc_) return;
  try {
    UpdateTimeline(session.media);
  } catch (const winrt::hresult_error&) {
  }
}

void SmtcSurface::clear() {
  sessionId_.clear();
  artwork_.clear();
  ++generation_;
  if (!smtc_) return;
  try {
    smtc_.PlaybackStatus(MediaPlaybackStatus::Closed);
    auto updater = smtc_.DisplayUpdater();
    updater.ClearAll();
    updater.Update();
    smtc_.UpdateTimelineProperties(SystemMediaTransportControlsTimelineProperties());
    smtc_.IsEnabled(false);
  } catch (const winrt::hresult_error&) {
  }
}

void SmtcSurface::UpdateTimeline(const MediaModel& session) {
  // A live stream (no duration) gets an empty timeline: no progress bar.
  auto timeline = awn_media::timelineOf(session);
  SystemMediaTransportControlsTimelineProperties properties;
  properties.StartTime(Milliseconds(timeline.start));
  properties.EndTime(Milliseconds(timeline.end));
  properties.Position(Milliseconds(timeline.position));
  properties.MinSeekTime(Milliseconds(timeline.minSeek));
  properties.MaxSeekTime(Milliseconds(timeline.maxSeek));
  smtc_.UpdateTimelineProperties(properties);
}

void SmtcSurface::LoadArtwork(const std::string& source, uint64_t generation) {
  ArtworkSource artwork = awn_media::artworkSourceOf(source);
  if (artwork.kind == ArtworkSource::Kind::None) return;

  std::weak_ptr<SmtcSurface> weak = weak_from_this();
  Post post = post_;
  std::thread([weak, post, artwork, generation]() {
    HRESULT com = ::CoInitializeEx(nullptr, COINIT_MULTITHREADED);
    try {
      std::filesystem::path path = ResolveArtwork(artwork);
      if (!path.empty()) {
        StorageFile file = StorageFile::GetFileFromPathAsync(path.wstring()).get();
        winrt::agile_ref<RandomAccessStreamReference> thumbnail{
            RandomAccessStreamReference::CreateFromFile(file)};
        post([weak, thumbnail, generation]() {
          auto self = weak.lock();
          if (!self || !self->smtc_ || self->generation_ != generation) return;
          try {
            auto updater = self->smtc_.DisplayUpdater();
            updater.Thumbnail(thumbnail.get());
            updater.Update();
          } catch (const winrt::hresult_error&) {
          }
        });
      }
    } catch (const winrt::hresult_error&) {
    }
    if (SUCCEEDED(com)) ::CoUninitialize();
  }).detach();
}

}  // namespace awesome_notifications_media

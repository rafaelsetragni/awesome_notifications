#include "mpris_player.h"

#include <dlfcn.h>
#include <unistd.h>

#include <algorithm>
#include <cstdio>
#include <cstring>
#include <system_error>
#include <thread>

namespace awn_media {

namespace {

constexpr const char* kObjectPath = "/org/mpris/MediaPlayer2";
constexpr const char* kRootInterface = "org.mpris.MediaPlayer2";
constexpr const char* kPlayerInterface = "org.mpris.MediaPlayer2.Player";

constexpr const char* kIntrospection = R"XML(
<node>
  <interface name="org.mpris.MediaPlayer2">
    <method name="Raise"/>
    <method name="Quit"/>
    <property name="CanQuit" type="b" access="read"/>
    <property name="CanRaise" type="b" access="read"/>
    <property name="HasTrackList" type="b" access="read"/>
    <property name="Identity" type="s" access="read"/>
    <property name="DesktopEntry" type="s" access="read"/>
    <property name="SupportedUriSchemes" type="as" access="read"/>
    <property name="SupportedMimeTypes" type="as" access="read"/>
  </interface>
  <interface name="org.mpris.MediaPlayer2.Player">
    <method name="Next"/>
    <method name="Previous"/>
    <method name="Pause"/>
    <method name="PlayPause"/>
    <method name="Stop"/>
    <method name="Play"/>
    <method name="Seek"><arg direction="in" name="Offset" type="x"/></method>
    <method name="SetPosition">
      <arg direction="in" name="TrackId" type="o"/>
      <arg direction="in" name="Position" type="x"/>
    </method>
    <method name="OpenUri"><arg direction="in" name="Uri" type="s"/></method>
    <signal name="Seeked"><arg name="Position" type="x"/></signal>
    <property name="PlaybackStatus" type="s" access="read"/>
    <property name="Rate" type="d" access="readwrite"/>
    <property name="Metadata" type="a{sv}" access="read"/>
    <property name="Volume" type="d" access="readwrite"/>
    <property name="Position" type="x" access="read"/>
    <property name="MinimumRate" type="d" access="read"/>
    <property name="MaximumRate" type="d" access="read"/>
    <property name="CanGoNext" type="b" access="read"/>
    <property name="CanGoPrevious" type="b" access="read"/>
    <property name="CanPlay" type="b" access="read"/>
    <property name="CanPause" type="b" access="read"/>
    <property name="CanSeek" type="b" access="read"/>
    <property name="CanControl" type="b" access="read"/>
  </interface>
</node>)XML";

/// The track id of "no track" (MPRIS).
constexpr const char* kNoTrack = "/org/mpris/MediaPlayer2/TrackList/NoTrack";

GDBusNodeInfo* NodeInfo() {
  static GDBusNodeInfo* info = g_dbus_node_info_new_for_xml(kIntrospection, nullptr);
  return info;
}

void HandleMethod(GDBusConnection*, const gchar*, const gchar*, const gchar* interface,
                  const gchar* method, GVariant* parameters, GDBusMethodInvocation* invocation,
                  gpointer data) {
  static_cast<MprisPlayer*>(data)->OnMethodCall(interface, method, parameters, invocation);
}

GVariant* HandleGetProperty(GDBusConnection*, const gchar*, const gchar*, const gchar* interface,
                            const gchar* property, GError**, gpointer data) {
  return static_cast<MprisPlayer*>(data)->OnGetProperty(interface, property);
}

gboolean HandleSetProperty(GDBusConnection*, const gchar*, const gchar*, const gchar*,
                           const gchar*, GVariant*, GError**, gpointer) {
  // Rate and Volume belong to the app's player: accepted and ignored.
  return TRUE;
}

const GDBusInterfaceVTable kVTable = {HandleMethod, HandleGetProperty, HandleSetProperty, {}};

bool IsFile(const std::filesystem::path& path) {
  std::error_code ec;
  return std::filesystem::is_regular_file(path, ec) && std::filesystem::file_size(path, ec) > 0;
}

std::filesystem::path ExecutableDirectory() {
  std::error_code ec;
  auto exe = std::filesystem::read_symlink("/proc/self/exe", ec);
  return ec ? std::filesystem::current_path(ec) : exe.parent_path();
}

/// libcurl, loaded at run time like the core's image resolver does (no build
/// dependency). Option ids are part of libcurl's stable ABI.
bool CurlDownload(const std::string& url, const std::filesystem::path& target) {
  using InitFn = void* (*)();
  using SetoptFn = int (*)(void*, int, ...);
  using PerformFn = int (*)(void*);
  using CleanupFn = void (*)(void*);
  static void* lib = [] {
    void* handle = dlopen("libcurl.so.4", RTLD_NOW | RTLD_LOCAL);
    return handle ? handle : dlopen("libcurl-gnutls.so.4", RTLD_NOW | RTLD_LOCAL);
  }();
  if (!lib) return false;
  auto init = reinterpret_cast<InitFn>(dlsym(lib, "curl_easy_init"));
  auto setopt = reinterpret_cast<SetoptFn>(dlsym(lib, "curl_easy_setopt"));
  auto perform = reinterpret_cast<PerformFn>(dlsym(lib, "curl_easy_perform"));
  auto cleanup = reinterpret_cast<CleanupFn>(dlsym(lib, "curl_easy_cleanup"));
  if (!init || !setopt || !perform || !cleanup) return false;

  FILE* file = std::fopen(target.c_str(), "wb");
  if (!file) return false;
  void* handle = init();
  bool ok = false;
  if (handle) {
    setopt(handle, 10002, url.c_str());  // CURLOPT_URL
    setopt(handle, 10001, file);         // CURLOPT_WRITEDATA
    setopt(handle, 52, 1L);              // CURLOPT_FOLLOWLOCATION
    setopt(handle, 45, 1L);              // CURLOPT_FAILONERROR
    setopt(handle, 99, 1L);              // CURLOPT_NOSIGNAL
    setopt(handle, 13, 30L);             // CURLOPT_TIMEOUT
    ok = perform(handle) == 0;
    cleanup(handle);
  }
  std::fclose(file);
  return ok;
}

/// Without libcurl, GIO fetches http(s) where gvfs is installed.
bool GioDownload(const std::string& url, const std::filesystem::path& target) {
  GFile* source = g_file_new_for_uri(url.c_str());
  GFile* destination = g_file_new_for_path(target.c_str());
  gboolean ok = g_file_copy(source, destination, G_FILE_COPY_OVERWRITE, nullptr, nullptr,
                            nullptr, nullptr);
  g_object_unref(source);
  g_object_unref(destination);
  return ok;
}

std::string Download(const std::string& url, const std::filesystem::path& cacheDirectory) {
  // Cached by URL: the same cover is fetched once.
  std::filesystem::path target = cacheDirectory / artworkCacheName(url);
  if (IsFile(target)) return target.string();

  std::error_code ec;
  std::filesystem::create_directories(cacheDirectory, ec);
  std::filesystem::path partial = target;
  partial += ".part";
  bool ok = CurlDownload(url, partial) || GioDownload(url, partial);
  if (!ok || !IsFile(partial)) {
    std::filesystem::remove(partial, ec);
    return {};
  }
  std::filesystem::rename(partial, target, ec);
  return ec ? std::string() : target.string();
}

GVariant* StringArray(std::initializer_list<const char*> items) {
  GVariantBuilder builder;
  g_variant_builder_init(&builder, G_VARIANT_TYPE("as"));
  for (const char* item : items) g_variant_builder_add(&builder, "s", item);
  return g_variant_builder_end(&builder);
}

}  // namespace

std::string ResolveArtworkFile(const std::string& source,
                               const std::filesystem::path& cacheDirectory) {
  ArtworkSource artwork = artworkSourceOf(source);
  std::filesystem::path path;
  switch (artwork.kind) {
    case ArtworkSource::Kind::None:
      return {};
    case ArtworkSource::Kind::Remote:
      return Download(artwork.path, cacheDirectory);
    case ArtworkSource::Kind::File:
      path = artwork.path;
      break;
    case ArtworkSource::Kind::Asset:
      path = ExecutableDirectory() / "data" / "flutter_assets" / artwork.path;
      break;
  }
  return IsFile(path) ? path.string() : std::string();
}

MprisPlayer::MprisPlayer(std::string appId, std::string identity,
                         std::filesystem::path cacheDirectory, Callbacks callbacks)
    : appId_(std::move(appId)),
      identity_(std::move(identity)),
      cacheDirectory_(std::move(cacheDirectory)),
      callbacks_(std::move(callbacks)) {}

MprisPlayer::~MprisPlayer() {
  if (ownerId_) g_bus_unown_name(ownerId_);
  if (connection_) {
    if (rootId_) g_dbus_connection_unregister_object(connection_, rootId_);
    if (playerId_) g_dbus_connection_unregister_object(connection_, playerId_);
    g_object_unref(connection_);
  }
}

bool MprisPlayer::Export() {
  if (connection_) return true;
  GError* error = nullptr;
  connection_ = g_bus_get_sync(G_BUS_TYPE_SESSION, nullptr, &error);
  if (!connection_) {
    g_warning("awesome_notifications_media: no session bus: %s",
              error ? error->message : "unknown");
    g_clear_error(&error);
    return false;
  }
  GDBusNodeInfo* info = NodeInfo();
  rootId_ = g_dbus_connection_register_object(
      connection_, kObjectPath, g_dbus_node_info_lookup_interface(info, kRootInterface), &kVTable,
      this, nullptr, nullptr);
  playerId_ = g_dbus_connection_register_object(
      connection_, kObjectPath, g_dbus_node_info_lookup_interface(info, kPlayerInterface),
      &kVTable, this, nullptr, nullptr);
  busName_ = busNameFor(appId_, static_cast<long>(getpid()));
  ownerId_ = g_bus_own_name_on_connection(connection_, busName_.c_str(),
                                          G_BUS_NAME_OWNER_FLAGS_NONE, nullptr, nullptr, nullptr,
                                          nullptr);
  return true;
}

bool MprisPlayer::show(const Session& session) {
  if (!Export()) return false;
  bool sameArtwork = session_ && session.media.artwork == artworkSource_;
  session_ = session;
  if (!sameArtwork) ResolveArtwork(session.media.artwork);
  EmitPlayerChanged();
  return true;
}

void MprisPlayer::positionChanged(const Session& session, bool jump) {
  if (!connection_ || !session_ || session_->media.sessionId != session.media.sessionId) return;
  session_ = session;
  // Position isn't signaled by PropertiesChanged (clients poll it, and
  // advance it from Rate): only a jump is announced.
  if (!jump) return;
  g_dbus_connection_emit_signal(
      connection_, nullptr, kObjectPath, kPlayerInterface, "Seeked",
      g_variant_new("(x)", static_cast<gint64>(session.media.positionMs) * 1000), nullptr);
}

void MprisPlayer::clear() {
  session_.reset();
  artworkSource_.clear();
  artUrl_.clear();
  if (connection_) EmitPlayerChanged();
}

void MprisPlayer::ResolveArtwork(const std::string& source) {
  artworkSource_ = source;
  artUrl_.clear();
  if (source.empty()) return;
  auto toUrl = [](const std::string& file) {
    if (file.empty()) return std::string();
    gchar* uri = g_filename_to_uri(file.c_str(), nullptr, nullptr);
    std::string url = uri ? uri : "";
    g_free(uri);
    return url;
  };
  if (artworkSourceOf(source).kind != ArtworkSource::Kind::Remote) {
    artUrl_ = toUrl(ResolveArtworkFile(source, cacheDirectory_));
    return;
  }
  // Downloads block: off the platform thread, then back on it.
  struct Result {
    std::weak_ptr<MprisPlayer> player;
    std::string source;
    std::string url;
  };
  std::weak_ptr<MprisPlayer> weak = weak_from_this();
  std::filesystem::path cache = cacheDirectory_;
  std::thread([weak, source, cache, toUrl] {
    auto* result = new Result{weak, source, toUrl(ResolveArtworkFile(source, cache))};
    g_idle_add_full(
        G_PRIORITY_DEFAULT,
        [](gpointer data) -> gboolean {
          auto* result = static_cast<Result*>(data);
          if (auto player = result->player.lock()) {
            if (player->session_ && player->artworkSource_ == result->source &&
                !result->url.empty()) {
              player->artUrl_ = result->url;
              player->EmitPlayerChanged(/*metadataOnly=*/true);
            }
          }
          return G_SOURCE_REMOVE;
        },
        result, [](gpointer data) { delete static_cast<Result*>(data); });
  }).detach();
}

GVariant* MprisPlayer::Metadata() const {
  GVariantBuilder builder;
  g_variant_builder_init(&builder, G_VARIANT_TYPE("a{sv}"));
  if (!session_) {
    g_variant_builder_add(&builder, "{sv}", "mpris:trackid", g_variant_new_object_path(kNoTrack));
    return g_variant_builder_end(&builder);
  }
  const MediaModel& media = session_->media;
  std::string trackId = trackIdFor(media.sessionId);
  g_variant_builder_add(&builder, "{sv}", "mpris:trackid",
                        g_variant_new_object_path(trackId.c_str()));
  g_variant_builder_add(&builder, "{sv}", "xesam:title", g_variant_new_string(media.title.c_str()));
  if (!media.artist.empty()) {
    const gchar* artists[] = {media.artist.c_str(), nullptr};
    g_variant_builder_add(&builder, "{sv}", "xesam:artist", g_variant_new_strv(artists, 1));
  }
  if (!media.album.empty())
    g_variant_builder_add(&builder, "{sv}", "xesam:album", g_variant_new_string(media.album.c_str()));
  if (media.durationMs)
    g_variant_builder_add(&builder, "{sv}", "mpris:length",
                          g_variant_new_int64(static_cast<gint64>(*media.durationMs) * 1000));
  if (!artUrl_.empty())
    g_variant_builder_add(&builder, "{sv}", "mpris:artUrl", g_variant_new_string(artUrl_.c_str()));
  return g_variant_builder_end(&builder);
}

void MprisPlayer::EmitPlayerChanged(bool metadataOnly) {
  if (!connection_) return;
  GVariantBuilder changed;
  g_variant_builder_init(&changed, G_VARIANT_TYPE("a{sv}"));
  const char* properties[] = {"Metadata",   "PlaybackStatus", "Rate",    "MinimumRate",
                              "MaximumRate", "CanGoNext",     "CanGoPrevious", "CanPlay",
                              "CanPause",    "CanSeek",       "CanControl"};
  for (const char* property : properties) {
    if (metadataOnly && std::strcmp(property, "Metadata") != 0) continue;
    g_variant_builder_add(&changed, "{sv}", property, OnGetProperty(kPlayerInterface, property));
  }
  g_dbus_connection_emit_signal(
      connection_, nullptr, kObjectPath, "org.freedesktop.DBus.Properties", "PropertiesChanged",
      g_variant_new("(sa{sv}as)", kPlayerInterface, &changed, nullptr), nullptr);
}

void MprisPlayer::OnMethodCall(const gchar* interface, const gchar* method, GVariant* parameters,
                               GDBusMethodInvocation* invocation) {
  if (g_strcmp0(interface, kRootInterface) == 0) {
    if (g_strcmp0(method, "Raise") == 0 && callbacks_.raise) callbacks_.raise();
    g_dbus_method_invocation_return_value(invocation, nullptr);
    return;
  }
  int64_t offset = 0, position = 0;
  std::string trackId;
  if (g_strcmp0(method, "Seek") == 0) {
    gint64 value = 0;
    g_variant_get(parameters, "(x)", &value);
    offset = value;
  } else if (g_strcmp0(method, "SetPosition") == 0) {
    const gchar* track = nullptr;
    gint64 value = 0;
    g_variant_get(parameters, "(&ox)", &track, &value);
    trackId = track ? track : "";
    position = value;
  }
  // Answer first: the command reaches Dart asynchronously anyway.
  g_dbus_method_invocation_return_value(invocation, nullptr);
  if (callbacks_.onMethod && g_strcmp0(method, "OpenUri") != 0)
    callbacks_.onMethod(method, offset, trackId, position);
}

GVariant* MprisPlayer::OnGetProperty(const gchar* interface, const gchar* property) {
  std::string name = property;
  if (g_strcmp0(interface, kRootInterface) == 0) {
    if (name == "CanQuit" || name == "HasTrackList") return g_variant_new_boolean(FALSE);
    if (name == "CanRaise") return g_variant_new_boolean(callbacks_.raise != nullptr);
    if (name == "Identity") return g_variant_new_string(identity_.c_str());
    if (name == "DesktopEntry") return g_variant_new_string(appId_.c_str());
    if (name == "SupportedUriSchemes" || name == "SupportedMimeTypes") return StringArray({});
    return nullptr;
  }

  PlayerCapabilities can = session_ ? capabilitiesOf(session_->media) : PlayerCapabilities{};
  double speed = session_ ? session_->media.speed : 0.0;
  // Rate can't be 0 in MPRIS: a halted player says so with PlaybackStatus.
  double rate = speed > 0 ? speed : 1.0;
  if (name == "PlaybackStatus")
    return g_variant_new_string(
        mprisPlaybackStatus(session_ ? session_->media.playback() : PlaybackState::Stopped));
  if (name == "Rate") return g_variant_new_double(rate);
  if (name == "MinimumRate") return g_variant_new_double(std::min(rate, 1.0));
  if (name == "MaximumRate") return g_variant_new_double(std::max(rate, 1.0));
  if (name == "Volume") return g_variant_new_double(1.0);
  if (name == "Metadata") return Metadata();
  if (name == "Position") {
    int64_t ms = session_ && callbacks_.position ? callbacks_.position() : 0;
    return g_variant_new_int64(static_cast<gint64>(ms) * 1000);
  }
  if (name == "CanGoNext") return g_variant_new_boolean(can.canGoNext);
  if (name == "CanGoPrevious") return g_variant_new_boolean(can.canGoPrevious);
  if (name == "CanPlay") return g_variant_new_boolean(can.canPlay);
  if (name == "CanPause") return g_variant_new_boolean(can.canPause);
  if (name == "CanSeek") return g_variant_new_boolean(can.canSeek);
  if (name == "CanControl") return g_variant_new_boolean(TRUE);
  return nullptr;
}

}  // namespace awn_media

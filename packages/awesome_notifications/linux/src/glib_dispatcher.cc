#include "glib_dispatcher.h"

namespace awesome_notifications {

namespace {

gboolean RunOnce(gpointer data) {
  (*static_cast<std::function<void()>*>(data))();
  return G_SOURCE_REMOVE;
}

void Destroy(gpointer data) { delete static_cast<std::function<void()>*>(data); }

}  // namespace

void GlibDispatcher::post(std::function<void()> work) {
  // g_idle_add_full attaches to the default (main) context from any thread.
  g_idle_add_full(G_PRIORITY_DEFAULT, RunOnce, new std::function<void()>(std::move(work)), Destroy);
}

guint GlibDispatcher::PostDelayed(std::chrono::milliseconds delay, std::function<void()> work) {
  guint interval = delay.count() <= 0 ? 0 : static_cast<guint>(delay.count());
  return g_timeout_add_full(G_PRIORITY_DEFAULT, interval, RunOnce,
                            new std::function<void()>(std::move(work)), Destroy);
}

void GlibDispatcher::CancelDelayed(guint handle) {
  if (handle != 0) g_source_remove(handle);
}

}  // namespace awesome_notifications

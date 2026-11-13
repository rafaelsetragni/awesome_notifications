#include "awn/registries.h"

#include <algorithm>

namespace awn {

NotificationBuilderRegistry& NotificationBuilderRegistry::shared() {
  static NotificationBuilderRegistry instance;
  return instance;
}

void NotificationBuilderRegistry::registerDecorator(int priority, Factory factory) {
  std::lock_guard<std::mutex> lock(mutex_);
  entries_.push_back({priority, std::move(factory)});
}

std::shared_ptr<NotificationBuilder> NotificationBuilderRegistry::makeBuilder() const {
  std::vector<Entry> sorted;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    sorted = entries_;
  }
  std::stable_sort(sorted.begin(), sorted.end(),
                   [](const Entry& a, const Entry& b) { return a.priority < b.priority; });
  auto builder = std::make_shared<NotificationBuilder>();
  for (const auto& entry : sorted) builder = entry.make(builder);
  return builder;
}

void NotificationBuilderRegistry::clearForTest() {
  std::lock_guard<std::mutex> lock(mutex_);
  entries_.clear();
}

AwesomeMethodHandlerRegistry& AwesomeMethodHandlerRegistry::shared() {
  static AwesomeMethodHandlerRegistry instance;
  return instance;
}

void AwesomeMethodHandlerRegistry::registerHandler(
    std::shared_ptr<AwesomeMethodHandler> handler) {
  std::lock_guard<std::mutex> lock(mutex_);
  if (std::find(handlers_.begin(), handlers_.end(), handler) == handlers_.end())
    handlers_.push_back(std::move(handler));
}

void AwesomeMethodHandlerRegistry::unregisterHandler(
    const std::shared_ptr<AwesomeMethodHandler>& handler) {
  std::lock_guard<std::mutex> lock(mutex_);
  handlers_.erase(std::remove(handlers_.begin(), handlers_.end(), handler), handlers_.end());
}

bool AwesomeMethodHandlerRegistry::handle(const std::string& method, const Value& arguments,
                                          MethodResult result) {
  std::vector<std::shared_ptr<AwesomeMethodHandler>> handlers;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    handlers = handlers_;
  }
  for (const auto& handler : handlers) {
    if (handler->handle(method, arguments, result)) return true;
  }
  return false;
}

void AwesomeMethodHandlerRegistry::clearForTest() {
  std::lock_guard<std::mutex> lock(mutex_);
  handlers_.clear();
}

AwesomeEventsReceiver& AwesomeEventsReceiver::shared() {
  static AwesomeEventsReceiver instance;
  return instance;
}

int AwesomeEventsReceiver::subscribe(Listener listener) {
  std::lock_guard<std::mutex> lock(mutex_);
  int token = nextToken_++;
  listeners_.emplace_back(token, std::move(listener));
  return token;
}

void AwesomeEventsReceiver::unsubscribe(int token) {
  std::lock_guard<std::mutex> lock(mutex_);
  listeners_.erase(std::remove_if(listeners_.begin(), listeners_.end(),
                                  [token](const auto& entry) { return entry.first == token; }),
                   listeners_.end());
}

void AwesomeEventsReceiver::notify(const std::string& event, const ValueMap& content) {
  std::vector<std::pair<int, Listener>> listeners;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    listeners = listeners_;
  }
  for (const auto& entry : listeners) entry.second(event, content);
}

}  // namespace awn

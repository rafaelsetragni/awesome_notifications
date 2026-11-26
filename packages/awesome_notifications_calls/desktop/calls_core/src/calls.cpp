#include "awn_calls/calls.h"

#include <algorithm>
#include <cctype>
#include <chrono>

#include "awn/definitions.h"
#include "awn/exception.h"

namespace awn_calls {

namespace {

namespace defs = awn::defs;
namespace hints = awn::presentation;

constexpr CallState kStates[] = {CallState::incoming, CallState::outgoing, CallState::ongoing,
                                 CallState::held,     CallState::ended,    CallState::missed};
constexpr Control kControls[] = {Control::accept, Control::decline, Control::hangUp,
                                 Control::mute, Control::hold};
constexpr Action kActions[] = {Action::accept,  Action::decline,        Action::hangUp,
                               Action::mute,    Action::unmute,         Action::hold,
                               Action::unhold,  Action::timeout,        Action::audioActivated,
                               Action::audioDeactivated};

std::string text(const ValueMap& map, const char* key) {
  return awn::getString(map, key).value_or("");
}

bool blank(const std::string& value) {
  return std::all_of(value.begin(), value.end(),
                     [](unsigned char c) { return std::isspace(c) != 0; });
}

bool startsWith(const std::string& value, const char* prefix) {
  return value.rfind(prefix, 0) == 0;
}

/// Present and not null.
const Value* field(const ValueMap& map, const char* key) {
  auto it = map.find(key);
  return it == map.end() || it->second.isNull() ? nullptr : &it->second;
}

[[noreturn]] void invalid(const std::string& message, const std::string& detail) {
  throw awn::AwesomeNotificationsException(
      awn::exception_code::INVALID_ARGUMENTS, message,
      std::string(awn::exception_code::DETAILED_INVALID_ARGUMENTS) + ".notificationCall" + detail);
}

ValueMap button(const char* key, const std::string& label, const char* actionType,
                bool dangerous) {
  ValueMap out{{defs::NOTIFICATION_BUTTON_KEY, key},
               {defs::NOTIFICATION_BUTTON_LABEL, label},
               {defs::NOTIFICATION_ACTION_TYPE, actionType},
               {defs::NOTIFICATION_AUTO_DISMISSIBLE, false}};
  if (dangerous) out[defs::NOTIFICATION_IS_DANGEROUS_OPTION] = true;
  return out;
}

int64_t idOf(const ValueMap& model) {
  return awn::NotificationBuilder::readId(awn::NotificationBuilder::content(model)).value_or(0);
}

}  // namespace

// MARK: - Enums

const char* stateName(CallState state) {
  switch (state) {
    case CallState::incoming: return "incoming";
    case CallState::outgoing: return "outgoing";
    case CallState::ongoing: return "ongoing";
    case CallState::held: return "held";
    case CallState::ended: return "ended";
    case CallState::missed: return "missed";
  }
  return "incoming";
}

std::optional<CallState> stateFrom(const std::string& name) {
  for (auto state : kStates)
    if (name == stateName(state)) return state;
  return std::nullopt;
}

const char* controlName(Control control) {
  switch (control) {
    case Control::accept: return "accept";
    case Control::decline: return "decline";
    case Control::hangUp: return "hangUp";
    case Control::mute: return "mute";
    case Control::hold: return "hold";
  }
  return "accept";
}

std::optional<Control> controlFrom(const std::string& name) {
  for (auto control : kControls)
    if (name == controlName(control)) return control;
  return std::nullopt;
}

const char* actionName(Action action) {
  switch (action) {
    case Action::accept: return "accept";
    case Action::decline: return "decline";
    case Action::hangUp: return "hangUp";
    case Action::mute: return "mute";
    case Action::unmute: return "unmute";
    case Action::hold: return "hold";
    case Action::unhold: return "unhold";
    case Action::timeout: return "timeout";
    case Action::audioActivated: return "audioActivated";
    case Action::audioDeactivated: return "audioDeactivated";
  }
  return "accept";
}

std::optional<Action> actionFrom(const std::string& name) {
  for (auto action : kActions)
    if (name == actionName(action)) return action;
  return std::nullopt;
}

std::optional<EndReason> endReasonFrom(const std::string& name) {
  if (name == "remoteEnded") return EndReason::remoteEnded;
  if (name == "declinedElsewhere") return EndReason::declinedElsewhere;
  if (name == "answeredElsewhere") return EndReason::answeredElsewhere;
  if (name == "unanswered") return EndReason::unanswered;
  if (name == "failed") return EndReason::failed;
  return std::nullopt;
}

// MARK: - Model

std::optional<CallModel> CallModel::parse(const Value& block, std::string* error) {
  auto fail = [error](const std::string& message) -> std::optional<CallModel> {
    if (error) *error = message;
    return std::nullopt;
  };
  if (!block.isMap()) return fail("The call block must be a map");
  const ValueMap& map = block.map();

  CallModel call;
  call.callId = text(map, keys::CALL_ID);
  if (blank(call.callId)) return fail("The call needs a non-empty callId");

  const Value* caller = field(map, keys::CALLER);
  if (!caller || !caller->isMap()) return fail("The call needs a caller");
  const ValueMap& person = caller->map();
  call.caller.key = text(person, keys::PERSON_KEY);
  call.caller.name = text(person, keys::PERSON_NAME);
  if (blank(call.caller.key)) return fail("The caller needs a non-empty key");
  if (blank(call.caller.name)) return fail("The caller needs a non-empty name");
  call.caller.avatar = text(person, keys::PERSON_AVATAR);
  call.caller.uri = text(person, keys::PERSON_URI);
  call.caller.isBot = awn::getBool(person, keys::PERSON_IS_BOT).value_or(false);
  call.caller.isImportant = awn::getBool(person, keys::PERSON_IS_IMPORTANT).value_or(false);

  if (const Value* handle = field(map, keys::HANDLE)) {
    call.handle = handle->asString().value_or("");
    if (blank(call.handle))
      return fail("The call handle can't be empty (leave it out to use the caller's key)");
  } else {
    call.handle = call.caller.key;
  }
  if (const Value* group = field(map, keys::GROUP_NAME)) {
    call.groupName = group->asString().value_or("");
    if (blank(call.groupName)) return fail("The call groupName can't be empty");
  }
  call.video = awn::getBool(map, keys::VIDEO).value_or(false);

  auto state = stateFrom(text(map, keys::STATE));
  if (!state) return fail("Unknown call state '" + text(map, keys::STATE) + "'");
  call.state = *state;
  call.startedAt = awn::getInt(map, keys::STARTED_AT);
  call.ringTimeoutMs = awn::getInt(map, keys::RING_TIMEOUT).value_or(60000);
  if (call.ringTimeoutMs <= 0) return fail("The ring timeout must be positive");
  call.missedNotification = awn::getBool(map, keys::MISSED_NOTIFICATION).value_or(true);

  if (field(map, keys::CONTROLS)) {
    for (const auto& entry : awn::getList(map, keys::CONTROLS))
      if (auto control = controlFrom(entry.asString().value_or("")))
        call.controls.insert(*control);
  } else {
    call.controls = {std::begin(kControls), std::end(kControls)};
  }
  if (call.state == CallState::incoming && !call.has(Control::accept) &&
      !call.has(Control::decline))
    return fail("An incoming call needs the accept or the decline control");

  std::string target = text(map, keys::COMMAND_TARGET);
  call.target = target == "stream" ? CommandTarget::stream
                : target == "both" ? CommandTarget::both
                                   : CommandTarget::actionEvent;
  call.systemCallUI = awn::getBool(map, keys::SYSTEM_CALL_UI).value_or(true);

  ValueMap texts = awn::getMap(map, keys::TEXTS);
  auto read = [&texts](const char* key, std::string& into) {
    if (auto value = awn::getString(texts, key)) into = *value;
  };
  read(keys::TEXT_INCOMING, call.texts.incoming);
  read(keys::TEXT_INCOMING_VIDEO, call.texts.incomingVideo);
  read(keys::TEXT_OUTGOING, call.texts.outgoing);
  read(keys::TEXT_ONGOING, call.texts.ongoing);
  read(keys::TEXT_MISSED, call.texts.missed);
  read(keys::TEXT_MISSED_VIDEO, call.texts.missedVideo);
  read(keys::TEXT_ACCEPT, call.texts.accept);
  read(keys::TEXT_DECLINE, call.texts.decline);
  read(keys::TEXT_HANG_UP, call.texts.hangUp);
  read(keys::TEXT_HELD, call.texts.held);
  return call;
}

ValueMap withState(const ValueMap& model, CallState state, std::optional<int64_t> startedAt) {
  ValueMap result = model;
  ValueMap block = awn::getMap(model, keys::CALL);
  block[keys::STATE] = stateName(state);
  if (startedAt) block[keys::STARTED_AT] = *startedAt;
  result[keys::CALL] = std::move(block);
  return result;
}

ValueMap callNotification(const ValueMap& model, const CallModel& call) {
  ValueMap result = model;
  ValueMap content = awn::NotificationBuilder::content(model);
  if (text(content, defs::NOTIFICATION_TITLE).empty())
    content[defs::NOTIFICATION_TITLE] = call.displayName();
  switch (call.state) {
    case CallState::incoming:
      content[defs::NOTIFICATION_BODY] = call.video ? call.texts.incomingVideo : call.texts.incoming;
      break;
    case CallState::outgoing:
      content[defs::NOTIFICATION_BODY] = call.texts.outgoing;
      break;
    case CallState::held:
      content[defs::NOTIFICATION_BODY] = call.texts.held;
      break;
    default:
      content[defs::NOTIFICATION_BODY] = call.texts.ongoing;
  }
  if (text(content, defs::NOTIFICATION_LARGE_ICON).empty() && !call.caller.avatar.empty()) {
    content[defs::NOTIFICATION_LARGE_ICON] = call.caller.avatar;
    content[defs::NOTIFICATION_ROUNDED_LARGE_ICON] = true;
  }
  ValueMap payload = awn::getMap(content, defs::NOTIFICATION_PAYLOAD);
  payload[keys::PAYLOAD_CALL_ID] = call.callId;
  content[defs::NOTIFICATION_PAYLOAD] = std::move(payload);
  result[defs::NOTIFICATION_CONTENT] = std::move(content);

  // The call's buttons first (a toast shows five at most), then the app's own.
  ValueList buttons;
  std::string accept = buttonKeyOf(Action::accept);
  if (call.state == CallState::incoming) {
    if (call.has(Control::accept))
      buttons.push_back(button(accept.c_str(), call.texts.accept, "Default", false));
    if (call.has(Control::decline))
      buttons.push_back(
          button(buttonKeyOf(Action::decline).c_str(), call.texts.decline, "SilentAction", true));
  } else if (call.has(Control::hangUp)) {
    buttons.push_back(
        button(buttonKeyOf(Action::hangUp).c_str(), call.texts.hangUp, "SilentAction", true));
  }
  for (const auto& entry : awn::NotificationBuilder::actionButtons(model)) {
    if (entry.isMap() && startsWith(text(entry.map(), defs::NOTIFICATION_BUTTON_KEY),
                                    keys::COMMAND_PREFIX))
      continue;  // the call's own, from a previous state
    buttons.push_back(entry);
  }
  if (buttons.empty())
    result.erase(defs::NOTIFICATION_BUTTONS);
  else
    result[defs::NOTIFICATION_BUTTONS] = std::move(buttons);

  // Ringing: the strongest notification of the platform. In a call: kept on
  // screen, quiet.
  ValueMap presentation;
  if (call.state == CallState::incoming) {
    presentation = ValueMap{{hints::URGENCY, 2},
                            {hints::RESIDENT, true},
                            {hints::SOUND_NAME, kLinuxRingSound},
                            {hints::TOAST_SCENARIO, "incomingCall"},
                            {hints::TOAST_AUDIO, kToastRingAudio},
                            {hints::TOAST_AUDIO_LOOP, true},
                            {hints::TOAST_BUTTON_STYLES, ValueMap{{accept, "Success"}}}};
  } else {
    presentation = ValueMap{{hints::URGENCY, 1}, {hints::RESIDENT, true}, {hints::SILENT, true}};
  }
  result[hints::BLOCK] = std::move(presentation);
  return result;
}

int64_t missedId(const std::string& callId) {
  // Java String.hashCode() of "missed:" + callId (int32 wrapping arithmetic
  // over UTF-16 code units), masked positive: the same id on every platform.
  std::string text = std::string("missed:") + callId;
  uint32_t hash = 0;
  auto add = [&hash](uint32_t unit) { hash = hash * 31u + unit; };
  for (size_t i = 0; i < text.size();) {
    unsigned char c = static_cast<unsigned char>(text[i]);
    uint32_t point = c;
    size_t length = 1;
    if (c >= 0xF0) {
      point = c & 0x07u;
      length = 4;
    } else if (c >= 0xE0) {
      point = c & 0x0Fu;
      length = 3;
    } else if (c >= 0xC0) {
      point = c & 0x1Fu;
      length = 2;
    }
    if (i + length > text.size()) length = 1, point = c;  // malformed tail: bytes as is
    for (size_t k = 1; k < length; ++k)
      point = (point << 6) | (static_cast<unsigned char>(text[i + k]) & 0x3Fu);
    i += length;
    if (point >= 0x10000) {
      point -= 0x10000;
      add(0xD800u + (point >> 10));
      add(0xDC00u + (point & 0x3FFu));
    } else {
      add(point);
    }
  }
  return static_cast<int64_t>(hash & 0x7fffffffu);
}

ValueMap missedNotification(const ValueMap& model, const CallModel& call) {
  ValueMap content = awn::NotificationBuilder::content(model);
  ValueMap missed{{defs::NOTIFICATION_ID, missedId(call.callId)},
                  {defs::NOTIFICATION_TITLE, call.displayName()},
                  {defs::NOTIFICATION_BODY, call.video ? call.texts.missedVideo : call.texts.missed},
                  {defs::NOTIFICATION_PAYLOAD, ValueMap{{keys::PAYLOAD_CALL_ID, call.callId}}}};
  if (auto channel = awn::getString(content, defs::NOTIFICATION_CHANNEL_KEY))
    missed[defs::NOTIFICATION_CHANNEL_KEY] = *channel;
  if (!call.caller.avatar.empty()) missed[defs::NOTIFICATION_LARGE_ICON] = call.caller.avatar;
  return ValueMap{{defs::NOTIFICATION_CONTENT, std::move(missed)}};
}

std::string buttonKeyOf(Action action) {
  return std::string(keys::COMMAND_PREFIX) + actionName(action);
}

ValueMap syntheticButton(Action action) {
  return ValueMap{{defs::NOTIFICATION_BUTTON_KEY, buttonKeyOf(action)},
                  {defs::NOTIFICATION_ACTION_TYPE,
                   action == Action::accept ? "Default" : "SilentAction"},
                  {defs::NOTIFICATION_AUTO_DISMISSIBLE, false}};
}

ValueMap streamEvent(Action action, const std::string& callId) {
  return ValueMap{{keys::KIND, keys::KIND_COMMAND},
                  {keys::ACTION, actionName(action)},
                  {keys::CALL_ID, callId}};
}

// MARK: - Host

CallHost engineHost(awn::AwesomeNotifications& core,
                    std::function<void(int64_t ms, std::function<void()> work)> after) {
  CallHost host;
  awn::AwesomeNotifications* engine = &core;
  host.present = [engine](const awn::BuiltNotification& built, std::function<void(bool)> done) {
    auto* presenter = engine->presenter();
    if (!presenter) {
      done(false);
      return;
    }
    presenter->present(built, std::move(done));
  };
  host.store = [engine](int64_t id, const ValueMap& model) {
    if (auto* store = engine->store()) store->put(id, model);
  };
  host.cancel = [engine](int64_t id) {
    if (engine->isConfigured()) engine->cancel(id);
  };
  host.create = [engine](const ValueMap& model) {
    if (engine->isConfigured()) engine->createNotification(model, [](bool) {});
  };
  host.action = [engine](const ValueMap& model, const std::string& buttonKey,
                         const std::optional<std::string>& input, const ValueMap& pressed) {
    engine->dispatchAction(model, buttonKey, input, pressed);
  };
  host.after = std::move(after);
  host.now = [] {
    return std::chrono::duration_cast<std::chrono::milliseconds>(
               std::chrono::system_clock::now().time_since_epoch())
        .count();
  };
  return host;
}

// MARK: - Controller

CallController::CallController(CallHost host) : host_(std::move(host)) {}

const ActiveCall* CallController::find(const std::string& callId) const {
  auto it = calls_.find(callId);
  return it == calls_.end() ? nullptr : &it->second;
}

ValueList CallController::activeCalls() const {
  ValueList list;
  for (const auto& [callId, active] : calls_)
    list.push_back(ValueMap{{keys::CALL_ID, callId}, {keys::STATE, stateName(active.call.state)}});
  return list;
}

void CallController::deliver(const CallModel& call, const awn::BuiltNotification& built,
                             std::function<void(bool)> done) {
  std::weak_ptr<CallController> weak = weak_from_this();
  host_.present(built, [weak, call, built, done](bool shown) {
    auto self = weak.lock();
    if (shown && self) {
      std::optional<int64_t> replaced;
      uint64_t ring = 0;
      auto previous = self->calls_.find(call.callId);
      if (previous != self->calls_.end()) {
        if (previous->second.notificationId != built.id) replaced = previous->second.notificationId;
        // An update of a ringing call keeps its timer.
        if (call.state == CallState::incoming && previous->second.call.state == CallState::incoming)
          ring = previous->second.ring;
      }
      if (call.state == CallState::incoming && ring == 0) {
        ring = self->nextRing_++;
        std::string callId = call.callId;
        if (self->host_.after) {
          self->host_.after(call.ringTimeoutMs, [weak, callId, ring] {
            if (auto alive = weak.lock()) alive->ringTimeout(callId, ring);
          });
        }
      }
      self->calls_[call.callId] = ActiveCall{call, built.model, built.id,
                                             call.state == CallState::incoming ? ring : 0};
      // The call moved to another notification id: the old one goes (it no
      // longer matches the call, so its removal doesn't end it).
      if (replaced) self->host_.cancel(*replaced);
    }
    done(shown);
  });
}

void CallController::finish(const CallModel& call, const ValueMap& model) {
  std::vector<int64_t> ids{idOf(model)};
  auto it = calls_.find(call.callId);
  if (it != calls_.end()) {
    if (it->second.notificationId != ids.front()) ids.push_back(it->second.notificationId);
    calls_.erase(it);
  }
  for (auto id : ids) host_.cancel(id);
  if (call.state == CallState::missed && call.missedNotification) showMissed(call, model);
}

void CallController::drop(const std::string& callId) {
  auto it = calls_.find(callId);
  if (it == calls_.end()) return;
  int64_t id = it->second.notificationId;
  calls_.erase(it);
  host_.cancel(id);
}

void CallController::showMissed(const CallModel& call, const ValueMap& model) {
  if (host_.create) host_.create(missedNotification(model, call));
}

void CallController::send(Action action, const CallModel& call, const ValueMap& model) {
  if (call.toActionEvent() && host_.action)
    host_.action(model, buttonKeyOf(action), std::nullopt, syntheticButton(action));
  if (call.toStream() && stream_) stream_(streamEvent(action, call.callId));
}

std::optional<awn::ActionType> CallController::onActivated(const ValueMap& model,
                                                           const std::string& buttonKey) {
  auto block = model.find(keys::CALL);
  if (block == model.end() || block->second.isNull()) return std::nullopt;
  auto parsed = CallModel::parse(block->second);
  if (!parsed) return std::nullopt;
  CallModel call = *parsed;
  int64_t id = idOf(model);

  // The notification itself: the app comes forward, the call goes on (the
  // notification stays while the call lasts).
  if (buttonKey.empty()) {
    if (host_.action) host_.action(model, "", std::nullopt, ValueMap{});
    return awn::ActionType::Default;
  }
  if (!startsWith(buttonKey, keys::COMMAND_PREFIX)) return std::nullopt;  // the app's own
  auto action = actionFrom(buttonKey.substr(std::char_traits<char>::length(keys::COMMAND_PREFIX)));
  if (!action) return std::nullopt;

  switch (*action) {
    case Action::accept: {
      // In the call: ongoing from now on, the ring stops, Hang up replaces
      // Accept / Decline.
      call.state = CallState::ongoing;
      if (!call.startedAt) call.startedAt = host_.now ? host_.now() : 0;
      ValueMap updated =
          callNotification(withState(model, CallState::ongoing, call.startedAt), call);
      calls_[call.callId] = ActiveCall{call, updated, id, 0};
      if (host_.store) host_.store(id, updated);
      awn::BuiltNotification built;
      built.id = id;
      built.model = updated;
      if (host_.present) host_.present(built, [](bool) {});
      send(Action::accept, call, updated);
      return awn::ActionType::Default;
    }
    case Action::decline:
    case Action::hangUp: {
      calls_.erase(call.callId);
      host_.cancel(id);
      send(*action, call, model);
      return awn::ActionType::SilentAction;
    }
    default:
      return std::nullopt;  // no other call button on the desktop
  }
}

void CallController::ringTimeout(const std::string& callId, uint64_t ring) {
  auto it = calls_.find(callId);
  if (it == calls_.end() || it->second.ring != ring || it->second.call.state != CallState::incoming)
    return;
  CallModel call = it->second.call;
  ValueMap model = it->second.model;
  drop(callId);
  if (call.missedNotification) showMissed(call, model);
  send(Action::timeout, call, model);
}

void CallController::end(const std::string& callId, EndReason reason) {
  auto it = calls_.find(callId);
  if (it == calls_.end()) return;
  CallModel call = it->second.call;
  ValueMap model = it->second.model;
  drop(callId);
  if (reason == EndReason::unanswered && call.missedNotification) showMissed(call, model);
}

void CallController::onRemoved(const std::vector<int64_t>& ids) {
  for (auto it = calls_.begin(); it != calls_.end();) {
    if (std::find(ids.begin(), ids.end(), it->second.notificationId) != ids.end())
      it = calls_.erase(it);
    else
      ++it;
  }
}

// MARK: - Builder

CallBuilder::CallBuilder(std::shared_ptr<awn::NotificationBuilder> inner,
                         std::shared_ptr<CallController> controller)
    : awn::NotificationBuilder(std::move(inner)), controller_(std::move(controller)) {}

std::optional<awn::BuiltNotification> CallBuilder::build(const ValueMap& model) {
  const Value* block = field(model, keys::CALL);
  if (!block) return next(model);

  // A call rings now (or comes by push), never later.
  if (field(model, defs::NOTIFICATION_SCHEDULE))
    invalid("A call notification can't be scheduled", ".schedule");

  std::string error;
  auto call = CallModel::parse(*block, &error);
  if (!call) invalid(error, "");

  auto controller = controller_;
  CallModel parsed = *call;
  if (!call->isLive()) {
    // ended / missed: nothing to show for this model; its call goes away.
    auto built = next(model);
    if (!built) return built;
    built->deliver = [controller, parsed](const awn::BuiltNotification& final,
                                          std::function<void(bool)> done) {
      controller->finish(parsed, final.model);
      done(true);
    };
    return built;
  }

  auto built = next(callNotification(model, *call));
  if (!built) return built;
  built->deliver = [controller, parsed](const awn::BuiltNotification& final,
                                        std::function<void(bool)> done) {
    controller->deliver(parsed, final, std::move(done));
  };
  return built;
}

// MARK: - Channel

CallMethodHandler::CallMethodHandler(std::shared_ptr<CallController> controller,
                                     ValueMap capabilities)
    : controller_(std::move(controller)), capabilities_(std::move(capabilities)) {}

bool CallMethodHandler::handle(const std::string& method, const Value& arguments,
                               awn::MethodResult result) {
  if (method == keys::METHOD_END) {
    if (arguments.isMap()) {
      const ValueMap& map = arguments.map();
      auto callId = awn::getString(map, keys::CALL_ID);
      auto reason = endReasonFrom(text(map, keys::REASON)).value_or(EndReason::remoteEnded);
      if (callId) controller_->end(*callId, reason);
    } else if (auto callId = arguments.asString()) {
      controller_->end(*callId, EndReason::remoteEnded);
    }
    result(Value());
    return true;
  }
  if (method == keys::METHOD_ACTIVE_CALLS) {
    result(Value(controller_->activeCalls()));
    return true;
  }
  if (method == keys::METHOD_VOIP_TOKEN) {
    result(Value());  // PushKit is iOS only
    return true;
  }
  if (method == keys::METHOD_CAN_USE_FULL_SCREEN_INTENT ||
      method == keys::METHOD_REQUEST_FULL_SCREEN_INTENT) {
    result(Value(true));  // Android 14+ only
    return true;
  }
  if (method == keys::METHOD_CAPABILITIES) {
    result(Value(capabilities_));
    return true;
  }
  return false;
}

ValueMap desktopCapabilities() {
  return ValueMap{{keys::CAP_SYSTEM_CALL_UI, false},
                  {keys::CAP_LOCK_SCREEN, false},
                  {keys::CAP_MUTE_AND_HOLD, false},
                  {keys::CAP_PUSH, false}};
}

void RegisterCalls(std::shared_ptr<CallController> controller, ValueMap capabilities,
                   awn::AwesomeNotifications& core) {
  awn::NotificationBuilderRegistry::shared().registerDecorator(
      kCallsPriority, [controller](std::shared_ptr<awn::NotificationBuilder> inner) {
        return std::make_shared<CallBuilder>(std::move(inner), controller);
      });
  awn::AwesomeMethodHandlerRegistry::shared().registerHandler(
      std::make_shared<CallMethodHandler>(controller, std::move(capabilities)));
  std::weak_ptr<CallController> weak = controller;
  core.addRemovalObserver([weak](const std::vector<int64_t>& ids) {
    if (auto alive = weak.lock()) alive->onRemoved(ids);
  });
  core.addActivationInterceptor(
      [weak](const ValueMap& model, const std::string& buttonKey,
             const awn::Activation&) -> std::optional<awn::ActionType> {
        auto alive = weak.lock();
        return alive ? alive->onActivated(model, buttonKey) : std::nullopt;
      });
}

}  // namespace awn_calls

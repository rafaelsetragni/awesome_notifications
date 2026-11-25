#include "awn/exception.h"

namespace awn {

AwesomeNotificationsException::AwesomeNotificationsException(std::string code,
                                                             const std::string& message,
                                                             std::string details)
    : std::runtime_error(message), code_(std::move(code)), details_(std::move(details)) {}

// Out of line: the core library owns the type's identity, so an exception a
// decorator library throws is caught by the core.
AwesomeNotificationsException::~AwesomeNotificationsException() = default;

}  // namespace awn

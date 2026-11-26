#pragma once

#include <stdexcept>
#include <string>

#include "awn/export.h"

namespace awn {

/// The desktop counterpart of the Android / Apple cores' exception: a decorator
/// throws it from `build` to fail the create call, and the bridge turns the
/// (code, message, details) triple into a Dart `PlatformException`, exactly as
/// 0.12 reported it.
class AWN_API AwesomeNotificationsException : public std::runtime_error {
 public:
  AwesomeNotificationsException(std::string code, const std::string& message,
                                std::string details);
  ~AwesomeNotificationsException() override;

  const std::string& code() const { return code_; }
  const std::string& details() const { return details_; }

 private:
  std::string code_;
  std::string details_;
};

/// The exception codes of 0.12 (ExceptionCode), shared by the decorators.
namespace exception_code {
inline constexpr const char* INVALID_ARGUMENTS = "INVALID_ARGUMENTS";
inline constexpr const char* INSUFFICIENT_PERMISSIONS = "INSUFFICIENT_PERMISSIONS";
inline constexpr const char* UNKNOWN_EXCEPTION = "UNKNOWN_EXCEPTION";
inline constexpr const char* DETAILED_INVALID_ARGUMENTS = "arguments.invalid";
inline constexpr const char* DETAILED_REQUIRED_ARGUMENTS = "arguments.required";
inline constexpr const char* DETAILED_INSUFFICIENT_PERMISSIONS = "insufficientPermissions";
inline constexpr const char* DETAILED_UNEXPECTED_ERROR = "unexpectedError";
}  // namespace exception_code

}  // namespace awn

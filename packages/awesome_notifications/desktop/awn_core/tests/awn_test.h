#pragma once

// A dependency-free test harness (no network fetch in CI, builds with any
// C++17 compiler): TEST registers a case, EXPECT_* records failures and the
// runner returns non-zero when any case failed.

#include <functional>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

namespace awn_test {

struct Case {
  const char* name;
  std::function<void()> body;
};

inline std::vector<Case>& cases() {
  static std::vector<Case> all;
  return all;
}

inline int& failures() {
  static int count = 0;
  return count;
}

struct Registrar {
  Registrar(const char* name, std::function<void()> body) { cases().push_back({name, body}); }
};

inline void fail(const char* file, int line, const std::string& message) {
  ++failures();
  std::cerr << "  FAILED " << file << ":" << line << ": " << message << "\n";
}

inline int runAll() {
  int failedCases = 0;
  for (const auto& c : cases()) {
    int before = failures();
    c.body();
    bool ok = failures() == before;
    if (!ok) ++failedCases;
    std::cout << (ok ? "[ OK ] " : "[FAIL] ") << c.name << "\n";
  }
  std::cout << cases().size() - failedCases << "/" << cases().size() << " passed\n";
  return failedCases == 0 ? 0 : 1;
}

template <typename T>
std::string show(const T& value) {
  std::ostringstream out;
  out << value;
  return out.str();
}
inline std::string show(bool value) { return value ? "true" : "false"; }
template <typename T>
std::string show(const std::vector<T>& values) {
  std::string out = "[";
  for (size_t i = 0; i < values.size(); ++i) out += (i ? ", " : "") + show(values[i]);
  return out + "]";
}

}  // namespace awn_test

#define AWN_CONCAT_(a, b) a##b
#define AWN_CONCAT(a, b) AWN_CONCAT_(a, b)

#define TEST(name)                                                          \
  static void name();                                                       \
  static awn_test::Registrar AWN_CONCAT(name, _registrar)(#name, &name);    \
  static void name()

#define EXPECT_TRUE(cond) \
  do { if (!(cond)) awn_test::fail(__FILE__, __LINE__, "expected true: " #cond); } while (0)

#define EXPECT_FALSE(cond) \
  do { if (cond) awn_test::fail(__FILE__, __LINE__, "expected false: " #cond); } while (0)

#define EXPECT_EQ(actual, expected)                                                    \
  do {                                                                                 \
    auto&& a_ = (actual);                                                              \
    auto&& e_ = (expected);                                                            \
    if (!(a_ == e_))                                                                   \
      awn_test::fail(__FILE__, __LINE__,                                               \
                     std::string(#actual " == " #expected "\n    actual:   ") +        \
                         awn_test::show(a_) + "\n    expected: " + awn_test::show(e_)); \
  } while (0)

#define EXPECT_CONTAINS(haystack, needle)                                              \
  do {                                                                                 \
    std::string h_ = (haystack);                                                       \
    std::string n_ = (needle);                                                         \
    if (h_.find(n_) == std::string::npos)                                              \
      awn_test::fail(__FILE__, __LINE__, "expected to contain: " + n_ + "\n    in: " + h_); \
  } while (0)

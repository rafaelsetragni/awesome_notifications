#pragma once

// AWN_API marks the core symbols that decorator plugins (separate DLLs / shared
// objects) link against, so every plugin shares the same registries.
//
// The core sources are compiled into the core plugin's shared library, which
// defines AWN_BUILDING_CORE. Decorators that link the core plugin define
// AWN_USING_CORE (through the core target's INTERFACE definitions). Standalone
// builds (unit tests) define neither and get plain symbols.
#if defined(_WIN32)
#if defined(AWN_BUILDING_CORE)
#define AWN_API __declspec(dllexport)
#elif defined(AWN_USING_CORE)
#define AWN_API __declspec(dllimport)
#else
#define AWN_API
#endif
#else
#define AWN_API __attribute__((visibility("default")))
#endif

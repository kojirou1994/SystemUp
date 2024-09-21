#define SWIFT_INLINE static inline __attribute__((__always_inline__))

#ifdef __linux__

#include <gnu/libc-version.h>

extern char **environ;


SWIFT_INLINE char** swift_get_environ() {
  return environ;
}
#endif // linux end

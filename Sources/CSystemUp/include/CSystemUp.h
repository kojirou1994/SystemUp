#define SWIFT_INLINE static inline __attribute__((__always_inline__))

#include <fts.h>

#ifdef __linux__

#include <sys/types.h>
#include <sys/stat.h>
#include <sys/vfs.h>
#include <dirent.h>

#include <sys/xattr.h>

#endif // linux end


#include <sys/wait.h>

SWIFT_INLINE int swift_WIFEXITED(int status) {
  return WIFEXITED(status);
}

SWIFT_INLINE int swift_WIFSIGNALED(int status) {
  return WIFSIGNALED(status);
}

SWIFT_INLINE int swift_WIFSTOPPED(int status) {
  return WIFSTOPPED(status);
}

SWIFT_INLINE int swift_WEXITSTATUS(int status) {
  return WEXITSTATUS(status);
}

SWIFT_INLINE int swift_WTERMSIG(int status) {
  return WTERMSIG(status);
}

SWIFT_INLINE int swift_WCOREDUMP(int status) {
  return WCOREDUMP(status);
}

SWIFT_INLINE int swift_WSTOPSIG(int status) {
  return WSTOPSIG(status);
}

SWIFT_INLINE int swift_WIFCONTINUED(int status) {
  return WIFCONTINUED(status);
}

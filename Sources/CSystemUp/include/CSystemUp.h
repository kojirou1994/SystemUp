#define SWIFT_INLINE static inline __attribute__((__always_inline__))

#include <fts.h>
#include <sys/ioctl.h>
#include <sys/resource.h>

#ifdef __linux__

#define __USE_GNU 1
#include <spawn.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/vfs.h>
#include <dirent.h>

#include <sys/xattr.h>

#define _GNU_SOURCE
#include <unistd.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/sysmacros.h>

#endif // linux end

#include <stdio.h>
#include <sys/wait.h>

#if __has_include(<sys/errno.h>)
#include <sys/errno.h>
#else
#include <errno.h>
#endif

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

SWIFT_INLINE int swift_W_EXITCODE(int ret, int sig) {
  return W_EXITCODE(ret, sig);
}

SWIFT_INLINE int swift_W_STOPCODE(int sig) {
  return W_STOPCODE(sig);
}

SWIFT_INLINE unsigned long swift_FIOCLEX() {
  return FIOCLEX;
}

SWIFT_INLINE unsigned long swift_FIONCLEX() {
  return FIONCLEX;
}

SWIFT_INLINE unsigned long swift_FIONREAD() {
  return FIONREAD;
}

SWIFT_INLINE unsigned long swift_FIONBIO() {
  return FIONBIO;
}

SWIFT_INLINE unsigned long swift_FIOASYNC() {
  return FIOASYNC;
}

#ifdef __APPLE__
SWIFT_INLINE unsigned long swift_FIOSETOWN() {
  return FIOSETOWN;
}

SWIFT_INLINE unsigned long swift_FIOGETOWN() {
  return FIOGETOWN;
}

SWIFT_INLINE unsigned long swift_FIODTYPE() {
  return FIODTYPE;
}
#endif

SWIFT_INLINE rlim_t swift_RLIM_INFINITY() {
  return RLIM_INFINITY;
}

SWIFT_INLINE int swift_RLIMIT_MEMLOCK() {
  return RLIMIT_MEMLOCK;
}

SWIFT_INLINE int swift_RLIMIT_NPROC() {
  return RLIMIT_NPROC;
}

SWIFT_INLINE int swift_RLIMIT_RSS() {
  return RLIMIT_RSS;
}

SWIFT_INLINE void swift_clearerr_unlocked(FILE *stream) {
  return clearerr_unlocked(stream);
}

SWIFT_INLINE int swift_feof_unlocked(FILE *stream) {
  return feof_unlocked(stream);
}

SWIFT_INLINE int swift_ferror_unlocked(FILE *stream) {
  return ferror_unlocked(stream);
}

SWIFT_INLINE int swift_fileno_unlocked(FILE *stream) {
  return fileno_unlocked(stream);
}

SWIFT_INLINE u_int32_t swift_major(dev_t dev) {
  return major(dev);
}

SWIFT_INLINE u_int32_t swift_minor(dev_t dev) {
  return minor(dev);
}

SWIFT_INLINE dev_t swift_makedev(u_int32_t major, u_int32_t minor) {
  return makedev(major, minor);
}

SWIFT_INLINE int swift_get_errno() {
  return errno;
}

SWIFT_INLINE void swift_set_errno(int value) {
  errno = value;
}

SWIFT_INLINE FILE* swift_get_stdin() {
  return stdin;
}

SWIFT_INLINE FILE* swift_get_stdout() {
  return stdout;
}

SWIFT_INLINE FILE* swift_get_stderr() {
  return stderr;
}

#define SWIFT_INLINE static inline __attribute__((__always_inline__))

#include <fts.h>
#include <sys/ioctl.h>
#include <sys/resource.h>
#include <arpa/inet.h>

#ifdef __linux__

#define __USE_GNU 1
#include <string.h>
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

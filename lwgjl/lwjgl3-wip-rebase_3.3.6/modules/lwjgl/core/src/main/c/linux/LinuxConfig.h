/*
 * Copyright LWJGL. All rights reserved.
 * License terms: https://www.lwjgl.org/license
 */

#include <stddef.h>
#include <stdint.h>

#define DISABLE_WARNINGS() \
    _Pragma("GCC diagnostic push")
#ifndef __clang__
    _Pragma("GCC diagnostic ignored \"-Wunused-parameter\"")
    _Pragma("GCC diagnostic ignored \"-Wunused-but-set-variable\"")
    _Pragma("GCC diagnostic ignored \"-Wsign-compare\"")
#else
    _Pragma("GCC diagnostic ignored \"-Wall\"") \
    _Pragma("GCC diagnostic ignored \"-Wextra\"")
#endif
#define ENABLE_WARNINGS() \
    _Pragma("GCC diagnostic pop")

// JNIEXPORT_CRITICAL & CRITICAL are used as a workaround for JDK-8167409 on applicable functions.
#define JNIEXPORT_CRITICAL static
#define CRITICAL(function) _JavaCritical_##function

#if __ANDROID_API__ < 24
#include <errno.h>
#include <sys/uio.h>

inline ssize_t preadv(int fd, const struct iovec *iov, int iovcnt, off_t offset) {
    errno = ENOSYS;
    return -1;
}
inline ssize_t pwritev(int fd, const struct iovec *iov, int iovcnt, off_t offset) {
    errno = ENOSYS;
    return -1;
}
inline ssize_t preadv2(int fd, const struct iovec *iov, int iovcnt, off_t offset, int flags) {
    errno = ENOSYS;
    return -1;
}
inline ssize_t pwritev2(int fd, const struct iovec *iov, int iovcnt, off_t offset, int flags) {
    errno = ENOSYS;
    return -1;
}
inline ssize_t process_vm_readv(pid_t pid, const struct iovec *local_iov, unsigned long liovcnt,
                                const struct iovec *remote_iov, unsigned long riovcnt, unsigned long flags) {
    errno = ENOSYS;
    return -1;
}
inline ssize_t process_vm_writev(pid_t pid, const struct iovec *local_iov, unsigned long liovcnt,
                                const struct iovec *remote_iov, unsigned long riovcnt, unsigned long flags) {
    errno = ENOSYS;
    return -1;
}
#endif

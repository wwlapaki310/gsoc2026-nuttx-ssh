/**
 * nuttx_compat.h
 * Compatibility shims for porting Dropbear to Apache NuttX.
 *
 * NuttX does not support fork(). This header provides replacements
 * using NuttX tasks and pthreads.
 *
 * SPDX-License-Identifier: MIT
 */

#ifndef NUTTX_COMPAT_H
#define NUTTX_COMPAT_H

#ifdef CONFIG_NUTTX

#include <pthread.h>
#include <nuttx/config.h>

/* -------------------------------------------------------------------
 * fork() replacement
 * Dropbear calls fork() to handle each SSH connection in a child process.
 * On NuttX we use pthread instead.
 * -------------------------------------------------------------------
 */

/**
 * Signature matching Dropbear's connection handler.
 * Replace fork()-based dispatch with this in svr-main.c
 */
typedef void *(*nuttx_conn_handler_t)(void *arg);

static inline int nuttx_spawn_connection(nuttx_conn_handler_t handler,
                                          void *ctx)
{
    pthread_t tid;
    pthread_attr_t attr;
    int ret;

    pthread_attr_init(&attr);
    /* SSH session needs sufficient stack: 16 KB minimum */
    pthread_attr_setstacksize(&attr, CONFIG_NETUTILS_DROPBEAR_STACKSIZE);

    ret = pthread_create(&tid, &attr, handler, ctx);
    pthread_attr_destroy(&attr);
    if (ret != 0) {
        return -1;
    }
    pthread_detach(tid);
    return 0;
}

/* -------------------------------------------------------------------
 * /dev/urandom
 * Required by Dropbear for cryptographic random number generation.
 * Ensure CONFIG_DEV_URANDOM=y in NuttX config.
 * -------------------------------------------------------------------
 */
#ifndef DROPBEAR_URANDOM_DEV
#  define DROPBEAR_URANDOM_DEV "/dev/urandom"
#endif

/* -------------------------------------------------------------------
 * PAM / passwd stub
 * NuttX has no PAM. Use a Kconfig-defined password for testing.
 * For production: extend to use CONFIG_LIBC_PASSWD.
 * -------------------------------------------------------------------
 */
#ifdef CONFIG_NETUTILS_DROPBEAR_PASSWORD
#  define NUTTX_SSH_PASSWORD CONFIG_NETUTILS_DROPBEAR_PASSWORD
#else
#  define NUTTX_SSH_PASSWORD "nuttx"
#endif

static inline int nuttx_check_password(const char *user,
                                        const char *password)
{
    (void)user; /* single-user system for now */
    return (strcmp(password, NUTTX_SSH_PASSWORD) == 0) ? 0 : -1;
}

/* -------------------------------------------------------------------
 * PTY wrapper
 * NuttX supports /dev/ptmx with CONFIG_PSEUDOTERM=y
 * openpty() can be emulated as:
 *   fd = open("/dev/ptmx", O_RDWR)
 *   grantpt(fd)
 *   unlockpt(fd)
 *   slave_name = ptsname(fd)
 * -------------------------------------------------------------------
 */
#ifdef CONFIG_PSEUDOTERM
#  include <pty.h>
   /* NuttX provides openpty() when CONFIG_PSEUDOTERM=y */
#else
#  warning "CONFIG_PSEUDOTERM not set: SSH shell sessions unavailable"
#endif

#endif /* CONFIG_NUTTX */
#endif /* NUTTX_COMPAT_H */

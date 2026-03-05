# Porting Notes: Dropbear → NuttX

> Technical feasibility study and porting analysis.
> Status: 🔬 Research phase

---

## Dropbear Source Audit

### Key Files in Dropbear

```
dropbear/
├── svr-main.c        # Server main loop — fork() per connection HERE
├── cli-main.c        # Client main
├── dbutil.c          # Utility: dropbear_log(), dropbear_exit()
├── session.c         # SSH session state machine
├── crypto/           # libtomcrypt wrapper
├── libtomcrypt/      # Bundled crypto (no OS deps)
├── libtommath/       # Bundled big-integer math (no OS deps)
└── runopts.c         # Runtime options parsing
```

---

## POSIX Gap Analysis

### 🔴 Critical Gaps

#### 1. `fork()` in server connection loop (`svr-main.c`)
```c
// Dropbear original (svr-main.c)
pid = fork();
if (pid == 0) {
    // child handles the connection
    handle_connect(...);
    exit(0);
}
```
**NuttX fix**: Use `task_create()` or `pthread_create()` instead.
```c
// NuttX adaptation
pthread_t tid;
pthread_create(&tid, NULL, handle_connect_thread, conn_ctx);
pthread_detach(tid);
```
Risk: **Medium** — needs careful context isolation (each connection needs its own session state).

#### 2. PTY (`openpty()` / `/dev/ptmx`)
Dropbear calls `openpty()` to allocate a pseudo-terminal for shell sessions.
- NuttX supports `/dev/ptmx` with `CONFIG_PSEUDOTERM=y`
- `openpty()` wrapper can be implemented using `/dev/ptmx` + `grantpt()` + `unlockpt()`
Risk: **Medium** — PTY is available but may need wrapper.

#### 3. PAM / `getpwnam()`
Dropbear uses PAM or `/etc/passwd` for authentication.
- NuttX has no PAM
- NuttX does have basic `getpwnam()` support via `CONFIG_LIBC_PASSWD`
- For GSoC scope: compile-time password via Kconfig is acceptable
Risk: **Low** — stub is straightforward.

### 🟡 Minor Gaps

| API | NuttX Status | Notes |
|-----|-------------|-------|
| `socket()` / `connect()` / `accept()` | ✅ LwIP BSD sockets | Should work as-is |
| `select()` / `poll()` | ✅ | Supported |
| `/dev/urandom` | ✅ `CONFIG_DEV_URANDOM=y` | Required for crypto |
| `fcntl(F_SETFL, O_NONBLOCK)` | ✅ | Supported |
| `syslog()` | ✅ | NuttX has syslog |
| `getaddrinfo()` | ✅ | LwIP DNS |
| `signal()` / `SIGCHLD` | ⚠️ Partial | No child processes; SIGCHLD not needed after fork→pthread refactor |
| `pipe()` | ✅ | Supported |

---

## Crypto Layer Assessment

### libtomcrypt (bundled in Dropbear)
- Pure C, no OS dependencies
- Should compile on NuttX with `-DLTC_NO_FILE` to disable file I/O
- ARM Cortex-M optimized paths available
- **Estimated effort**: Minor `Makefile` changes only

### Alternative: mbedTLS
- Already supported in NuttX (`CONFIG_MBEDTLS`)
- Would require more significant Dropbear changes
- **Recommendation**: Use libtomcrypt for initial port; mbedTLS as future optimization

---

## Memory Estimates

| Component | Flash (est.) | RAM (est.) |
|-----------|-------------|------------|
| Dropbear server binary | ~110 KB | ~30 KB |
| libtomcrypt | ~80 KB | ~5 KB |
| Active SSH session state | — | ~20 KB/session |
| **Total** | **~190 KB** | **~55 KB** |

ESP32-S3 has 512 KB RAM and 8 MB Flash — **comfortably within budget**.
RP2040 (Pico W) has 264 KB RAM — tight but feasible with 1 session.

---

## Build System Integration Plan

### Directory structure in `nuttx-apps`
```
netutils/dropbear/
├── Kconfig
├── CMakeLists.txt
├── Makefile
├── dropbear/          # Dropbear source (git submodule)
├── nuttx_port/
│   ├── nuttx_compat.h  # fork() → task_create() shims
│   ├── nuttx_passwd.c  # Minimal password auth
│   └── nuttx_pty.c     # PTY wrapper
└── README.md
```

### Kconfig
```kconfig
menu "Dropbear SSH"

config NETUTILS_DROPBEAR
    bool "Dropbear SSH"
    depends on NET && NET_TCP && DEV_URANDOM
    select CRYPTO

config NETUTILS_DROPBEAR_SERVER
    bool "SSH Server (dropbear)"
    depends on NETUTILS_DROPBEAR && PSEUDOTERM
    default y

config NETUTILS_DROPBEAR_CLIENT
    bool "SSH Client (dbclient)"
    depends on NETUTILS_DROPBEAR
    default y

config NETUTILS_DROPBEAR_PORT
    int "SSH server port"
    depends on NETUTILS_DROPBEAR_SERVER
    default 22

config NETUTILS_DROPBEAR_PASSWORD
    string "Default password (for testing only)"
    depends on NETUTILS_DROPBEAR_SERVER
    default "nuttx"

endmenu
```

---

## Development Environment Setup

```bash
# 1. NuttX + NuttX-apps
git clone https://github.com/apache/nuttx.git
git clone https://github.com/apache/nuttx-apps.git

# 2. Toolchain (ARM / Xtensa)
sudo apt install gcc-arm-none-eabi
# For ESP32:
pip install esptool

# 3. QEMU simulation target (for early testing)
cd nuttx
./tools/configure.sh sim:nsh
make -j$(nproc)
./nuttx  # runs NuttX in QEMU-like simulator

# 4. Dropbear source
git clone https://github.com/mkj/dropbear.git netutils/dropbear/dropbear
```

---

## Open Questions

- [ ] Does NuttX `pthread` stack size default accommodate Dropbear's session stack usage?
- [ ] Is `CONFIG_PSEUDOTERM` stable on ESP32 NuttX port?
- [ ] `libtomcrypt` hardware acceleration: can ESP32's AES HW accelerator be leveraged?
- [ ] Upstream appetite for Dropbear vs. a lighter custom SSH-2 subset?

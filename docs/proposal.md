# GSoC 2026 — Project Proposal

## Dropbear SSH Server/Client Port to Apache NuttX

**Applicant:** Satoru  
**Organization:** Apache Software Foundation  
**Mentors:** Alan Carvalho de Assis (acassis@apache.org), dev@nuttx.apache.org  
**Difficulty:** Major | **Size:** ~90 hours (Small)

---

## 1. Abstract

Apache NuttX is a POSIX-compliant RTOS widely used in resource-constrained embedded systems. Despite having mature TCP/IP networking support via LwIP, NuttX currently lacks any SSH implementation. This project ports [Dropbear SSH](https://github.com/mkj/dropbear) — a lightweight, production-proven SSH-2 implementation — to NuttX, delivering both an SSH server (for remote board maintenance) and an SSH client (for secure remote control of Linux hosts from NuttX+LVGL devices).

---

## 2. Motivation & Background

### Why SSH on NuttX?

Embedded boards running NuttX are increasingly deployed in the field — industrial sensors, IoT gateways, camera systems — where physical access for maintenance is impractical. Telnet exists, but transmits credentials in plaintext. SSH solves this with:

- **Encrypted channel**: AES/ChaCha20 transport encryption
- **Host authentication**: Prevents man-in-the-middle attacks
- **Port forwarding**: Enables secure tunneling of other protocols

### Use Cases

| Scenario | Value |
|----------|-------|
| Factory floor NuttX sensor → remote debug via SSH | No physical access needed |
| NuttX + LVGL display board → SSH into Linux server | Secure embedded terminal |
| OTA preparation | Can be combined with SFTP for file transfer |

### Why Dropbear?

| Implementation | Binary Size | Dependencies | License |
|---------------|-------------|--------------|--------|
| OpenSSH | ~2 MB | OpenSSL, zlib, PAM | BSD |
| **Dropbear** | **~110 KB** | libtomcrypt (built-in) | **MIT** |
| wolfSSH | ~100 KB | wolfSSL | GPL/Commercial |

Dropbear's minimal footprint and MIT license make it the best fit for NuttX's embedded constraints and Apache licensing requirements.

---

## 3. Technical Approach

### 3.1 Porting Strategy

Dropbear relies on a POSIX-compatible environment. NuttX provides POSIX compliance at the application level, but some gaps need bridging:

```
Dropbear layer          NuttX adaptation needed
─────────────────────   ──────────────────────────────────
socket / select()    →  NuttX LwIP BSD socket API (mostly compatible)
fork() / exec()      →  Replace with NuttX tasks/pthread
/dev/urandom         →  NuttX /dev/urandom (CONFIG_DEV_URANDOM)
getpwnam() / PAM     →  Stub or NuttX passwd file
ptmx / openpty()     →  NuttX /dev/ptmx (CONFIG_PSEUDOTERM)
fcntl() / ioctl()    →  NuttX VFS layer (largely compatible)
```

### 3.2 Crypto Layer

Dropbear ships with `libtomcrypt` and `libtommath`. These are C-only libraries with no OS dependencies — they should compile on NuttX with minor `Makefile` adjustments.

Alternatively, NuttX already has **mbedTLS** support (`CONFIG_MBEDTLS`). A future optimization could swap libtomcrypt for mbedTLS to reduce duplication.

### 3.3 Key Porting Challenges

1. **`fork()` absence**: NuttX does not support `fork()`. Dropbear's server uses `fork()` per connection. Solution: refactor to `pthread`-based or `task_create()`-based connection handler.
2. **`/etc/passwd` / PAM**: NuttX has no PAM. Solution: implement a minimal password check using a compile-time or Kconfig-defined credential, or NuttX's `passwd` file support.
3. **Terminal (PTY)**: SSH shell sessions require a pseudo-terminal. NuttX supports `/dev/ptmx` with `CONFIG_PSEUDOTERM=y`.
4. **Entropy**: `dropbear` requires `/dev/urandom`. NuttX provides this with `CONFIG_DEV_URANDOM=y`.

### 3.4 NuttX Kconfig Integration

New Kconfig symbols to be added to NuttX:

```kconfig
config NETUTILS_DROPBEAR
    bool "Dropbear SSH server/client"
    depends on NET_TCP && DEV_URANDOM
    ---help---
        Enable Dropbear SSH server and/or client for NuttX.

config NETUTILS_DROPBEAR_SERVER
    bool "Enable SSH server (dropbear)"
    depends on NETUTILS_DROPBEAR && PSEUDOTERM

config NETUTILS_DROPBEAR_CLIENT
    bool "Enable SSH client (dbclient)"
    depends on NETUTILS_DROPBEAR
```

---

## 4. Deliverables

| # | Deliverable | Week |
|---|-------------|------|
| 1 | Dropbear + libtomcrypt compiles on NuttX (no link errors) | 2 |
| 2 | SSH server accepts connection on QEMU NuttX sim | 4 |
| 3 | Password authentication working | 5 |
| 4 | Interactive shell session over SSH | 6 |
| 5 | SSH client connects to Linux host | 8 |
| 6 | Running on real hardware (ESP32-S3 or Pico W) | 10 |
| 7 | Upstream PR to nuttx-apps with Kconfig integration | 12 |
| 8 | Documentation + example config | 12 |

---

## 5. Timeline

### Community Bonding (May 1–26)
- Deep-read NuttX networking internals (`net/`, `libs/libc/`)
- Audit Dropbear source: identify all `fork()`/PAM/PTY call sites
- Set up QEMU-based NuttX development environment
- First contact with mentors, align on scope

### Week 1–2 (May 27 – Jun 9)
- Get Dropbear + libtomcrypt to compile under NuttX toolchain
- Resolve `sys/types.h`, `unistd.h` compatibility issues
- CI: GitHub Actions build check

### Week 3–4 (Jun 10 – Jun 23)
- Adapt socket layer: verify BSD socket compatibility with LwIP
- Replace `fork()` with `pthread`/`task_create()` in server connection loop
- SSH server listens on port 22 in QEMU sim

### Week 5–6 (Jun 24 – Jul 7) — *Midterm*
- Password authentication via NuttX passwd stub
- PTY allocation (`/dev/ptmx`) for shell session
- Interactive `nsh` shell accessible over SSH

### Week 7–8 (Jul 8 – Jul 21)
- SSH client (`dbclient`) port
- Connect from NuttX board to Linux host
- Execute remote commands, capture output

### Week 9–10 (Jul 22 – Aug 4)
- Flash and test on ESP32-S3-DevKit (primary target)
- Memory profiling: RAM/Flash usage report
- Fix hardware-specific issues

### Week 11–12 (Aug 5 – Aug 18) — *Final*
- RSA/Ed25519 key-based authentication
- Kconfig polish, `make menuconfig` integration
- Upstream PR to [nuttx-apps](https://github.com/apache/nuttx-apps)
- Final documentation

---

## 6. About Me

I am an EdgeAI specialist at Sony Semiconductor Solutions, working on IMX500 intelligent vision sensors and the AITRIOS platform. My background spans:

- **Embedded systems**: NuttX, FreeRTOS, Raspberry Pi, ESP32, STM32
- **Networking**: TCP/IP stack internals, Azure IoT, MQTT, REST APIs
- **Security**: Embedded secure boot, TLS in constrained environments
- **Linux systems programming**: systemd services, device drivers, POSIX APIs

I have maintained multiple open-source GitHub projects and contributed to technical documentation for Sony's IMX500 ecosystem. My experience with resource-constrained networking makes me well-suited to tackle the porting challenges this project presents.

---

## 7. Community Engagement Plan

- Weekly progress posts on the NuttX mailing list (`dev@nuttx.apache.org`)
- All work done in public on this GitHub repository
- Draft PR to `nuttx-apps` by Week 8 for early mentor feedback
- Blog post summarizing the porting journey at project end

---

## 8. References

1. Dropbear SSH — https://github.com/mkj/dropbear
2. Apache NuttX Apps — https://github.com/apache/nuttx-apps
3. NuttX Networking Docs — https://nuttx.apache.org/docs/latest/components/net/
4. NuttX POSIX Support — https://nuttx.apache.org/docs/latest/reference/user/
5. GSoC 2026 NuttX Ideas — https://cwiki.apache.org/confluence/display/NUTTX/GSoC2026

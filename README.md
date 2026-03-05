# GSoC 2026 — Dropbear SSH Port to Apache NuttX

> **Google Summer of Code 2026**
> Organization: [Apache Software Foundation](https://summerofcode.withgoogle.com/programs/2026/organizations/apache-software-foundation)
> Project: *Dropbear port (or other SSH Server/Client) to NuttX*
> Difficulty: Major | Size: ~90 hours (Small)

---

## 📌 Project Overview

[Apache NuttX](https://nuttx.apache.org/) is a mature, standards-compliant RTOS targeting microcontrollers and resource-constrained embedded systems. Despite having robust networking support (TCP/IP via LwIP), **NuttX currently has no SSH client or server implementation**.

This project aims to port [Dropbear SSH](https://matt.ucc.asn.au/dropbear/dropbear.html) — a lightweight, production-proven SSH implementation — to NuttX, enabling:

- 🔒 **SSH Server**: Remote maintenance access to NuttX-powered boards deployed in the field
- 💻 **SSH Client**: Low-cost NuttX + LVGL boards acting as secure remote consoles for Linux servers

---

## 🎯 Goals

### Primary Goals
- [ ] Port Dropbear SSH server to NuttX (target: ESP32 / Raspberry Pi Pico W)
- [ ] Port Dropbear SSH client to NuttX
- [ ] Integrate with NuttX's POSIX-compatible filesystem and networking stack

### Stretch Goals
- [ ] SFTP subsystem support (secure file transfer to/from NuttX)
- [ ] Key-based authentication (RSA / Ed25519)
- [ ] CI integration with NuttX build system (GitHub Actions)

---

## 🏗️ Architecture

```
┌──────────────────────────────────────┐
│            NuttX RTOS                │
│  ┌────────────┐  ┌────────────────┐  │
│  │ Dropbear   │  │  Dropbear      │  │
│  │ SSH Server │  │  SSH Client    │  │
│  └─────┬──────┘  └──────┬─────────┘  │
│        │                │            │
│  ┌─────▼────────────────▼─────────┐  │
│  │     NuttX TCP/IP (LwIP)        │  │
│  └────────────────────────────────┘  │
│  ┌─────────────────────────────────┐  │
│  │  NuttX VFS / POSIX layer        │  │
│  └─────────────────────────────────┘  │
└──────────────────────────────────────┘
```

---

## 📅 Timeline

| Period | Milestone |
|--------|-----------|
| Community Bonding (May) | Study NuttX networking internals, Dropbear codebase audit, setup build environment |
| Week 1–2 | Porting Dropbear crypto layer (libtomcrypt / mbedTLS) to NuttX |
| Week 3–4 | Adapt Dropbear POSIX socket calls to NuttX networking API |
| Week 5–6 | **SSH Server** — basic password authentication, shell session |
| Week 7–8 | **SSH Client** — connect to remote Linux host, execute commands |
| Week 9–10 | Testing on real hardware (ESP32-S3 / Raspberry Pi Pico W) |
| Week 11–12 | Key-based auth, SFTP subsystem, documentation & upstream PR |

---

## 🖥️ Target Hardware

| Board | SoC | RAM | Flash | Wi-Fi |
|-------|-----|-----|-------|-------|
| ESP32-S3-DevKit | Xtensa LX7 | 512 KB | 8 MB | ✅ |
| Raspberry Pi Pico W | RP2040 | 264 KB | 2 MB | ✅ |
| STM32F429-Discovery | Cortex-M4 | 256 KB | 2 MB | (Ethernet) |

---

## 🔧 Tech Stack

- **RTOS**: Apache NuttX (≥ 12.x)
- **SSH Implementation**: Dropbear SSH 2022.83+
- **Crypto**: mbedTLS (NuttX-compatible) or libtomcrypt
- **Networking**: LwIP (built into NuttX)
- **Build System**: CMake / Kconfig (NuttX native)
- **CI**: GitHub Actions + QEMU NuttX simulation

---

## 📚 References

- [NuttX Official Docs](https://nuttx.apache.org/docs/latest/)
- [Dropbear SSH Source](https://github.com/mkj/dropbear)
- [GSoC 2026 NuttX Ideas Page](https://cwiki.apache.org/confluence/display/NUTTX/Google+Summer+of+Code+2026+Idea+List)
- [NuttX Networking (LwIP)](https://nuttx.apache.org/docs/latest/components/net/index.html)

---

## 👤 Applicant

**Satoru** — EdgeAI Specialist, Sony Semiconductor Solutions
Experience: Embedded systems, Raspberry Pi, Azure IoT, RTOS, EdgeAI (IMX500 / AITRIOS)

📧 Mentors:
- Alan Carvalho de Assis — acassis (at) apache.org
- Project Devs — dev (at) nuttx.apache.org

---

## 📝 Progress Log

| Date | Activity |
|------|----------|
| 2026-03-05 | Repository created, initial research started |

---

> *This repository tracks proposal drafts, feasibility experiments, and implementation progress for the GSoC 2026 application.*

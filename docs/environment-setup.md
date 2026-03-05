# Development Environment Setup

> Step-by-step guide to set up NuttX build environment for SSH porting work.

---

## Prerequisites

```bash
# Ubuntu 22.04 / 24.04
sudo apt update
sudo apt install -y \
    git cmake ninja-build \
    gcc-arm-none-eabi \
    picocom minicom \
    python3-pip \
    kconfig-frontends
```

---

## 1. Clone NuttX

```bash
mkdir ~/nuttx-workspace && cd ~/nuttx-workspace
git clone https://github.com/apache/nuttx.git nuttx
git clone https://github.com/apache/nuttx-apps.git apps
```

---

## 2. Simulator Build (for initial porting)

```bash
cd nuttx
./tools/configure.sh sim:nsh
make -j$(nproc)
./nuttx
```

Expected output:
```
NuttXConfig: sim
NuttShell (NSH) NuttX-12.x
nsh> ?
```

---

## 3. ESP32-S3 Build

```bash
# Install ESP-IDF toolchain
pip3 install esptool

# Configure for ESP32-S3
cd nuttx
./tools/configure.sh esp32s3-devkit:wifi

# Enable networking
kconfig-tweak --enable CONFIG_NET
kconfig-tweak --enable CONFIG_NET_TCP
kconfig-tweak --enable CONFIG_DEV_URANDOM

make -j$(nproc)

# Flash
esptool.py --port /dev/ttyUSB0 write_flash 0x0 nuttx.bin
```

---

## 4. Raspberry Pi Pico W Build

```bash
./tools/configure.sh raspberrypi-pico-w:nsh
make -j$(nproc)
# Copy nuttx.uf2 to Pico W in BOOTSEL mode
```

---

## 5. Network Test (QEMU sim)

```bash
# In one terminal — run NuttX sim
./nuttx

# In NuttX shell
nsh> ifup eth0
nsh> ifconfig eth0 10.0.2.15

# In another terminal — connect to future SSH server
ssh -p 2222 nuttx@localhost
```

---

## 6. Dropbear Build Test (host)

```bash
# First build on Linux to understand the build system
cd /tmp
git clone https://github.com/mkj/dropbear.git
cd dropbear
autoconf && autoheader
./configure
make PROGRAMS="dropbear dbclient"
./dropbear -F -p 2222 -r test_host_key  # run in foreground
```

---

## Useful NuttX Commands for Debugging

```bash
nsh> free          # show memory usage
nsh> ps            # list tasks
nsh> netstat       # network connections
nsh> ifconfig      # network interfaces
nsh> cat /proc/net/tcp  # active TCP connections
```

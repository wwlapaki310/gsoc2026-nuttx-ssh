#!/bin/bash
# =============================================================================
# menuconfig.sh — NuttX の設定を GUI で変更する
# Dropbear 用に有効化すべき設定のガイド付き
# =============================================================================
set -euo pipefail

WORKSPACE="${NUTTX_WORKSPACE:-$HOME/nuttx-workspace}"

echo "================================================"
echo " NuttX menuconfig"
echo "================================================"
echo ""
echo "Dropbear SSH に必要な設定 (参考):"
echo ""
echo "  [必須]"
echo "  Networking Support"
echo "    └─ Networking Support → ON"
echo "    └─ SOCK_STREAM (TCP) → ON"
echo ""
echo "  Device Drivers"
echo "    └─ /dev/urandom → ON   (CONFIG_DEV_URANDOM)"
echo ""
echo "  RTOS Features"
echo "    └─ POSIX Message Queues → ON"
echo "    └─ pthread support → ON"
echo ""
echo "  [SSH server に必要]"
echo "  Device Drivers"
echo "    └─ Pseudo-Terminal Support → ON (CONFIG_PSEUDOTERM)"
echo ""
echo "Press Enter to open menuconfig..."
read -r

cd "$WORKSPACE/nuttx"
make menuconfig

echo ""
echo "設定を保存しました。ビルドするには:"
echo "  cd $WORKSPACE/nuttx && make -j\$(nproc)"
echo "  bash scripts/run-qemu.sh"

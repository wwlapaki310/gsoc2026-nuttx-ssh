#!/bin/bash
# =============================================================================
# run-qemu.sh — NuttX (qemu-armv7a) を QEMU で起動
#
# ネットワーク構成:
#   ホスト localhost:2222 → NuttX port 22  (SSH テスト用)
#   ホスト localhost:8080 → NuttX port 80  (将来の HTTP テスト用)
#
# 終了方法: Ctrl-A → X
# =============================================================================
set -euo pipefail

WORKSPACE="${NUTTX_WORKSPACE:-$HOME/nuttx-workspace}"
KERNEL="$WORKSPACE/nuttx/nuttx"

if [ ! -f "$KERNEL" ]; then
    echo "ERROR: $KERNEL が見つかりません"
    echo "先に setup.sh を実行してください: bash scripts/setup.sh"
    exit 1
fi

echo "================================================"
echo " NuttX on QEMU (ARM Cortex-A7)"
echo "================================================"
echo " カーネル : $KERNEL"
echo " ポート転送: localhost:2222 → NuttX:22"
echo " 終了方法 : Ctrl-A → X"
echo "================================================"
echo ""

exec qemu-system-arm \
    -M virt \
    -cpu cortex-a7 \
    -nographic \
    -bios none \
    -kernel "$KERNEL" \
    -net nic,model=virtio \
    -net user,hostfwd=tcp::2222-:22,hostfwd=tcp::8080-:80

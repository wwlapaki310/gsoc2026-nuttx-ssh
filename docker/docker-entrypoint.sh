#!/bin/bash
# =============================================================================
# docker-entrypoint.sh
# Docker コンテナ起動時に QEMU で NuttX を実行する
# =============================================================================
set -e

KERNEL=/opt/nuttx/nuttx

if [ ! -f "$KERNEL" ]; then
  echo "ERROR: $KERNEL が見つかりません。ビルドが失敗した可能性があります。"
  exit 1
fi

echo "========================================"
echo " NuttX on QEMU (ARM Cortex-A7)"
echo "========================================"
echo " カーネル : $KERNEL ($(ls -lh $KERNEL | awk '{print $5}'))"
echo " ポート転送: コンテナ:22 → ホスト:2222"
echo "   → 別ターミナルで: ssh -p 2222 nuttx@localhost"
echo " 終了方法 : Ctrl-A → X"
echo "========================================"
echo ""

exec qemu-system-arm \
  -M virt \
  -cpu cortex-a7 \
  -nographic \
  -bios none \
  -kernel "$KERNEL" \
  -net nic,model=virtio \
  -net user,hostfwd=tcp::22-:22

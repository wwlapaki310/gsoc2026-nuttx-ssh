#!/bin/bash
# =============================================================================
# setup.sh — NuttX + QEMU 開発環境セットアップ (Ubuntu 22.04 / 24.04)
# Usage: bash scripts/setup.sh
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORKSPACE="$HOME/nuttx-workspace"

echo "============================================"
echo " GSoC 2026 NuttX SSH — 環境セットアップ"
echo "============================================"
echo ""

# --- 1. 必要パッケージ ---
echo "[1/4] パッケージをインストール中..."
sudo apt-get update -q
sudo apt-get install -y \
    git cmake ninja-build \
    python3-pip python3-pyelftools \
    gcc-arm-none-eabi binutils-arm-none-eabi \
    qemu-system-arm \
    kconfig-frontends \
    gperf gettext bison flex libssl-dev
echo "     OK"

# --- 2. バージョン確認 ---
echo ""
echo "[2/4] ツールチェーン確認..."
echo -n "  arm-none-eabi-gcc: "
arm-none-eabi-gcc --version | head -1
echo -n "  qemu-system-arm:   "
qemu-system-arm --version | head -1
echo -n "  cmake:             "
cmake --version | head -1

# --- 3. NuttX クローン ---
echo ""
echo "[3/4] NuttX リポジトリをクローン中..."
mkdir -p "$WORKSPACE"

if [ ! -d "$WORKSPACE/nuttx/.git" ]; then
    git clone --depth=1 https://github.com/apache/nuttx.git "$WORKSPACE/nuttx"
else
    echo "  nuttx/ は既に存在します。スキップ。"
fi

if [ ! -d "$WORKSPACE/apps/.git" ]; then
    git clone --depth=1 https://github.com/apache/nuttx-apps.git "$WORKSPACE/apps"
else
    echo "  apps/ は既に存在します。スキップ。"
fi

# --- 4. qemu-armv7a:nsh をビルド ---
echo ""
echo "[4/4] qemu-armv7a:nsh をビルド中..."
cd "$WORKSPACE/nuttx"
./tools/configure.sh qemu-armv7a:nsh
make -j"$(nproc)" 2>&1 | tail -5

if [ -f "$WORKSPACE/nuttx/nuttx" ]; then
    echo ""
    echo "============================================"
    echo " ビルド成功!"
    echo "============================================"
    echo ""
    echo "  バイナリ: $WORKSPACE/nuttx/nuttx"
    SIZE=$(ls -lh "$WORKSPACE/nuttx/nuttx" | awk '{print $5}')
    echo "  サイズ:   $SIZE"
    echo ""
    echo "次のステップ:"
    echo "  QEMU 起動 → bash $REPO_DIR/scripts/run-qemu.sh"
else
    echo "ERROR: ビルドが失敗しました"
    exit 1
fi

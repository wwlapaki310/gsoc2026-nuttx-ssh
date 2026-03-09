# =============================================================================
# GSoC 2026 — NuttX SSH Development Environment
#
# 含まれるもの:
#   - arm-none-eabi-gcc (ARMクロスコンパイラ)
#   - qemu-system-arm  (ARMエミュレーター)
#   - NuttX + nuttx-apps (ソース込み)
#
# 使い方:
#   docker compose up --build   # ビルド + NuttX起動
#   docker compose run dev bash  # 開発用シェル
# =============================================================================
FROM ubuntu:24.04

LABEL description="NuttX ARM development environment for GSoC 2026 SSH porting"

# タイムゾーン設定（apt install 中の対話をスキップ）
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tokyo

# --- 必要パッケージ ---
RUN apt-get update -q && apt-get install -y --no-install-recommends \
    # ビルドツール
    git cmake ninja-build make \
    gcc g++ \
    # ARMクロスコンパイラ
    gcc-arm-none-eabi binutils-arm-none-eabi \
    # QEMUのARMエミュレーター
    qemu-system-arm \
    # NuttX Kconfig
    kconfig-frontends \
    # Dropbear のビルドに必要
    autoconf automake libtool \
    # Python (NuttX ツールチェーン)
    python3 python3-pip python3-pyelftools \
    # デバッグ用
    gdb-multiarch \
    # ネットワークツール
    iproute2 iputils-ping \
    # その他
    wget curl vim less \
  && rm -rf /var/lib/apt/lists/*

# --- NuttX ソースを取得 ---
WORKDIR /opt
RUN git clone --depth=1 https://github.com/apache/nuttx.git nuttx && \
    git clone --depth=1 https://github.com/apache/nuttx-apps.git apps

# --- Dropbear ソース (ポーティング作業用) ---
RUN git clone --depth=1 https://github.com/mkj/dropbear.git /opt/dropbear

# --- qemu-armv7a:nsh をビルド ---
WORKDIR /opt/nuttx
RUN ./tools/configure.sh qemu-armv7a:nsh && \
    make -j$(nproc) 2>&1 | tail -10

# --- バイナリ確認 ---
RUN file /opt/nuttx/nuttx && ls -lh /opt/nuttx/nuttx

# --- 作業ディレクトリ ---
WORKDIR /workspace

# SSH ポート (将来のDropbear用)
EXPOSE 22

# デフォルト: NuttX を QEMU で起動
CMD ["/opt/nuttx/scripts/docker-entrypoint.sh"]

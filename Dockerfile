# =============================================================================
# GSoC 2026 — NuttX SSH Development Environment
# =============================================================================
FROM ubuntu:24.04

LABEL description="NuttX ARM development environment for GSoC 2026 SSH porting"

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tokyo

# --- 必要パッケージ ---
RUN apt-get update -q && apt-get install -y --no-install-recommends \
    git cmake ninja-build make \
    gcc g++ \
    gcc-arm-none-eabi binutils-arm-none-eabi \
    qemu-system-arm \
    kconfig-frontends \
    autoconf automake libtool \
    python3 python3-pip python3-pyelftools \
    gdb-multiarch \
    iproute2 iputils-ping \
    unzip zip \
    wget curl vim less \
  && rm -rf /var/lib/apt/lists/*

# --- kconfiglib をインストール ---
# NuttX 公式推奨の Python 製 Kconfig 実装。
# /usr/local/bin に入るため PATH 順で apt 版より優先される。
RUN pip3 install --break-system-packages kconfiglib

# PATH 確認: kconfiglib が優先されていることを確認
RUN echo "olddefconfig -> $(which olddefconfig)" && \
    echo "kconfig-tweak -> $(which kconfig-tweak)"

# --- NuttX ソースを取得 ---
WORKDIR /opt
RUN git clone --depth=1 https://github.com/apache/nuttx.git nuttx && \
    git clone --depth=1 https://github.com/apache/nuttx-apps.git apps

# --- Dropbear ソース (ポーティング作業用) ---
RUN git clone --depth=1 https://github.com/mkj/dropbear.git /opt/dropbear

# --- qemu-armv7a:nsh をビルド ---
WORKDIR /opt/nuttx
RUN ./tools/configure.sh qemu-armv7a:nsh && \
    make -j$(nproc) 2>&1 | tail -20

# --- バイナリ確認 ---
RUN file /opt/nuttx/nuttx && ls -lh /opt/nuttx/nuttx

# --- エントリポイントスクリプトをイメージ内にコピー ---
COPY docker/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

WORKDIR /workspace
EXPOSE 22

CMD ["/usr/local/bin/docker-entrypoint.sh"]

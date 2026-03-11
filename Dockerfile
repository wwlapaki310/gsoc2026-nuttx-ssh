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
    gcc-arm-none-eabi binutils-arm-none-eabi libnewlib-arm-none-eabi \
    qemu-system-arm \
    kconfig-frontends \
    autoconf automake libtool \
    python3 python3-pip python3-pyelftools \
    gdb-multiarch \
    iproute2 iputils-ping \
    wget curl vim less unzip patch \
  && rm -rf /var/lib/apt/lists/*

# --- kconfiglib をインストール ---
# NuttX 公式推奨の Python 製 Kconfig 実装。
# /usr/local/bin に入るため PATH 順で apt 版より優先される。
RUN pip3 install --break-system-packages kconfiglib

# PATH 確認
RUN echo "olddefconfig -> $(which olddefconfig)" && \
    echo "kconfig-tweak -> $(which kconfig-tweak)"

# --- NuttX ソースを取得 ---
WORKDIR /opt
RUN git clone --depth=1 --branch nuttx-12.7.0 https://github.com/apache/nuttx.git nuttx && \
    git clone --depth=1 --branch nuttx-12.7.0 https://github.com/apache/nuttx-apps.git apps

# --- Dropbear ソース (ポーティング作業用) ---
RUN git clone --depth=1 https://github.com/mkj/dropbear.git /opt/dropbear

# --- qemu-armv7a:nsh をベースに設定 ---
WORKDIR /opt/nuttx
RUN ./tools/configure.sh qemu-armv7a:nsh

# --- ネットワーク関連の設定を有効化 ---
# kconfig-tweak は .config の指定行を書き換えるだけのツール。
# Kconfig 構文の解析をしないので apt 版で問題なし。
# kconfiglib（pip）は make の内部で呼ばれる olddefconfig が担当する。
RUN kconfig-tweak --enable  CONFIG_NET            && \
    kconfig-tweak --enable  CONFIG_NET_IPv4        && \
    kconfig-tweak --enable  CONFIG_NET_TCP         && \
    kconfig-tweak --enable  CONFIG_NET_UDP         && \
    kconfig-tweak --enable  CONFIG_VIRTIO          && \
    kconfig-tweak --enable  CONFIG_VIRTIO_NET      && \
    kconfig-tweak --enable  CONFIG_NETUTILS_IFCONFIG && \
    kconfig-tweak --enable  CONFIG_NETUTILS_PING   && \
    make olddefconfig 2>&1 | tail -5

# --- ビルド ---
RUN bash -c 'set -o pipefail; make -j$(nproc) 2>&1 | tail -20'

# --- バイナリ確認 ---
RUN file /opt/nuttx/nuttx && ls -lh /opt/nuttx/nuttx

# --- エントリポイントスクリプトをイメージ内にコピー ---
COPY docker/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN sed -i 's/\r$//' /usr/local/bin/docker-entrypoint.sh && \
    chmod +x /usr/local/bin/docker-entrypoint.sh

WORKDIR /workspace
EXPOSE 22

CMD ["/usr/local/bin/docker-entrypoint.sh"]

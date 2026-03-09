# NuttX on QEMU — セットアップガイド

> ターゲット: `qemu-armv7a:nsh`
> ARM Cortex-A7 をエミュレート。SSH ポーティングのメイン開発環境。

---

## なぜ sim:nsh ではなく QEMU か

| | sim:nsh | qemu-armv7a:nsh |
|---|---|---|
| 動作 | Linux プロセスとして動く | ARM バイナリを QEMU でエミュレート |
| コンパイラ | ホストの gcc | arm-none-eabi-gcc（クロスコンパイル） |
| ネットワーク | ホストと共有 | 仮想 NIC（ポートフォワード可） |
| 実機との近さ | 遠い | 近い |
| SSH テスト | しにくい | **ポート2222→22 でそのまま試せる** |

SSH の開発には QEMU が断然向いている。

---

## ネットワーク構成

```
┌──────────────────────────────────────────┐
│ あなたの Linux PC (ホスト)                │
│                                           │
│  $ ssh -p 2222 nuttx@localhost            │
│         │                                 │
│   localhost:2222                          │
│         │ QEMU ポートフォワード           │
│         ▼                                 │
│  ┌─────────────────────────────────┐      │
│  │ QEMU (qemu-system-arm)          │      │
│  │                                  │      │
│  │  NuttX (ARM Cortex-A7)          │      │
│  │  IP: 10.0.2.15                  │      │
│  │  port 22 ← SSH server (予定)    │      │
│  └─────────────────────────────────┘      │
└──────────────────────────────────────────┘
```

QEMU の `-net user,hostfwd=tcp::2222-:22` オプションで
ホストの 2222 番ポートを NuttX の 22 番に転送する。

---

## Step 1: 必要パッケージのインストール

```bash
sudo apt update
sudo apt install -y \
    git cmake ninja-build python3-pip \
    gcc-arm-none-eabi binutils-arm-none-eabi \
    qemu-system-arm \
    kconfig-frontends \
    libgmp-dev libmpc-dev libmpfr-dev

# バージョン確認
arm-none-eabi-gcc --version
# → arm-none-eabi-gcc 12.x.x ...

qemu-system-arm --version
# → QEMU emulator version 8.x.x ...
```

---

## Step 2: NuttX をクローン

```bash
mkdir -p ~/nuttx-workspace && cd ~/nuttx-workspace
git clone https://github.com/apache/nuttx.git nuttx
git clone https://github.com/apache/nuttx-apps.git apps
```

ディレクトリ構成:
```
~/nuttx-workspace/
├── nuttx/   ← OSカーネル本体
└── apps/    ← アプリケーション（ここに Dropbear を追加する）
```

---

## Step 3: qemu-armv7a:nsh を設定・ビルド

```bash
cd ~/nuttx-workspace/nuttx

# ターゲット設定
./tools/configure.sh qemu-armv7a:nsh

# ビルド
make -j$(nproc)

# 成功すると nuttx（ELF バイナリ）が生成される
file nuttx
# → nuttx: ELF 32-bit LSB executable, ARM ...

ls -lh nuttx
# → 約 1~2 MB
```

---

## Step 4: QEMU で起動

```bash
# scripts/run-qemu.sh を使う（後述）
bash ~/nuttx-workspace/scripts/run-qemu.sh
```

手動で実行する場合:
```bash
qemu-system-arm \
  -M virt \
  -cpu cortex-a7 \
  -nographic \
  -bios none \
  -kernel ~/nuttx-workspace/nuttx/nuttx \
  -net nic,model=virtio \
  -net user,hostfwd=tcp::2222-:22
```

起動すると:
```
ABCNuttX-12.x.x
NuttShell (NSH) NuttX-12.x.x
nsh>
```

QEMU 終了: `Ctrl-A` → `X`

---

## Step 5: NuttX 内でネットワーク確認

```
nsh> ifconfig
# eth0 のアドレスを確認

nsh> ifup eth0
nsh> ping 10.0.2.2
# → 10.0.2.2 は QEMU のデフォルトゲートウェイ（ホスト側）
```

---

## Step 6: telnetd で疎通確認（SSH の前段テスト）

SSH サーバーを作る前に、まず Telnet でポートフォワードが機能するか確認する。

```bash
# menuconfig でTelnetdを有効化
cd ~/nuttx-workspace/nuttx
make menuconfig
# → Application Configuration
#   → Network Utilities
#     → Telnet daemon → ON
make -j$(nproc)
```

QEMU で起動後:
```
nsh> telnetd
```

ホスト側から:
```bash
telnet localhost 23
# → NuttX の nsh> プロンプトが出れば成功
```

これが動けば SSH サーバー（port 22）も同じ構成でテストできる。

---

## トラブルシューティング

### `arm-none-eabi-gcc: command not found`
```bash
sudo apt install gcc-arm-none-eabi
# または
sudo apt install gcc-arm-none-eabi binutils-arm-none-eabi
```

### `qemu-system-arm: network backend 'user' is not compiled in`
```bash
# QEMU を再インストール
sudo apt install --reinstall qemu-system-arm
qemu-system-arm -net help  # user が出ることを確認
```

### NuttX が起動しない（QEMU が無反応）
```bash
# nuttx バイナリが ARM ELF か確認
file nuttx/nuttx
# → ELF 32-bit LSB executable, ARM, EABI5 ...

# qemu-armv7a ターゲットで configure し直す
cd nuttx
make distclean
./tools/configure.sh qemu-armv7a:nsh
make -j$(nproc)
```

### ネットワークが通らない
```bash
# QEMU 起動後に NuttX 側で手動設定
nsh> ifconfig eth0 10.0.2.15 netmask 255.255.255.0
nsh> route add default 10.0.2.2
```

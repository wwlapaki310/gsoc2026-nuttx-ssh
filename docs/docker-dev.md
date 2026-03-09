# Docker 開発環境ガイド

> **推奨環境**: Docker Desktop (Mac/Windows) または Docker Engine (Linux)  
> QEMU は ARM ソフトウェアエミュレーションなので、Docker内でも完全動作します。

---

## なぜ Docker か

```
直接インストールの場合:
  Ubuntu に gcc-arm-none-eabi, qemu-system-arm 等を手動インストール
  → バージョン差異でビルドが通らないことがある
  → ホスト環境が汚れる

Docker の場合:
  Dockerfile に全依存関係が記述されている
  → docker compose up だけで同じ環境が再現される
  → ホスト環境はクリーンなまま
  → mentorと完全に同じ環境を共有できる
```

---

## 前提条件

```bash
# Docker がインストール済みであること
docker --version   # Docker 24.x 以上推奨
docker compose version  # v2.x 以上推奨
```

---

## クイックスタート

### 1. イメージをビルド

```bash
git clone https://github.com/wwlapaki310/gsoc2026-nuttx-ssh.git
cd gsoc2026-nuttx-ssh

make build
# または: docker compose build
```

内部で何が起きているか:
```
Dockerfile
  └─ Ubuntu 24.04 ベース
  └─ gcc-arm-none-eabi インストール  ← ARM クロスコンパイラ
  └─ qemu-system-arm インストール    ← ARM エミュレーター
  └─ NuttX + apps を git clone
  └─ qemu-armv7a:nsh を make        ← ARM バイナリをビルド
```

初回は 10〜15分かかります（NuttX のビルドのため）。

### 2. NuttX を起動

```bash
make run
# または: docker compose up nuttx
```

成功すると:
```
========================================
 NuttX on QEMU (ARM Cortex-A7)
========================================
 カーネル : /opt/nuttx/nuttx (1.5M)
 ポート転送: コンテナ:22 → ホスト:2222
   → 別ターミナルで: ssh -p 2222 nuttx@localhost
 終了方法 : Ctrl-A → X
========================================

ABCNuttShell (NSH) NuttX-12.x
nsh>
```

**終了**: `Ctrl-A` → `X`

### 3. 開発用シェルを起動

NuttX を起動したまま**別ターミナル**で:

```bash
make shell
# または: docker compose run --rm dev bash
```

コンテナ内のディレクトリ構成:
```
/opt/nuttx/      ← NuttX カーネルソース + ビルド済みバイナリ
/opt/apps/       ← nuttx-apps（ここに Dropbear を追加する）
/opt/dropbear/   ← Dropbear ソース（ポーティング作業用）
/workspace/      ← このリポジトリ（ホストとマウント共有）
```

---

## 開発ワークフロー

### NuttX の設定を変える (menuconfig)

```bash
make menuconfig
```

GUI が開くので、例えば:
```
Networking Support
  └─ [*] Networking Support
  └─ [*] SOCK_STREAM (TCP)

Device Drivers
  └─ [*] /dev/urandom      ← Dropbearの乱数生成に必要

RTOS Features
  └─ [*] Pseudo-Terminal Support  ← SSH シェルセッションに必要
```

変更後はリビルド:
```bash
make rebuild
make run
```

### Dropbear をホスト向けにビルドして動作確認

```bash
make dropbear-host
```

ビルドが通ったら:
```bash
make shell
# コンテナ内で:
cd /opt/dropbear
./dropbearkey -t ed25519 -f /tmp/host_key
./dropbear -F -E -p 2222 -r /tmp/host_key

# 別ターミナルから接続テスト
ssh -p 2222 root@localhost
```

---

## ネットワーク構成図

```
あなたのPC (ホスト)
  ┌─────────────────────────────────────────┐
  │                                         │
  │  $ ssh -p 2222 nuttx@localhost          │
  │         │                               │
  │   localhost:2222                        │
  │         │ docker -p 2222:22             │
  │         ▼                               │
  │  ┌─────────────────────────────────┐   │
  │  │ Docker コンテナ                  │   │
  │  │                                 │   │
  │  │  QEMU (qemu-system-arm)         │   │
  │  │  -net user,hostfwd=tcp::22-:22  │   │
  │  │         │                       │   │
  │  │         ▼                       │   │
  │  │  NuttX (ARM Cortex-A7)          │   │
  │  │  10.0.2.15 : port 22            │   │
  │  │  ← Dropbear SSH server (予定)   │   │
  │  └─────────────────────────────────┘   │
  └─────────────────────────────────────────┘
```

ポートの流れ:
```
[PC:2222] → docker -p → [コンテナ:22] → QEMU hostfwd → [NuttX:22]
```

---

## トラブルシューティング

### `docker: command not found`
```bash
# Ubuntu
sudo apt install docker.io docker-compose-v2
sudo usermod -aG docker $USER  # 再ログインが必要
```

### QEMU が起動するが nsh> が出ない
```bash
# コンテナ内で手動確認
make shell
cd /opt/nuttx
file nuttx  # ARM ELF であることを確認
qemu-system-arm -M virt -cpu cortex-a7 -nographic -bios none -kernel nuttx
```

### ビルドエラーで止まる
```bash
# キャッシュを消してフルビルド
make clean
make build
```

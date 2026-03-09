# Week 00 — 環境構築フェーズ

**期間**: 2026-03-05 〜
**ステータス**: 🔧 進行中

---

## 今週のゴール

- [ ] Ubuntu に arm-none-eabi-gcc / qemu-system-arm をインストール
- [ ] NuttX + apps をクローン
- [ ] `qemu-armv7a:nsh` ビルドが通る
- [ ] QEMU で `nsh>` プロンプトが出る
- [ ] QEMU ネットワーク越しに ping が通る
- [ ] Dropbear をホスト Linux でビルドして手元で動作確認

---

## 実施ログ

### 2026-03-05
- GitHub リポジトリ作成
- プロポーザル初稿作成 (`docs/proposal.md`)
- Dropbear ポーティングの技術調査 (`docs/porting-notes.md`)
- `nuttx_port/nuttx_compat.h` — fork() → pthread シム
- `nuttx_port/Kconfig` — NuttX menuconfig 統合
- QEMU セットアップガイド作成 (`docs/qemu-setup.md`)
- CI ワークフロー追加 (`.github/workflows/build-check.yml`)

---

## メモ・気づき

- `sim:nsh` はホスト gcc でビルドするので手軽だが、ネットワークの扱いが本物と違う
- `qemu-armv7a:nsh` は ARM クロスコンパイルが必要な分、実機に近い
- `hostfwd=tcp::2222-:22` でホストから `ssh -p 2222 localhost` で SSH テストが直接できる構成
- telnetd が動けば SSH も同じポートフォワード構成で動く見込み

---

## 次週の予定

- NuttX sim上で自作 pthread サンプルをビルド・実行
- `apps/netutils/telnetd/` のソースを読んで接続ハンドリングを理解
- Dropbear の `svr-main.c` を読んで fork() 箇所を全て把握

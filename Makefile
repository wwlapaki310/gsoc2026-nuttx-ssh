# =============================================================================
# Makefile — よく使うコマンドのショートカット
# =============================================================================
.PHONY: build run shell clean rebuild menuconfig dropbear-host help

## Dockerイメージをビルド (初回・Dockerfile変更後)
build:
	docker compose build

## NuttXをQEMUで起動 (Ctrl-A → X で終了)
run:
	docker compose up nuttx

## 開発用シェルを起動
shell:
	docker compose run --rm dev bash

## NuttXをクリーンビルド
rebuild:
	docker compose run --rm dev bash -c \
		"cd /opt/nuttx && make distclean && ./tools/configure.sh qemu-armv7a:nsh && make -j\$(nproc)"

## menuconfig を開く
menuconfig:
	docker compose run --rm dev bash -c \
		"cd /opt/nuttx && make menuconfig"

## DropbearをホストLinuxでビルド (動作確認用)
dropbear-host:
	docker compose run --rm dev bash -c \
		"cd /opt/dropbear && autoconf && autoheader && \
		 ./configure --disable-zlib --disable-pam && \
		 make PROGRAMS='dropbear dbclient' -j\$(nproc) && \
		 echo '=== ビルド成功 ===' && ls -lh dropbear dbclient"

## コンテナとボリュームを削除
clean:
	docker compose down -v

## このヘルプを表示
help:
	@echo ""
	@echo "GSoC 2026 NuttX SSH — 開発コマンド"
	@echo "-------------------------------------"
	@echo "  make build           Dockerイメージをビルド"
	@echo "  make run             NuttXをQEMUで起動"
	@echo "  make shell           開発用シェルを起動"
	@echo "  make rebuild         NuttXをクリーンビルド"
	@echo "  make menuconfig      NuttX設定GUIを起動"
	@echo "  make dropbear-host   Dropbearをホスト向けビルド"
	@echo "  make clean           環境をリセット"
	@echo ""

#!/usr/bin/env bash
set -eu

APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_BUNDLE="$APP_DIR/build/bin/ClamAV Desktop.app"

WAILS_BIN="$(command -v wails || true)"
if [ -z "$WAILS_BIN" ]; then
  WAILS_BIN="$(go env GOPATH)/bin/wails"
fi

if [ ! -x "$WAILS_BIN" ]; then
  printf '找不到 Wails CLI：%s\n' "$WAILS_BIN" >&2
  exit 1
fi

cd "$APP_DIR"
export GOCACHE="${GOCACHE:-$APP_DIR/build/go-cache}"

"$WAILS_BIN" build -clean -skipbindings

if [ ! -x "$APP_BUNDLE/Contents/MacOS/clamav-desktop" ]; then
  printf '建置後找不到 APP 執行檔：%s\n' "$APP_BUNDLE" >&2
  exit 1
fi

if [ ! -f "$APP_BUNDLE/Contents/Resources/iconfile.icns" ]; then
  printf '建置後找不到 APP icon：%s\n' "$APP_BUNDLE" >&2
  exit 1
fi

codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
printf 'APP_PATH=%s\n' "$APP_BUNDLE"

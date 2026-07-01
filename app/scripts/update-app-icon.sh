#!/usr/bin/env bash
set -eu

if [ "$#" -ne 1 ]; then
  printf 'Usage: %s <source-image>\n' "$0" >&2
  exit 1
fi

SOURCE_IMAGE="$1"
APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if [ ! -f "$SOURCE_IMAGE" ]; then
  printf 'Source image not found: %s\n' "$SOURCE_IMAGE" >&2
  exit 1
fi

if ! command -v uv >/dev/null 2>&1; then
  printf 'Missing required command: uv\n' >&2
  exit 1
fi

uv run --with pillow python - "$SOURCE_IMAGE" "$APP_DIR" <<'PY'
from pathlib import Path
import sys

from PIL import Image, ImageDraw, ImageOps


source_path = Path(sys.argv[1])
app_dir = Path(sys.argv[2])
size = 1024

with Image.open(source_path) as source:
    icon = ImageOps.fit(
        source.convert("RGB"),
        (size, size),
        method=Image.Resampling.LANCZOS,
    ).convert("RGBA")

mask = Image.new("L", (size, size), 0)
ImageDraw.Draw(mask).rounded_rectangle(
    (8, 8, size - 9, size - 9),
    radius=224,
    fill=255,
)
icon.putalpha(mask)

png_targets = [
    app_dir / "build" / "appicon.png",
    app_dir / "frontend" / "src" / "assets" / "appicon.png",
]
for target in png_targets:
    target.parent.mkdir(parents=True, exist_ok=True)
    icon.save(target, format="PNG", optimize=True)

windows_icon = app_dir / "build" / "windows" / "icon.ico"
windows_icon.parent.mkdir(parents=True, exist_ok=True)
icon.save(
    windows_icon,
    format="ICO",
    sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)],
)

favicon = app_dir / "frontend" / "src" / "assets" / "favicon.ico"
icon.save(favicon, format="ICO", sizes=[(16, 16), (32, 32), (48, 48)])
PY

printf 'Updated app icon assets from %s\n' "$SOURCE_IMAGE"

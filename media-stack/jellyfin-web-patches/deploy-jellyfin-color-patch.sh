#!/usr/bin/env bash
set -euo pipefail

PATCH_DIR="/root/Kronk/media-stack/config/jellyfin/kronk-web-patches"
WEB_DIR="/jellyfin/jellyfin-web"
STAMP="$(date +%Y%m%d-%H%M%S)"

mkdir -p "$PATCH_DIR"
cp /tmp/kronk-jellyfin-colors.js "$PATCH_DIR/kronk-jellyfin-colors.js"

docker cp /tmp/kronk-jellyfin-colors.js media-stack-jellyfin-1:"$WEB_DIR/kronk-jellyfin-colors.js"
docker cp media-stack-jellyfin-1:"$WEB_DIR/index.html" /tmp/jellyfin-index.html
cp /tmp/jellyfin-index.html "$PATCH_DIR/index.html.backup.$STAMP"

python3 - <<'PY'
from pathlib import Path
import re

p = Path("/tmp/jellyfin-index.html")
text = p.read_text(encoding="utf-8")
tag = '<script defer="defer" src="kronk-jellyfin-colors.js?v=20260518"></script>'

if "kronk-jellyfin-colors.js" not in text:
    text = text.replace("</body>", tag + "</body>")
else:
    text = re.sub(r'<script[^>]+src="kronk-jellyfin-colors\.js[^>]*></script>', tag, text)

p.write_text(text, encoding="utf-8")
PY

docker cp /tmp/jellyfin-index.html media-stack-jellyfin-1:"$WEB_DIR/index.html"
docker restart media-stack-jellyfin-1
docker ps --filter name=media-stack-jellyfin-1 --format '{{.Names}} {{.Status}}'

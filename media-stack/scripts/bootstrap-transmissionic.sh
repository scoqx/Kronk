#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="$ROOT/config/transmissionic-web"
TMP="$(mktemp)"
TMPZIP="$(mktemp)"

cleanup() {
	rm -f "$TMP" "$TMPZIP"
}
trap cleanup EXIT

echo "Fetching latest Transmissionic release metadata..."
curl -fsSL "https://api.github.com/repos/6c65726f79/Transmissionic/releases/latest" -o "$TMP"

resolve_webui_zip_url() {
	local meta="$1"
	if command -v jq >/dev/null 2>&1; then
		jq -r '.assets[] | select(.name | test("^Transmissionic-webui-.*\\.zip$")) | .browser_download_url' "$meta" | head -n1
		return 0
	fi
	python3 - "$meta" <<'PY'
import json, sys
path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
	data = json.load(f)
for a in data.get("assets", []):
	name = a.get("name") or ""
	if name.startswith("Transmissionic-webui-") and name.endswith(".zip"):
		print(a.get("browser_download_url") or "")
		break
PY
}

URL="$(resolve_webui_zip_url "$TMP")"
if [[ -z "$URL" || "$URL" == "null" ]]; then
	echo "Could not find Transmissionic-webui-*.zip in the latest release." >&2
	exit 1
fi

echo "Downloading: $URL"
curl -fsSL "$URL" -o "$TMPZIP"

rm -rf "$DEST"
mkdir -p "$DEST"

unzip -q "$TMPZIP" -d "$DEST"

# Архив может распаковаться во вложенную папку — поднимем файлы наверх при необходимости
if [[ ! -f "$DEST/index.html" ]]; then
	INNER="$(find "$DEST" -maxdepth 2 -name index.html -print -quit)"
	if [[ -n "$INNER" ]]; then
		INNER_DIR="$(dirname "$INNER")"
		shopt -s dotglob
		mv "$INNER_DIR"/* "$DEST/"
		shopt -u dotglob
		find "$DEST" -mindepth 1 -maxdepth 1 -type d -empty -delete
	fi
fi

DEFAULT_JSON="$DEST/default.json"
if [[ ! -f "$DEFAULT_JSON" ]]; then
	cat >"$DEFAULT_JSON" <<'EOF'
{
  "language": "ru",
  "openMagnetLinks": true
}
EOF
	echo "Wrote $DEFAULT_JSON (magnet handling works best over HTTPS or localhost)."
fi

echo "Transmissionic web UI installed to: $DEST"
echo "Start stack from $ROOT with: docker compose up -d"

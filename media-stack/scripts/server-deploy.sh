#!/usr/bin/env bash
# Деплой на VPS: HTTPS на домене (Caddy + Let's Encrypt), те же префиксы /jellyfin /prowlarr /transmission.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ "$(uname -s)" != "Linux" ]]; then
	echo "Этот сценарий рассчитан на Linux-сервер (VPS)." >&2
fi

for f in scripts/*.sh; do
	[[ -f "$f" ]] || continue
	sed -i 's/\r$//' "$f" || true
done

if [[ ! -f .env ]]; then
	echo "Нет .env — скопируйте шаблон:" >&2
	echo "  cp .env.server.example .env" >&2
	echo "Заполните PUBLIC_HOSTNAME, TRANSMISSION_PASS, при необходимости PUID/PGID." >&2
	exit 1
fi

PH="$(grep -E '^PUBLIC_HOSTNAME=' .env | cut -d= -f2- | tr -d '\r' || true)"
PH="${PH// /}"
if [[ -z "$PH" ]]; then
	echo "В .env должен быть задан PUBLIC_HOSTNAME (FQDN без https://)." >&2
	exit 1
fi

if ! grep -qE '^CADDY_PRIMARY_FILE=Caddyfile\.server' .env 2>/dev/null; then
	echo "В .env для сервера выставьте: CADDY_PRIMARY_FILE=Caddyfile.server" >&2
	exit 1
fi

if ! grep -qE '^EDGE_HTTP_PORT=80\s*$' .env 2>/dev/null; then
	echo "Предупреждение: для прод обычно EDGE_HTTP_PORT=80 (сейчас другое значение в .env)." >&2
fi

if ! command -v docker >/dev/null 2>&1; then
	echo "Нужен Docker и compose-плагин (docker compose)." >&2
	exit 1
fi

DC=(docker compose)
if ! docker compose version >/dev/null 2>&1; then
	echo "Нужен Docker Compose v2: docker compose." >&2
	exit 1
fi

if ! docker info >/dev/null 2>&1; then
	echo "Docker недоступен (docker info)." >&2
	exit 1
fi

PEER="$(grep -E '^TRANSMISSION_PEER_PORT=' .env | cut -d= -f2- | tr -d '\r' || true)"
PEER="${PEER:-51413}"

chmod +x scripts/bootstrap-transmissionic.sh 2>/dev/null || true
./scripts/bootstrap-transmissionic.sh

"${DC[@]}" -f docker-compose.yml -f docker-compose.server.yml pull
"${DC[@]}" -f docker-compose.yml -f docker-compose.server.yml up -d --remove-orphans

echo ""
echo "Готово. Проверьте DNS: ${PH} → IP этого сервера (A/AAAA)."
echo "Откройте https://${PH}/ — портал; пути /prowlarr/ /transmission/web/ /jellyfin/"
echo ""
echo "Фаервол (если есть): TCP 80, 443 и TCP+UDP ${PEER} для торрентов."
echo "Первый вход: Jellyfin Base URL /jellyfin; Prowlarr URL Base /prowlarr и при необходимости External URL https://${PH}/prowlarr"
echo ""
echo "Логи gateway (TLS): docker compose -f docker-compose.yml -f docker-compose.server.yml logs -f gateway"

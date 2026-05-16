#!/usr/bin/env bash
# Деплой на VPS: HTTPS на нескольких FQDN (Caddy + Let's Encrypt).
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
	echo "Заполните PUBLIC_HOSTNAME, PROWLARR_HOSTNAME, DELUGE_HOSTNAME, JELLYFIN_HOSTNAME." >&2
	exit 1
fi

require_env_var() {
	local key="$1"
	local val
	val="$(grep -E "^${key}=" .env | cut -d= -f2- | tr -d '\r' || true)"
	val="${val// /}"
	if [[ -z "$val" ]]; then
		echo "В .env должен быть задан ${key} (FQDN без https://)." >&2
		exit 1
	fi
}

require_env_var PUBLIC_HOSTNAME
require_env_var PROWLARR_HOSTNAME
require_env_var DELUGE_HOSTNAME
require_env_var JELLYFIN_HOSTNAME

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

PEER="$(grep -E '^DELUGE_PEER_PORT=' .env | cut -d= -f2- | tr -d '\r' || true)"
PEER="${PEER:-6881}"

SING_BOX_CONFIG_FILE="$(grep -E '^SING_BOX_CONFIG_FILE=' .env | cut -d= -f2- | tr -d '\r' || true)"
if [[ -n "${SING_BOX_CONFIG_FILE// /}" && ! -f "$SING_BOX_CONFIG_FILE" ]]; then
	echo "SING_BOX_CONFIG_FILE задан, но файл не найден: ${SING_BOX_CONFIG_FILE}" >&2
	echo "Создайте внешний sing-box config.json на сервере или уберите переменную для direct-конфига из repo." >&2
	exit 1
fi

PH="$(grep -E '^PUBLIC_HOSTNAME=' .env | cut -d= -f2- | tr -d '\r')"
LFT="$(grep -E '^PROWLARR_HOSTNAME=' .env | cut -d= -f2- | tr -d '\r')"
MMD="$(grep -E '^DELUGE_HOSTNAME=' .env | cut -d= -f2- | tr -d '\r')"
WV="$(grep -E '^JELLYFIN_HOSTNAME=' .env | cut -d= -f2- | tr -d '\r')"

"${DC[@]}" -f docker-compose.yml -f docker-compose.server.yml pull
"${DC[@]}" -f docker-compose.yml -f docker-compose.server.yml up -d --remove-orphans

echo ""
echo "Готово. Проверьте DNS (A/AAAA на IP этого сервера):"
echo "  ${PH}, ${LFT}, ${MMD}, ${WV}"
echo ""
echo "Портал: https://${PH}/"
echo "Prowlarr: https://${LFT}/  |  Deluge Web: https://${MMD}/  |  Jellyfin: https://${WV}/"
echo ""
echo "Deluge Web UI: первый вход обычно admin / deluge (смените в UI). Prowlarr → Deluge: хост deluge-net, порт 58846."
echo "В Jellyfin/Prowlarr при поддоменах Base URL и URL Base оставьте пустыми."
echo "Фаервол (если есть): TCP 80, 443 и TCP+UDP ${PEER} для торрентов."
echo ""
echo "Логи gateway: docker compose -f docker-compose.yml -f docker-compose.server.yml logs -f gateway"

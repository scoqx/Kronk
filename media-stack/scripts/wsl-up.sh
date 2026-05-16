#!/usr/bin/env bash
# Локальный запуск стека из WSL (из каталога media-stack или любого места).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v docker >/dev/null 2>&1; then
	echo "В этой WSL-среде нет команды docker." >&2
	echo "" >&2
	echo "Вариант A — Docker Desktop (Windows): включите интеграцию с вашим дистрибутивом:" >&2
	echo "  Docker Desktop → Settings → Resources → WSL integration → включите Ubuntu (или ваш)." >&2
	echo "  Затем перезапустите терминал WSL или wsl --shutdown в PowerShell." >&2
	echo "" >&2
	echo "Вариант B — движок прямо в WSL:" >&2
	echo "  https://docs.docker.com/engine/install/ubuntu/ (docker-ce + compose plugin)" >&2
	exit 1
fi

DC=(docker compose)
if ! docker compose version >/dev/null 2>&1; then
	if command -v docker-compose >/dev/null 2>&1; then
		DC=(docker-compose)
	else
		echo "Нужен Docker Compose v2 (docker compose) или docker-compose." >&2
		exit 1
	fi
fi

if ! docker info >/dev/null 2>&1; then
	echo "Docker установлен, но демон недоступен (docker info падает)." >&2
	echo "Запустите Docker Desktop на Windows или службу docker в WSL (sudo service docker start)." >&2
	exit 1
fi

if [[ ! -f .env ]]; then
	cp .env.example .env
	echo "Создан .env из .env.example — при необходимости отредактируйте."
fi

"${DC[@]}" up -d --remove-orphans

HOST="${WSL_TEST_HOST:-localhost}"
PORT="${EDGE_HTTP_PORT:-8080}"
grep -q '^EDGE_HTTP_PORT=' .env 2>/dev/null && PORT="$(grep -E '^EDGE_HTTP_PORT=' .env | cut -d= -f2- | tr -d '\r')"

echo ""
echo "Поднято. Откройте в браузере:"
echo "  http://${HOST}:${PORT}/           — портал"
echo "  http://${HOST}:${PORT}/prowlarr/"
echo "  http://${HOST}:${PORT}/flood/"
echo "  http://${HOST}:${PORT}/jellyfin/"
echo ""
echo "С Windows браузера часто работает localhost:${PORT}; с телефона — IP ПК и тот же порт."
echo "Первый раз: Jellyfin Base URL /jellyfin, Prowlarr URL Base /prowlarr."
echo "Flood/Prowlarr → qBittorrent: хост qbittorrent, порт 8080, username admin, пароль Web UI из логов qbittorrent."

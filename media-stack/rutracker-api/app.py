import os
from typing import Any

from fastapi import FastAPI, HTTPException, Query
from fastapi.encoders import jsonable_encoder
from py_rutracker import AsyncRuTrackerClient


app = FastAPI(title="RuTracker Search API")


def _client_kwargs() -> dict[str, Any]:
	login = os.getenv("RUTRACKER_LOGIN")
	password = os.getenv("RUTRACKER_PASSWORD")
	proxy = os.getenv("RUTRACKER_PROXY")

	if not login or not password:
		raise HTTPException(
			status_code=503,
			detail="Set RUTRACKER_LOGIN and RUTRACKER_PASSWORD in .env",
		)

	kwargs: dict[str, Any] = {}
	if proxy:
		kwargs["proxy"] = proxy

	return {"login": login, "password": password, "kwargs": kwargs}


def _as_dict(result: Any) -> dict[str, Any]:
	if hasattr(result, "model_dump"):
		return result.model_dump()
	if hasattr(result, "dict"):
		return result.dict()
	if isinstance(result, dict):
		return result
	return jsonable_encoder(result)


def _first(data: dict[str, Any], *keys: str) -> Any:
	for key in keys:
		value = data.get(key)
		if value not in (None, ""):
			return value
	return None


def _normalize_result(result: Any) -> dict[str, Any]:
	data = _as_dict(result)
	topic_id = _first(data, "topic_id", "topicId", "id")

	return {
		"topic_id": topic_id,
		"title": _first(data, "title", "name") or "Без названия",
		"forum": _first(data, "forum", "forum_name", "forumName", "section"),
		"size": _first(data, "size", "size_text", "sizeText"),
		"seeders": _first(data, "seeders", "seeds"),
		"leechers": _first(data, "leechers", "leeches"),
		"registered": _first(data, "registered", "created_at", "createdAt"),
		"url": f"https://rutracker.org/forum/viewtopic.php?t={topic_id}" if topic_id else None,
	}


@app.get("/health")
async def health() -> dict[str, str]:
	return {"status": "ok"}


@app.get("/search")
async def search(
	q: str = Query(..., min_length=2, max_length=120),
	limit: int = Query(default=25, ge=1, le=100),
) -> dict[str, Any]:
	config = _client_kwargs()
	max_results = min(limit, int(os.getenv("RUTRACKER_MAX_RESULTS", "25")))

	try:
		try:
			client = AsyncRuTrackerClient(
				config["login"],
				config["password"],
				**config["kwargs"],
			)
		except TypeError:
			client = AsyncRuTrackerClient(config["login"], config["password"])

		async with client:
			results = await client.search_all_pages(q)
	except HTTPException:
		raise
	except Exception as exc:
		raise HTTPException(status_code=502, detail=str(exc)) from exc

	items = [_normalize_result(item) for item in results[:max_results]]
	return {"query": q, "count": len(items), "items": items}

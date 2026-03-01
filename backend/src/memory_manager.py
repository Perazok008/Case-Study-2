import json
from pathlib import Path

MEMORY_FILE = Path(__file__).parent / "memory.json"

def _load() -> dict:
    if MEMORY_FILE.exists():
        with open(MEMORY_FILE, "r") as f:
            return json.load(f)
    return {}

def _save(store: dict):
    with open(MEMORY_FILE, "w") as f:
        json.dump(store, f, indent=2)

_store: dict = _load()

def get_personality_memory(user_id: str, personality: str) -> list[dict]:
    return list(_store.get(user_id, {}).get(personality.lower(), []))

def save_personality_memory(user_id: str, personality: str, items: list[dict]):
    _store.setdefault(user_id, {})[personality.lower()] = items
    _save(_store)

def delete_personality_memory(user_id: str, personality: str):
    if user_id in _store and personality.lower() in _store[user_id]:
        del _store[user_id][personality.lower()]
        _save(_store)
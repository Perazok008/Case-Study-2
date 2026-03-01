from fastapi import FastAPI
from config import PERSONALITY_CHOICES, PERSONALITIES
from schemas import HealthResponse, PersonalityStyle, ChatRequest, MemoryItem, ChatResponse
from fastapi import HTTPException
from response_manager import respond
from memory_manager import get_personality_memory

app = FastAPI(title="Case Study 2 - Group 6 Backend")

@app.get("/health", response_model=HealthResponse)
def health_check() -> HealthResponse:
    """Check that the backend is running."""
    return HealthResponse(status="ok")

@app.get("/personalities", response_model=list[str])
def get_personality_choices() -> list[str]:
    """Get the list of available personalities."""
    return PERSONALITY_CHOICES

@app.get("/personalities/style/{personality}", response_model=PersonalityStyle)
def get_personality_style(personality: str) -> PersonalityStyle:
    """Get the style of the specified personality."""
    if personality not in PERSONALITIES:
        raise HTTPException(status_code=404, detail="Personality not found")
    return PersonalityStyle(**PERSONALITIES[personality]["style"])

@app.post("/respond", response_model=ChatResponse)
def respond_to_message(request: ChatRequest) -> ChatResponse:
    """Respond to a message."""
    return respond(request)

@app.get("/memory/{session_id}/{personality}", response_model=list[MemoryItem])
def get_memory(session_id: str, personality: str) -> list[MemoryItem]:
    """Get the memory of the personality."""
    return get_personality_memory(session_id, personality)

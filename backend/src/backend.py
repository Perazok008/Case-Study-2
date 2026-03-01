from fastapi import FastAPI, HTTPException, status

from config import PERSONALITY_CHOICES, PERSONALITIES
from schemas import HealthResponse, PersonalityStyle, ChatRequest, MemoryItem, ChatResponse
from response_manager import respond
from memory_manager import get_personality_memory, delete_personality_memory

app = FastAPI(
    title="Case Study 2 - Group 6 Backend",
    description="Chatbot API with personality switching and persistent memory.",
    version="1.0.0",
)


@app.get("/health", response_model=HealthResponse)
def health_check() -> HealthResponse:
    return HealthResponse(status="ok")


@app.get("/personalities", response_model=list[str])
def get_personality_choices() -> list[str]:
    return PERSONALITY_CHOICES


@app.get(
    "/personalities/style/{personality}",
    response_model=PersonalityStyle,
    responses={404: {"description": "Personality not found"}},
)
def get_personality_style(personality: str) -> PersonalityStyle:
    if personality not in PERSONALITIES:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Personality '{personality}' not found",
        )
    return PersonalityStyle(**PERSONALITIES[personality]["style"])


@app.post(
    "/respond",
    response_model=ChatResponse,
    responses={
        404: {"description": "Personality not found"},
        500: {"description": "Model inference failed"},
    },
)
def respond_to_message(request: ChatRequest) -> ChatResponse:
    if request.personality not in PERSONALITIES:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Personality '{request.personality}' not found",
        )
    try:
        return respond(request)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e),
        )


@app.get(
    "/memory/{session_id}/{personality}",
    response_model=list[MemoryItem],
    responses={404: {"description": "Personality not found"}},
)
def get_memory(session_id: str, personality: str) -> list[MemoryItem]:
    if personality not in PERSONALITIES:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Personality '{personality}' not found",
        )
    return get_personality_memory(session_id, personality)


@app.delete(
    "/memory/{session_id}/{personality}",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={404: {"description": "Personality not found"}},
)
def clear_memory(session_id: str, personality: str):
    if personality not in PERSONALITIES:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Personality '{personality}' not found",
        )
    delete_personality_memory(session_id, personality)

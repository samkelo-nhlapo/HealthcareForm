import time
import uuid
from fastapi import FastAPI
from pydantic import BaseModel
from typing import List, Optional
from fastapi.middleware.cors import CORSMiddleware
from langchain_ollama import OllamaEmbeddings, OllamaLLM
from langchain_chroma import Chroma
import uvicorn

app = FastAPI()

# Allow all origins (harmless for local VS Code extension)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load vector store and LLM once
embeddings = OllamaEmbeddings(model="nomic-embed-text")
vectorstore = Chroma(persist_directory="./code_rag_db_v2", embedding_function=embeddings)
llm = OllamaLLM(model="deepseek-coder:1.3b-instruct", temperature=0.1)

# ------------------ Request Models ------------------
class Message(BaseModel):
    role: str
    content: str

class ChatRequest(BaseModel):
    messages: List[Message]
    model: Optional[str] = "rag-model"
    temperature: Optional[float] = 0.1
    stream: Optional[bool] = False
    max_tokens: Optional[int] = 512
    k: Optional[int] = 4   # number of retrieved chunks

class PromptRequest(BaseModel):
    prompt: str
    k: Optional[int] = 4

# ------------------ Helper ------------------
def generate_answer(query: str, k: int) -> str:
    docs = vectorstore.similarity_search(query, k=k)
    context = "\n\n".join(
        f"--- Source: {doc.metadata['source']} ---\n{doc.page_content}" for doc in docs
    )
    full_prompt = f"""You are a helpful coding assistant. Use the following code context to answer the question.
If the answer is not in the context, say you don't know.

Context:
{context}

Question: {query}

Answer:"""
    return llm.invoke(full_prompt)

# ------------------ Endpoints ------------------
@app.post("/chat/completions")
@app.post("/v1/chat/completions")
async def chat_completions(request: ChatRequest):
    # Extract latest user message
    user_query = ""
    for msg in reversed(request.messages):
        if msg.role == "user":
            user_query = msg.content
            break
    if not user_query:
        return {"error": "No user message found"}

    answer = generate_answer(user_query, request.k)

    response = {
        "id": f"chatcmpl-{uuid.uuid4().hex}",
        "object": "chat.completion",
        "created": int(time.time()),
        "model": request.model or "rag-model",
        "choices": [
            {
                "index": 0,
                "message": {
                    "role": "assistant",
                    "content": answer
                },
                "finish_reason": "stop"
            }
        ],
        "usage": {
            "prompt_tokens": 0,
            "completion_tokens": 0,
            "total_tokens": 0
        }
    }
    return response

@app.post("/completions")
@app.post("/v1/completions")
async def completions(request: PromptRequest):
    answer = generate_answer(request.prompt, request.k)
    return {
        "id": f"cmpl-{uuid.uuid4().hex}",
        "object": "text_completion",
        "created": int(time.time()),
        "model": "rag-model",
        "choices": [
            {
                "text": answer,
                "index": 0,
                "finish_reason": "stop"
            }
        ],
        "usage": {
            "prompt_tokens": 0,
            "completion_tokens": 0,
            "total_tokens": 0
        }
    }

@app.get("/models")
@app.get("/v1/models")
async def list_models():
    return {
        "object": "list",
        "data": [
            {
                "id": "rag-model",
                "object": "model",
                "created": int(time.time()),
                "owned_by": "local"
            }
        ]
    }

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)

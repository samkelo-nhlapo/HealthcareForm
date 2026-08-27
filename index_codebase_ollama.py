#!/usr/bin/env python3
from pathlib import Path
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_community.embeddings import OllamaEmbeddings
from langchain_community.vectorstores import Chroma
from langchain_core.documents import Document

# ---------- CONFIGURATION ----------
PROJECT_ROOT = Path("/home/samkelo/HealthcareForm")
PERSIST_DIR = "./chroma_db_ollama"   # new directory to avoid conflict

INCLUDE_EXTS = {".cs", ".ts", ".js", ".html", ".scss", ".css",
                ".sql", ".json", ".yml", ".yaml", ".md", ".txt", ".py"}

EXCLUDE_DIRS = {"bin", "obj", "node_modules", "packages", "dist",
                ".git", "__pycache__", ".vs", ".vscode", "docker-volumes",
                "docker", "release-readiness", "dev-start", "004-images",
                "generated", "scripts"}

def should_include(path: Path) -> bool:
    for part in path.parts:
        if part in EXCLUDE_DIRS:
            return False
    return path.suffix.lower() in INCLUDE_EXTS and path.is_file()

print("Scanning files...")
text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=1500,
    chunk_overlap=200,
    separators=["\n\n", "\n", " ", ""],
    length_function=len,
)

documents = []
total_files = 0
for file_path in PROJECT_ROOT.rglob("*"):
    if should_include(file_path):
        total_files += 1
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                content = f.read()
        except (UnicodeDecodeError, PermissionError):
            continue

        rel_path = str(file_path.relative_to(PROJECT_ROOT))
        chunks = text_splitter.split_text(content)
        for chunk in chunks:
            documents.append(
                Document(page_content=chunk, metadata={"source": rel_path})
            )

print(f"Indexed {total_files} files -> {len(documents)} chunks.")

print("Creating embeddings and storing in Chroma...")
embedding_model = OllamaEmbeddings(model="nomic-embed-text")

vectorstore = Chroma.from_documents(
    documents=documents,
    embedding=embedding_model,
    persist_directory=PERSIST_DIR,
    collection_name="healthcareform_code"
)
vectorstore.persist()
print("Indexing complete!")

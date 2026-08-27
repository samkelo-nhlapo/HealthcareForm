import os
from langchain_ollama import OllamaEmbeddings
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_community.vectorstores import Chroma

# --- Configuration ---
CODE_DIRS = [
    "/home/samkelo/HealthcareForm",  # adjust as needed
    # Add other project directories if needed
]

# Only files with these extensions will be indexed
EXTENSIONS = {
    ".cs", ".ts", ".html", ".css", ".sql", ".dart",
    ".json", ".csproj", ".yml", ".yaml", ".dockerfile",
    ".txt", ".md", ".tsx", ".scss", ".sh"
}

# Directories to skip entirely
EXCLUDED_DIRS = {
    "node_modules", "bin", "obj", "dist", "build", ".git",
    ".angular", "target", "out", "coverage", ".vs", ".vscode",
    "packages", "wwwroot/lib", "scripts/lib", "README", "MIGRATION", "backup", "legacy"
}

# Files to skip if they exceed this size (bytes)
MAX_FILE_SIZE = 200_000  # 200 KB

CHUNK_SIZE = 2000        # larger chunks → fewer embeddings
CHUNK_OVERLAP = 200

# --- Helper functions ---
def is_relevant_file(filepath):
    _, ext = os.path.splitext(filepath)
    if ext.lower() in EXTENSIONS:
        return True
    basename = os.path.basename(filepath).lower()
    return basename in {"dockerfile", "docker-compose.yml", "docker-compose.yaml"}

def should_skip_dir(dirname):
    return dirname in EXCLUDED_DIRS

# --- Scan files ---
documents = []
for directory in CODE_DIRS:
    if not os.path.exists(directory):
        print(f"Warning: {directory} does not exist.")
        continue
    for root, dirs, files in os.walk(directory):
        # Prune excluded directories
        dirs[:] = [d for d in dirs if not should_skip_dir(d)]
        for file in files:
            filepath = os.path.join(root, file)
            # Skip if file is too large
            try:
                if os.path.getsize(filepath) > MAX_FILE_SIZE:
                    continue
            except OSError:
                continue
            if is_relevant_file(filepath):
                try:
                    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
                        text = f.read()
                    if text.strip():
                        documents.append({"text": text, "source": filepath})
                except Exception as e:
                    print(f"Could not read {filepath}: {e}")

print(f"Loaded {len(documents)} files.")

# Split into chunks
text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=CHUNK_SIZE,
    chunk_overlap=CHUNK_OVERLAP,
    separators=["\n\n", "\n", " ", ""],
)
chunks = text_splitter.create_documents(
    [doc["text"] for doc in documents],
    metadatas=[{"source": doc["source"]} for doc in documents],
)
print(f"Created {len(chunks)} chunks.")

# Create embeddings and store in Chroma
embedding_model = OllamaEmbeddings(model="nomic-embed-text")
vectorstore = Chroma.from_documents(
    documents=chunks,
    embedding=embedding_model,
    persist_directory="./code_rag_db_v2",
)
print("Indexing complete! Saved to ./code_rag_db_v2")

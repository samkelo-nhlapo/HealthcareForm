#!/usr/bin/env python3
from langchain_community.vectorstores import Chroma
from langchain_community.embeddings import OllamaEmbeddings
import ollama

PERSIST_DIR = "./chroma_db_ollama"

embedding = OllamaEmbeddings(model="nomic-embed-text")
vectorstore = Chroma(
    persist_directory=PERSIST_DIR,
    embedding_function=embedding,
    collection_name="healthcareform_code"
)

def retrieve_context(query: str, k: int = 5):
    return vectorstore.similarity_search(query, k=k)

def ask_ollama(question: str, context_docs: list) -> str:
    context = "\n\n".join([doc.page_content for doc in context_docs])
    prompt = f"""You are an expert on the HealthcareForm codebase.
Use the following code snippets to answer the question.
If you don't know, say so – do not make up information.

Context:
{context}

Question: {question}

Answer:"""
    response = ollama.chat(
        model="deepseek-coder:1.3b-instruct",
        messages=[{"role": "user", "content": prompt}]
    )
    return response["message"]["content"]

def ask(question: str):
    docs = retrieve_context(question, k=5)
    print(f"\nRetrieved {len(docs)} chunks from:")
    for d in docs:
        print(f"  - {d.metadata.get('source', 'unknown')}")
    print("\nGenerating answer...\n")
    return ask_ollama(question, docs)

if __name__ == "__main__":
    print("HealthcareForm RAG Query Interface")
    print("Type your question (or 'exit' to quit).")
    while True:
        q = input("\nQuestion: ").strip()
        if q.lower() in ("exit", "quit"):
            break
        if not q:
            continue
        answer = ask(q)
        print("\n" + "="*60)
        print(answer)
        print("="*60)

import sys
from langchain_ollama import OllamaEmbeddings, OllamaLLM
from langchain_chroma import Chroma

# Load vector store
embeddings = OllamaEmbeddings(model="nomic-embed-text")
vectorstore = Chroma(persist_directory="./code_rag_db_v2", embedding_function=embeddings)

# Load LLM
llm = OllamaLLM(model="deepseek-coder:1.3b-instruct", temperature=0.1)

# Get question from command line or use default
if len(sys.argv) > 1:
    question = " ".join(sys.argv[1:])
else:
    question = "How is authentication handled in the backend?"

# Retrieve relevant chunks
retriever = vectorstore.as_retriever(search_kwargs={"k": 4})
docs = retriever.invoke(question)

# Build context from retrieved documents
context = "\n\n".join([f"--- Source: {doc.metadata['source']} ---\n{doc.page_content}" for doc in docs])

# Construct prompt
prompt = f"""You are a helpful coding assistant. Use the following code context to answer the question.
If the answer is not in the context, say you don't know.

Context:
{context}

Question: {question}

Answer:"""

# Generate answer
answer = llm.invoke(prompt)

print(f"Question: {question}\n")
print("Answer:")
print(answer)
print("\nSources:")
for doc in docs:
    print(f"- {doc.metadata['source']}")

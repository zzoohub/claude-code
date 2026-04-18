# RAG: Retrieval-Augmented Generation

RAG grounds a language model in your data. Done well, it's the difference between a model that hallucinates confidently and one that cites sources. Done poorly, it's an expensive way to serve irrelevant context.

## When RAG is right

Use RAG when:

- The answer requires knowledge the model doesn't have (private docs, recent data, user-specific content).
- The knowledge base is too large to fit in context (anything > ~50k tokens at query time).
- Answers need to cite sources or be auditable.

Don't use RAG when:

- The full knowledge base fits in context (< 100k tokens, rarely changing) — just include it. Prompt caching makes this cheaper than retrieval infrastructure.
- The task is generative, not factual (creative writing, brainstorming).
- A direct database query would work (structured data, exact lookups).

## The pipeline

```
Query → [Retrieve] → [Rank] → [Filter] → [Augment prompt] → [Generate]
```

Each stage has independent design choices. Skipping ranking or filtering is the most common source of "the model gave a wrong answer from the right documents."

## Indexing: chunking

Chunking is the choice of how to slice documents for embedding and retrieval. It's the highest-leverage decision in a RAG system — and the most commonly done by defaults.

**Naive fixed-size chunks** (e.g., 500 tokens with 50-token overlap) work for well-structured prose but destroy code, tables, and hierarchical docs.

**Better: respect structure.**

- Markdown: chunk by section (## headings), with a minimum size threshold that combines short sections.
- Code: chunk by function or class, not by line count.
- Tables: keep each table as one chunk, with the surrounding context.
- PDFs: respect page breaks for layout-sensitive docs.

**Include context in each chunk.** A bare paragraph often loses meaning without its heading. Prepend breadcrumbs:

```
[Product Docs > Billing > Refunds]

Refunds are processed within 5 business days...
```

This costs a few tokens per chunk and massively improves retrieval quality.

**Chunk size tradeoffs:**

- Small (100-300 tokens): precise retrieval, many chunks needed per answer, more retrieval overhead.
- Medium (500-1000 tokens): balanced; most systems start here.
- Large (2000+ tokens): rich context per chunk, fewer chunks, but noisier (retrieved chunks may contain a lot of irrelevant text).

Iterate based on eval results — there's no universal right answer.

## Retrieval: more than vector search

Pure vector (embedding) search retrieves semantically similar chunks. It's great for fuzzy queries ("how do I cancel"), bad for exact queries ("error code E1042").

**Hybrid search = vector + keyword.**

- **Vector** (dense) retrieval captures semantic meaning.
- **Keyword** (sparse, BM25) retrieval captures exact matches and rare terms.
- Combine with reciprocal rank fusion (RRF) or weighted scoring.

Almost every serious RAG system ends up hybrid. Start with one, add the other when you see failures the first can't explain.

**Metadata filters.** Attach structured metadata to each chunk (doc_type, date, author, tags). At query time, filter before or after vector search. This is how you make RAG scale beyond "the whole org's documents as one index":

- User asks about "refund policy" → filter to `doc_type: policy` before ranking.
- Query mentions a product version → filter by `version: >=4.0`.

## Ranking: the second-stage filter

Initial retrieval returns the top-K chunks. Rarely are the top 3 of those the actual most relevant. Re-ranking fixes this.

**Cross-encoder rerankers** (Cohere Rerank, BGE, custom cross-encoder): pass the query + each retrieved chunk through a model that scores relevance directly. Much more accurate than cosine similarity but slower — usable at the top-20 or top-50 level, not top-1000.

**LLM-as-reranker.** Send the retrieved chunks to a cheap, fast model and ask it to select the most relevant ones. Works surprisingly well for small K, costs more but needs no extra infrastructure.

**Rule of thumb:** retrieve top-50, rerank to top-5, send top-5 to the generation prompt. Don't skip the rerank step unless your eval shows it's not adding quality.

## Augmentation: how to inject context

Naive: concatenate retrieved chunks into the prompt. This works but has failure modes:

- **Order matters.** Models weight the start and end of long contexts more than the middle ("lost in the middle" problem). Put the most relevant chunk first or last.
- **Cite explicitly.** Label each chunk with an id and instruct the model to cite it in the answer. This enables source attribution and hallucination detection.
- **Handle "no match" gracefully.** If retrieval returns nothing relevant, tell the model. Otherwise it'll confabulate from its training data.

Example injection:

```
Here are relevant documentation passages:

[Doc 1] (Billing > Refunds)
Refunds are processed within 5 business days...

[Doc 2] (Support > Returns)
Customers can return items within 30 days...

---

User question: How long does a refund take?

Answer using only the information above. If the passages do not contain the answer, say so. Cite doc numbers in your response.
```

## Evaluation

RAG evals are multi-stage — a final-answer eval can't tell you whether retrieval, ranking, or generation failed.

- **Retrieval hit rate:** for a golden set of (query, expected_doc_id) pairs, does the retriever include the right doc in top-K? Track separately for top-1, top-5, top-20.
- **Answer faithfulness:** does the generated answer actually come from the retrieved chunks, or is it hallucinated? Use LLM-as-judge with a "cite or abstain" prompt.
- **Answer correctness:** compared to the golden answer.
- **Latency breakdown:** embed time, retrieval time, rerank time, generation time. Optimize the bottleneck.

See `references/evaluation.md` for eval infrastructure patterns.

## Agentic retrieval

Simple RAG retrieves once per query. Complex questions ("compare our refund policy to Stripe's for international customers") need multi-hop retrieval: the model plans, retrieves, reasons, possibly retrieves more.

**Agentic retrieval patterns:**

- **Query decomposition.** LLM rewrites the user query into sub-queries, retrieves for each, synthesizes.
- **Iterative retrieval.** LLM retrieves, reads, decides if it has enough, retrieves more if not.
- **Self-querying.** LLM writes structured queries (with metadata filters) from the natural-language question.

These are more expensive and harder to debug than one-shot RAG. Upgrade only when eval shows one-shot failing, and see `references/agents.md` for the agent loop patterns.

## Common anti-patterns

**Treating retrieval quality as a solved problem.** "We use embeddings, it should work." Embedding quality depends on the model, your chunk design, and your query distribution. Evaluate retrieval separately from generation.

**Storing the entire raw chunk as the only representation.** Store the chunk plus pre-computed variants: title, summary, keywords. Search over the richest representation, return the full chunk for generation.

**Re-chunking everything for every change.** Large corpora with churn need incremental indexing. Plan for it early — retrofitting is painful.

**Ignoring metadata.** Every chunk should know its source document, section, date, and type. This becomes essential for filtering, citation, and eval.

**Using RAG when fine-tuning or prompting would be simpler.** A domain vocabulary glossary can live in the system prompt. Style or formatting preferences are prompt-level. Reserve RAG for *facts the model doesn't know.*

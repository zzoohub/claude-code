# AI/LLM Architecture Decision Framework

Architecture patterns for systems that integrate Large Language Models. Use this reference when the PRD includes AI-powered features — generation, summarization, search, agents, or any LLM-driven capability.

---

## When This Reference Applies

Read this if the system includes any of:
- Text generation, summarization, or transformation via LLM
- Semantic search or retrieval-augmented generation (RAG)
- Autonomous agents that use tools or make decisions
- AI-powered features (chat, copilot, content generation, classification)

If the system just calls an LLM API for a simple task (e.g., one-shot classification), a thin integration layer is sufficient — skip to the "Direct API Integration" pattern and skim the cost/observability sections.

---

## 1. LLM Integration Patterns

Three tiers of integration complexity. Choose the simplest tier that meets requirements.

### Tier 1: Direct API Integration

Call the LLM provider's API directly from your service. No middleware.

```
Service ──HTTP POST──▶ LLM Provider API (Anthropic, OpenAI)
        ◀──response───
```

**When**: Single provider, single model, low request volume, no fallback needs.
**Trade-offs**: Simplest to build, but you're coupled to one provider. No automatic fallback, no cost tracking, no caching.

**Our stack**: Rust with `reqwest` — always. LLM providers are HTTP APIs; there is no reason to use Python for API calls. Python only if the project physically requires a Python-only library (PyTorch, LangGraph, etc.).

### Tier 2: LLM Gateway

A routing layer between your service and multiple LLM providers. Handles failover, load balancing, cost tracking, and unified API format.

```
Service ──▶ LLM Gateway ──▶ Provider A (primary)
                          ──▶ Provider B (fallback)
                          ──▶ Provider C (cost-optimized)
```

**When**: Multiple models or providers, need automatic failover, want unified cost tracking, or need request/response logging.
**Trade-offs**: Adds 50-200ms latency per request. Worth it for production reliability.

**Our stack**: **LiteLLM** (self-hosted, open-source). Unified interface to 100+ providers, YAML config, 15-30 min setup. Run as a sidecar on Cloud Run. For solopreneur scale, LiteLLM gives you Portkey/Helicone-level features without the subscription cost.

### Tier 3: Model Cascading

Route queries to progressively more expensive models based on complexity. A cheap model handles 80-90% of requests; expensive models handle the rest.

```
Query ──▶ Router/Classifier
          ├── Simple → Haiku/GPT-4o-mini ($)
          ├── Medium → Sonnet/GPT-4o ($$)
          └── Complex → Opus/o1 ($$$)
```

**When**: High request volume where cost matters, queries vary significantly in difficulty, and you can define a confidence threshold.
**Impact**: 70-87% cost reduction in production deployments. Cursor uses this pattern — a small draft model proposes tokens, a larger model verifies.

**Implementation**: LiteLLM supports router-based cascading. Alternatively, implement a lightweight classifier (even rule-based: token count, keyword presence, conversation depth) that routes to appropriate models.

---

## 2. Streaming Architecture

Most LLM-powered features need to stream tokens to the user as they're generated, because waiting 5-30 seconds for a complete response is unacceptable UX.

### Protocol: SSE (Server-Sent Events)

SSE is the standard protocol for LLM token streaming. All major providers (Anthropic, OpenAI, Google) use SSE.

**Why SSE over WebSocket**: SSE is stateless, builds on HTTP, works natively with serverless (Cloud Run, Workers, Lambda), and requires no connection management. WebSocket is only justified when you need bidirectional real-time communication (collaborative editing, voice streams).

### Architecture Pattern

```
Client ──POST /chat──▶ API Server ──SSE stream──▶ LLM Provider
       ◀──SSE stream──              ◀──tokens────
```

**Key decisions**:
- **Backpressure**: In Rust (Axum), use `axum::response::sse::Sse` with `async-stream` or `futures::Stream`. For raw byte passthrough (proxying LLM SSE directly), use `Body::from_stream(reqwest_response.bytes_stream())`. In Python (FastAPI), use `StreamingResponse` with async generators. Never buffer the entire response.
- **Structured output streaming**: When the LLM emits structured JSON token-by-token, use a partial JSON parser to render progressive UI updates. This is a hard problem — plan for it if your feature requires structured generation.
- **Frontend consumption**: Vercel AI SDK (`useChat()`, `useCompletion()`) handles SSE parsing, streaming state, and error recovery out of the box. Despite the name, it has **zero Vercel dependency** — it's an open-source (MIT) library that works on any hosting (Cloudflare Pages, self-hosted, etc.). The server-side part (`streamText`, `generateText`) also runs on Cloudflare Workers. For custom implementations without the SDK, use `fetch` + `ReadableStream`.
- **Timeout budgets**: LLM responses can take 30-60 seconds for long generations. Set Cloud Run request timeout to 300s for LLM-facing endpoints. Standard 60s timeouts will cause truncated responses.

---

## 3. RAG (Retrieval-Augmented Generation)

RAG connects the LLM to your data. Instead of relying on the model's training data alone, you retrieve relevant context from your own documents and include it in the prompt.

### When to Use RAG

- The LLM needs access to **private or recent data** not in its training set
- Answers must be **grounded in source documents** (reducing hallucination)
- The knowledge base is too large to fit in a single prompt
- You need **attributable responses** with source citations

### When NOT to Use RAG

- The task is creative generation (writing, brainstorming) — retrieval adds noise
- The knowledge fits comfortably in the system prompt (< 100K tokens)
- Real-time data is needed — use tool calls to live APIs instead

### RAG Architecture Tiers

**Tier 1 — Naive RAG**: Query → embed → retrieve top-k chunks → stuff into prompt → generate. Start here. It works surprisingly well for most use cases. If retrieval quality is above 80%, you may not need anything more sophisticated.

**Tier 2 — Advanced RAG**: Adds pre-retrieval and post-retrieval optimization:
- **Hybrid search**: Combine dense (semantic embeddings) + sparse (BM25 keyword matching). Hybrid improves NDCG by 26-31% over dense-only.
- **Reranking**: After initial retrieval, re-score candidates with a cross-encoder model (e.g., Cohere Rerank). Dramatically improves precision for the cost of ~50ms latency.
- **Contextual retrieval** (Anthropic's approach): Before embedding, prepend a concise context summary to each chunk explaining where it fits in the source document. Reduces retrieval failures by 49%.

**Tier 3 — Agentic RAG**: The LLM autonomously decides when to retrieve, what queries to use, and whether results are sufficient. Handles multi-hop questions by decomposing them into sub-queries. Use when: questions require reasoning across multiple documents, or the retrieval strategy depends on the question type.

### Retrieval Strategy Selection

| Strategy | When to Use | Latency Impact |
|---|---|---|
| Dense only (embeddings) | Homogeneous content, semantic queries | Baseline |
| Hybrid (dense + BM25) | Mixed content, exact term matching matters | +10-20ms |
| + Reranking | Precision-critical, top-k has noise | +50-100ms |
| + Query decomposition | Multi-hop questions, complex queries | +1-2s (extra LLM call) |
| + Contextual retrieval | Chunks lose meaning without document context | Build-time cost only |
| Parent document retrieval | Small chunks for precision, large for context | Minimal |

### Vector Storage

| Priority | Platform | When to Use |
|---|---|---|
| 1st | **pgvector on Neon** | Default. Under 10M vectors, need ACID, already using Postgres. HNSW index for sub-100ms queries. Unified relational + vector queries eliminate a separate database. |
| 2nd | **Qdrant (Cloud Run)** | Over 10M vectors, need advanced filtering, or vector-specific features (multi-tenancy, named vectors). Self-host on Cloud Run or use Qdrant Cloud. |
| 3rd | **Pinecone** | Fully managed, zero-ops vector search. Choose when operational simplicity outweighs cost and you don't need relational queries alongside vectors. |

**Our stack**: pgvector on Neon is the default — it keeps your data in one place and Neon's scale-to-zero means you don't pay for a separate vector database at low traffic. Only break out to a dedicated vector DB when you hit pgvector's performance ceiling (~10M vectors) or need vector-specific features.

**Tuning pgvector**: Use HNSW index (not IVFFlat) for production. Set `ef_search = 200` as starting point. Use `lists = rows/200` for IVFFlat if you must. Combine vector KNN with structured prefilters (`WHERE tenant_id = X`) — this usually outperforms vector-only by an order of magnitude.

### Chunking Strategy

| Document Type | Strategy | Chunk Size |
|---|---|---|
| FAQ / knowledge base | Fixed-size or recursive | 256-512 tokens |
| Technical docs / API refs | Structure-aware (headers, sections) | 400-600 tokens |
| Legal / contracts | Semantic + structure-aware | 300-500 tokens |
| Long-form narrative | Recursive with larger overlap | 512-1024 tokens |
| Source code | AST-aware (function/class level) | Function boundaries |

**Default**: Start with recursive character splitting at 400-512 tokens with 10-20% overlap. This achieves 85-90% recall without complexity. Optimize chunking only after measuring retrieval quality.

**Advanced**: Jina AI's late chunking processes the entire document through the transformer before chunking, so each chunk's embedding captures full document context. Available in jina-embeddings-v3. Consider for high-value corpora where retrieval quality is critical.

### Embedding Models

| Model | MTEB | Price/1M tok | Dimensions | Max Input | Multilingual | Notes |
|---|---|---|---|---|---|---|
| Google `gemini-embedding-001` | **68.3** (1st) | $0.15 (free tier avail) | 768/1536/3072 | 2,048 | 100+ langs | Highest quality. Free tier for dev. Short max input forces aggressive chunking. |
| OpenAI `text-embedding-3-large` | 64.6 (5th) | $0.13 (batch $0.065) | 256~3072 (any) | 8,191 | Yes | Most flexible dimensions. Mature ecosystem. Best batch pricing. |
| Cohere `embed-v4` | 65.2 (4th) | $0.12 | 256~1536 | **128,000** | 100+ langs | 128K context eliminates chunking. Multimodal (text+image+PDF). Cheapest standard. |
| Jina `jina-embeddings-v3` | — | — | 1024 | 8,192 | Yes | Late chunking support, task-specific LoRA adapters. |
| `BAAI/bge-m3` | — | Free (OSS) | 1024 | 8,192 | Yes | Open-source, supports dense + sparse + ColBERT in one model. |

**Our stack**: Google `gemini-embedding-001` at 1536 dimensions. MTEB leader by a wide margin (+3.1 over 2nd place), free tier for development, and the 2K token limit is a non-issue because RAG workloads chunk to 400-512 tokens anyway. Matryoshka support means you can reduce to 768 dimensions with only 0.26% quality loss if storage matters.

**Exception**: Cohere `embed-v4` when you need to embed full documents without chunking (128K context) or need multimodal embeddings (text + images + PDFs). The 128K window is especially useful for Korean where morphological complexity makes chunk boundary placement harder.

---

## 4. Agent Architecture

Agents are LLM systems that autonomously plan, use tools, and iterate toward a goal. Use agent patterns when the task requires multi-step reasoning, tool orchestration, or adaptive behavior that can't be hardcoded into a pipeline.

### When to Use Agents vs. Pipelines

| Signal | Use Pipeline | Use Agent |
|---|---|---|
| Steps are predictable | Yes | - |
| Tool selection depends on results | - | Yes |
| Needs self-correction on failure | - | Yes |
| User interaction is structured | Yes | - |
| Open-ended exploration needed | - | Yes |

### Agent Patterns

**ReAct (Reason + Act)**: The default pattern. Agent iteratively thinks → acts (uses tool) → observes result → thinks again. Most common for single-agent systems. Simple, debuggable, effective.

**Plan-and-Execute**: Agent first creates a full plan (list of steps), then executes sequentially, re-planning if a step fails. Better for complex multi-step tasks where upfront planning improves coherence.

**Multi-Agent Orchestration**: Specialized agents handle different domains. A supervisor agent delegates and consolidates.
- **Supervisor pattern**: Central coordinator assigns tasks to specialists
- **Scatter-gather**: Tasks distributed in parallel, results consolidated
- **Pipeline**: Agents handle sequential stages concurrently

### State Management — The Critical Production Concern

Agent conversations can run for minutes. If a process crashes mid-execution, without checkpointing you lose all progress and cost.

**Durable execution options**:

| Priority | Platform | When to Use |
|---|---|---|
| 1st | **LangGraph checkpointing** (Postgres) | Default for LangGraph agents. Checkpoint after every graph step to `AsyncPostgresSaver` on Neon. Resume from last checkpoint on failure. |
| 2nd | **DBOS** (Postgres-based) | Lightweight durable execution without new infrastructure. Uses Postgres as orchestration layer. Annotate functions → get checkpoint-based recovery. |
| 3rd | **Temporal** | Heavy-duty workflow orchestration. When agent workflows are complex, long-running (hours/days), or require exactly-once guarantees across distributed services. |

**Our stack**: LangGraph with `AsyncPostgresSaver` on Neon. Checkpoint state persists in the same database you already have — no new infrastructure. For non-LangGraph agents, DBOS provides durability with just Postgres, fitting our "minimize infrastructure" philosophy.

### Human-in-the-Loop

Implement as interrupt points where agent execution pauses, surfaces context to a human (via webhook, Slack, or UI), and resumes when they respond. LangGraph models this as interrupt nodes in the graph — the persistence layer holds state while waiting for human input.

**Key insight**: The human approval step should be asynchronous. Don't hold a request open waiting for human response. Persist the agent state, notify the human, and resume via a callback endpoint when they respond.

### MCP (Model Context Protocol) for Tool Integration

MCP is the standard protocol for connecting agents to external tools and data sources. Instead of building custom tool adapters, expose capabilities via MCP servers.

**Architecture**:
```
Agent ──MCP Client──▶ MCP Server (GitHub)
                   ──▶ MCP Server (Database)
                   ──▶ MCP Server (Slack)
```

**Transport**: Use stdio for local development (credentials stay local). Use HTTP + SSE with OAuth 2.1 for remote/production deployments.

**Our stack**: For solopreneur scale, local MCP servers via stdio are sufficient. For production services, run MCP servers as lightweight Cloud Run services with OAuth 2.1 auth.

---

## 5. Cross-Cutting Concerns for AI Systems

### Cost Optimization

AI inference costs can dominate cloud spend. Address this architecturally, not as an afterthought.

| Strategy | Cost Impact | Implementation Effort |
|---|---|---|
| **Prompt optimization** (trim unnecessary context) | 15-30% reduction | Low |
| **Semantic caching** (cache semantically similar queries) | 30-70% reduction for repetitive workloads | Medium |
| **Model cascading** (cheap model first, expensive for hard cases) | 70-87% reduction | Medium |
| **Batch API** (for non-real-time workloads) | 50% reduction | Low |
| **Reduced embedding dimensions** | 50-75% storage reduction | Low |

**Semantic caching**: Use vector similarity to identify queries with the same meaning and serve cached responses. Redis with vector search is the simplest option. Cache hit rates of 60-85% are typical for support/docs workloads — cache hits return in ~50ms vs. 1-2s for inference.

**Our stack**: Start with prompt optimization + model cascading (biggest ROI). Add semantic caching via Redis (Memorystore) for workloads with repetitive queries. Use batch APIs for background processing (content generation, data extraction).

### Guardrails & Safety

Production AI systems need input/output validation. Layer defenses by cost and speed:

```
Input → [Rule-based filters ~1ms] → [ML classifiers ~10ms] → [LLM validators ~200ms]
  → LLM Generation →
Output → [Format validation ~1ms] → [Factuality check ~10ms] → [Safety review ~200ms]
  → Response
```

**Key decisions**:
- **PII detection**: Microsoft Presidio (open-source, production-proven). Run as pre-processing to mask PII before it reaches the LLM.
- **Content safety**: Llama Guard or NVIDIA NeMo Guardrails for comprehensive input/output filtering. NeMo supports 5 rail types with Kubernetes-ready deployment.
- **Sync vs. async**: For real-time chat, heavy guardrails (LLM-based) can add 200ms+ latency. Consider async monitoring — let the response through immediately but run background checks and flag/retract if needed.

### Observability for AI Systems

Standard RED metrics (Rate, Errors, Duration) plus AI-specific metrics:

**Essential AI metrics**:
- Token usage per request (input vs. output, by model)
- Cost per request, per user, per feature
- Time-to-first-token (TTFT) — critical for streaming UX
- Hallucination rate / groundedness score
- Cache hit rate (if using semantic caching)
- Retrieval quality (if using RAG): precision@k, relevance score

**Our stack**: PostHog for user-level analytics + Sentry for error tracking (already in stack). For AI-specific observability, add **Langfuse** (open-source, self-hostable, OTel-native) — it tracks prompts, completions, token usage, cost, and latency. Unified dashboard with PostHog via webhooks. For deep LangChain/LangGraph debugging, LangSmith is the tightest integration.

**OpenTelemetry**: The **OpenLLMetry** project extends OTel with GenAI semantic conventions — standardized spans for LLM calls, tool usage, and agent steps. Use this if you're already on OTel and want unified tracing across LLM and non-LLM services.

### Prompt Management

For production systems with multiple prompts that evolve over time:

- **Decouple prompts from code**: Store prompts in a registry, fetch at runtime. Enables changes without redeployment.
- **Version and test**: Every prompt change gets a version. Run eval suites before promotion.
- **A/B test**: Feature-flag infrastructure (LaunchDarkly, PostHog) can manage prompt variants the same way it manages code variants.

For solopreneur scale, storing prompts as version-controlled files in the repo is fine. Move to a prompt registry when you have multiple prompts changing frequently or need non-engineer access to prompt editing.

---

## 6. AI Architecture Decision Flowchart

```
Does the feature need an LLM?
├── Just classification/extraction → Consider fine-tuned small model or structured prompting
├── Generation/conversation/reasoning → Continue below
│
How does the LLM access knowledge?
├── Built-in knowledge is sufficient → Direct API call (Tier 1)
├── Needs private/recent data → RAG (Section 3)
├── Needs to take actions → Agent with tools (Section 4)
└── Needs data + actions → Agentic RAG (Section 3 + 4 combined)
│
How many models/providers?
├── One → Direct API integration
└── Multiple or need failover → LLM Gateway (Tier 2)
│
Is cost a concern at scale?
├── YES → Add model cascading (Tier 3) + semantic caching
└── NO → Direct calls are fine
│
Does the user need real-time output?
├── YES → SSE streaming (Section 2)
└── NO → Standard request-response, consider batch API for throughput
│
Is the agent long-running or failure-prone?
├── YES → Durable execution (LangGraph + Postgres checkpoints)
└── NO → Stateless agent loop is fine
```

---

## Real-World Architecture Compositions

| Company | Architecture | Key Insight |
|---|---|---|
| **Cursor** | Speculative decoding (small model drafts, large verifies) + parallel agents in isolated git worktrees + custom fast-apply model (~1000 tok/s) | Train specialized models for bottleneck tasks. Parallel agents with isolation for throughput. |
| **Perplexity** | Hybrid retrieval on Vespa.ai (200B+ URL index) + multi-stage pipeline (intent → retrieve → rerank → generate) + streaming | Scale RAG with a dedicated retrieval engine. LLM-based intent parsing outperforms keyword matching. |
| **GitHub Copilot** | Context engine (cursor, open files, repo embeddings) + multi-model orchestration (Microsoft Prometheus) + MCP for tool access | Codebase indexing with SQLite-backed embeddings for local search. Fill-in-middle model for code-aware completion. |
| **Notion AI** | RAG over workspace content + LLM-as-judge for quality monitoring + structured test fixtures + human-labeled feedback | Combine automated and human evaluation. RAG over heterogeneous content (docs, tables, databases) requires content-type-aware chunking. |

---

## Anti-Patterns

**RAG Everything**: Shoving all data into a vector store when half of it would be better served by structured queries (SQL) or API calls. Vector search is for semantic similarity — use the right tool for each data type.

**Agent When a Pipeline Will Do**: If the steps are predictable and don't depend on intermediate results, a hardcoded pipeline is simpler, faster, cheaper, and more debuggable than an agent.

**Ignoring LLM Costs Until the Bill Arrives**: A single GPT-4 call costs ~$0.03. At 100K requests/day, that's $3K/day. Model cascading and caching should be in the architecture from day one for any high-volume feature.

**Prompt Engineering as Architecture**: Relying on prompt tweaks to compensate for missing retrieval, poor data quality, or wrong model choice. Fix the architecture first — prompts should refine behavior, not compensate for structural problems.

**Treating LLM Output as Trusted**: LLMs hallucinate. Any LLM output that drives critical decisions (financial transactions, medical advice, access control) needs validation — either programmatic (schema checks, business rule verification) or human-in-the-loop.

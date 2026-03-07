# AI/LLM Architecture Decision Framework

Architecture patterns for systems that integrate Large Language Models. Use this reference when the PRD includes AI-powered features — generation, summarization, search, agents, or any LLM-driven capability.

**Important**: The AI landscape evolves rapidly. This document covers **stable architectural patterns** that remain valid across model generations. For specific model choices, pricing, and benchmarks, **always verify current state via WebSearch** before committing.

---

## Table of Contents

1. [LLM Integration Patterns](#1-llm-integration-patterns) — Direct API, Gateway, Model Cascading
2. [Streaming Architecture](#2-streaming-architecture) — SSE, backpressure, frontend consumption
3. [RAG (Retrieval-Augmented Generation)](#3-rag-retrieval-augmented-generation) — When to use, tiers, vector storage, chunking, embeddings
4. [Agent Architecture](#4-agent-architecture) — Patterns, Rust-first implementation, state management, MCP
5. [Cross-Cutting Concerns for AI Systems](#5-cross-cutting-concerns-for-ai-systems) — Cost, guardrails, observability, prompt management
6. [AI Testing & Evaluation](#6-ai-testing--evaluation) — RAG quality, agent reliability, prompt regression, EDD
7. [Fine-Tuning Decision Framework](#7-fine-tuning-decision-framework) — When to fine-tune vs. prompt engineer vs. RAG
8. [Model Lifecycle Management](#8-model-lifecycle-management) — Migration strategy, data flywheel
9. [AI Architecture Decision Flowchart](#9-ai-architecture-decision-flowchart)
10. [Anti-Patterns](#10-anti-patterns)

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
Service --HTTP POST--> LLM Provider API
        <--response---
```

**When**: Single provider, single model, low request volume, no fallback needs.
**Trade-offs**: Simplest to build, but you're coupled to one provider. No automatic fallback, no cost tracking, no caching.

**Our stack**: Rust with `reqwest`. LLM providers expose HTTP APIs — use them directly. For structured request/response handling, `serde` makes JSON serialization type-safe at compile time.

### Tier 2: LLM Gateway

A routing layer between your service and multiple LLM providers. Handles failover, load balancing, cost tracking, and unified API format.

```
Service --> LLM Gateway --> Provider A (primary)
                        --> Provider B (fallback)
                        --> Provider C (cost-optimized)
```

**When**: Multiple models or providers, need automatic failover, want unified cost tracking, or need request/response logging.
**Trade-offs**: Adds 50-200ms latency per request. Worth it for production reliability.

**Our stack**: Search for current open-source LLM gateway/proxy projects. Look for: unified multi-provider interface, YAML/config-based setup, ability to run as sidecar on Cloud Run. The gateway itself may be Python — that's fine, your calling service remains Rust via HTTP.

### Tier 3: Model Cascading

Route queries to progressively more expensive models based on complexity. A cheap model handles 80-90% of requests; expensive models handle the rest.

```
Query --> Router/Classifier
          |-- Simple -> Small/fast model ($)
          |-- Medium -> Mid-tier model ($$)
          +-- Complex -> Frontier model ($$$)
```

**When**: High request volume where cost matters, queries vary significantly in difficulty, and you can define a confidence threshold.
**Impact**: 70-87% cost reduction in production deployments.

**Implementation**: Use a lightweight classifier (rule-based: token count, keyword presence, conversation depth) that routes to appropriate models. Or use the gateway's built-in router if available.

---

## 2. Streaming Architecture

Most LLM-powered features need to stream tokens to the user as they're generated, because waiting 5-30 seconds for a complete response is unacceptable UX.

### Protocol: SSE (Server-Sent Events)

SSE is the standard protocol for LLM token streaming. All major providers use SSE.

**Why SSE over WebSocket**: SSE is stateless, builds on HTTP, works natively with serverless (Cloud Run, Workers, Lambda), and requires no connection management. WebSocket is only justified when you need bidirectional real-time communication (collaborative editing, voice streams).

### Architecture Pattern

```
Client --POST /chat--> API Server --SSE stream--> LLM Provider
       <--SSE stream--              <--tokens----
```

**Key decisions**:
- **Backpressure**: In Rust (Axum), use `axum::response::sse::Sse` with `async-stream` or `futures::Stream`. For raw byte passthrough (proxying LLM SSE directly), use `Body::from_stream(reqwest_response.bytes_stream())`.
- **Structured output streaming**: When the LLM emits structured JSON token-by-token, use a partial JSON parser to render progressive UI updates. This is a hard problem — plan for it if your feature requires structured generation.
- **Frontend consumption**: Vercel AI SDK (`useChat()`, `useCompletion()`) handles SSE parsing, streaming state, and error recovery out of the box. Despite the name, it has **zero Vercel dependency** — it's an open-source (MIT) library that works on any hosting. For custom implementations without the SDK, use `fetch` + `ReadableStream`.
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

**Tier 1 — Naive RAG**: Query -> embed -> retrieve top-k chunks -> stuff into prompt -> generate. Start here. It works surprisingly well for most use cases. If retrieval quality is above 80%, you may not need anything more sophisticated.

**Tier 2 — Advanced RAG**: Adds pre-retrieval and post-retrieval optimization:
- **Hybrid search**: Combine dense (semantic embeddings) + sparse (BM25 keyword matching). Hybrid improves retrieval quality significantly over dense-only.
- **Reranking**: After initial retrieval, re-score candidates with a cross-encoder reranking model. Dramatically improves precision for the cost of ~50ms latency.
- **Contextual retrieval**: Before embedding, prepend a concise context summary to each chunk explaining where it fits in the source document. Reduces retrieval failures substantially.
- **Graph-based RAG**: Build entity-relationship graphs from documents. Useful for questions that require understanding relationships across the corpus (e.g., "What are the common themes across all reports?"). Search for current GraphRAG implementations and benchmarks.

**Tier 3 — Agentic RAG**: The LLM autonomously decides when to retrieve, what queries to use, and whether results are sufficient. Handles multi-hop questions by decomposing them into sub-queries. Use when: questions require reasoning across multiple documents, or the retrieval strategy depends on the question type.

### Retrieval Strategy Selection

| Strategy | When to Use | Latency Impact |
|---|---|---|
| Dense only (embeddings) | Homogeneous content, semantic queries | Baseline |
| Hybrid (dense + BM25) | Mixed content, exact term matching matters | +10-20ms |
| + Reranking | Precision-critical, top-k has noise | +50-100ms |
| + Query decomposition | Multi-hop questions, complex queries | +1-2s (extra LLM call) |
| + Contextual retrieval | Chunks lose meaning without document context | Build-time cost only |
| Graph-based | Thematic/relational questions across corpus | Variable |
| Parent document retrieval | Small chunks for precision, large for context | Minimal |

### Vector Storage

Choose based on your scale and existing infrastructure:

| Scale | Approach | Rationale |
|---|---|---|
| < ~100M vectors | **pgvector on Postgres** | Unified relational + vector queries, no separate database. Use HNSW index for production. Combine vector KNN with structured prefilters (`WHERE tenant_id = X`). Check current pgvector version for latest performance improvements. |
| > 100M vectors, cost-sensitive | **Object-storage-first vector DB** | Search for current options that use S3/GCS as primary storage with SSD cache tier. Dramatically lower cost than memory-first databases. |
| > 100M vectors, query-intensive | **Dedicated vector database** | Search for current benchmarks comparing options (filtered search, multi-tenancy, throughput). Evaluate managed vs self-hosted. |
| Need zero-ops | **Fully managed vector service** | Higher cost, lowest operational burden. Evaluate current managed offerings. |

**Our stack**: pgvector on Neon is the default — it keeps your data in one place and Neon's scale-to-zero means you don't pay for a separate vector database at low traffic. Only break out to a dedicated vector DB when you hit pgvector's performance ceiling or need vector-specific features. Always verify current pgvector capabilities — the extension improves rapidly.

### Chunking Strategy

| Document Type | Strategy | Chunk Size |
|---|---|---|
| FAQ / knowledge base | Fixed-size or recursive | 256-512 tokens |
| Technical docs / API refs | Structure-aware (headers, sections) | 400-600 tokens |
| Legal / contracts | Semantic + structure-aware | 300-500 tokens |
| Long-form narrative | Recursive with larger overlap | 512-1024 tokens |
| Source code | AST-aware (function/class level) | Function boundaries |

**Default**: Start with recursive character splitting at 400-512 tokens with 10-20% overlap. This achieves 85-90% recall without complexity. Optimize chunking only after measuring retrieval quality.

### Embedding Models

**Do not hardcode a specific embedding model.** The leaderboard shifts every few months.

**Selection criteria** (in priority order for our stack):
1. **Retrieval quality**: Check the current MTEB leaderboard (huggingface.co/spaces/mteb/leaderboard) for your language mix
2. **Max input tokens**: Must accommodate your chunk size. Some models support 128K+ tokens (eliminating chunking)
3. **Multilingual support**: Required for Korean/multilingual content
4. **Dimensions**: Lower dimensions = less storage. Many models support Matryoshka (variable dimensions)
5. **Cost**: Compare per-token pricing across providers. Check for free tiers and batch discounts
6. **Latency**: On-device/self-hosted models for latency-critical paths

**Decision process**: Before choosing an embedding model, run `WebSearch` for "best embedding models [current year] MTEB" and compare the top 3-5 options against these criteria for your specific use case.

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

**ReAct (Reason + Act)**: The default pattern. Agent iteratively thinks -> acts (uses tool) -> observes result -> thinks again. Most common for single-agent systems. Simple, debuggable, effective.

**Plan-and-Execute**: Agent first creates a full plan (list of steps), then executes sequentially, re-planning if a step fails. Better for complex multi-step tasks where upfront planning improves coherence.

**Multi-Agent Orchestration**: Specialized agents handle different domains. A supervisor agent delegates and consolidates.
- **Supervisor pattern**: Central coordinator assigns tasks to specialists
- **Scatter-gather**: Tasks distributed in parallel, results consolidated
- **Pipeline**: Agents handle sequential stages concurrently

### Context Engineering

Context engineering is the discipline of designing the full information environment an agent operates in — not just the prompt, but the schemas, retrieved data, memory, tool definitions, and conversation history that shape the agent's behavior.

**Why this matters more than prompt engineering**: A well-structured context window (clear tool schemas, relevant retrieved data, properly managed conversation history) has more impact on agent reliability than clever prompt phrasing. Think of it as the difference between giving someone a well-organized briefing packet vs. a better-worded question.

**Key practices**:
- **Context window management**: Trim, summarize, or compress conversation history to keep the most relevant information within token limits
- **Tool schema design**: Clear, unambiguous tool descriptions and parameter schemas reduce tool-call errors
- **Memory architecture**: Decide what persists across turns (conversation memory), across sessions (long-term memory), and across users (shared knowledge)

### Implementation: Rust-First Agents

An agent loop is fundamentally: prompt LLM -> parse tool calls -> execute tools -> feed results back. This is HTTP + JSON — Rust handles it naturally.

**How to build agents in Rust**:
- **Custom agent loop**: The most reliable approach. Implement the ReAct loop with `reqwest` + `serde` — ~200 lines for a basic agent. The Anthropic Messages API returns `tool_use` blocks that you parse and dispatch. No framework dependency, full control.
- **Rust LLM frameworks**: The ecosystem is evolving fast. Search for current Rust agent/LLM crates before choosing — evaluate maturity, maintenance activity, and API stability. A thin custom layer over `reqwest` often ages better than framework lock-in.

**Why Rust works for agents**: The agent loop is I/O-bound (waiting for LLM API responses), not CPU-bound. Rust's async runtime (Tokio) handles concurrent tool execution efficiently. Type-safe tool definitions catch integration errors at compile time rather than runtime.

### State Management & Checkpointing

Agent conversations can run for minutes. If a process crashes mid-execution, without checkpointing you lose all progress and cost.

| Approach | When to Use |
|---|---|
| **Postgres checkpointing (direct)** | Default. After each agent step, serialize state to an `agent_checkpoints` table. Resume from last checkpoint on failure. Simple, no new infrastructure. |
| **Durable execution framework** | When you want checkpoint-based recovery with minimal code changes. Search for current options that use Postgres as orchestration layer. |
| **Workflow orchestration** | Heavy-duty. When agent workflows are complex, long-running (hours/days), or require exactly-once guarantees across distributed services. |

**Our stack**: Postgres checkpointing on Neon. Store `(agent_id, step_index, state_json, created_at)` — that's the minimum viable checkpoint. Serialize with `serde_json`. On crash recovery, query the latest checkpoint and resume the agent loop from there.

**Python exception path**: If the project uses Python (FastAPI) because it requires Python-only libraries, LangGraph with Postgres-backed checkpointing is a strong choice for agent orchestration. LangGraph's graph-based state machine and built-in checkpointing reduce boilerplate for complex agent flows.

### Human-in-the-Loop

Implement as interrupt points where agent execution pauses, surfaces context to a human (via webhook, Slack, or UI), and resumes when they respond.

**Patterns beyond simple approval**:
- **Policy-driven routing**: Define which decisions need human review based on risk, confidence, and business rules — not a blanket "approve everything" approach
- **Progressive automation**: Start with 100% human review (audit mode), then increase autonomy as trust builds based on measured accuracy
- **Human-on-the-loop**: Continuous supervision with ability to intervene, like pilots monitoring autopilot. Distinct from human-in-the-loop where every action requires approval

**Key insight**: The human approval step should be asynchronous. Don't hold a request open waiting for human response. Persist the agent state to the checkpoint table, notify the human, and resume via a callback endpoint when they respond.

### MCP (Model Context Protocol) for Tool Integration

MCP is the industry-standard protocol for connecting agents to external tools and data sources. Instead of building custom tool adapters, expose capabilities via MCP servers.

**Architecture**:
```
Agent --MCP Client--> MCP Server (GitHub)
                  --> MCP Server (Database)
                  --> MCP Server (Slack)
```

MCP has achieved widespread adoption across major AI platforms and tools. The ecosystem includes thousands of public servers covering common integrations.

**Transport**: Use stdio for local development (credentials stay local). Use HTTP + SSE (or the newer Streamable HTTP transport) with OAuth 2.1 for remote/production deployments.

**Our stack**: For local development, use MCP servers via stdio. For production services, run MCP servers as lightweight Cloud Run services with OAuth 2.1 auth. Search for current Rust MCP SDK implementations — the protocol is HTTP + JSON, so even without a dedicated SDK, direct implementation is straightforward.

**Agent-to-Agent communication**: For multi-agent systems, search for current inter-agent protocols (e.g., A2A) that complement MCP's agent-to-tool focus. This space is evolving rapidly.

---

## 5. Cross-Cutting Concerns for AI Systems

### Cost Optimization

AI inference costs can dominate cloud spend. Address this architecturally, not as an afterthought.

| Strategy | Cost Impact | Implementation Effort |
|---|---|---|
| **Prompt optimization** (trim unnecessary context) | 15-30% reduction | Low |
| **Semantic caching** (cache semantically similar queries) | 30-70% reduction for repetitive workloads | Medium |
| **Model cascading** (cheap model first, expensive for hard cases) | 70-87% reduction | Medium |
| **Batch API** (for non-real-time workloads) | ~50% reduction | Low |
| **Reduced embedding dimensions** | 50-75% storage reduction | Low |

**Semantic caching**: Use vector similarity to identify queries with the same meaning and serve cached responses. Cache hit rates of 60-85% are typical for support/docs workloads.

**Self-hosting threshold**: When monthly inference spend exceeds ~$50K, evaluate self-hosted GPU clusters vs managed APIs. Factor in operational overhead.

**Our stack**: Start with prompt optimization + model cascading (biggest ROI). Add semantic caching for workloads with repetitive queries. Use batch APIs for background processing (content generation, data extraction).

### Guardrails & Safety

Production AI systems need input/output validation. Layer defenses by cost and speed:

```
Input -> [Rule-based filters ~1ms] -> [ML classifiers ~10ms] -> [LLM validators ~200ms]
  -> LLM Generation ->
Output -> [Format validation ~1ms] -> [Factuality check ~10ms] -> [Safety review ~200ms]
  -> Response
```

**Key decisions**:
- **PII detection**: Search for current open-source PII detection libraries. Run as pre-processing to mask PII before it reaches the LLM.
- **Content safety**: Search for current guardrail frameworks (open-source and managed). Evaluate based on latency, accuracy, and language support.
- **Indirect Prompt Injection (IPI)**: The most dangerous vulnerability for RAG systems. Malicious instructions embedded in retrieved documents can manipulate agent behavior. Mitigations: separate user instructions from retrieved context, validate tool calls against permissions, monitor for anomalous agent behavior.
- **Sync vs. async**: For real-time chat, heavy guardrails (LLM-based) can add 200ms+ latency. Consider async monitoring — let the response through immediately but run background checks and flag/retract if needed.

**Regulatory awareness**: AI regulations (EU AI Act, NIST AI RMF, ISO 42001) increasingly mandate specific guardrails for production AI systems, especially in high-risk domains (finance, healthcare). Check current regulatory requirements for your domain and region before finalizing the guardrails architecture.

### Observability for AI Systems

Standard RED metrics (Rate, Errors, Duration) plus AI-specific metrics:

**Essential AI metrics**:
- Token usage per request (input vs. output, by model)
- Cost per request, per user, per feature
- Time-to-first-token (TTFT) — critical for streaming UX
- Hallucination rate / groundedness score
- Cache hit rate (if using semantic caching)
- Retrieval quality (if using RAG): precision@k, relevance score

**Our stack**: PostHog for user-level analytics + Sentry for error tracking (already in stack). For AI-specific observability, search for current open-source LLM observability tools that support: prompt/completion tracing, token usage tracking, cost attribution, and latency monitoring. Prefer tools with an HTTP API so Rust services integrate via `reqwest` without needing a language-specific SDK.

**OpenTelemetry**: The OpenLLMetry project extends OTel with GenAI semantic conventions — standardized spans for LLM calls, tool usage, and agent steps. Use this if you're already on OTel and want unified tracing across LLM and non-LLM services.

### Prompt Management

For production systems with multiple prompts that evolve over time:

- **Decouple prompts from code**: Store prompts in a registry, fetch at runtime. Enables changes without redeployment.
- **Version and test**: Every prompt change gets a version. Run eval suites before promotion.
- **A/B test**: Feature-flag infrastructure (PostHog) can manage prompt variants the same way it manages code variants.

For solopreneur scale, storing prompts as version-controlled files in the repo is fine. Move to a prompt registry when you have multiple prompts changing frequently.

---

## 6. AI Testing & Evaluation

AI systems need testing strategies beyond conventional software testing because outputs are non-deterministic. Treat evaluation as a first-class architectural concern — "evals are the new unit tests."

### Evaluation-Driven Development (EDD)

Inspired by TDD/BDD but reimagined for LLM systems:
1. **Define eval suite before building**: For each AI feature, define 10-30 test cases with expected output characteristics (not exact matches)
2. **Assertions over expectations**: Check for structural compliance, key information inclusion, absence of known failure modes — not string equality
3. **CI integration**: Run eval suite on every PR that modifies prompts, retrieval logic, or model configuration. Block merge if pass rate drops below threshold
4. **Traceability**: Link every evaluation score to the exact version of prompt, model, and retrieval config that produced it

### RAG Quality Evaluation

| Metric | What It Measures | Target |
|---|---|---|
| **Precision@k** | % of retrieved chunks that are relevant | > 80% |
| **Recall@k** | % of relevant chunks that were retrieved | > 70% |
| **Faithfulness** | Does the answer stick to retrieved context? | > 90% |
| **Answer relevance** | Does the answer address the question? | > 85% |

**Evaluation approach**: Build a golden test set (50-100 question-answer pairs with source documents). Run retrieval + generation on each, score with an LLM-as-judge (a stronger model evaluates a weaker model's output). Automate this as a CI step on prompt or retrieval logic changes.

### Agent Reliability Testing

- **Task completion rate**: % of test scenarios where the agent achieves the goal
- **Tool call accuracy**: Does the agent call the right tools with correct parameters?
- **Step efficiency**: How many steps to complete vs. optimal path?
- **Recovery testing**: Does the agent recover gracefully from tool failures?

**Approach**: Define 20-50 test scenarios covering common paths and edge cases. Run each 3 times (non-determinism). Track pass rate and step count. Alert on regression.

### A/B Testing for AI Features

Offline evaluation often doesn't correlate with business metrics. Production A/B testing is essential:
- Test not just model swaps but prompts, hyperparameters, retrieval strategies
- Measure business outcomes (conversion, engagement, task completion), not just model quality metrics
- Use feature-flag infrastructure (PostHog) to manage AI experiment variants

---

## 7. Fine-Tuning Decision Framework

| Approach | When to Use | Cost | Maintenance |
|---|---|---|---|
| **Prompt engineering** | Default starting point. Task is definable in instructions. Few-shot examples fit in context. | Lowest | Lowest |
| **RAG** | LLM needs access to private/dynamic data. Answers must cite sources. | Medium | Medium (index updates) |
| **Fine-tuning** | Consistent style/format across thousands of outputs. Latency-critical (shorter prompts). Domain-specific terminology. Prompt engineering plateaued. | High (training) | High (retraining on new data) |
| **Fine-tuning + RAG** | Domain-adapted model that also needs current data. Best quality ceiling. | Highest | Highest |

**Decision rule**: Exhaust prompt engineering and RAG before considering fine-tuning. Fine-tuning is a last resort for solopreneur scale — it requires training data curation, compute cost, evaluation infrastructure, and ongoing maintenance. The gap between a well-prompted frontier model and a fine-tuned smaller model is narrowing with each generation.

**When fine-tuning is justified**:
- You have 1000+ high-quality input-output examples
- The task has a consistent, well-defined output format
- You need to reduce per-request cost at high volume (smaller fine-tuned model > larger general model)
- Latency requirements demand shorter prompts (fine-tuned knowledge vs. in-context knowledge)

---

## 8. Model Lifecycle Management

### Model Migration Strategy

LLM switching is not plug-and-play. Models have different tokenizers, context window behaviors, instruction-following patterns, and failure modes.

**Triggers for migration**: Major new model release, rising costs, latency degradation, expanding task types, governance/compliance changes.

**Required infrastructure**:
- **Stable baselines**: Before any migration, capture current performance metrics (quality, latency, cost) as the baseline to compare against
- **Side-by-side evaluation**: Run candidate models on the same eval suite under identical conditions. Never switch based on benchmarks alone — your workload is unique
- **Gradual rollout**: Use feature flags to route a percentage of traffic to the new model. Monitor quality and cost before full cutover
- **Rollback plan**: Keep the old model configuration readily available. A model migration that degrades quality must be instantly reversible

**Architecture implication**: The LLM Gateway pattern (Tier 2) makes model migration dramatically easier. If your service calls models directly, every migration requires code changes. With a gateway, you change config.

### Data Flywheel

A production AI system generates valuable data exhaust that can improve future performance:

```
Production usage → Collect logs (prompt/response/feedback)
    → Curate high-quality examples
    → Fine-tune or improve retrieval
    → Deploy improved system
    → Repeat
```

**Key components**:
- **Feedback collection**: Thumbs up/down, regeneration requests, user edits to AI output — all signal quality
- **Data curation**: Filter for high-quality examples, remove PII, deduplicate
- **Evaluation loop**: Verify improvements on eval suite before deploying
- **Cost reduction**: The flywheel naturally produces training data for smaller, cheaper, specialized models that can replace expensive frontier models for specific tasks

For solopreneur scale, start with simple feedback collection (store prompt/response/user-rating in Postgres). Build the curation and fine-tuning pipeline only when you have enough data to justify it.

---

## 9. AI Architecture Decision Flowchart

```
Does the feature need an LLM?
|-- Just classification/extraction -> Consider structured prompting or fine-tuned small model
|-- Generation/conversation/reasoning -> Continue below
|
How does the LLM access knowledge?
|-- Built-in knowledge is sufficient -> Direct API call (Tier 1)
|-- Needs private/recent data -> RAG (Section 3)
|-- Needs to take actions -> Agent with tools (Section 4)
+-- Needs data + actions -> Agentic RAG (Section 3 + 4 combined)
|
How many models/providers?
|-- One -> Direct API integration
+-- Multiple or need failover -> LLM Gateway (Tier 2)
|
Is cost a concern at scale?
|-- YES -> Add model cascading (Tier 3) + semantic caching
+-- NO -> Direct calls are fine
|
Does the user need real-time output?
|-- YES -> SSE streaming (Section 2)
+-- NO -> Standard request-response, consider batch API for throughput
|
Is the agent long-running or failure-prone?
|-- YES -> Postgres checkpointing (Section 4)
+-- NO -> Stateless agent loop is fine
|
Has prompt engineering plateaued with enough training data available?
|-- YES -> Consider fine-tuning (Section 7)
+-- NO -> Keep optimizing prompts and RAG
```

---

## 10. Anti-Patterns

**RAG Everything**: Shoving all data into a vector store when half of it would be better served by structured queries (SQL) or API calls. Vector search is for semantic similarity — use the right tool for each data type.

**Agent When a Pipeline Will Do**: If the steps are predictable and don't depend on intermediate results, a hardcoded pipeline is simpler, faster, cheaper, and more debuggable than an agent.

**Ignoring LLM Costs Until the Bill Arrives**: At high volume, inference costs compound fast. Model cascading and caching should be in the architecture from day one for any high-volume feature.

**Prompt Engineering as Architecture**: Relying on prompt tweaks to compensate for missing retrieval, poor data quality, or wrong model choice. Fix the architecture first — prompts should refine behavior, not compensate for structural problems.

**Treating LLM Output as Trusted**: LLMs hallucinate. Any LLM output that drives critical decisions (financial transactions, medical advice, access control) needs validation — either programmatic (schema checks, business rule verification) or human-in-the-loop.

**Premature Fine-Tuning**: Jumping to fine-tuning before exhausting prompt engineering and RAG. Fine-tuning adds training data curation, compute cost, and retraining cycles. Often a better prompt or better retrieval achieves the same result with far less maintenance burden.

**Hardcoding Model Versions**: Pinning to a specific model version without a migration strategy. Models get deprecated, pricing changes, and better options emerge. Design for model portability from day one.

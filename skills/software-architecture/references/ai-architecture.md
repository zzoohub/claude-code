# AI/LLM Architecture Decision Framework

Architecture patterns for systems that integrate Large Language Models. Use this reference when the PRD includes AI-powered features — generation, summarization, search, agents, or any LLM-driven capability.

**Important**: The AI landscape evolves rapidly. This document covers **stable architectural patterns** that remain valid across model generations. For specific model choices, pricing, and benchmarks, **always verify current state via WebSearch** before committing.

---

## Table of Contents

1. [LLM Integration Patterns](#1-llm-integration-patterns) — Direct API, Gateway, Model Cascading
2. [Streaming Architecture](#2-streaming-architecture) — SSE, backpressure, frontend consumption
3. [RAG (Retrieval-Augmented Generation)](#3-rag-retrieval-augmented-generation) — When to use, tiers, vector storage, chunking, embeddings
4. [Agent Architecture](#4-agent-architecture) — Patterns, Rust-first implementation, state management, MCP
5. [Multimodal Architecture](#5-multimodal-architecture) — Vision, audio/speech, multimodal RAG, output generation
6. [Cross-Cutting Concerns for AI Systems](#6-cross-cutting-concerns-for-ai-systems) — Cost, guardrails, observability, prompt management
7. [AI Testing & Evaluation](#7-ai-testing--evaluation) — RAG quality, agent reliability, prompt regression, EDD
8. [Fine-Tuning Decision Framework](#8-fine-tuning-decision-framework) — When to fine-tune vs. prompt engineer vs. RAG
9. [Model Lifecycle Management](#9-model-lifecycle-management) — Migration strategy, data flywheel
10. [AI Architecture Decision Flowchart](#10-ai-architecture-decision-flowchart)
11. [Anti-Patterns](#11-anti-patterns)

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

**Our stack**: Native `fetch` in Hono on Workers. LLM providers expose HTTP APIs — use them directly. Zod for response validation ensures type safety at runtime.

### Tier 2: LLM Gateway

A routing layer between your service and multiple LLM providers. Handles failover, load balancing, cost tracking, and unified API format.

```
Service --> LLM Gateway --> Provider A (primary)
                        --> Provider B (fallback)
                        --> Provider C (cost-optimized)
```

**When**: Multiple models or providers, need automatic failover, want unified cost tracking, or need request/response logging.
**Trade-offs**: Adds 50-200ms latency per request. Worth it for production reliability.

**Our stack**:
- **CF bundle**: **AI Gateway** (Cloudflare-native). Multi-provider proxy (OpenAI, Anthropic, Bedrock, etc.), caching, rate limiting, cost tracking, fallback routing. Zero setup — just route through `gateway.ai.cloudflare.com`.
- **Container escape hatch**: Search for current open-source LLM gateway/proxy projects. Look for: unified multi-provider interface, YAML/config-based setup, ability to run as sidecar.

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
- **Backpressure**: In Hono on Workers, use `c.stream()` or `c.streamSSE()` for SSE responses. For raw byte passthrough (proxying LLM SSE directly), pipe the provider's `ReadableStream` through. In Rust (Axum), use `axum::response::sse::Sse` with `async-stream`.
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

When the system requires adaptive multi-step behavior — tool orchestration, autonomous decision-making, or long-running workflows — use agent patterns. Default to simpler patterns (augmented LLM, prompt chaining) and escalate only when needed.

**Full guide**: `references/ai-agents.md` — pattern hierarchy, protocols (MCP, A2A, AG-UI), context engineering, durable execution, multi-agent systems, and safety.

---

## 5. Multimodal Architecture

When the system processes or generates images, audio, video, or documents beyond plain text. Multimodal adds distinct architectural concerns: larger payloads, specialized preprocessing, different latency profiles, and storage requirements.

### Input Modalities

| Modality | Architecture Pattern | Key Decisions |
|---|---|---|
| **Vision (images)** | Presigned upload → preprocess → LLM vision API | Max image size, resize before API call (cost/latency), format conversion |
| **Documents (PDF, DOCX)** | Upload → extract text/structure → process as text | Extraction approach: OCR vs structured parsing vs multimodal LLM. Layout-aware extraction for tables/forms |
| **Audio/Speech** | Upload or stream → STT → process text → TTS (optional) | Real-time vs batch, streaming STT for live input, language detection, speaker diarization |
| **Video** | Upload → extract frames + audio track → process separately | Frame sampling rate, keyframe extraction, parallel audio/visual analysis |

### Vision Integration

Most common multimodal pattern. Two approaches:

**Direct vision API**: Send image + text prompt to a multimodal LLM (Claude, GPT-4o). Simple, handles most use cases.

```
Client → upload image → API → multimodal LLM (image + prompt) → response
```

**Pipeline with preprocessing**: When you need structured extraction, OCR validation, or cost optimization.

```
Client → upload image → resize/optimize → specialized model (OCR/detection)
                                        → multimodal LLM (complex reasoning only)
                                        → merge results → response
```

**Cost consideration**: Vision API calls cost significantly more than text-only (image tokens are expensive). For high-volume image processing, preprocess with cheaper specialized models (OCR, object detection) and send only extracted data to the LLM for reasoning.

### Audio/Speech Architecture

**Speech-to-Text (STT)**:
- **Batch**: Upload audio file → STT API → text. Simple, higher latency
- **Streaming**: WebSocket audio stream → streaming STT → real-time text. Required for voice interfaces and live transcription
- Provider options: Whisper API, Deepgram, AssemblyAI, CF Workers AI (Whisper models). Verify current pricing and accuracy benchmarks

**Text-to-Speech (TTS)**:
- Generate audio from LLM output for voice interfaces
- **Streaming TTS**: Generate audio chunks as text streams in — critical for conversational UX
- Cache commonly generated phrases to reduce cost and latency

**Voice agents**: Combine streaming STT → LLM → streaming TTS for real-time voice conversation. Latency budget is tight (~500ms total round-trip for natural feel). Consider WebRTC for lowest latency transport.

**Our stack**: CF Agents SDK supports voice triggers natively. For custom voice pipelines, Workers + WebSocket for streaming, R2 for audio storage.

### Multimodal RAG

Extending RAG (Section 3) to handle non-text content:

| Content Type | Indexing Strategy | Retrieval |
|---|---|---|
| **Images in documents** | Extract description with multimodal LLM, embed the description | Text query matches image descriptions |
| **Diagrams/charts** | Multimodal LLM generates structured description + data extraction | Text or structured query |
| **Audio/video** | Transcribe → chunk → embed transcription. Store timestamps for seeking | Text query, return with timestamp references |
| **Mixed documents** | Process each modality separately, link via document ID | Unified query across modalities |

**Key insight**: Most multimodal RAG works by converting non-text content into text representations for embedding. True multimodal embeddings (CLIP-style) are useful for image-to-image similarity but add complexity. Start with text-based indexing of multimodal content.

### Output Modalities

| Output | Architecture | Considerations |
|---|---|---|
| **Image generation** | Text prompt → image model API → store result | Async generation (2-30s), progress indication, R2 for storage |
| **Audio generation (TTS)** | Text → TTS API → audio stream/file | Streaming for real-time, batch for pre-generation |
| **Document generation** | LLM generates structured content → render to PDF/DOCX | Template-based rendering, not LLM-generated binary |

### Multimodal Anti-Patterns

**Sending raw high-res images to LLMs**: Resize to the minimum resolution the model needs. A 4000x3000 image costs 10x more tokens than 1000x750 with negligible quality difference for most tasks.

**Synchronous video processing**: Video analysis is inherently slow. Always use async processing with progress callbacks. Never block a user request on video analysis.

**Ignoring modality-specific costs**: A single image analysis can cost 10-50x a text-only call. Track cost per modality separately and apply model cascading per modality.

---

## 6. Cross-Cutting Concerns for AI Systems

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

**Our stack**: PostHog for user-level analytics + Sentry for error tracking (already in stack). For AI-specific observability:
- **CF bundle**: AI Gateway provides built-in cost tracking, request logging, and caching metrics. Combine with Workers Analytics Engine for custom AI metrics (token usage, TTFT, cost per user).
- For deeper LLM tracing (prompt/completion traces, quality scoring), search for current open-source LLM observability tools that support HTTP API integration.

**OpenTelemetry**: The OpenLLMetry project extends OTel with GenAI semantic conventions — standardized spans for LLM calls, tool usage, and agent steps. Use this if you're already on OTel and want unified tracing across LLM and non-LLM services.

### Prompt Management

For production systems with multiple prompts that evolve over time:

- **Decouple prompts from code**: Store prompts in a registry, fetch at runtime. Enables changes without redeployment.
- **Version and test**: Every prompt change gets a version. Run eval suites before promotion.
- **A/B test**: Feature-flag infrastructure (PostHog) can manage prompt variants the same way it manages code variants.

For solopreneur scale, storing prompts as version-controlled files in the repo is fine. Move to a prompt registry when you have multiple prompts changing frequently.

---

## 7. AI Testing & Evaluation

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

## 8. Fine-Tuning Decision Framework

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

## 9. Model Lifecycle Management

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

## 10. AI Architecture Decision Flowchart

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
|-- YES -> Consider fine-tuning (Section 8)
+-- NO -> Keep optimizing prompts and RAG
```

---

## 11. Anti-Patterns

**RAG Everything**: Shoving all data into a vector store when half of it would be better served by structured queries (SQL) or API calls. Vector search is for semantic similarity — use the right tool for each data type.

**Agent When a Pipeline Will Do**: If the steps are predictable and don't depend on intermediate results, a hardcoded pipeline is simpler, faster, cheaper, and more debuggable than an agent.

**Ignoring LLM Costs Until the Bill Arrives**: At high volume, inference costs compound fast. Model cascading and caching should be in the architecture from day one for any high-volume feature.

**Prompt Engineering as Architecture**: Relying on prompt tweaks to compensate for missing retrieval, poor data quality, or wrong model choice. Fix the architecture first — prompts should refine behavior, not compensate for structural problems.

**Treating LLM Output as Trusted**: LLMs hallucinate. Any LLM output that drives critical decisions (financial transactions, medical advice, access control) needs validation — either programmatic (schema checks, business rule verification) or human-in-the-loop.

**Premature Fine-Tuning**: Jumping to fine-tuning before exhausting prompt engineering and RAG. Fine-tuning adds training data curation, compute cost, and retraining cycles. Often a better prompt or better retrieval achieves the same result with far less maintenance burden.

**Hardcoding Model Versions**: Pinning to a specific model version without a migration strategy. Models get deprecated, pricing changes, and better options emerge. Design for model portability from day one.

---
name: llm-app-design
description: |
  Provider-neutral LLM application design: prompt engineering, tool use, RAG, agent patterns, evaluation, and production concerns.
  Use when: designing an AI feature or product (chatbot, copilot, agent, RAG system, semantic search, classification, extraction), deciding whether to use an LLM at all, structuring system prompts, designing tool/function-calling schemas, planning a RAG pipeline, picking an agent architecture, setting up evals before shipping, or reasoning about latency/cost/reliability of LLM features. Also trigger on "AI feature", "LLM app", "chatbot", "copilot", "agent", "RAG", "retrieval augmented", "prompt engineering", "eval", "LLM-as-judge", "tool use", "function calling", "semantic search", "fine-tune vs prompt".
  Do not use for: provider-specific SDK mechanics (use claude-api for Anthropic, vercel:ai-sdk for multi-provider Vercel apps), tracing/observability setup (use posthog:instrument-llm-analytics or sentry:sentry-setup-ai-monitoring), or pure ML/training.
  Workflow: software-architecture (system design) → this skill (LLM-specific patterns, decision framework, evals) → claude-api | vercel:ai-sdk (implementation).
references:
  - references/prompting.md
  - references/tool-use.md
  - references/rag.md
  - references/agents.md
  - references/evaluation.md
  - references/production.md
---

# LLM Application Design

A design skill, not a coding skill. It helps you decide **what to build, how to structure it, and how to know if it works** — before you touch an SDK.

## The first question: do you need an LLM?

LLMs are the right tool when the problem has:

- **Open-ended language** — input or output is free-form prose, where hand-coded rules would miss cases.
- **Fuzzy matching or synthesis** — combining or summarizing information that isn't cleanly structured.
- **Novel inputs** — the full input space can't be enumerated, so pattern recognition beats exhaustive rules.

They are the wrong tool when:

- A regex, SQL query, or deterministic function would produce the same answer faster and cheaper.
- Correctness is safety-critical and the model's confidence can't be verified (payments, medical dosing, legal filings without review).
- The output is a simple classification with sufficient training data — a small classifier is usually faster, cheaper, and more reliable.

If you can solve 80% of the task deterministically and only use the LLM for the residual 20%, that's almost always the right architecture. Pre-filter with code, let the model handle the ambiguous cases, post-validate the output.

## The four layers of any LLM app

Every LLM feature decomposes into the same four layers. Design them explicitly — skipping any of them is how systems ship and then degrade silently.

1. **Context layer** — what the model sees: system prompt, user input, retrieved documents, tool results, conversation history. The job here is relevance and cost: get the right tokens in, keep irrelevant tokens out.
2. **Reasoning layer** — how the model thinks: single-shot vs multi-step, chain-of-thought, tool-calling loops, agent planning. The job is matching the task's shape to the model's strengths.
3. **Output layer** — what comes back: free text, structured JSON, tool calls, streaming. The job is making the output usable by downstream code without a second guessing step.
4. **Evaluation layer** — how you know it works: golden examples, LLM-as-judge, A/B tests, production monitoring. The job is catching regressions before users do.

Most "my LLM app is flaky" problems trace back to a missing or vague layer. If you can't answer "what's in the context, how does it reason, what's the output contract, and how do I measure quality?" in one sentence each, the design isn't ready to implement.

## Picking the shape

Pick the simplest shape that solves the task. Upgrading to a more complex shape is cheap; downgrading from one is a rewrite.

| Task shape | Right architecture | When to upgrade |
|---|---|---|
| Classify, extract, rewrite, summarize | Single prompt, structured output | Never — if this works, stop |
| Answer from a knowledge base | RAG: retrieve → augment → generate | Multi-hop questions need agent retrieval |
| Call external systems (search, DB, API) | Tool use / function calling | Multi-tool planning needs an agent loop |
| Multi-step reasoning over a plan | Agent: plan → act → observe → repeat | Most tasks don't actually need this |
| Multiple specialized roles collaborating | Multi-agent / orchestrator-worker | Only when one agent demonstrably can't do it |

Read `references/prompting.md` before designing any shape — prompt structure underlies all of them. Then jump to the shape-specific reference:

- `references/tool-use.md` — tool/function-calling design
- `references/rag.md` — retrieval architecture, chunking, hybrid search, re-ranking
- `references/agents.md` — agent loops, planning, safety rails
- `references/evaluation.md` — eval strategies for all shapes
- `references/production.md` — latency, cost, caching, rate limits, observability

## The design flow

Follow this sequence when designing a new LLM feature. Skipping steps is a false economy — each one takes minutes and saves hours of rework.

**1. Name the task in one sentence.**
"Given X, produce Y, so that Z." If you can't, the task isn't defined well enough to prompt. Example: "Given a customer support ticket, produce a category label and confidence, so that we route high-confidence tickets automatically."

**2. Write 5–10 input/output examples by hand.**
This is your first eval set. If you can't write them, the task is underspecified. If writing them is tedious but possible, congratulations — the LLM is probably the right tool. If writing them feels ambiguous (you'd label things differently on different days), that ambiguity will show up in the model's output too — spec the edge cases first.

**3. Decide the output contract.**
Structured (JSON schema, regex-parseable) or free-form? Structured outputs cost more tokens but cut the downstream validation burden. For anything a program will consume, use structured. For anything a human will read, free-form is fine.

**4. Pick the shape (table above).** Start with the simplest. Don't add an agent because it feels modern — add one when a simpler shape demonstrably fails your eval set.

**5. Write the system prompt.** Role, task, constraints, output format, examples. See `references/prompting.md`.

**6. Run your hand-written examples.** If it passes, expand the eval set. If it fails, read `references/evaluation.md` for how to diagnose.

**7. Plan production concerns.** Before shipping: caching strategy, rate limiting, cost estimation, latency budget, error handling, observability. See `references/production.md`.

## Anti-patterns to avoid

**Prompt stuffing.** Cramming every edge case into the system prompt as a bullet list. LLMs weight long prompts unevenly — the 47th "always do X" gets ignored. Use structure (sections, examples, clear roles) instead of volume.

**No evals.** Iterating on prompts by vibes. Without a fixed eval set, every "fix" can silently break a previous case. You cannot ship an LLM feature responsibly without one — even 10 hand-written examples beat zero.

**Over-agentifying.** Wrapping a single-prompt task in an agent loop because agents are trendy. Agents are multiplicatively more expensive, slower, and harder to debug. Use them only when the task genuinely requires tool-use planning the model has to figure out at runtime.

**Trusting structured output without validation.** Even with JSON mode or schema-constrained decoding, models occasionally drift. Validate every structured output and define recovery (retry, fallback, escalate) before shipping.

**Logging nothing.** LLM apps generate latent failure modes: hallucinations, drift after a model update, quality regression from a prompt tweak. Without traces, you find out from users. Wire observability from day one — it costs almost nothing and saves everything.

**Mixing design and implementation.** Deciding "we'll figure out the prompt while we code" leads to prompts shaped like the first thing that compiled. Design the prompt, the output contract, and the eval set *before* opening the SDK.

## Handoff to implementation

Once the design is locked:

- **Anthropic SDK (Python/TS)** → `claude-api` plugin skill
- **Multi-provider via Vercel** → `vercel:ai-sdk` plugin skill
- **Instrumentation** → `posthog:instrument-llm-analytics` or `sentry:sentry-setup-ai-monitoring`
- **Architecture doc** → `software-architecture` skill (if the LLM feature is part of a larger system)

This skill's job ends where the implementation SDK begins.

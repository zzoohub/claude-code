# Cost Reference

Pricing data for architecture cost estimation. **Last verified: March 2026.** Prices change — verify current rates before committing to cost-sensitive decisions.

---

## Cloudflare Services

All CF developer platform services require or benefit from the **Workers Paid plan ($5/mo per account)**.

| Service | Free Tier | Paid (Workers Paid $5/mo) | Watch |
|---|---|---|---|
| **Workers** | 100K req/day, 10ms CPU | 10M req/mo + 30M CPU-ms included. $0.30/M req, $0.02/M CPU-ms overage | Free resets daily; paid monthly. 30s CPU on paid. |
| **Durable Objects** | 100K req/day, 5 GB storage | 1M req/mo included, $0.15/M extra. 400K GB-s/mo, $12.50/M GB-s extra | Use Hibernatable DOs to avoid idle charges |
| **R2** | 10 GB storage, 1M Class A, 10M Class B ops/mo | $0.015/GB-mo, $4.50/M Class A, $0.36/M Class B. **Zero egress always** | Zero egress is the key differentiator vs S3 |
| **KV** | 100K reads/day, 1K writes/day, 1 GB | $0.50/M reads, $5.00/M writes, $0.50/GB-mo | Eventually consistent. Daily limits on free |
| **D1** | 5M rows read/day, 100K written/day, 5 GB | $0.001/M rows read, $1.00/M rows written, $0.75/GB-mo | Extremely cheap for read-heavy workloads |
| **Queues** | 10K ops/day | 1M ops/mo included, $0.40/M extra | 1 message lifecycle ~3 ops (write+read+delete) |
| **Workflows** | Same as Workers free | Same as Workers pricing + $0.20/GB-mo engine storage | Billed through Workers billing |
| **Vectorize** | 30M queried dims/mo, 5M stored dims/mo | 50M queried + 10M stored included, $0.01/M queried, $0.05/100M stored | Billed by dimensions, not vectors |
| **Workers AI** | 10K Neurons/day | $0.011/1K Neurons | Cost varies by model size |
| **AI Gateway** | Free core features, 100K logs/mo | 1M logs/mo on paid. Unified Billing for third-party model usage | No overage — hard cap on logs |
| **CF Images** | None | $5/100K images stored/mo, $1/100K delivered/mo | Per-image, not per-byte |
| **CF Stream** | None standalone | $5/1K min stored, $1/1K min delivered | Billed by duration, not file size. Ingress free |

---

## External Services

| Service | Free Tier | First Paid Tier | Watch |
|---|---|---|---|
| **Neon** | 100 CU-hrs/project/mo, 0.5 GB storage, 20 projects | **Launch $5/mo**: $0.106/CU-hr, $0.35/GB-mo storage, 7-day PITR | Post-Databricks price drop: storage 80% cheaper |
| **Supabase** | 500 MB DB, 50K MAU, 1 GB file storage, 2 projects | **Pro $25/mo**: 8 GB DB, 100K MAU, 100 GB storage | Free projects pause after 7 days inactivity |
| **Sentry** | 5K errors/mo, 10K perf units, 1 user | **Team $29/mo**: 50K errors, unlimited users | Error overage: $0.00029/event |
| **PostHog** | 1M events, 5K replays, 1M flag requests, 100K error events/mo | Usage-based: ~$0.00005/event, $0.005/replay. Free allowance persists on paid | 90%+ companies stay on free. Hard billing caps available |
| **Resend** | 3K emails/mo | **Pro $20/mo**: 50K emails. Marketing Pro $40/mo: 5K contacts | Daily send limits on free |
| **Stripe** | No monthly fee | 2.9% + $0.30/transaction (US cards). +0.5% international | $15 per dispute. Refunds don't return fee |
| **Better Auth** | **Fully free, MIT open source** | N/A — self-hosted only | Cost = your DB + server hosting. No MAU billing |
| **Axiom** | 500 GB/mo ingest, 30-day retention | **Pro $25/mo**: 2 TB/mo ingest, 60-day retention | Unified logs + traces + metrics. Default observability backend |

---

## Solopreneur Cost Scenarios

### Launch (~100 DAU)

Most services stay within free tiers at this scale.

| Component | Estimated Monthly Cost |
|---|---|
| CF Workers Paid plan | $5 |
| Neon (light usage, scale-to-zero) | $0 (free tier) |
| R2 (< 10 GB) | $0 (free tier) |
| Sentry | $0 (free tier) |
| PostHog | $0 (free tier) |
| Resend (< 3K emails) | $0 (free tier) |
| Domain + DNS (Cloudflare) | ~$10-15/yr |
| **Total** | **~$5-7/mo** |

### Growth (~1K DAU)

| Component | Estimated Monthly Cost |
|---|---|
| CF Workers Paid (10-50M req) | $5 + $0-12 overage |
| Neon Launch (active compute) | $5-15 |
| R2 (10-50 GB) | $0-0.75 |
| Sentry Team (if > 5K errors) | $0-29 |
| PostHog (if > 1M events) | $0-20 |
| Resend Pro (if > 3K emails) | $0-20 |
| LLM API costs (if AI features) | $10-200+ (highly variable) |
| **Total (no AI)** | **~$10-50/mo** |
| **Total (with AI)** | **~$20-250/mo** |

### Cost Traps to Watch

- **LLM inference** dominates spend at scale — add model cascading and caching early
- **Durable Objects idle duration** — use Hibernatable DOs
- **Supabase Pro** jumps to $25/mo per project (vs Neon's $5/mo)
- **Axiom Pro** is $25/mo — free tier (500GB) covers most solopreneur projects
- **Stripe disputes** cost $15 each regardless of outcome

---

## Notable Pricing Changes (2025-2026)

- **Neon**: Post-Databricks acquisition — storage 80% cheaper ($1.75 → $0.35/GB-mo), free compute doubled
- **CF Queues**: Available on free plan since Feb 2026
- **CF AI Gateway**: Unified Billing launched — pay third-party model usage on CF invoice
- **PostHog**: Free survey responses increased 250 → 1,500/mo. Added error tracking (100K free)
- **Sentry**: Aug 2025 restructured base quotas. Added Sentry Logs product

---

## AI / LLM API Costs

Pricing varies dramatically across model tiers. **Always verify current pricing** — providers update rates frequently, often with significant reductions.

### Cost Tiers (approximate ranges)

| Tier | Input (per 1M tokens) | Output (per 1M tokens) | Examples | Use Case |
|---|---|---|---|---|
| **Frontier** | $10-20 | $30-80 | Claude Opus, GPT-4.5, Gemini Ultra | Complex reasoning, research, multi-step agents |
| **Balanced** | $2-5 | $8-20 | Claude Sonnet, GPT-4o, Gemini Pro | Default for most production features |
| **Fast/Cheap** | $0.10-1.00 | $0.25-5.00 | Claude Haiku, GPT-4o-mini, Gemini Flash | Classification, extraction, high-volume tasks |
| **Embedding** | $0.01-0.10 | N/A | text-embedding-3-small/large, Cohere embed | RAG, semantic search, similarity |
| **Edge inference** | Per-neuron pricing | Varies | CF Workers AI | Low-latency edge inference, no external API call |

### Monthly Cost Estimation

Formula: `monthly_cost = (avg_input_tokens + avg_output_tokens) × requests_per_day × 30 × price_per_token`

| Scenario | Model Tier | Requests/Day | Avg Tokens (in+out) | Est. Monthly Cost |
|---|---|---|---|---|
| Light AI feature (classification) | Fast | 500 | 500 | $1-5 |
| Chat / copilot (moderate use) | Balanced | 1,000 | 2,000 | $50-150 |
| RAG Q&A (knowledge base) | Balanced | 2,000 | 3,000 | $100-400 |
| Content generation (heavy) | Balanced | 5,000 | 4,000 | $300-1,000 |
| Agent workflows (complex) | Frontier | 500 | 10,000 | $200-800 |

### Cost Optimization Impact

| Strategy | Typical Reduction | Effort |
|---|---|---|
| Model cascading (cheap model first) | 70-87% | Medium |
| Semantic caching | 30-70% | Medium |
| Prompt optimization (trim context) | 15-30% | Low |
| Batch API (non-real-time) | ~50% | Low |

### Key Cost Traps

- **Long system prompts**: A 4,000-token system prompt on every request at 10K req/day = 1.2B input tokens/month
- **Vision/multimodal**: Image tokens cost 10-50x text. Resize images before sending
- **Agent loops**: An agent taking 15 tool-call steps uses 15x the tokens of a single call. Set step limits
- **Embedding re-indexing**: Re-embedding entire corpus on model change. Plan embedding model switches carefully

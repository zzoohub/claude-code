# UX Patterns for AI Features

UX considerations specific to LLM/AI-powered features. AI output is non-deterministic; classic loaded/error/empty states aren't enough.

## Streaming output

Token-by-token streaming is the baseline for chat/copilot UI in 2026. Patterns:

- **Time-to-first-feedback**: for fast-start models, show first token within ~1s. For reasoning models that deliberately think before answering, don't force a fake token — show a labeled `Thinking…` state instead. Either way, never leave a bare spinner: a typing indicator or a thinking state implies "working now".
- **Stop button** must be visible during streaming and actually cancel the request server-side (not just hide the UI).
- **Partial-state recovery**: if streaming fails mid-response, keep the partial text visible with a "regenerate" or "continue" affordance — never silently truncate.
- **Markdown rendering during stream**: render incrementally (don't wait for full response). Use a streaming markdown parser, not full re-parse per token.
- **Auto-scroll with break**: auto-scroll while streaming, but stop auto-scroll the moment the user manually scrolls up (they're reading).

### Reasoning / thinking display

For models that produce extended reasoning before the answer:

- Show a **collapsible "Thinking" panel**, collapsed by default, that the user can expand to inspect the reasoning. Don't bury the final answer below a wall of raw chain-of-thought.
- Summarize long reasoning ("Considered 3 approaches…") rather than dumping every token.
- Make the transition from thinking → answer visible so the user knows the real response has started.

### Artifacts / canvas

For long or structured output (code, documents, tables), render it in a **side panel / canvas** outside the chat transcript, not inline:

- The transcript stays scannable; the artifact is editable/copyable/versionable in place.
- Stream into the artifact; keep a short summary in the chat ("Drafted the spec →").

### Interruptible / steerable generation

- Let the user **edit and resteer mid-generation** (or immediately after stop) without losing the partial output — not just stop-and-restart from scratch.
- Preserve the conversation so a redirect ("shorter", "use Python instead") continues rather than discards.

## Citations and provenance

If the AI is grounded on documents (RAG), surface the source:

- Inline citation markers (`[1]`, `[Source]`) clickable to the underlying chunk
- **Span-level attribution**: where it matters (high-stakes, dense answers), highlight which sentence/claim maps to which source rather than only a trailing `[1]` at the end of the whole answer
- **Per-claim grounding, not one answer-level badge**: a single response can be partly grounded and partly model-generated — mark grounded claims distinctly from ungrounded ones rather than stamping the whole answer "grounded"
- **Conflicting sources**: when retrieved sources disagree, surface the conflict ("Source A says X, Source B says Y") instead of silently picking one
- **Verify cited-but-unsupported**: a citation that doesn't actually support the claim is a distinct, common failure. Where feasible, check that the cited span supports the statement, and let users flag "this citation doesn't match"
- Distinguish **grounded answers** (with citations) from **unsupported generations** visually (subtle badge or disclaimer)
- Allow users to click through to the source page/document
- Show retrieval freshness if relevant ("Indexed 2 days ago")

## Agent transparency

When the model takes actions (calls tools, modifies data):

- Show **what the model is doing in real time** (Action: searching docs → reading file X → calling API Y), not just final output. Users tolerate longer waits when they see progress.
- **Confirmation gates** for destructive or irreversible actions (delete, send, charge, deploy). The model proposes; the user confirms. Never silent execution for these.
- **Action log** — keep a scrollable transcript of tool calls and results; let users inspect any step.
- **Cost / quota indicator** if the user is on a metered plan, so a long agent run doesn't quietly burn their budget.

## Trust calibration

Users over-trust confident-sounding wrong answers and under-trust hedged correct ones. Design for calibration:

- **Confidence cues** when available — prefer the model's own stated hedging ("I'm not sure, but…") and more robust signals: retrieval coverage (grounded vs ungrounded), a separate verifier/judge model, or self-consistency across samples. Treat token logprobs with caution — they're unavailable on several hosted APIs and correlate weakly with factual correctness (a model can be confidently wrong), so don't make a "Low confidence" badge depend on them alone.
- **Failure modes acknowledged**: ship a "Why might this be wrong?" affordance for high-stakes answers (medical, financial, legal).
- **Compare to non-AI baseline**: for new AI features, show what the prior (non-AI) workflow looked like so users can verify.

## Error and degraded states

AI features fail in shapes that don't map to classic 7 states:

| Failure | UX |
|---|---|
| Model returned empty / refused | Show what the model said, plus a "rephrase" suggestion. Never "Unknown error". |
| Rate limited / quota hit | Tell the user what they hit and when it resets. Offer to queue or downgrade. |
| Hallucinated tool call (tool doesn't exist) | Server-side validate; tell the user "Couldn't complete X — try Y" with a real next step. |
| Streaming cut off mid-response | Show "Connection interrupted" with a "Continue" affordance that re-prompts with the partial response as context. (True token-level resume needs server-side state retention; most stacks continue via re-prompt, which can seam — don't promise exact resumption you can't build.) |
| RAG returned no results | Don't generate ungrounded answer. Tell user "I couldn't find this in your documents" + offer to search the web or rephrase. |

## Editing and regeneration

Users will want to revise either the input or the output:

- **Edit prompt + regenerate** as a single affordance (not "delete this and retype")
- **Regenerate variations** ("Try again with different wording") for free-form generation
- **Compare versions** for non-trivial regenerations
- **Save / pin good responses** so users can return to them after further iteration

## Onboarding for AI features

- Show the model's **capabilities and limits** up front (one screen, not a wall of text)
- Provide **sample prompts** users can click to try — empty chat boxes intimidate
- Surface what data the model sees (especially in B2B / privacy-sensitive contexts)

## Accessibility for AI UI

- Streaming text needs `aria-live="polite"` so screen readers announce updates without spamming
- Don't rely on color alone for confidence/citation badges
- Keyboard shortcut to stop generation (Esc by convention)
- Provide a non-streaming "complete response" mode for users who can't track streaming output

## Anti-Patterns

| Anti-Pattern | Why It Fails | Alternative |
|--------------|--------------|-------------|
| Bare spinner during a long generation | No sense of progress; users assume it hung and bail | Streaming tokens, a typing indicator, or a labeled "Thinking…" state |
| Stop button only hides the UI | Request keeps running and billing; "stop" is a lie | Cancel server-side on stop |
| Silent truncation when streaming fails | User can't tell the answer is incomplete | Keep partial text + "continue"/"regenerate" affordance |
| Presenting a confident answer with no provenance | Users over-trust; can't verify | Citations + grounded/ungrounded distinction; hedging when uncertain |
| Citing a source that doesn't support the claim | Looks grounded, isn't — worse than no citation | Verify the cited span; let users flag mismatches |
| Auto-executing destructive/irreversible actions | One bad generation deletes/sends/charges | Confirmation gate: model proposes, user confirms |
| Dumping raw chain-of-thought above the answer | Buries the actual response | Collapsible "Thinking" panel, collapsed by default |
| Empty chat box with no guidance | Blank-page paralysis | Sample prompts + capability/limit summary |
| "Unknown error" on refusal/rate-limit/no-results | User has no next step | Say what happened + a concrete recovery action |

## Validation Checklist

Before shipping an AI feature:

- [ ] First feedback is fast (token <~1s for fast models, or a labeled "Thinking…" state for reasoning models) — never a bare spinner
- [ ] Stop button cancels the request server-side, not just visually
- [ ] Streaming failure keeps partial output + offers continue/regenerate
- [ ] Long/structured output renders in an artifact/canvas, not buried in the transcript
- [ ] Destructive or irreversible actions are gated behind explicit user confirmation
- [ ] Grounded answers cite sources; grounded vs ungrounded claims are visually distinct
- [ ] Citations are checked to actually support the claim (or users can flag mismatches)
- [ ] AI-specific error states (refusal, rate limit, hallucinated tool, RAG miss) each have a real next step — no "Unknown error"
- [ ] Confidence/uncertainty is surfaced honestly (model hedging / grounding / verifier — not logprobs alone)
- [ ] Streaming text uses `aria-live="polite"`; stop is keyboard-accessible (Esc); a non-streaming mode exists
- [ ] Capabilities, limits, and what data the model sees are shown up front

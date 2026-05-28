# UX Patterns for AI Features

UX considerations specific to LLM/AI-powered features. AI output is non-deterministic; classic loaded/error/empty states aren't enough.

## Streaming output

Token-by-token streaming is the default for chat/copilot UI in 2026. Patterns:

- **Show first token within 1s**; if the model is slow to start, show a typing indicator, not a spinner. Spinners imply waiting; typing implies "working now".
- **Stop button** must be visible during streaming and actually cancel the request server-side (not just hide the UI).
- **Partial-state recovery**: if streaming fails mid-response, keep the partial text visible with a "regenerate" or "continue" affordance — never silently truncate.
- **Markdown rendering during stream**: render incrementally (don't wait for full response). Use a streaming markdown parser, not full re-parse per token.
- **Auto-scroll with break**: auto-scroll while streaming, but stop auto-scroll the moment the user manually scrolls up (they're reading).

## Citations and provenance

If the AI is grounded on documents (RAG), surface the source:

- Inline citation markers (`[1]`, `[Source]`) clickable to the underlying chunk
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

- **Confidence cues** when available — "I'm not sure, but..." prefix from the model OR a UI tag like "Low confidence" based on the model's logprobs / classifier.
- **Failure modes acknowledged**: ship a "Why might this be wrong?" affordance for high-stakes answers (medical, financial, legal).
- **Compare to non-AI baseline**: for new AI features, show what the prior (non-AI) workflow looked like so users can verify.

## Error and degraded states

AI features fail in shapes that don't map to classic 7 states:

| Failure | UX |
|---|---|
| Model returned empty / refused | Show what the model said, plus a "rephrase" suggestion. Never "Unknown error". |
| Rate limited / quota hit | Tell the user what they hit and when it resets. Offer to queue or downgrade. |
| Hallucinated tool call (tool doesn't exist) | Server-side validate; tell the user "Couldn't complete X — try Y" with a real next step. |
| Streaming cut off mid-response | Show "Connection interrupted" with a "Continue" button that resumes from last token. |
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

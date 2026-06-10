---
name: security-checklists
description: |
  Security review checklists by domain, aligned with OWASP Top 10:2025. Use this skill for any security review, vulnerability assessment, code audit, OWASP Top 10 risk check, or penetration-testing prep — including partial reviews — covering auth, API, business logic, supply chain, cryptography, SSRF, misconfiguration, logging, and AI/LLM security. Also use when the user mentions "security checklist", "vulnerability checklist", "OWASP check", "auth review", "crypto review", or "API audit". Scope is web / server / API and cloud / supply-chain; mobile-client-internal security (MASVS, jailbreak/root detection) and legal privacy-compliance (GDPR/CCPA) are out of scope. Do NOT use for: correctness bugs that survive CI — races, idempotency, cache invalidation, partial failure (use correctness-checklists); maintainability smells — coupling, cohesion, leaky abstractions (use maintainability-checklists); style/formatting (linters own those); or implementing the fixes.
---

# Security Checklists

Comprehensive security review checklists organized by domain. Each checklist includes specific patterns to detect, CWE references, and OWASP Top 10:2025 mapping.

## OWASP Top 10:2025 Coverage Map

| OWASP Category | Checklist File(s) |
|---------------|-------------------|
| A01: Broken Access Control | `references/auth.md`, `references/api.md`, `references/ssrf.md` |
| A02: Security Misconfiguration | `references/misconfiguration.md` |
| A03: Software Supply Chain Failures | `references/supply-chain.md` |
| A04: Cryptographic Failures | `references/crypto.md` |
| A05: Injection | `references/api.md` |
| A06: Insecure Design | `references/business-logic.md` |
| A07: Authentication Failures | `references/auth.md` |
| A08: Software or Data Integrity Failures | `references/supply-chain.md`, `references/api.md` (deserialization) |
| A09: Security Logging & Alerting Failures | `references/error-logging.md` |
| A10: Mishandling of Exceptional Conditions | `references/error-logging.md` |

_AI/LLM security is governed by the separate OWASP Top 10 for LLM Applications 2025 (LLM01–LLM10), not the web Top 10 above; see `references/llm-security.md` in the "When to Reference" table below._

## When to Reference

| Reviewing... | Read |
|--------------|------|
| Login, signup, session, JWT, OAuth, SAML/SSO, MFA, CSRF, cookies | `references/auth.md` |
| REST/GraphQL endpoints, input validation, XSS, path traversal, file upload, CORS, WebSocket, deserialization, reverse proxy / load balancer (request smuggling) | `references/api.md` |
| Payment, inventory, pricing, state machines, discounts, limits | `references/business-logic.md` |
| package.json, requirements.txt, Dockerfile, CI/CD, git | `references/supply-chain.md` |
| Encryption, hashing, key management, TLS, certificates | `references/crypto.md` |
| Headers, debug mode, default creds, cloud config, CORS, subdomain takeover, cache poisoning | `references/misconfiguration.md` |
| URL fetching, webhooks, callbacks, image/file proxy | `references/ssrf.md` |
| Error messages, logging, audit trails, alerting, exceptions | `references/error-logging.md` |
| LLM/AI integration, prompt handling, model output rendering | `references/llm-security.md` |

Most security reviews require reading **3-5 checklists**. When in doubt, read more rather than fewer.

## Quick Reference — Universal Red Flags

These auto-fail patterns apply everywhere regardless of domain:

```
□ Secrets in code, logs, or git history (CWE-798)
□ User input reaching shell, eval, or raw queries (CWE-78, CWE-89, CWE-94)
□ Missing ownership check before data access (CWE-639)
□ State-changing request without authenticity/origin verification — CSRF, missing signature/webhook check (CWE-345)
□ TLS/certificate verification disabled (CWE-295)
□ User-controlled URL in server-side request (CWE-918)
□ Sensitive data in error responses or logs (CWE-209, CWE-532)
□ Weak or deprecated cryptographic algorithm (CWE-327)
```

## Before You Report — Exploitability Discipline

A security checklist that cries wolf gets ignored. Before reporting a finding:

1. **Trace the source** — is the input actually attacker-controlled, or does it originate from config or a trusted service? Name the entry point.
2. **Check one layer up** — middleware authz, framework auto-escaping, schema validation, or a gateway control may already guard what looks unguarded locally. A guard that lives upstream is still a guard; cite it instead of flagging its local absence.
3. **Check context applicability** — webhook/cloud/storage items assume those features exist; don't apply bucket-policy findings to a CLI tool.
4. **State the precondition with the finding** — "exploitable when X" beats "vulnerable"; it gives the reader both the risk and the test.

## Review Output Contract

This is **Pass 1 (blocking)**, alongside `correctness-checklists`: a confirmed critical/high finding stops the commit until fixed or explicitly accepted with written justification.

```markdown
- **[Issue Name]** (CWE-XXX, OWASP A0X) — `file:line` — severity: critical | high | medium
  - Problem: [one line]
  - Exploit path: [who controls the input, what they reach — the precondition]
  - Fix: [specific remediation]
```

Severity = impact × exploitability: **critical** — remote compromise, auth bypass, secrets exposure, injection with attacker-controlled input; **high** — exploitable with preconditions, sensitive-data exposure; **medium** — hardening gaps (headers, rate limits, verbose errors). Medium escalates when findings chain (verbose error + IDOR = targeted exfiltration) — report chains explicitly.

---
name: z-security-checklists
description: |
  Comprehensive security checklists by domain, aligned with OWASP Top 10:2025. Covers authentication, API security, business logic, supply chain, cryptography, SSRF, security misconfiguration, error handling & logging, and AI/LLM security. Use this skill whenever performing a security review, vulnerability assessment, code audit, checking code for OWASP Top 10 risks, or preparing for penetration testing. Reference specific checklist files based on the domain being reviewed. Always use this skill alongside security review tasks — even partial reviews benefit from structured checklists. Also use when the user mentions "security checklist", "vulnerability checklist", "OWASP check", "auth review", "crypto review", "API audit", or any domain-specific security question.
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
| A05: Injection | `references/api.md`, `references/ssrf.md` |
| A06: Insecure Design | `references/business-logic.md` |
| A07: Authentication Failures | `references/auth.md` |
| A08: Software or Data Integrity Failures | `references/supply-chain.md` |
| A09: Security Logging & Alerting Failures | `references/error-logging.md` |
| A10: Mishandling of Exceptional Conditions | `references/error-logging.md` |

## When to Reference

| Reviewing... | Read |
|--------------|------|
| Login, signup, session, JWT, OAuth, MFA, cookies | `references/auth.md` |
| REST/GraphQL endpoints, input validation, file upload, CORS, WebSocket, deserialization | `references/api.md` |
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
□ State change without proper validation (CWE-345)
□ TLS/certificate verification disabled (CWE-295)
□ User-controlled URL in server-side request (CWE-918)
□ Sensitive data in error responses or logs (CWE-209, CWE-532)
□ Weak or deprecated cryptographic algorithm (CWE-327)
```

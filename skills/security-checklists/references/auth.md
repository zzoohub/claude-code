# Authentication & Authorization Security

> OWASP: A01 (Broken Access Control), A07 (Authentication Failures)

---

## Password Security

| Check | Why | CWE |
|-------|-----|-----|
| Strong adaptive hashing (bcrypt/argon2id) with proper cost factor | Rainbow tables, GPU cracking | CWE-916 |
| No password in logs, errors, responses, or URLs | Credential leakage | CWE-532 |
| Secure reset flow (expiring, single-use, random token) | Account takeover via reset | CWE-640 |
| Password change requires current password verification | Session hijack escalation | CWE-620 |
| Minimum password length enforced (>=8, ideally >=12) | Brute force feasibility | CWE-521 |
| Breached password check (Have I Been Pwned API or similar) | Credential stuffing with known passwords | CWE-521 |

**Patterns to catch:**
- Weak hash algorithms (MD5, SHA1, SHA256 without key stretching for passwords)
- Password field included in API responses or serialized user objects
- Reset tokens that don't expire or are reusable
- Reset token is user ID or email encoded in base64 (predictable)
- Password stored in plaintext or reversible encryption
- No minimum password complexity or length requirement
- Same error message not used for "user not found" vs "wrong password" (see Rate Limiting section)

---

## Multi-Factor Authentication (MFA)

| Check | Why | CWE |
|-------|-----|-----|
| TOTP implementation uses proper time window (30s, ±1 step) | Replay and timing attacks | CWE-308 |
| Recovery codes are single-use and securely stored | Recovery code reuse | CWE-308 |
| MFA cannot be silently disabled without re-authentication | MFA bypass via settings | CWE-306 |
| MFA challenge cannot be skipped by modifying client flow | Step-skipping attack | CWE-304 |
| Backup authentication method doesn't weaken MFA | Weakest link bypass | CWE-308 |
| SMS-based MFA discouraged (SIM swap vulnerability) | SIM swapping | CWE-308 |

**Patterns to catch:**
- TOTP secret transmitted to client after setup (should only display once during enrollment)
- MFA verification endpoint without rate limiting
- MFA status stored only in JWT/client without server-side verification
- Recovery flow that bypasses MFA entirely (e.g., email-only reset disables MFA)
- No re-authentication required before changing MFA settings

---

## Session Management

| Check | Why | CWE |
|-------|-----|-----|
| Server-side invalidation on logout | Token theft persistence | CWE-613 |
| Session ID regeneration after auth state change | Session fixation | CWE-384 |
| Concurrent session limits or notification | Account sharing, stolen sessions | CWE-613 |
| Idle timeout (15-30 min) + absolute timeout (8-24 hours) | Abandoned session hijack | CWE-613 |
| Separate long-lived token for remember-me | Reduced exposure window | CWE-613 |
| Session bound to user-agent and/or IP range | Session theft detection | CWE-384 |

**Patterns to catch:**
- Logout only clears client state, server still accepts token
- Same session ID before and after login
- No mechanism to invalidate all sessions ("log out everywhere")
- Session tokens in URL parameters (exposed in referrer headers, logs)
- Missing `Set-Cookie` security attributes (see Cookie Security below)

---

## Cookie Security

| Check | Why | CWE |
|-------|-----|-----|
| `HttpOnly` flag on session cookies | XSS cannot steal session | CWE-1004 |
| `Secure` flag on all sensitive cookies | Prevents transmission over HTTP | CWE-614 |
| `SameSite=Lax` or `Strict` on session cookies | CSRF mitigation | CWE-1275 |
| Cookie `Path` restricted to application scope | Reduces exposure surface | CWE-1004 |
| `__Host-` prefix for sensitive cookies | Prevents subdomain attacks | CWE-1004 |
| No sensitive data stored in cookies beyond session ID | Cookie theft exposure | CWE-315 |

**Patterns to catch:**
- Session cookie without `HttpOnly` (XSS can read it via `document.cookie`)
- Cookie set without `Secure` flag (sent over plain HTTP)
- `SameSite=None` without `Secure` (browser rejects, or enables cross-site)
- Token/user data stored in cookie instead of just session reference
- Cookie expiration set excessively long (months/years)

---

## JWT Security

| Check | Why | CWE |
|-------|-----|-----|
| Algorithm explicitly verified (whitelist, not blacklist) | Algorithm confusion attack ("none", HS256/RS256 swap) | CWE-327 |
| Short-lived access tokens (5-15 minutes) | Token theft window | CWE-613 |
| Refresh token rotation (new refresh token on each use) | Refresh token theft detection | CWE-613 |
| Sensitive claims verified server-side on every request | JWT tampering | CWE-345 |
| Token stored in httpOnly cookie, NOT localStorage | XSS token theft | CWE-922 |
| `iss`, `aud`, `exp` claims validated | Token misuse across services | CWE-345 |
| JWK/JWKS endpoint properly secured | Key confusion attacks | CWE-327 |

**Patterns to catch:**
- JWT verification without algorithm whitelist (`algorithms: ["RS256"]`)
- Long-lived access tokens (hours/days instead of minutes)
- Same refresh token valid after use (no rotation)
- Role/permissions stored only in JWT, not verified against DB
- Token stored in `localStorage` or `sessionStorage` (XSS accessible)
- JWT secret is a simple string (not cryptographically random, >=256 bits)
- Token in URL parameters or query strings
- Missing `exp` claim or very distant expiration

---

## OAuth / SSO

| Check | Why | CWE |
|-------|-----|-----|
| State parameter validated (tied to user session) | CSRF on OAuth flow | CWE-352 |
| PKCE for all public clients (and recommended for confidential) | Auth code interception | CWE-345 |
| Redirect URI strictly validated against allowlist | Open redirect to steal tokens | CWE-601 |
| Token exchange happens server-side | Token exposure to client | CWE-522 |
| ID token `nonce` validated | Replay attacks | CWE-345 |
| Scopes are minimal (principle of least privilege) | Over-privileged tokens | CWE-269 |

**Patterns to catch:**
- Missing state parameter check on callback
- Redirect URI from user input without strict allowlist matching
- Redirect URI validation using string prefix (allows `evil.com?redirect=good.com`)
- Access token handled in frontend JavaScript (implicit flow)
- Missing PKCE on mobile/SPA clients
- OAuth tokens stored without encryption at rest

---

## Authorization (Access Control)

| Check | Why | CWE |
|-------|-----|-----|
| Ownership verified before every data access | IDOR | CWE-639 |
| Role check on every protected endpoint (server-side) | Broken access control | CWE-285 |
| Default deny — explicit allow per endpoint | Forgotten endpoints exposed | CWE-276 |
| Indirect references where possible (UUIDs, not sequential IDs) | ID enumeration | CWE-639 |
| Horizontal privilege checked (user A can't access user B's data) | Horizontal escalation | CWE-639 |
| Vertical privilege checked (regular user can't access admin) | Vertical escalation | CWE-269 |
| Resource-level permissions, not just endpoint-level | Granular access bypass | CWE-285 |

**Patterns to catch:**
- Data fetched by ID without ownership check: `db.find(req.params.id)`
- Role check only on frontend (hidden UI elements, not enforced server-side)
- New endpoints inherit no protection by default
- Sequential integer IDs exposed in URLs (`/api/users/123`)
- Admin endpoints rely only on separate URL path, no role verification
- Missing permission check on sub-resources (user owns order, but can they see its invoice?)
- `isAdmin` or `role` field settable via API request body

---

## Rate Limiting & Brute Force

| Check | Why | CWE |
|-------|-----|-----|
| Strict limit on login endpoint (5-10 attempts / 15 min) | Credential stuffing | CWE-307 |
| Very strict limit on password reset (3-5 / hour) | Account enumeration | CWE-307 |
| Lockout or CAPTCHA after threshold | Automated attacks | CWE-307 |
| Timing-safe comparison for all credential checks | Timing-based enumeration | CWE-208 |
| Consistent error messages (same for "not found" and "wrong password") | User enumeration | CWE-203 |
| Rate limit by multiple dimensions (IP + account + fingerprint) | Distributed brute force | CWE-307 |

**Patterns to catch:**
- No rate limit on login/register/reset endpoints
- Different error messages: "user not found" vs "wrong password"
- Early return on user lookup failure (timing difference reveals existence)
- Rate limit only by IP (bypassed with IP rotation)
- Registration endpoint allows unlimited account creation
- OTP/MFA code verification without attempt limit
- Password reset email sent regardless of account existence (timing difference)

# Cryptographic Failures

> OWASP: A04 (Cryptographic Failures)

---

## Password & Credential Hashing

| Check | Why | CWE |
|-------|-----|-----|
| Bcrypt (cost ≥12) or Argon2id for passwords | GPU/ASIC resistance | CWE-916 |
| NEVER MD5, SHA1, SHA256 alone for passwords | No key stretching, rainbow tables | CWE-328 |
| Unique salt per password (auto-handled by bcrypt/argon2) | Pre-computation attacks | CWE-916 |
| API tokens hashed with SHA-256 before storage | Token theft from DB | CWE-256 |
| Timing-safe comparison for all credential checks | Timing side-channel | CWE-208 |

**Patterns to catch:**
- `md5(password)`, `sha1(password)`, `sha256(password)` for password storage
- `hashlib.md5`, `crypto.createHash('md5')` used for security purposes
- Custom hash function or "encryption" for passwords
- Same salt for all users (global salt)
- String comparison (`===`, `==`) instead of `crypto.timingSafeEqual` for tokens
- Password stored with reversible encryption (AES) instead of hashing

---

## Encryption (At Rest)

| Check | Why | CWE |
|-------|-----|-----|
| AES-256-GCM or ChaCha20-Poly1305 for symmetric encryption | Authenticated encryption required | CWE-327 |
| NEVER ECB mode (patterns visible in ciphertext) | Pattern preservation | CWE-327 |
| Unique IV/nonce per encryption operation | IV reuse breaks confidentiality | CWE-329 |
| Encryption keys stored in KMS/HSM, not in code or config files | Key exposure | CWE-321 |
| Key rotation mechanism exists and is exercised | Compromised key longevity | CWE-324 |
| Sensitive database columns encrypted at application level | DB breach protection | CWE-311 |

**Patterns to catch:**
- `AES-ECB` mode anywhere: `cipher = AES.new(key, AES.MODE_ECB)`
- `DES`, `3DES`, `RC4`, `Blowfish` (deprecated algorithms)
- Hardcoded encryption key in source code: `key = "my-secret-key-123"`
- IV/nonce set to static value or zeros: `iv = b'\x00' * 16`
- Same key used for encryption and authentication
- Encryption without authentication (AES-CBC without HMAC)
- Key derived from password without proper KDF (see Key Derivation below)
- `crypto.createCipher()` in Node.js (deprecated, weak key derivation)

---

## Encryption (In Transit)

| Check | Why | CWE |
|-------|-----|-----|
| TLS 1.2+ enforced (TLS 1.0, 1.1 disabled) | Known protocol attacks | CWE-326 |
| Strong cipher suites only (no RC4, DES, NULL, EXPORT) | Weak cipher downgrade | CWE-326 |
| Certificate validation enabled (never disabled) | MITM attacks | CWE-295 |
| HSTS header with long max-age (≥31536000) | Protocol downgrade | CWE-319 |
| Internal service communication also encrypted | Lateral movement after breach | CWE-319 |
| Certificate pinning for mobile apps (when appropriate) | CA compromise | CWE-295 |

**Patterns to catch:**
- `verify=False` (Python requests), `rejectUnauthorized: false` (Node.js)
- `InsecureSkipVerify: true` (Go), `@insecure` annotation
- `NODE_TLS_REJECT_UNAUTHORIZED=0` environment variable
- HTTP URLs for API calls to external services (no TLS)
- Self-signed certificates accepted in production
- TLS configuration allowing SSLv3 or TLS 1.0
- Missing HSTS header or very short max-age

---

## Key Derivation

| Check | Why | CWE |
|-------|-----|-----|
| PBKDF2 (≥600,000 iterations), scrypt, or Argon2 for password-derived keys | Brute force resistance | CWE-916 |
| HKDF for deriving multiple keys from shared secret | Proper key separation | CWE-327 |
| High entropy salt (≥128 bits, cryptographically random) | Pre-computation resistance | CWE-916 |
| Iteration count reviewed annually (increases with hardware) | Moore's law | CWE-916 |

**Patterns to catch:**
- `PBKDF2` with <100,000 iterations (OWASP 2023 minimum: 600,000 for SHA-256)
- Direct use of password as encryption key: `AES(password, data)`
- Single-round hash as key derivation: `key = sha256(password)`
- Salt shorter than 128 bits or non-random salt
- Same derived key used for multiple purposes without HKDF expand step

---

## Random Number Generation

| Check | Why | CWE |
|-------|-----|-----|
| Cryptographic RNG for all security values | Predictable outputs | CWE-338 |
| `Math.random()` NEVER used for security | Not cryptographic, predictable | CWE-330 |
| Sufficient entropy for tokens (≥128 bits, ideally 256) | Brute force feasibility | CWE-334 |
| UUIDs use v4 (random) for security purposes, not v1 (time-based) | Predictable UUIDs | CWE-330 |

**Patterns to catch:**
- `Math.random()` for tokens, IDs, secrets, session IDs, nonces
- `random.random()` (Python) for security (use `secrets` module)
- `rand.Intn()` (Go) without `crypto/rand` for security values
- Short tokens: `Math.random().toString(36)` (only ~48 bits entropy)
- UUID v1 used for session tokens (contains timestamp and MAC address)
- Seed from predictable source (`time.Now()`, process ID)
- Custom random function ("roll your own")

**Correct alternatives:**
- JavaScript: `crypto.randomUUID()`, `crypto.getRandomValues()`
- Python: `secrets.token_hex()`, `secrets.token_urlsafe()`
- Go: `crypto/rand.Read()`
- Java: `SecureRandom`
- Ruby: `SecureRandom.hex`

---

## Digital Signatures & Verification

| Check | Why | CWE |
|-------|-----|-----|
| RSA keys ≥2048 bits (ideally 4096) | Key factoring | CWE-326 |
| ECDSA with P-256 or Ed25519 (preferred over RSA for new systems) | Modern standards | CWE-327 |
| Signature verified before trusting signed data | Unsigned data accepted | CWE-347 |
| No signature algorithm confusion (JWT "none" alg) | Algorithm downgrade | CWE-327 |
| Webhook/callback signatures verified with constant-time comparison | Forged payloads | CWE-345 |

**Patterns to catch:**
- RSA key <2048 bits
- DSA keys (deprecated, use ECDSA or Ed25519)
- Signature verification optional or skipped on error
- JWT without algorithm whitelist: `jwt.verify(token, key)` without `algorithms` param
- HMAC comparison with `==` instead of constant-time function
- Signature covers only part of the payload (unsigned fields can be modified)

---

## Certificate Management

| Check | Why | CWE |
|-------|-----|-----|
| Certificates auto-renewed (Let's Encrypt, cert-manager) | Expiration outage | CWE-298 |
| Certificate revocation checking enabled (OCSP stapling) | Compromised cert usage | CWE-299 |
| Wildcard certificates scoped appropriately | Over-broad trust | CWE-295 |
| Private keys have restricted file permissions (0600) | Key theft | CWE-732 |
| No self-signed certificates in production | Trust chain validation bypass | CWE-295 |

**Patterns to catch:**
- Certificate files with world-readable permissions (`chmod 644 server.key`)
- Private keys stored in git repository (even `.gitignore`d, check history)
- Self-signed certificates in production deployment configurations
- Certificate expiration >1 year (industry standard now 398 days max)
- No automated certificate renewal process

---

## Homegrown Crypto Detection

| Check | Why | CWE |
|-------|-----|-----|
| No custom encryption algorithms | Unaudited, likely broken | CWE-327 |
| No custom hash functions for security | Not cryptographically proven | CWE-328 |
| No XOR-based "encryption" | Trivially reversible | CWE-327 |
| No Base64 treated as encryption | Encoding is not encryption | CWE-311 |
| Standard well-maintained libraries used (libsodium, OpenSSL, crypto) | Audited implementations | CWE-327 |

**Patterns to catch:**
- Custom `encrypt()` function that XORs input with a key
- Base64 encoding called "encryption" or used to "protect" sensitive data
- ROT13, Caesar cipher, or substitution cipher for any security purpose
- Custom padding implementation (use PKCS7 from library)
- Re-implementation of standard algorithms (custom AES, custom SHA)
- "Obfuscation" passed off as encryption (string reversal, character shifting)
- `btoa()` / `atob()` used to "secure" data

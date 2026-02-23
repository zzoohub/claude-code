# Supply Chain Security

> OWASP: A03 (Software Supply Chain Failures), A08 (Software or Data Integrity Failures)

---

## Dependency Management

| Check | Why | CWE |
|-------|-----|-----|
| Lock file present and committed (package-lock.json, yarn.lock, poetry.lock, Cargo.lock) | Reproducible builds, tamper detection | CWE-829 |
| Lock file integrity — no manual edits, matches manifest | Lock file manipulation | CWE-345 |
| No wildcard or range versions in production deps | Unexpected updates | CWE-829 |
| `npm audit` / `pip audit` / `cargo audit` integrated in CI | Known vulnerability detection | CWE-1395 |
| Unused dependencies removed | Unnecessary attack surface | CWE-1104 |
| Private registry configured correctly (scoped packages) | Dependency confusion | CWE-427 |
| Dependencies pinned to exact versions or hash-verified | Supply chain tampering | CWE-345 |

**Patterns to catch:**
- Missing lock file entirely (`.gitignore` includes lock file)
- Version ranges in production: `"lodash": "^4.0.0"` (allows 4.x auto-update)
- Dependencies with known critical CVEs (check `npm audit --production`)
- Packages with very few downloads or very recent publication (typosquatting risk)
- Private package names that could collide with public registry (dependency confusion)
- `package.json` has `"*"` or `"latest"` as version
- Lock file diverges from manifest (edited manually to pin different version)
- `postinstall` scripts in dependencies that execute arbitrary code

---

## Dependency Confusion & Typosquatting

| Check | Why | CWE |
|-------|-----|-----|
| Private packages use scoped names (`@org/package`) | Public package name collision | CWE-427 |
| Registry priority configured (private first, public fallback) | Registry confusion | CWE-427 |
| Package names verified against known typosquatting patterns | Malicious lookalike packages | CWE-427 |
| `.npmrc` / `pip.conf` configured with explicit registry URLs | Registry misconfiguration | CWE-427 |

**Patterns to catch:**
- Internal package `utils` without scope (public `utils` package could override)
- No `.npmrc` defining registry for private scopes
- Package name differs by one character from popular package (`lodasb` vs `lodash`)
- `pip install` without `--index-url` or `--extra-index-url` properly configured
- `requirements.txt` or `setup.py` referencing internal packages without private index

---

## CI/CD Pipeline Security

| Check | Why | CWE |
|-------|-----|-----|
| Secrets in environment variables, not hardcoded in pipeline config | Secret exposure in logs/repo | CWE-798 |
| Pipeline runs with least privilege | Compromised pipeline escalation | CWE-269 |
| Build artifacts signed or checksummed | Tampered artifact injection | CWE-345 |
| Third-party actions/orbs pinned to commit SHA, not tag | Tag mutation attack | CWE-829 |
| `pull_request_target` workflows don't checkout PR code | Arbitrary code execution from forks | CWE-94 |
| Self-hosted runners isolated and ephemeral | Runner compromise persistence | CWE-269 |
| Pipeline secrets scoped per environment (dev/staging/prod) | Cross-environment leakage | CWE-798 |

**Patterns to catch (GitHub Actions specific):**
- `uses: actions/checkout@main` instead of `@SHA` (tag can be moved)
- `pull_request_target` with `actions/checkout` of PR HEAD (code injection from fork)
- `GITHUB_TOKEN` with write permissions when only read needed
- Secrets printed to logs: `echo ${{ secrets.API_KEY }}`
- Workflow triggered by `workflow_run` without proper filtering (chain attack)
- Cache poisoning: attacker PR populates cache, legitimate build uses it
- `if: github.event.pull_request.head.repo.fork == false` missing on sensitive steps

**Patterns to catch (general CI/CD):**
- Build script downloads and executes remote scripts: `curl ... | bash`
- Pipeline variables interpolated into shell commands (injection)
- No branch protection on deployment branches
- Deployment triggered without required reviews/approvals
- Artifact storage accessible without authentication
- Build cache shared across untrusted branches

---

## Container Security

| Check | Why | CWE |
|-------|-----|-----|
| Minimal base image (distroless, alpine, slim) | Reduced attack surface | CWE-1104 |
| Non-root user in container | Container escape escalation | CWE-250 |
| Multi-stage build (no build tools in production image) | Unnecessary tooling | CWE-1104 |
| Image vulnerability scanning in CI (Trivy, Snyk, Grype) | Known CVEs in base image | CWE-1395 |
| No secrets baked into image layers | Layer inspection reveals secrets | CWE-798 |
| Image tags immutable (use digest, not `latest`) | Image replacement attack | CWE-345 |
| Read-only filesystem where possible | Runtime tampering | CWE-276 |

**Patterns to catch:**
- `FROM node:latest` or `FROM python:3` (mutable tags)
- `USER root` or no `USER` directive (runs as root)
- `COPY . .` without `.dockerignore` (copies secrets, `.git`, etc.)
- `ENV API_KEY=xxx` or `ARG SECRET=xxx` in Dockerfile (visible in image layers)
- `RUN apt-get install -y curl wget netcat` in production image (unnecessary tools)
- Single-stage build with dev dependencies in final image
- `.env` files or private keys present in Docker build context
- `docker run --privileged` in deployment configuration

---

## Git Security

| Check | Why | CWE |
|-------|-----|-----|
| No secrets in git history (scan with gitleaks/truffleHog) | Historical secret exposure | CWE-798 |
| `.gitignore` covers `.env`, keys, credentials, build artifacts | Accidental commit prevention | CWE-798 |
| Pre-commit hooks for secret detection | Shift-left prevention | CWE-798 |
| Signed commits required for protected branches | Commit impersonation | CWE-345 |
| Branch protection enforced (reviews, status checks) | Unauthorized changes | CWE-269 |
| Force push disabled on main/production branches | History rewrite attack | CWE-269 |

**Patterns to catch:**
- `.env` file committed to repository
- AWS keys, private keys, or tokens in git history (even if removed in HEAD)
- `.gitignore` missing entries for common secret files (`.env.local`, `*.pem`, `credentials.json`)
- No branch protection rules on main branch
- Direct push to main allowed (no PR required)
- Merge commits from unknown or unverified contributors

---

## SBOM & Provenance

| Check | Why | CWE |
|-------|-----|-----|
| Software Bill of Materials (SBOM) generated for releases | Transparency, audit trail | CWE-1395 |
| Build provenance attestation (SLSA, Sigstore) | Tamper evidence | CWE-345 |
| License compliance checked (GPL contamination, etc.) | Legal risk | — |
| Transitive dependencies inventoried | Hidden vulnerability depth | CWE-1395 |
| Dependency update policy defined (auto-merge patches, review minors) | Update hygiene | CWE-1395 |

**Patterns to catch:**
- No SBOM generation in build pipeline
- No way to audit what went into a specific release
- Transitive dependencies not visible (only direct deps tracked)
- No automated dependency update tool (Dependabot, Renovate)
- Dependency updates ignored for months/years
- GPL-licensed code in proprietary project without compliance review

# Upstream & fork posture

`browse` is a **frozen vendored snapshot** of the `browse/` directory from
[garrytan/gstack](https://github.com/garrytan/gstack/tree/main/browse).

- **Upstream:** `https://github.com/garrytan/gstack` → `browse/`
- **Fork point:** added to this repo on **2026-03-16** (commit `4e2dde1`,
  "add browse skill").
- **Tracking policy:** this snapshot does **not** track upstream. There is no
  git remote, no submodule, and no sync script.

## Why it doesn't auto-sync

Upstream `gstack` is a large monorepo; `browse/` is one leaf that depends on a
parent CLI (`bin/gstack-config`, `bin/gstack-update-check`, a top-level
`VERSION` / `config.yaml`, a root `setup`). This fork vendored **only**
`browse/`, renamed its install path from `skills/gstack/browse/` to
`skills/browse/`, and dropped the parent. Because of that structural
divergence, `git merge` / `git subtree pull` are not mechanically possible —
any upstream pickup is a manual, file-by-file cherry-pick against a moving
target.

## What this fork deliberately dropped or changed vs upstream

- Deleted the gstack-CLI test suites (`test/gstack-config.test.ts`,
  `test/gstack-update-check.test.ts`) — they targeted parent scripts that were
  never vendored here.
- Removed `getRemoteSlug()` / `bin/remote-slug` (gstack project-registry
  machinery with no caller in this fork).
- Renamed the per-project state directory `.gstack/` → `.browse/`.
- Replaced the upstream doc-generation pipeline (`SKILL.md.tmpl` +
  `gen:skill-docs`) with a hand-maintained `SKILL.md` (keep its command tables
  in sync with `src/commands.ts`).
- Added a self-contained `./setup` (the upstream build lived in the gstack
  root `setup`).

## If you ever want a specific upstream fix

Browse-relevant upstream changes land in the gstack CHANGELOG under entries
like daemonization, WebSocket re-attach, idle-shutdown, and long-session memory.
Add the gstack remote, read `browse/` diffs since the fork point, and
cherry-pick by hand. Given this repo is otherwise pure-markdown skills, the
recommended default is to **stay frozen** and only pull a fix when you hit the
bug it addresses.

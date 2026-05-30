/**
 * find-browse — locate the browse binary.
 *
 * Compiled to browse/dist/find-browse (standalone binary, no bun runtime needed).
 * Outputs the absolute path to the browse binary on stdout, or exits 1 if not found.
 */

import { existsSync } from 'fs';
import { join } from 'path';
import { homedir } from 'os';

// ─── Binary Discovery ───────────────────────────────────────────

function getGitRoot(): string | null {
  try {
    const proc = Bun.spawnSync(['git', 'rev-parse', '--show-toplevel'], {
      stdout: 'pipe',
      stderr: 'pipe',
    });
    if (proc.exitCode !== 0) return null;
    return proc.stdout.toString().trim();
  } catch {
    return null;
  }
}

export function locateBinary(): string | null {
  const root = getGitRoot();
  const home = homedir();

  // Workspace-local takes priority (for development). Two dev layouts:
  if (root) {
    // (1) skill installed under .claude/ (plugin / managed layout)
    const localDotClaude = join(root, '.claude', 'skills', 'browse', 'dist', 'browse');
    if (existsSync(localDotClaude)) return localDotClaude;
    // (2) skill checked out directly under the repo (this repo's dev layout)
    const localBare = join(root, 'skills', 'browse', 'dist', 'browse');
    if (existsSync(localBare)) return localBare;
  }

  // Global fallback
  const global = join(home, '.claude', 'skills', 'browse', 'dist', 'browse');
  if (existsSync(global)) return global;

  return null;
}

// ─── Main ───────────────────────────────────────────────────────

function main() {
  const bin = locateBinary();
  if (!bin) {
    process.stderr.write('ERROR: browse binary not found. Run: cd <skill-dir> && ./setup\n');
    process.exit(1);
  }

  console.log(bin);
}

// Only run when executed directly (compiled binary / `bun run`), not when
// imported (e.g. by tests) — importing must not call process.exit.
if (import.meta.main) {
  main();
}

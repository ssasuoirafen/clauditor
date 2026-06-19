# Freshness subroutine

Shared routine for checking whether a file's content is still current. Referenced by
`${CLAUDE_PLUGIN_ROOT}/skills/audit-claude/references/checks/rules.md`,
`checks/claude-md.md`, and `checks/local-docs.md` (future). Apply per file being audited.

The caller sets `layer` and `path` on each Finding; this routine only specifies
`severity`, `action`, and `detail`.

## Steps

### 1. Intro/conclusion mismatch

Read the first 20 lines and the last 20 lines of the file.

If the introduction describes scope or content that the conclusion does not address,
or vice versa, the file may have been partially updated while the rest was left stale.

Emit: `severity: "low"`, `action: "flag"`,
`detail: "intro/conclusion mismatch - possible partial rewrite"`.

### 2. Code identifier staleness

Grep the file for inline references to code identifiers: table names, function names,
file paths, and module or class names cited in prose or code blocks. For each identifier
found, verify it still exists in the repo using Glob or Grep against the project path
from Baseline `project_path`.

Count identifiers that no longer exist in the repo.

If >=3 stale identifiers found:
emit `severity: "medium"`, `action: "flag"`,
`detail: "drift candidate: <N> stale identifiers (<id1>, <id2>, ...)"`.

### 3. Age without active TODO

Determine the file's last modification time via:

```bash
git -C <project_path> log -1 --format="%ci" -- <repo_relative_path>
```

Fallback if no git repo: OS stat (PowerShell `(Get-Item <path>).LastWriteTime` or
POSIX `stat -c%y <path>`).

If last modified >6 months ago AND the file contains none of the active lifecycle
markers below, flag as archival or deletion candidate.

Active lifecycle markers (search both English and common project-language equivalents):
- English: `TODO`, `WIP`, `DRAFT`
- Russian: `ЗАДАЧА:`, `ЧЕРНОВИК:`, `В РАБОТЕ:`

Emit: `severity: "low"`, `action: "flag"`,
`detail: "no edit in >6 months and no active lifecycle marker - archival or deletion candidate"`.

### 4. Date stamps

Grep the file for date-stamp phrases matching any of:
- `as of YYYY-MM-DD`
- `<!-- last reviewed: YYYY-MM-DD -->`
- `updated YYYY-MM-DD`
- Lines containing words like "last checked", "snapshot", or "version" immediately
  followed by or near an ISO date `YYYY-MM-DD`

For each date stamp where the date is >6 months before today:
emit `severity: "low"`, `action: "flag"`,
`detail: "date stamp <date> is >6mo old - re-validate content"`.

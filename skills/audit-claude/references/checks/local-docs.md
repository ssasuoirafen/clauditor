# Local docs check - Stage 6 + Stage 7

This document governs what the `audit-local-docs` reviewer checks. Finding and
`promotion_signals` shapes are defined in
`${CLAUDE_PLUGIN_ROOT}/skills/audit-claude/references/contracts.md`.

All findings from this reviewer use `layer: "local-docs"`.

## Precondition

If `Baseline.local_surface` has all empty arrays (`docs: []`, `projects: []`, `data: []`)
and no `.claude/docs/` files are present, return `{ "findings": [], "promotion_signals": [] }` -
absence is not itself a finding.

## What to read

Read `${CLAUDE_PLUGIN_ROOT}/skills/audit-claude/references/freshness.md` once so you know
the freshness routine before the Stage 7 freshness section below. Do not re-read it during
the run.

Read in parallel (translate to Read/Glob/Grep tool calls):

```text
# .local/docs/ - primary documentation surface (Baseline local_surface.docs)
Read: each file in Baseline local_surface.docs

# .local/projects/ - active work trackers (Baseline local_surface.projects)
Read: each file in Baseline local_surface.projects

# .local/data/ - payloads, may hold non-regenerable key/cert material
# List only; read file content only when needed to assess whether it is key/cert material
Glob: <project_path>/.local/data/**/*

# .claude/docs/ - should be near-empty in healthy projects
Glob: <project_path>/.claude/docs/**/*

# For cross-reference integrity (Stage 7 check 7.2):
# Resolve CLAUDE.md path from Baseline.claude_md_path ("root" -> <project_path>/CLAUDE.md,
# ".claude" -> <project_path>/.claude/CLAUDE.md)
Read: <project_path>/CLAUDE.md  (per Baseline.claude_md_path)
Glob: <project_path>/.claude/rules/*.md
# Memory files (if memory_dir not null):
Glob: <memory_dir>/*.md
```

## Stage 6 - .local/ surface categorization

### 6A - .local/docs/ lifecycle classification

Apply to each file in `Baseline.local_surface.docs`. Emit one Finding per file
(`layer: "local-docs"`). Where a keep decision is deliberate, emit a `keep` finding
so `audit-consolidate` knows the file was reviewed.

Every Finding MUST include `topic_key`, `gist`, and `detail` per contracts.md.

| ID  | Category | Action | Severity |
|-----|----------|--------|----------|
| L01 | Specs/plans for DONE tickets - ticket closed in tracker, intent captured in code/commits | `delete` | medium |
| L02 | Artifacts from completed migrations (proposal, mapping, execution-plan) | `delete` | medium |
| L03 | Active TODOs and in-progress analysis | `keep` | low |
| L04 | Reusable templates and runbooks the user uses personally | `keep` | low |
| L05 | Drafts for external systems (CMDB, tracker assets) - check if completed | `delete` if done; `keep` if still in progress | medium |

> **Ticket status:** do not call any tracker MCP from this reviewer - ticket status is resolved
> by `audit-recon` and available in `Baseline.ticket_status`. If a file references a ticket
> (`PROJ-XXXX`), look up its status there:
> - `"closed"` -> apply L01 (`delete`).
> - `"unknown"` or absent -> emit `flag` with `detail: "<ticket-id> -> verify status"`.
> - `"open"` -> no finding; ticket is active.
>
> **No ticket mentioned:** skip status check entirely.
>
> **For L05 files, apply the same ticket-status logic to decide whether the draft is done (delete) or still in progress (keep).**

### 6B - .local/projects/ trackers

Apply to each file in `Baseline.local_surface.projects`. Apply the same closed/active determination used for local docs files (LP1-LP3 below).

| ID  | Category | Action | Severity |
|-----|----------|--------|----------|
| LP1 | Tracker for a shipped/closed effort | `delete` | medium |
| LP2 | Active tracker | `keep` | low |
| LP3 | Thin memory pointer to a .local/projects/ file that still exists | `keep` - intentional pointer <-> canonical pattern; not a duplicate | low |

### 6C - .local/data/ crypto/secret guard

**Before recommending deletion of ANY `.local/data/` file**, check whether it is
non-regenerable key/cert/secret material. Pattern indicators:

- Private key files: `.key`, `.pem`, PEM block header `-----BEGIN`
- Node-identity bundles
- Filename matches `*-secretkey*`
- Certificate files: `.crt`, `.cer`, `.p12`, `.pfx`

If a file matches any indicator:
- Emit `action: "keep"`, `severity: "low"`, `topic_key: "crypto_keep_<basename>"`,
  `detail: "must-keep: non-regenerable key/cert material - never propose for deletion; verify this file is gitignored"`.

> **Hard rule: do NOT emit `action: "delete"` for non-regenerable key/cert material
> under any circumstances**, even if the file appears stale, orphaned, or undocumented.

Only ephemeral payloads (sample JSON, scratch CSVs, test data with no key material) are
eligible for `action: "delete"`.

### 6D - .claude/docs/ (near-empty target)

`.claude/docs/` should be near-empty in healthy projects. Personal artifacts belong in
`.local/docs/`; `.claude/` is for Claude config only. For each file found under
`.claude/docs/`:

| ID  | Category | Action | Severity |
|-----|----------|--------|----------|
| CD1 | Setup instructions (mcp-setup.md, CLI auth) - one-time content | `migrate` to repo README or `delete` | medium |
| CD2 | Personal lookup tables (team usernames, environment URLs) | `migrate` to .local/docs/ | low |
| CD3 | Multi-line notes that should be quick-loaded | `migrate` to `.claude/rules/<name>.md` with `paths:` scoping, or to a memory `reference_*.md` entry | low |
| CD4 | Anything else | `migrate` to .local/docs/ | low |

Note: any new `.claude/rules/` file created from a CD3 migration must still pass Stage 3
rules-optimization and Stage 5d entity-appropriateness checks.

## Stage 7 - Local docs deep audit

Run this pass on each file in `Baseline.local_surface.docs`. Also apply lifecycle
sub-passes (7.4) to `.local/projects/` trackers. Skip team-wiki sync unless the project
explicitly opts in (detection signals: CLAUDE.md "Wiki"/"Confluence" section with URL,
rules file referencing wiki, memory reference pointing to wiki space, or MCP server for
wiki tools registered and CLAUDE.md names it canonical for docs).

### 7.1 - Freshness check

Apply the shared freshness subroutine from
`${CLAUDE_PLUGIN_ROOT}/skills/audit-claude/references/freshness.md`
to each file in `Baseline.local_surface.docs`. The routine was read once in "What to read"
above - apply it here, once per file. Do not re-read the routine during this pass.

Set `layer: "local-docs"` and `path` to the file's absolute path on all freshness findings.

### 7.2 - Cross-reference integrity

Using the CLAUDE.md, `.claude/rules/*.md`, and memory `*.md` files already read above,
grep for references to local doc filenames (basename match is sufficient).

| Result | Action | Severity |
|--------|--------|----------|
| File is referenced somewhere | `keep`; verify the reference path still resolves | low |
| File is NOT referenced anywhere AND not in an active-TODO/WIP category | `flag` as orphan candidate | low |

For unreferenced files: emit `action: "flag"`, `topic_key: "orphan_<basename>"`,
`detail: "unreferenced in CLAUDE.md/rules/memory - orphan candidate; confirm deletion with user"`.

### 7.3 - Redundancy

Group files in `Baseline.local_surface.docs` by topic (filename prefix, content keywords).

Where two or more files cover overlapping scope:
- Emit `action: "merge"`, `severity: "low"`.
- Set `path` to the primary/first file; set `paths` to the full list.
- `detail`: propose merging into a single canonical doc.

Where a file duplicates content from CLAUDE.md, a `.claude/rules/` file, or a memory entry
(cross-layer overlap):
- Emit `action: "delete"`, `severity: "low"`.
- `detail`: name the authoritative source and note that the local doc is redundant.

> **Cross-layer dedup is NOT the final authority here.** Emit a precise `topic_key` and
> `gist` on every Finding so `audit-consolidate` can confirm cross-layer deduplication
> across all reviewer outputs.

### 7.4 - Lifecycle markers

Scan each file in `Baseline.local_surface.docs` (and each `.local/projects/` tracker) for
lifecycle markers. Search both English and common project-language equivalents.

Active lifecycle markers:
- English: `TODO`, `WIP`, `DRAFT`
- Russian: `ЗАДАЧА:`, `ЧЕРНОВИК:`, `В РАБОТЕ:`

Ticket ID pattern: `[A-Z]+-\d+` (e.g. `PROJ-123`, `GH-456`)

Date stamp patterns:
- `as of YYYY-MM-DD`
- `<!-- last reviewed: YYYY-MM-DD -->`
- `updated YYYY-MM-DD`
- Lines with "last checked", "snapshot", or "version" immediately before/after an ISO date

**Ticket IDs:** do not call any tracker MCP from this reviewer - read from `Baseline.ticket_status`.
- If the file content explicitly states the ticket is Done/Closed (e.g. "Status: DONE", "closed <date>"), apply L01 `delete` regardless of mode.
- Otherwise look up each ticket ID in `Baseline.ticket_status`:
  - `"closed"` -> emit L01 finding (`action: delete`).
  - `"unknown"` or absent -> emit `flag` with `detail: "<ticket-id> -> verify status"`. (Do not emit verify flag if L01 `delete` was already emitted for this file.)
  - `"open"` -> no finding.

**Date stamps older than 6 months:** emit `severity: "low"`, `action: "flag"`,
`topic_key: "stale_date_stamp_<basename>"`,
`detail: "date stamp <date> is >6mo old - re-validate content"`.

### 7.5 - Per-file action table

For each file in `Baseline.local_surface.docs`, consolidate the findings from 7.1-7.4 into
one primary Finding whose `detail` includes a summary row:

| Category | Action | Severity |
|----------|--------|----------|
| Active TODO / in-progress | `keep` | low |
| Stale references / drift (from freshness check) | `flag` | medium |
| Orphan, no recent edit | `flag` | low |
| Redundant with another local doc | `merge` | low |
| Duplicates CLAUDE.md / rule / memory content | `delete` | low |
| Closed-ticket artifact | `delete` | medium |

Where multiple findings apply to the same file, emit each as a separate Finding with the
same `path` but distinct `topic_key` values.

## Promotion signals - local-runbook

After completing all checks, identify files in `Baseline.local_surface.docs` that were
classified as reusable templates or runbooks (L04 keeps).

If two or more such files cover the same recurring process (similar filename prefix,
overlapping content topic, or near-identical structure), emit one `promotion_signals`
entry per cluster:

```json
{ "kind": "local-runbook", "topic_key": "<normalized>", "count": <n>, "paths": ["<abs>", ...] }
```

Normalize `topic_key`: lowercase, strip punctuation, replace spaces with underscores
(e.g. "Deploy runbook" -> `deploy_runbook`).

The signal feeds `audit-consolidate` to decide whether to consolidate the runbooks or
promote the pattern into a `.claude/skills/<name>/SKILL.md`.

Do NOT emit a signal for a single unrepeated runbook - only for clusters of two or more
files covering the same process.

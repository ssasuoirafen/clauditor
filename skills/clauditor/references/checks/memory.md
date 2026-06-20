# Memory check - Stage 2

> Best-practice rules here are grounded in the sources cited in `${CLAUDE_PLUGIN_ROOT}/skills/clauditor/references/sources.md`.

This document governs what the `clauditor-memory` reviewer checks. Finding and
`promotion_signals` shapes are defined in
`${CLAUDE_PLUGIN_ROOT}/skills/clauditor/references/contracts.md`.

## Precondition

If the Baseline's `memory_dir` is `null`, return an empty result with no
findings - absence is not itself a finding.

## What to read

Read in parallel (translate to Read/Glob/Grep calls):

```text
Read: <memory_dir>/MEMORY.md
Glob: <memory_dir>/feedback_*.md
Glob: <memory_dir>/project_*.md
Glob: <memory_dir>/reference_*.md
# Parent-scope memory (Baseline parent_memory_dir, if not null):
Read: <parent_memory_dir>/MEMORY.md
Glob: <parent_memory_dir>/feedback_*.md
Glob: <parent_memory_dir>/project_*.md
Glob: <parent_memory_dir>/reference_*.md
# Active work trackers (.local/projects/ - Baseline local_surface.projects):
# Skip this pass entirely when local_surface.projects is an empty list.
Read: each file in local_surface.projects
```

## Classification table

Apply to each memory entry. For each entry, emit exactly one Finding
(contracts.md shape, `layer: "memory"`). Where a keep decision is deliberate,
emit a `keep` finding so clauditor-consolidate knows the entry was reviewed.

| ID  | Category | Action | Severity |
|-----|----------|--------|----------|
| M01 | Duplicate of a rule in `.claude/rules/` | `delete` memory entry | medium |
| M02 | Duplicate of project `CLAUDE.md` (root) | `delete` memory entry | medium |
| M03 | Duplicate of global `~/.claude/CLAUDE.md` | `delete` memory entry | medium |
| M04 | Duplicate of a `.local/docs/` file or external wiki page | `delete` or `migrate` (convert to reference with link/path) | low |
| M05 | Thin `project_*` pointer to an authoritative `.local/projects/*` tracker | `keep` - pointer<->canonical is an intentional pattern, NOT a duplicate | low |
| M06 | Parent-scope reference genuinely shared across sibling projects | `keep` at parent; flag with `migrate` **only** if also duplicated into this project's memory | low |
| M07 | One-shot context (applied once, not a recurring pattern) | `delete` | low |
| M08 | Completed project (Jira ticket DONE, or file states ticket closed/done/completed) | `delete` - information lives in code / tracker history / local docs | medium |
| M17 | Related feedback on same topic (>=2 files) | `merge` + emit a `promotion_signals` entry of kind `feedback-cluster` (see M17 section) | low |
| M09 | Active protective rule (guards against review/debug mistakes) | `keep` | low |
| M10 | Active project with open TODO | `keep` | low |
| M11 | External resource (URL, API token reference, escalation contact) | `keep` as reference | low |

## M17 - feedback cluster (merge-or-promote)

When two or more `feedback_*.md` files share a common topic:

1. Emit one Finding per cluster: `action: "merge"`, `severity: "low"`, `path` set
   to the first file in the cluster, `paths` set to the full list of cluster file
   paths (per the multi-file finding rule in contracts.md), detail explaining which
   files overlap and what the consolidated topic is.
2. Also emit one `promotion_signals` entry:
   ```json
   { "kind": "feedback-cluster", "topic_key": "<normalized>", "count": <n>, "paths": ["<abs>", ...] }
   ```
   Normalize `topic_key`: lowercase, strip punctuation, replace spaces with
   underscores (e.g. "SQL query formatting" -> `sql_query_formatting`).

The `promotion_signals` entry feeds `clauditor-consolidate` to decide whether to
merge the files or promote the cluster into a `.claude/rules/` entry (merge-or-promote;
the consolidator chooses based on cross-layer signals).

## Load-cap checks (M4 additions)

Run after reading `MEMORY.md`. These are independent of the classification table.

| ID  | Check | Severity | Action |
|-----|-------|----------|--------|
| MC1 | `MEMORY.md` line count > 200 | high | `flag` - oversized index burns session token budget on every load; prune stale entries or split into sections |
| MC2 | `MEMORY.md` file size > 25 KB | high | `flag` - load-cap risk; prune or restructure |

Measure line count with `Bash: (Get-Content <path>).Count` (Windows) or
`Bash: wc -l <path>` (POSIX). File size via
`Bash: (Get-Item <path>).Length` (Windows) or `Bash: stat -c%s <path>` (POSIX).

## Wikilink integrity check (M4 addition)

Scan every per-fact file (`feedback_*.md`, `project_*.md`, `reference_*.md`) for
`[[wikilink]]` patterns. For each wikilink found:

1. Extract the target: strip `[[` and `]]`; append `.md` if no extension present.
2. Check whether `<memory_dir>/<target>` exists (use `Glob` or `Read`).
3. If the file does not exist: emit a Finding - `layer: "memory"`, `severity: "medium"`,
   `action: "flag"`, `detail: "broken wikilink: [[<target>]] in <source_file>"`.

## MEMORY.md index integrity check (end-of-stage)

After classifying all entries, verify the MEMORY.md index is consistent.

Match on the link TARGET - the `(filename.md)` portion of a markdown link
`[label](filename.md)` - NOT on the label text. Both directions apply:

1. **Orphan index entries:** for every markdown link `[label](filename.md)` in
   `MEMORY.md`, check whether `<memory_dir>/filename.md` exists on disk. If the
   target file is missing -> Finding: `severity: "medium"`, `action: "flag"`,
   `detail: "orphan index entry: filename.md missing on disk"`.
2. **Missing index entries:** for every `feedback_*.md`, `project_*.md`,
   `reference_*.md` in `<memory_dir>/`, check whether `MEMORY.md` contains at
   least one line whose `(target)` portion matches the filename. If no such line
   exists -> Finding: `severity: "low"`, `action: "flag"`,
   `detail: "file <name> not referenced in MEMORY.md index"`.

Note: this reviewer is read-only. Do not repair the index - emit findings only.

## Project status verification

Do not call any tracker MCP from this reviewer - ticket status is resolved by `clauditor-recon`
and available in `Baseline.ticket_status`.

If a `project_*.md` mentions a ticket identifier (`PROJ-XXXX`, `GH-NNN`, `LINEAR-NNN`, etc.):

1. If the file text explicitly states the ticket is closed/done/completed (e.g. "Status: DONE",
   "closed 2025-01-10") - emit M08 finding (`action: delete`) regardless of mode.
2. Otherwise, look up the ticket ID in `Baseline.ticket_status`:
   - Status `"closed"` -> emit M08 finding (`action: delete`).
   - Status `"unknown"` or ticket absent from `ticket_status` -> emit a `flag` finding with
     `detail: "<ticket-id> -> verify status"` and let the user resolve.
   - Status `"open"` -> no finding; ticket is active.

**No ticket mentioned:** skip status check entirely.

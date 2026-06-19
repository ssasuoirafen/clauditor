# CLAUDE.md check - Stage 4

Governs what `clauditor-claude-md` checks. Finding and `promotion_signals` shapes are defined in
`${CLAUDE_PLUGIN_ROOT}/skills/clauditor/references/contracts.md`.

All findings from this reviewer use `layer: "claude-md"`.

## Precondition

If `Baseline.claude_md_path` is `"missing"`, emit one Finding:
`layer: "claude-md"`, `severity: "high"`, `action: "flag"`,
`detail: "no CLAUDE.md found at project root or .claude/"`.
Return that single Finding and stop.

## What to read

Read `${CLAUDE_PLUGIN_ROOT}/skills/clauditor/references/freshness.md` so you know the routine before the Freshness check section below.

Every Finding MUST include both `gist` (short one-line summary) and `detail` (full recommendation) per contracts.md.

Resolve the CLAUDE.md path from Baseline:
- `claude_md_path == "root"` -> `<project_path>/CLAUDE.md`
- `claude_md_path == ".claude"` -> `<project_path>/.claude/CLAUDE.md`

Read the file in full. Reuse the `rule -> @-reference` mapping from the Baseline - do not re-glob.

For C04 (version drift), use `Baseline.stack_versions` which already carries versions extracted from
dependency configs (`pyproject.toml` / `package.json` / `Cargo.toml` / `go.mod` / etc.). Re-read a
dep file only when you need a value that Baseline does not carry.

## Stage 4 checks

| ID  | Check | Action | Severity |
|-----|-------|--------|----------|
| C01 | CLAUDE.md repeats content already in a `.claude/rules/` file (whether `@`-referenced or not) - the rule loads via auto-load regardless | `delete` the duplicate section | medium |
| C02 | A one-line stub section in CLAUDE.md duplicates a rule | `delete` section entirely | low |
| C03 | CLI installation, auth login, or API token generation steps are present - one-time operations do not belong in every-session context. See the C03 dev-workflow exception note below. | `migrate` to repo README or `delete` | medium |
| C04 | A stack version stated in CLAUDE.md does not match the actual version in `Baseline.stack_versions` | `flag` with both the stated and actual values | high |
| C05 | CLAUDE.md contains a hardcoded counter ("N models", "N files") - source of truth is `git ls-files`, counters go stale | `delete` counter | low |
| C06 | CLAUDE.md restates content that lives in a `.local/docs/` file - the prose copy drifts as the doc grows | `migrate` to a one-line pointer | low |
| C07 | CLAUDE.md contains a hand-maintained roster of `.local/docs/` (or `.local/*`) filenames - goes stale silently | `flag` - replace with one durable pointer, not a file list | low |
| C08 | Server IPs, hostnames, or panel/API URLs present in CLAUDE.md of an infra or networking project - commit risk | `flag` - move to a gitignored config file | medium |
| C09 | Language is inconsistent within the file (e.g. section headings in one language, bullets in another) | `flag` - pick one language for the whole file | low |
| C10 | Orphan heading (`### Subsection` with no parent `## Section`) | `flag` - fix heading hierarchy | low |
| C11 | Intra-CLAUDE.md duplicate: the same bullet, line, or instruction appears more than once within this file (same-layer, within-file repetition - distinct from cross-layer dedup) | `delete` the redundant copy | low |

> **Cross-layer dedup is NOT this reviewer's job.** Do NOT assert that a CLAUDE.md section duplicates
> a memory entry or a local-docs file without reading both. Emit a precise `topic_key` and `gist` on
> every Finding (including `action: "keep"`) so `clauditor-consolidate` check C1 can detect cross-layer
> duplication across all reviewer outputs.

### C03 - dev-workflow exception

A recurring dev-workflow section (e.g. "Adding a new model", "Adding a tool module",
"Releasing a new version") is NOT one-time setup - it describes a process a developer
repeats. Do NOT flag such a section under C03.

Instead, emit a `claude-md-procedure` promotion_signal for the block so `clauditor-consolidate`
can propose extracting it into a dedicated skill. This keeps the workflow discoverable while
signaling that it may warrant a standalone skill file.

## H7 - AGENTS.md bridge check

Read `Baseline.agents_md_present`.

If `agents_md_present` is `true`:

1. Search CLAUDE.md for `@AGENTS.md` (an import reference) or a symlink declaration pointing to
   `AGENTS.md`.
2. If neither is found: emit a Finding -
   `severity: "critical"`, `action: "flag"`, `topic_key: "agents_md_unread"`,
   `detail: "AGENTS.md is present but CLAUDE.md does not import it via @AGENTS.md - the file will not be read"`.

If `agents_md_present` is `false`: skip this check entirely.

## M10 - Freshness stamp check

Grep CLAUDE.md for sections that contain volatile information:
- Stack or version tables
- Provider or toolchain version references
- MCP server lists

For each volatile section found:

1. Check whether it carries a `<!-- last reviewed: YYYY-MM-DD -->` stamp immediately before or
   after the section heading or table.
2. Stamp absent: emit `severity: "medium"`, `action: "flag"`,
   `topic_key: "missing_freshness_stamp"`,
   `detail: "volatile section '<heading>' is missing a <!-- last reviewed: YYYY-MM-DD --> stamp"`.
3. Stamp present but date is >6 months before today: emit `severity: "low"`, `action: "flag"`,
   `topic_key: "stale_freshness_stamp"`,
   `detail: "freshness stamp <date> in '<heading>' is >6mo old - re-validate the volatile section"`.

## Freshness check (reality pass)

> **M10 and the freshness subroutine are additive and non-overlapping.** M10 is CLAUDE.md-specific:
> it checks that volatile sections carry a `<!-- last reviewed: YYYY-MM-DD -->` stamp. The freshness
> subroutine (`${CLAUDE_PLUGIN_ROOT}/skills/clauditor/references/freshness.md`) is generic file
> health: stale code identifiers, intro/conclusion mismatch, and age. Run both; neither substitutes
> for the other.

Apply the shared freshness subroutine from
`${CLAUDE_PLUGIN_ROOT}/skills/clauditor/references/freshness.md`
to the CLAUDE.md file. Set `layer: "claude-md"` and `path` to the CLAUDE.md absolute path on all
freshness findings.

## Reference - typical target section set

Use this as a guide when evaluating structure, not as a mandatory checklist. Adapt to project type:

```
# <Project> -- Instructions

## Team & communication    -- language, ticket tracker, repo
## Stack                   -- versions only, no counters
## Architecture overview   -- layers, data flow, key modules
## Common commands         -- commands frequently run
## Rules (auto-load)       -- list of rules with descriptions
## Testing                 -- project-specific only
## Git workflow            -- branches, MR/PR, CI/CD briefly
## MCP servers             -- priority rule only
## Agents                  -- if project agents exist
## Reference               -- links to key external documents
```

For non-data projects adapt accordingly. For an MCP-server-producer repo, sections like
`Tool module pattern`, `Adding a new tool`, and `Known quirks` are correct - not bloat. The set is
a guide, not a checklist to enforce.

## Promotion signals - claude-md-procedure

After completing all checks, scan CLAUDE.md for multi-step procedural paragraphs: blocks with
numbered steps (1. 2. 3. ...), ordered instructions, or workflow outlines describing a recurring
process (e.g. "How to add a new model", "Releasing a new version", "Onboarding a new environment").

For each such paragraph that constitutes a reusable multi-step process, emit one `promotion_signals`
entry:

```json
{ "kind": "claude-md-procedure", "topic_key": "<normalized>", "count": 1, "paths": ["<abs-path-to-CLAUDE.md>"] }
```

Normalize `topic_key`: lowercase, strip punctuation, replace spaces with underscores
(e.g. "Adding a new model" -> `adding_a_new_model`).

The consolidation barrier turns these into new-skill proposals - `clauditor-consolidate` decides whether
to promote.

Do NOT emit a signal for one-liner mentions or passive rules - only for genuine multi-step flows
that would benefit from extraction into a `.claude/skills/<name>/SKILL.md`.

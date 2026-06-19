# Entities check - Stage 5a/5b/5c/5i/5j

Governs what `audit-entities` checks. Finding and `promotion_signals` shapes are defined in
`${CLAUDE_PLUGIN_ROOT}/skills/audit-claude/references/contracts.md`.

All findings from this reviewer use `layer: "entities"`.

## Precondition

If `entities.skills`, `entities.agents`, `entities.commands`, and `entities.plugins` are all
empty lists in the Baseline, return `{ "findings": [], "promotion_signals": [] }`.

**Entities are configuration, not documents.** Do NOT apply the freshness subroutine to entity
files.

## Command/skill-merge caveat

Before judging 5a/5c entity-type choices, apply the command/skill-merge caveat in Principle 5 of
`${CLAUDE_PLUGIN_ROOT}/skills/audit-claude/references/profile.md`. The real distinction is
auto-trigger vs manual-only, not file location.

## What to read

Use the Baseline `entities.*` lists to locate files. The `has_tools` flag in Baseline already
encodes whether an agent has a `tools:` allowlist - no re-glob needed for that signal.

```text
# Skills
Glob: <project_path>/.claude/skills/*/SKILL.md

# Agents
Glob: <project_path>/.claude/agents/*.md
# has_tools already in Baseline - no re-glob needed

# Commands
Glob: <project_path>/.claude/commands/*.md

# Plugins
Read: <project_path>/.claude/settings.json   # enabledPlugins key
Read: ~/.claude/settings.json                # user-level enabledPlugins
Glob: ~/.claude/plugins/marketplaces/*/plugins/*/commands/*.md
Glob: ~/.claude/plugins/marketplaces/*/plugins/*/skills/*/SKILL.md
```

Every Finding MUST include both `gist` (short one-line summary) and `detail` (full recommendation)
per contracts.md.

## 5a Skills

**Purpose:** multi-step AI workflow in the main session, auto-activated by triggers in
`description`.

**Frontmatter:**
- `description` - **required.** Claude pattern-matches this text to decide when to invoke the
  skill. Concrete activation cues ("use when user asks about X", "trigger when editing Y files")
  improve match quality; vague descriptions cause missed or wrong activation.
- `name` - optional; defaults to the directory name. If present, must match the directory name.

`allowed-tools:` in a skill is **pre-approval, not restriction.** The skill retains access to all
session tools regardless. True tool restriction requires an agent.

| ID  | Check | Action | Severity |
|-----|-------|--------|----------|
| E01 | `description` absent or empty | `flag` - skill will not auto-trigger reliably; add concrete activation cues | high |
| E02 | `name` present but does not match directory name | `flag` - mismatch causes invocation confusion; align name or drop the override | low |
| E03 | Skill body shows manual-invocation intent (argument-driven, no auto-trigger cues) | `relabel` -> command | medium |
| E04 | Skill requires isolated context, parallel execution, or enforced tool restriction | `relabel` -> agent | medium |
| E05 | Skill body is passive text-instruction with no steps or tool calls | `relabel` -> rule | low |
| E06 | Skill > 300 lines or description indicates it routinely runs in isolation | `flag` - consider converting to an agent | low |
| E07 | Skill is vendored (`metadata.json`, `AGENTS.md`, `LICENSE` header, or large `rules/*.md` library) and has a structural or content issue | `flag` - re-vendor from source; do not propose line edits on vendored files | low |

Emit `action: "keep"` when none of E01-E07 applies.

## 5b Agents (L9)

**Purpose:** isolated context invoked via the `Agent` tool.

### Required frontmatter

- `name` - **required.** Absence is a hard failure.
- `description` - **required.** Absence is a hard failure.

### Recommended frontmatter

- `tools:` - **recommended** isolation heuristic (best practice). An agent without `tools:`
  receives all session tools; the isolation intent is undermined. Absence is a
  recommendation-level finding, not a spec requirement - flag it so the author can decide whether
  isolation is the actual intent.
- `model:` - **recommended** when the task warrants a specific cost or capability profile.
  Absence is a low-severity note, not a failure.

Subagents CAN preload skills via a `skills:` array in frontmatter (per the sub-agents docs).
Skills not listed in `skills:` are unavailable inside the subagent.

| ID  | Check | Action | Severity |
|-----|-------|--------|----------|
| E10 | `name` frontmatter absent | `flag` | high |
| E11 | `description` frontmatter absent or empty | `flag` | high |
| E12 | `tools:` allowlist absent (`has_tools: false` in Baseline) | `relabel` or `flag` - best-practice gap; missing allowlist means the agent receives all session tools, undermining isolation intent | medium |
| E13 | `model:` absent and description implies a non-default cost or capability need | `flag` - recommended; add `model:` if the task warrants it | low |
| E14 | Agent purpose requires context shared with the user (needs to hand back to main dialogue) | `relabel` -> skill or command | medium |
| E15 | Agent is a thin wrapper over 2-3 tool calls with no isolation or analysis purpose | `flag` - inline in the calling skill/command; no standalone agent needed | low |

Emit `action: "keep"` when none of E10-E15 applies.

## 5c Commands

**Purpose:** parameterized flow with explicit invocation `/name <args>` in the main session.

**Frontmatter:**
- `description` - recommended (shown on tab-completion).
- `argument-hint` - optional; documents argument format (`<stage>`, `<PR-number>`, etc.).
- `allowed-tools` - optional; restricts tool set during execution.

| ID  | Check | Action | Severity |
|-----|-------|--------|----------|
| E20 | `description` absent | `flag` - add a one-liner shown on tab-completion | low |
| E21 | Command should auto-trigger from context (no explicit invocation intent, no argument) | `relabel` -> skill | medium |
| E22 | Command body is passive knowledge with no concrete flow or steps | `relabel` -> rule or CLAUDE.md | low |
| E23 | Command has no parameterization and the scenario is non-linear | `relabel` -> skill | low |

Emit `action: "keep"` when none of E20-E23 applies.

## 5i Cross-check: artifact vs entity

After applying 5a/5b/5c checks per-file, confirm the combined view: no entity type was silently
skipped. Per-file findings from 5a/5b/5c already cover all issues; this pass captures any gap.

Emit one summary `keep` Finding per entity that passed all checks, so `audit-consolidate` knows
every entry was reviewed.

> **Cross-layer dedup is NOT this reviewer's job.** Do NOT assert that an entity duplicates a
> memory entry or CLAUDE.md content - that is audit-consolidate's C3 job. Emit a precise
> `topic_key` and `gist` on every Finding (including `action: "keep"`) so C3 can detect
> cross-layer duplication by matching across all reviewer outputs.

## 5j Plugins

**Purpose:** plugins ship their own skills, agents, commands, hooks, and output-styles into the
session - they coexist with hand-rolled entities and can shadow them.

Sources: `enabledPlugins` in project `settings.json` and user `~/.claude/settings.json`. Plugin
files live in `~/.claude/plugins/marketplaces/*/plugins/*/`.

| ID  | Check | Action | Severity |
|-----|-------|--------|----------|
| E30 | Plugin command/skill shares a `/name` with a local entity (name collision) | `flag` - document which wins; rename local entity if needed | medium |
| E31 | Plugin already covers a hand-rolled local workflow (duplicate intent) | `flag` - drop the redundant local copy or disable the plugin feature | medium |
| E32 | Plugin-shipped hooks fire in this project but are not in the hooks audit | `flag` - route to hooks reviewer; do not audit hook body here | low |
| E33 | Plugin skill `description` auto-triggers on the same work as a local rule/skill, with no name collision (semantic/intent overlap) | `flag` with stable `topic_key` so C3 can resolve the conflict | medium |
| E34 | The correct plugin for the project type is not enabled (e.g. `mcp-server-dev` for an MCP-server repo) | `flag` - positive fit gap; recommend enabling | low |

For E33: set a stable normalized `topic_key` on the Finding (lowercase, underscores, e.g.
`dbt_conventions_overlap`) so `audit-consolidate` barrier C3 can match it against findings from
other layers.

Never edit plugin-internal files in `~/.claude/plugins/cache/` - they are overwritten on update.
Adjust via your config or `enabledPlugins`.

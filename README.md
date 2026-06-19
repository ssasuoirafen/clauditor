# clauditor

Audits and tidies a Claude Code project's configuration: `.claude/` (rules, skills, agents, commands, hooks, output styles, settings), `.mcp.json`, auto-memory, and `.local/` working docs.

It is manual and read-only by default. It produces a report; it only changes files after you sign off.

## What it does

- **Inventories** the whole setup and checks it against repo reality (stack versions vs dependency files, referenced paths that no longer exist, stale identifiers).
- **Finds duplication** across layers - the same rule living in CLAUDE.md and a rule file and memory - and keeps the single auto-loaded copy.
- **Checks placement** - is each thing the right kind of artifact? A multi-step procedure buried in CLAUDE.md should be a skill; a prose "reminder" configured as a hook should be a rule; a file-scoped rule should carry `paths:`.
- **Flags secrets and gitignore issues** - a hardcoded token in a tracked file is a leak; a secret in a gitignored personal file is fine. Credentials embedded in connection-string URLs are caught.
- **Promotes accumulated knowledge** into the right entity - when the same feedback shows up twice, or a procedure keeps getting repeated, it proposes turning it into a rule, skill, or hook.
- **Protects what must not be lost** - non-regenerable key/cert material under `.local/data/` is never proposed for deletion.

## Architecture

`/clauditor` is a manual orchestrator skill (`disable-model-invocation: true`). It runs:

1. **recon** - one agent inventories the project and returns a structured baseline.
2. **six reviewers in parallel** (read-only), one per domain: memory, rules, CLAUDE.md, entities (skills/agents/commands/plugins), security and config (hooks/MCP/settings/secrets), and local docs. Each returns findings plus promotion signals.
3. **consolidate** - a barrier agent that sees all six outputs: cross-layer dedup, promotion detection, cross-scope precedence, and report assembly.
4. **sign-off, then apply** - in an interactive run, you approve the proposed actions and the orchestrator applies them one at a time as the single writer, then a verify pass confirms each edit.

A read-only run stops at the report.

The audit rubric lives once under `skills/clauditor/references/` (a shared profile, decision matrix, anti-patterns, report template, contracts, a freshness routine, and one check spec per reviewer); each agent reads only the slice it needs.

## Install

```
/plugin marketplace add ssasuoirafen/clauditor
/plugin install clauditor@clauditor
```

Or from a local checkout:

```
/plugin marketplace add /path/to/clauditor
/plugin install clauditor@clauditor
```

## Usage

```
/clauditor                      # audit the current working directory
/clauditor C:\path\to\project   # audit a specific project
```

Run it read-only first to read the report. In an interactive run it asks for sign-off before changing anything and never deletes a must-keep item.

## Optional drift nudge

A `SessionStart` hook nudges you when a project's `.claude/` has not been audited in over 30 days. It emits a single factual line of context and is otherwise silent. The orchestrator records the last-review date after a completed interactive run.

## Tests

`test/fixtures/` holds a sample project with one planted issue per reviewer and an `EXPECTED.md` mapping each planted defect to the finding it should produce.

## License

MIT - see [LICENSE](LICENSE).

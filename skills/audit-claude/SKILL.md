---
name: audit-claude
description: Audit and optimize a project's .claude/ structure, memory, rules, skills, agents, commands, hooks, MCP, settings, and .local/ docs. Manual only.
disable-model-invocation: true
argument-hint: "[project-path]"
---

# Configuration Auditor

Manual orchestrator. `$ARGUMENTS` = project path (default: cwd). Mode defaults to `interactive`
unless invoked inside a subagent, in CI, with no tracker MCP reachable, or when the user asked
only for a report - in those cases mode is `read-only`.

Read `${CLAUDE_PLUGIN_ROOT}/skills/audit-claude/references/report-template.md` for the output shape.

Run in order:

**Step 0 - Determine `mode`.**
Set `mode = read-only` if ANY of the following is true:
- This skill is running inside a subagent (Agent tool context).
- A CI environment variable (`CI`, `GITHUB_ACTIONS`, `GITLAB_CI`, etc.) is set.
- No tracker MCP (Jira/Linear/GitHub Issues) is reachable in the current session.
- The user's request explicitly asks only for a report (e.g. "just audit", "show me findings", "read-only").
Otherwise set `mode = interactive`. Pass `mode` to `audit-recon` in Step 1.

1. Dispatch the `audit-recon` agent (Agent tool) with the project path + `mode`. Capture the Baseline JSON it returns.
2. Fan out the six reviewers IN PARALLEL (one message, six Agent calls): `audit-memory`, `audit-rules`,
   `audit-claude-md`, `audit-entities`, `audit-security-config`, `audit-local-docs`.
   Each prompt = the Baseline JSON + "audit your domain; return findings + promotion_signals per contracts.md."
3. Dispatch the `audit-consolidate` agent with the Baseline + all six JSON outputs. Capture its report + proposed_actions.
4. Present the report to the user.
5. **Read-only run** (`Baseline.mode == "read-only"`): stop here. Do not edit anything.
6. **Interactive run:** request sign-off on `proposed_actions`. After approval, apply each approved
   action yourself (you are the single writer) one atomic action at a time, reporting status after each.
   Never delete an `action: keep` item (non-regenerable key/cert material). No edits before sign-off.
   After all approved actions are applied, dispatch the `audit-verify` agent (Agent tool) with the list
   of touched file paths and a description of what each change was meant to do. Surface its pass/fail
   results ([{ path, ok, note }]) to the user before closing the run.
7. Do NOT hand off to any external CLAUDE.md tool (none exist in this toolchain).

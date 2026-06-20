# Rubric-currency check

> This check audits clauditor's OWN best-practice rules against live Anthropic docs.
> It does NOT audit a user's project. It is optional and requires web access.
>
> Best-practice rules in clauditor's rubric are grounded in the sources cited in
> `${CLAUDE_PLUGIN_ROOT}/skills/clauditor/references/sources.md`.

---

## Purpose

clauditor's rules are baked-in from the live docs at the time of last verification. This check
re-fetches each official doc URL from sources.md, compares "Key points clauditor relies on" against
the live page content, and flags any rule that has drifted or is now mis-stated.

---

## Output shape

Return ONLY this JSON - no prose:

```json
{
  "findings": [
    {
      "layer": "rubric-currency",
      "topic_key": "stale_rule_<area>",
      "gist": "<one-line summary of drift>",
      "severity": "high | medium | low",
      "action": "flag",
      "detail": "<which check file + rule ID needs updating, what the live doc now says, and source URL>"
    }
  ],
  "currency_summary": "<N rules checked, M stale>"
}
```

No `promotion_signals` key - not applicable to this check.

**Severity scale:**
- `high` - a rule is now WRONG or would mis-flag valid user config based on the live doc
- `medium` - a rule is an undocumented heuristic presented as a spec hard rule (or vice versa)
- `low` - only wording changed, or the live doc added a new capability the rubric does not mention

---

## Offline / no-web-access degrade

Before fetching any URL, attempt `WebFetch` on the first URL in the table (Memory / CLAUDE.md).
If the fetch fails or WebFetch is unavailable:

1. Emit exactly one finding:

```json
{
  "layer": "rubric-currency",
  "topic_key": "stale_rule_offline",
  "gist": "live doc check skipped - no web access; rubric last verified 2026-06-20",
  "severity": "low",
  "action": "flag",
  "detail": "WebFetch unavailable or returned an error. Re-run with web access to confirm rubric currency. Last known verification date: 2026-06-20 (see sources.md Currency notes section)."
}
```

2. Return `{ "findings": [<above>], "currency_summary": "0 rules checked (offline), 0 stale" }`.
3. Do not attempt further fetches. Do not error.

---

## Subsystems to check

For each row, fetch the URL and compare against the stated key points. The table below lists what
clauditor currently relies on and which check files encode it.

### 1. Memory / CLAUDE.md
URL: https://code.claude.com/docs/en/memory

Key points clauditor relies on:
- MEMORY.md load cap: first 200 lines OR 25 KB (whichever comes first)
- CLAUDE.md target <200 lines
- Load order: managed -> user -> project -> local (CLAUDE.local.md)
- Subdirectory CLAUDE.md files load on demand (not at launch)
- HTML comments stripped before context injection
- `autoMemoryDirectory` setting overrides default path
- `claudeMdExcludes` skips files by glob
- `@path` imports expand at launch

Check files: `checks/memory.md` MC1, MC2; `checks/claude-md.md` C04, C05, C10, M10; `checks/recon.md` M12

### 2. Settings
URL: https://code.claude.com/docs/en/settings

Key points clauditor relies on:
- Precedence: managed > CLI > local > project > user
- Permission allow/deny arrays MERGE (union) across scopes; deny wins
- Settings files reload live without restart (except `model` and `outputStyle`)
- `env` block applies to subprocesses
- `allowManagedPermissionRulesOnly` and `allowManagedHooksOnly` lock down hooks/permissions
- MCP servers: project in `.mcp.json`; user/local in `~/.claude.json`

Check files: `checks/security-config.md` G01-G13, G20, G30, G40-G41, M14; `decision-matrix.md`

### 3. Slash commands / Skills
URL: https://code.claude.com/docs/en/slash-commands

Key points clauditor relies on:
- Custom commands merged into skills: `.claude/commands/*.md` == `.claude/skills/<name>/SKILL.md`
- `disable-model-invocation: true` for explicit-invocation-only skills
- Skills take precedence over same-name commands
- Skills load on demand (not every session)
- `description` frontmatter drives auto-trigger matching
- `allowed-tools` is pre-approval, not restriction

Check files: `checks/entities.md` E01-E07, E20-E23, 5c caveat; `decision-matrix.md`

### 4. Subagents
URL: https://code.claude.com/docs/en/sub-agents

Key points clauditor relies on:
- Agent files: `.claude/agents/<name>.md`
- Required frontmatter: `name`, `description`
- Recommended: `tools:` (restriction), `model:`
- `disallowedTools` (camelCase) frontmatter denies specific tools, removed from the inherited/specified list
- Without `tools:` the agent receives all session tools
- Agents can preload skills via `skills:` array
- Built-in agents: Explore (Haiku, read-only), Plan (read-only), general-purpose (all tools)

Check files: `checks/entities.md` E10-E15, 5b agents section

### 5. Agent Skills
URL: https://code.claude.com/docs/en/skills

Key points clauditor relies on:
- Skill format: `SKILL.md` with YAML frontmatter
- `description` required for auto-trigger
- Skill body loads on demand only (not every session)
- Dynamic context injection via `` !`cmd` `` syntax
- Skill precedence: enterprise > personal > project > bundled
- Plugin skills namespaced as `plugin:skill`
- No documented hard body-size limit; live doc advisory: keep SKILL.md under 500 lines (E06 uses 500)
- `disallowed-tools` frontmatter removes tools from Claude's pool for the current turn (clears next message); a skill using `disallowed-tools` does NOT need relabeling to an agent solely for tool restriction

Check files: `checks/entities.md` E01-E07, E06 specifically; `decision-matrix.md`

**D3 - FIXED (confirm clean):** E06 now flags skills >500 lines (advisory), matching the live doc's own 500-line guidance. Confirm no finding if E06 says 500.

### 6. Hooks
URL: https://code.claude.com/docs/en/hooks

Key points clauditor relies on:
- Five handler types: `command`, `http`, `mcp_tool`, `prompt`, `agent`
- Events (non-exhaustive, ~30 total): SessionStart, UserPromptSubmit, PreToolUse, PostToolUse,
  PostToolUseFailure, PermissionRequest, Stop, SessionEnd, SubagentStart, SubagentStop,
  PreCompact, PostCompact, Notification, InstructionsLoaded, ConfigChange, CwdChanged,
  FileChanged, WorktreeCreate, WorktreeRemove - see live hooks doc for the full list
- Default timeouts: command/http/mcp_tool = 600 s, prompt = 30 s, agent = 60 s
- Exit 2 blocks the action; exit 1 is non-blocking
- Hooks run without controlling terminal (v2.1.139+)
- `if` filter fails open

Check files: `checks/security-config.md` H01-H06; `checks/consolidate.md` C4

### 7. MCP
URL: https://code.claude.com/docs/en/mcp

Key points clauditor relies on:
- Transport types: `http` (recommended, alias `streamable-http`), `sse` (deprecated), `stdio`, `ws` (WebSocket, persistent bidirectional)
- SSE is deprecated - rubric correctly flags it as a finding
- Source of truth: `.mcp.json` (project/team); `~/.claude.json` (user/local)
- `${VAR}` expansion in `.mcp.json` draws from OS/shell env only (NOT settings.json `env`)
- `CLAUDE_PROJECT_DIR` injected into stdio server env
- `enableAllProjectMcpServers` auto-enables project servers
- Hardcoded tokens in tracked `.mcp.json` = critical leak

Check files: `checks/security-config.md` F01-F08; `checks/recon.md`

**Known drift target (confirm):** SSE deprecation - confirmed correct per grounding-1-report.md.
Re-confirm on live page.

### 8. Plugins
URL: https://code.claude.com/docs/en/plugins

Key points clauditor relies on:
- Plugin root structure: `.claude-plugin/plugin.json` (manifest), `skills/`, `agents/`, etc.
- Manifest fields: `name`, `description`, `version`, `author`
- Common mistake: do NOT put `skills/`, `agents/` inside `.claude-plugin/` - only `plugin.json` goes there
- Plugin `settings.json` at plugin root: ONLY `agent` and `subagentStatusLine` keys are honored
- Check E35 in entities.md 5j flags a plugin `settings.json` with keys other than `agent`/`subagentStatusLine`

Check files: `checks/entities.md` E30-E35; `checks/recon.md`

**D4 - FIXED (confirm clean):** E35 now exists in entities.md 5j and audits plugin settings.json key scope. Confirm no finding if E35 is present and covers this constraint.

### 9. Plugin marketplaces
URL: https://code.claude.com/docs/en/plugin-marketplaces

Key points clauditor relies on:
- `marketplace.json` catalog in a git repo
- Official marketplace: `claude-plugins-official` (Anthropic-curated, auto-available)
- Community marketplace install identifier: `claude-community` (repo: `anthropics/claude-plugins-community`;
  add via `/plugin marketplace add anthropics/claude-plugins-community`)
- `claude plugin validate` runs same checks as review pipeline
- Approved plugins pinned to commit SHA

Check files: `checks/entities.md` E34; `checks/security-config.md` F06

### 10. Best practices
URL: https://code.claude.com/docs/en/best-practices

Key points clauditor relies on:
- CLAUDE.md: target <200 lines; prune entries Claude follows without instruction
- Use hooks for must-happen actions
- Skills vs CLAUDE.md: skills for domain knowledge/workflows, CLAUDE.md for session-wide facts
- Context is the key constraint - subagents keep exploration out of main context
- `disable-model-invocation: true` for side-effect workflows
- Adversarial review pattern
- `/clear` between unrelated tasks

Check files: `checks/claude-md.md` C03, C08; `checks/memory.md` MC1-MC2; `checks/rules.md` R01-R10; `checks/consolidate.md` C2

---

## Known drift targets from grounding-1-report.md (2026-06-20)

These are pre-seeded targets the agent must confirm or correct on each run:

| # | Target | Expected severity | Points at |
|---|---|---|---|
| D1 | SSE transport deprecated - rubric already correct | confirm (no finding if still correct) | `checks/security-config.md` F01 |
| D2 | Commands merged into skills - rubric's auto-trigger/explicit criterion is correct | confirm (no finding if still correct) | `checks/entities.md` 5c |
| D3 | E06 skill size threshold - rubric now says 500 (advisory), matching live doc | confirm (no finding if E06 says 500) | `checks/entities.md` E06 |
| D4 | Plugin settings.json key scope - E35 now exists in entities.md 5j | confirm (no finding if E35 is present) | `checks/entities.md` E35 |
| D5 | `~/.claude.json` is MCP user/local config (not `~/.claude/settings.json`) - recon check correct | confirm (no finding if still correct) | `checks/recon.md` |

For each D-target: if the live doc confirms the rubric is correct, do NOT emit a finding.
If the live doc contradicts the rubric, emit a finding with the appropriate severity and detail.
If the live doc is ambiguous, emit a low finding noting the ambiguity.

---

## Evaluation steps

1. Read `${CLAUDE_PLUGIN_ROOT}/skills/clauditor/references/sources.md` to get the current URL table and last-verified dates.
2. Attempt offline probe (fetch the Memory URL). On failure -> degrade (see Offline section above).
3. For each of the 10 subsystems above, `WebFetch` the URL.
4. Compare the "Key points clauditor relies on" against the live page text.
5. For each D-target, determine confirm vs. flag.
6. For any other detected drift not in the D-targets, emit an additional finding.
7. Compile findings, count total rules checked and stale, return the JSON.

Do not emit a finding for a rule that is confirmed correct. Only emit findings for actual drift.

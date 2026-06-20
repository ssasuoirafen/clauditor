# clauditor citation source-of-truth

This is the single source for citations used by clauditor's rubric. Every best-practice rule
in the check files traces to a row in the official table below. Tag `[official]` = Anthropic
docs; `[community]` = third-party. Citations live here only; check files point at this file
rather than inline-linking.

Content is baked-in as of the last-verified dates shown. The `clauditor-rubric-currency` agent
re-checks live docs against this file to surface stale assumptions.

---

## Official docs <!-- last reviewed: 2026-06-20 -->

| Subsystem | Source URL | Tag | Key points clauditor relies on | Last verified |
|---|---|---|---|---|
| Memory / CLAUDE.md | https://code.claude.com/docs/en/memory | [official] | MEMORY.md load cap: first 200 lines or 25 KB, whichever comes first. CLAUDE.md target <200 lines for adherence. Load order: managed -> user -> project -> local (CLAUDE.local.md). Subdirectory CLAUDE.md files load on demand (not at launch). HTML comments stripped before context injection. `autoMemoryDirectory` setting overrides default path. `claudeMdExcludes` skips files by glob. `@path` imports expand at launch (still consume context). | 2026-06-20 |
| Settings | https://code.claude.com/docs/en/settings | [official] | Precedence: managed > CLI > local (settings.local.json) > project (settings.json) > user. Permission allow/deny arrays MERGE across all scopes (union, not override); deny wins over allow. Settings files reload live without restart (except `model` and `outputStyle`). `env` block applies to subprocesses. `allowManagedPermissionRulesOnly` and `allowManagedHooksOnly` lock down user/project hooks/permissions. MCP servers: project in `.mcp.json`; user/local in `~/.claude.json`. `enableAllProjectMcpServers: true` auto-enables all project `.mcp.json` servers (still present in docs). `enabledMcpjsonServers` lists specific servers to approve; `disabledMcpjsonServers` lists servers to reject. | 2026-06-20 |
| Slash commands / Skills | https://code.claude.com/docs/en/slash-commands | [official] | Custom commands merged into skills - `.claude/commands/*.md` and `.claude/skills/<name>/SKILL.md` are equivalent. `disable-model-invocation: true` for explicit-invocation-only skills. Skills take precedence over same-name commands. Skills load on demand (not every session). `description` frontmatter drives auto-trigger matching. `allowed-tools` is pre-approval, not restriction. | 2026-06-20 |
| Subagents | https://code.claude.com/docs/en/sub-agents | [official] | Agent files: `.claude/agents/<name>.md`. Required frontmatter: `name`, `description`. Recommended: `tools:` (restriction), `model:`. `disallowedTools` (camelCase) denies specific tools from the inherited/specified list. Without `tools:` the agent receives all session tools. Agents can preload skills via `skills:` array. Built-in agents: Explore (Haiku, read-only), Plan (read-only), general-purpose (all tools). `skills:` in frontmatter lists which skills are available inside the subagent. | 2026-06-20 |
| Agent Skills | https://code.claude.com/docs/en/skills | [official] | Skill format: `SKILL.md` with YAML frontmatter. `description` required for auto-trigger. Skill body loads on demand only (not every session). Dynamic context injection via `` !`cmd` `` syntax. Skill precedence: enterprise > personal > project > bundled. Plugin skills namespaced as `plugin:skill`. Nested `.claude/skills/` in subdirectories load when Claude works in those directories. No documented hard body-size limit; live doc advisory: keep SKILL.md under 500 lines (E06 threshold). `disallowed-tools` frontmatter removes tools from Claude's pool for the current turn only (clears next message) - a real per-turn restriction mechanism for skills. | 2026-06-20 |
| Hooks | https://code.claude.com/docs/en/hooks | [official] | Five handler types: `command` (shell), `http` (HTTP POST), `mcp_tool`, `prompt` (single-turn LLM), `agent` (subagent). Events (~30 total, non-exhaustive common set): SessionStart, UserPromptSubmit, PreToolUse, PostToolUse, PostToolUseFailure, PermissionRequest, Stop, SessionEnd, SubagentStart, SubagentStop, PreCompact, PostCompact, Notification, InstructionsLoaded, ConfigChange, CwdChanged, FileChanged, WorktreeCreate, WorktreeRemove - see live hooks doc for the full list. Default timeouts: command/http/mcp_tool = 600 s, prompt = 30 s, agent = 60 s. Exit 2 blocks the action; exit 1 is non-blocking. Hooks run without controlling terminal (v2.1.139+). `if` filter fails open - use permission system for hard enforcement. Hooks in: settings.json (project/user/local) and plugin hooks/hooks.json. | 2026-06-20 |
| MCP | https://code.claude.com/docs/en/mcp | [official] | Transport types: `http` (recommended, also accepted as `streamable-http`), `sse` (deprecated), `stdio`, `ws` (WebSocket, persistent bidirectional). Source of truth: `.mcp.json` for project/team; `~/.claude.json` for user/local. `${VAR}` expansion in `.mcp.json` draws from OS/shell env, NOT from settings.json `env` block. `CLAUDE_PROJECT_DIR` injected into stdio server env. Project MCP approval: `enableAllProjectMcpServers: true` auto-enables all; `enabledMcpjsonServers` approves specific servers; `disabledMcpjsonServers` rejects specific servers. Hardcoded tokens in tracked `.mcp.json` = critical leak. | 2026-06-20 |
| Plugins | https://code.claude.com/docs/en/plugins | [official] | Plugin root structure: `.claude-plugin/plugin.json` (manifest), `skills/`, `agents/`, `hooks/hooks.json`, `.mcp.json`, `settings.json`, `commands/`, `bin/`, `monitors/`. Skills inside plugins are namespaced `plugin-name:skill-name`. Manifest fields: `name`, `description`, `version`, `author`. Common mistake: do NOT put `skills/`, `agents/`, etc. inside `.claude-plugin/` - only `plugin.json` goes there. `settings.json` at plugin root: only `agent` and `subagentStatusLine` keys honored. | 2026-06-20 |
| Plugin marketplaces | https://code.claude.com/docs/en/plugin-marketplaces | [official] | Marketplace = `marketplace.json` catalog in a git repo. Official marketplaces: `claude-plugins-official` (Anthropic-curated, auto-available), community marketplace install identifier: `claude-community` (repo: `anthropics/claude-plugins-community`; add via `/plugin marketplace add anthropics/claude-plugins-community`, install via `/plugin install <name>@claude-community`). `claude plugin validate` runs the same checks as the review pipeline. Approved plugins pinned to commit SHA in the community catalog; CI bumps pin on new commits. | 2026-06-20 |
| Best practices | https://code.claude.com/docs/en/best-practices | [official] | CLAUDE.md: target <200 lines; prune entries Claude follows correctly without the instruction; use hooks for must-happen actions. Skills vs CLAUDE.md: skills for domain knowledge/workflows, CLAUDE.md for session-wide facts. Context is the key constraint - subagents keep exploration out of main context. `disable-model-invocation: true` for side-effect workflows. Adversarial review pattern. `/clear` between unrelated tasks. | 2026-06-20 |

---

## Community sources

| Source | URL | Credibility tag | Notes |
|---|---|---|---|
| awesome-claude-code | https://github.com/hesreallyhim/awesome-claude-code | [community] popular-repo | Curated list of Claude Code setups, skills, patterns. High signal but not authoritative; treat as practitioner evidence, not spec. |
| ClaudeLog | https://claudelog.com/ | [community] single-author | Tips and commentary by one practitioner. Lower authority; useful for pattern discovery, not for rubric grounding. |
| Anthropic steering blog | https://claude.com/blog/steering-claude-code-skills-hooks-rules-subagents-and-more | [community] consensus | Official Anthropic blog post on the skills/hooks/rules/subagents architecture. High credibility (Anthropic-authored) but supplementary to the primary docs above. |

---

## What clauditor enforces from each subsystem

| Subsystem | Check file(s) + check IDs |
|---|---|
| Memory / CLAUDE.md | `checks/memory.md` MC1 (MEMORY.md >200 lines), MC2 (>25 KB); `checks/claude-md.md` C04 (version drift), C05 (hardcoded counters), C10 (heading hierarchy), M10 (freshness stamps); `checks/recon.md` M12 (memory path resolution) |
| Settings | `checks/security-config.md` G01-G13 (env/permissions), G20 (model pin), G30 (statusLine), G40-G41 (scope hygiene), M14 (cross-scope permission union); `decision-matrix.md` (scope precedence note) |
| Slash commands / Skills | `checks/entities.md` E01-E07 (skills), E20-E23 (commands), 5c command/skill-merge caveat; `decision-matrix.md` (skills vs commands routing) |
| Subagents | `checks/entities.md` E10-E15 (L9 required fields: name+description, recommended tools+model), 5b agents section |
| Agent Skills | `checks/entities.md` E01-E07 (skill body/description/size), E06 (>500 lines advisory flag), `disallowed-tools` per-turn restriction documented; `decision-matrix.md` (multi-step auto-trigger -> skill) |
| Hooks | `checks/security-config.md` 5e H01-H06 (5 handler types, dangerous patterns, exit codes, scope); `checks/consolidate.md` C4 cross-scope hook flags |
| MCP | `checks/security-config.md` 5f F01-F08 (SSE deprecated -> use http, source-of-truth, blast radius, token leak); `checks/recon.md` (MCP server inventory) |
| Plugins | `checks/entities.md` 5j E30-E35 (plugin vs local collision, intent overlap, plugin settings.json key scope); `checks/recon.md` (enabledPlugins inventory) |
| Plugin marketplaces | `checks/entities.md` E34 (correct plugin for project type not enabled); `checks/security-config.md` F06 (unused server); community marketplace identifier = `claude-community` (repo `anthropics/claude-plugins-community`) |
| Best practices | `checks/claude-md.md` C03 (one-time setup not in CLAUDE.md), C08 (infra URLs); `checks/memory.md` MC1-MC2 (load cap); `checks/rules.md` R01-R10; `checks/consolidate.md` C2 (promotion detection) |

---

## Currency notes (findings from live doc verification 2026-06-20)

The following points were confirmed or found CHANGED on the live docs vs what the rubric assumed:

1. **SSE transport deprecated** - confirmed live: the MCP docs show SSE as deprecated with a
   warning; the rubric's F01-F08 checks correctly treat SSE as a finding. No rubric change needed.

2. **Commands merged into skills** - confirmed live: the skills docs explicitly state "Custom
   commands have been merged into skills." A `.claude/commands/*.md` file and a
   `.claude/skills/<name>/SKILL.md` file are equivalent and both create `/name`. The rubric's
   5a/5c distinction (auto-trigger vs manual) is the real criterion, not file location. The
   decision-matrix and entities checks correctly use auto-trigger vs explicit-invocation as the
   routing criterion.

3. **Skill body size - FIXED** - the live docs do NOT state a 300-line body limit. The live
   skills doc explicitly advises "Keep `SKILL.md` under 500 lines." E06 threshold updated to 500
   (advisory). Currency target D3 is now clean.

4. **MEMORY.md load cap is 200 lines OR 25 KB (first wins)** - confirmed live. The rubric's MC1
   (>200 lines) and MC2 (>25 KB) checks are both correct and independent.

5. **`allowed-tools` in a skill is pre-approval, not restriction** - confirmed live. `disallowed-tools`
   is also now documented: it removes tools from Claude's available pool for the current turn
   (clears next message). E03/E04 updated to acknowledge `disallowed-tools` as a valid per-turn
   restriction; only SESSION-scoped isolation triggers an agent relabel.

6. **`skills:` array in agent frontmatter** - confirmed live: subagents can preload skills via a
   `skills:` array; skills not listed are unavailable inside the subagent. The rubric's entities.md
   already documents this.

7. **Five hook handler types confirmed** - command, http, mcp_tool, prompt, agent. The security-
   config.md M15 table is correct. Hook event list expanded to non-exhaustive (~30 events); rubric
   now marks it as non-exhaustive and lists notable newer events.

8. **`streamable-http` as alias for `http` in MCP JSON** - confirmed live. The rubric does not
   flag `streamable-http` as wrong; this is consistent.

9. **Plugin `settings.json` key scope - FIXED** - confirmed live: only `agent` and
   `subagentStatusLine` are honored. Check E35 added to entities.md 5j section. Currency target
   D4 is now clean.

10. **`~/.claude.json` is the MCP user/local config file** - confirmed live (not `~/.claude/settings.json`
    for MCP). The recon check correctly distinguishes `.mcp.json` (project) from `~/.claude.json`
    (user/local).

11. **`enableAllProjectMcpServers` still present in settings docs** - confirmed live as of
    2026-06-20. The key auto-enables all project `.mcp.json` servers. Two additional related keys
    also documented: `enabledMcpjsonServers` (approve specific servers) and `disabledMcpjsonServers`
    (reject specific servers). Rubric updated to reference all three; F06 check broadened accordingly.

12. **Community marketplace install identifier - FIXED** - the install identifier is `claude-community`
    (not `claude-plugins-community`). Repo is `anthropics/claude-plugins-community`. Add via
    `/plugin marketplace add anthropics/claude-plugins-community`; install via
    `/plugin install <name>@claude-community`. Updated in sources.md and entities.md enforcement row.

13. **Hook events non-exhaustive - FIXED** - live docs list ~30 events (not 7). security-config.md
    now marks the event list as non-exhaustive and includes notable newer events: SubagentStart,
    SubagentStop, PreCompact, PostCompact, SessionEnd, PermissionRequest, and others.

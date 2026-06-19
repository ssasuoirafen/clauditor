# Decision matrix - where things should live

| Artifact | Where |
|---|---|
| Universal project rule (stack, architecture, CI/CD, MCP servers) | `<project>/CLAUDE.md` (project root; `.claude/CLAUDE.md` also supported - profile #1) |
| Universal personal rule (communication style, gitignore strategy) | `~/.claude/CLAUDE.md` |
| Narrow normative rule / convention scoped to specific files (needed only when those files are edited) | `.claude/rules/<name>.md` with `paths:` frontmatter - native path-scoped auto-load |
| Universal-but-modular rule (needed every session, but content size warrants its own file) | `.claude/rules/<name>.md` with no `paths:` - unconditional auto-load |
| Operational / intent-triggered rule (state-destroy safety, PR-close lifecycle, plan/apply quirks - triggers on an action, not a file edit) | `.claude/rules/<name>.md` unconditional (no `paths:` fits) with a `description:` stating the trigger, OR `feedback_*.md` if personal-protective |
| Multi-step AI workflow with auto-trigger by context | `.claude/skills/<name>/SKILL.md` (triggers in `description`) |
| Isolated context / parallelism / restricted tool set / role-specific task | `.claude/agents/<name>.md` (with `tools:` allowlist) |
| Parameterized flow with explicit user invocation (`/release-notes`, `/check <stage>`) | `.claude/commands/<name>.md` |
| Automatic harness reaction to an event (PreToolUse, Stop, PostToolUse) | `.claude/settings.json` section `hooks` (shell command, not an instruction) |
| MCP server registration | `.mcp.json` at repo root (committed if team-shared, gitignored if personal) or `.claude/settings.json` `mcpServers` (personal) |
| Permissions (allow/deny lists) | `.claude/settings.json` `permissions` (project) or `.claude/settings.local.json` (personal) |
| Environment variables (secrets, runtime config) | `.claude/settings.json` `env` (gitignored per-project) |
| Output style override | `.claude/output-styles/<name>.md` |
| Narrow protective rule (one rule per file) | `~/.claude/projects/<encoded-path>/memory/feedback_*.md` |
| Active project / TODO | `~/.claude/projects/<encoded-path>/memory/project_*.md` |
| External resource with URL, tokens, escalation | `~/.claude/projects/<encoded-path>/memory/reference_*.md` |
| Team process / runbook / task template | `.local/docs/` (personal); team wiki if explicitly required by project |
| Setup instructions (MCP setup, CLI install) | NOT in CLAUDE.md (one-time); if needed - in repo README |

**Scope precedence:** managed > CLI > local (`settings.local.json`) > project (`settings.json`) > user (`~/.claude/settings.json`). When auditing, check all scopes - inherited settings affect behavior even if not in project.

Permission allow/deny arrays merge/accumulate across scopes; judge stale/dangerous entries against the union, not per file.

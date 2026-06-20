# Anti-patterns (what NOT to do)

## Duplicates and placement

| Anti-pattern | Why it's bad |
|---|---|
| Memory as backup for rules / CLAUDE.md | Duplicate pollutes context, source of truth becomes unclear |
| `~/.claude/CLAUDE.md` duplicates project CLAUDE.md | Project is for specifics, global is for personal rules - don't mix |
| Setup instructions in CLAUDE.md | One-time things don't need to be in every session |
| Counters (number of models/files) in the stack | Go stale, source of truth is `git ls-files` |
| `.claude/docs/` used as a docs surface | Wrong directory - personal artifacts belong in `.local/docs/`; `.claude/` is for Claude config only |
| Memory entry "MR/PR #N - fixed X" (`feedback_*`) | One-shot context, not a rule |
| `project_*` memory entry for closed/Done ticket | Stale - delete; lifecycle info lives in tracker history |
| `reference_*` memory entry with hardcoded secrets (token, password) | Secrets belong in `settings.json` `env`, not memory |
| `reference_*` memory pointing to URL that 404s | Stale link - update or delete |
| Long execution-plan for a DONE ticket in `.local/docs/` | Past artifact, takes up space |
| Hardcoded response language in agent/skill | Doesn't work in cross-language projects - derive from context |
| Hardcoded project name/ticket prefix in a universal artifact | Not reusable - parameterize it |
| MCP server in both `.mcp.json` and `settings.json` `mcpServers` without intent | Two sources of truth - pick one (or document the override intent) |
| MCP server defined but never used in any workflow | Dead config - removing it shortens MCP init time |
| Hardcoded secret in a **tracked/committed** `.mcp.json` (or tracked `settings.json`/`.env`) | Token leak via git - replace with `${VAR}` from OS env. (A secret in a **gitignored** `.mcp.json` is fine - profile #2.) |
| Real secret in a committed `.env.example` placeholder file | Leak - examples must use placeholders; rotate the exposed value |
| Flagging a hardcoded secret in a gitignored personal `.mcp.json`/`settings.json` | False positive - that's the intended setup (profile #2); only tracked files leak |
| AI-tooling paths (`.claude`/`CLAUDE.md`/`.mcp.json`/`superpowers`) in a COMMITTED `.gitignore` of a deployment-target repo | Leaks internal tooling to the team - move to `.git/info/exclude` (profile #3) |
| Broad-scope credential (`*_GLOBAL_API_KEY`) in `env` next to scoped tokens, no documented reason | Over-privileged - one leak = full access; use the scoped token or document why |
| Recommending deletion of key/cert material in `.local/data/` | Non-regenerable - losing it = re-provision; never auto-delete (Stage 6) |
| CLAUDE.md enumerating files in a gitignored `.local/` scratch dir | Roster drifts silently - use one pointer, not a list |
| Token-bearing `.mcp.json`/`settings.json` in a repo with no `.gitignore` (or no git) | Latent leak if ever committed - add a preemptive `.gitignore` (profile #4) |
| Custom output style with no `outputStyle` setting referencing it | Dead file - delete or activate |

## Wrong entity choice

| Anti-pattern | What it should be | Why |
|---|---|---|
| Domain-specific rule without `paths:` and not universally needed | add `paths:` | Otherwise it loads every session and bloats context |
| Skill for a one-step parameterized flow (`/release-notes`) | command | Skill is for auto-triggering, not manual invocation with an argument |
| Command for knowledge that should auto-trigger | skill | Command requires explicit invocation; auto-knowledge goes through skill triggers |
| Rule with multi-step logic / tool calls | skill | Rule = passive text; steps/tools make it a skill |
| Skill requires SESSION-scoped tool isolation or parallel execution | agent | `disallowed-tools` handles per-turn removal; agent is only needed for session-scoped isolation, not per-turn restriction |
| Skill body >500 lines with no supporting files | split body or move reference material to sibling files | Live doc advisory: keep SKILL.md under 500 lines; move detailed reference to sibling files |
| Skill for role-based tasks ("respond as support") | agent | Context is shared with user, no tool isolation |
| Agent without `tools:` allowlist | add allowlist or make a skill | Isolation loses meaning - the agent sees everything |
| Agent for interactive audit/cleanup with handoff back to main session | command | Subagent runs isolated; orchestration that hands results back belongs in a command. (Subagent CAN call preloaded skills via `skills:` frontmatter, but cannot return to main dialogue.) |
| Hook for a text reminder for me | rule or CLAUDE.md | Hook is a shell command, not an instruction; doesn't influence me |
| Rule applicable to 100% of tasks, in `rules/` | CLAUDE.md | Always needed anyway - no point in lazy-load |
| Relying on CLAUDE.md `@.claude/rules/<rule>` reference to "delay" loading | use `paths:` for scoped load | `@` is a doc-link, not a load mechanism - referenced rules load unconditionally same as inline content |

# Security config check - Stage 5e/5f/5g/5h + secrets/gitignore

Governs what `audit-security-config` checks. Finding and `promotion_signals` shapes are defined in
`${CLAUDE_PLUGIN_ROOT}/skills/audit-claude/references/contracts.md`.

All findings from this reviewer use one of these layers: `"hooks"`, `"mcp"`, `"settings"`,
`"output-styles"`.

Secrets and gitignore policy (profile #2-4) is documented in
`${CLAUDE_PLUGIN_ROOT}/skills/audit-claude/references/profile.md`. Do not restate it here -
derive the rules from profile.md when auditing.

## Precondition

This reviewer always runs - there is no empty-list precondition. Even a project with no hooks,
MCP servers, or settings entries may have secrets findings.

**Security config is configuration, not documents.** Do NOT apply the freshness subroutine to
hooks, settings, or MCP files.

## What to read

```text
# Settings - all three scopes
Read: <project_path>/.claude/settings.json          # project shared
Read: <project_path>/.claude/settings.local.json    # project personal
Read: ~/.claude/settings.json                       # user-level

# MCP registrations
Read: <project_path>/.mcp.json

# Gitignore / tracking status (use Baseline tracked_map for most files)
# For files NOT already in tracked_map, run:
Bash: git -C <project_path> ls-files <file>         # empty = untracked/gitignored

# Committed .gitignore (for AI-tooling leak check, profile #3)
Read: <project_path>/.gitignore

# Local gitignore excludes
Read: <project_path>/.git/info/exclude

# Output styles (project + user scope)
Glob: <project_path>/.claude/output-styles/*.md
Glob: ~/.claude/output-styles/*.md
```

Every Finding MUST include both `gist` (short one-line summary) and `detail` (full
recommendation) per contracts.md.

---

## 5e Hooks

**Concept (M15):** A hook is a deterministic harness reaction at a lifecycle point. The handler
may be one of five types:

| Handler type | Schema key | Notes |
|---|---|---|
| `command` | `command: "<shell>"` | Shell command executed by the OS |
| `http` | `type: "http"`, `url: "..."` | HTTP endpoint called by the harness |
| `prompt` | `type: "prompt"`, ... | Single-turn LLM call |
| `mcp_tool` | `type: "mcp_tool"`, ... | Calls an MCP tool |
| `agent` | `type: "agent"`, ... | Spawns a subagent |

Current default timeouts (from hooks docs):
- `command`, `http`, `mcp_tool`: **600 s**
- `prompt`: **30 s**
- `agent`: **60 s**

"Fast" is **advice** for hooks that block the event loop, not a hard <1 s limit. Do NOT flag
a prompt/agent/http hook as wrong-entity simply because it is not a shell command.

**What IS a wrong-entity hook:** a `command` whose value is prose instruction or a reminder
("Remind yourself to...", "Always check..."), not an executable. That belongs as a **rule** or
in CLAUDE.md.

**Scopes to audit:** project `settings.json`, project `settings.local.json`, user
`~/.claude/settings.json`. User-level hooks fire in this project - they belong in the audit.

| ID  | Check | Action | Severity |
|-----|-------|--------|----------|
| H01 | Hook `command` value is prose text / natural-language instruction, not an executable shell command | `migrate` -> rule or CLAUDE.md | high |
| H02 | Hook performs a destructive operation without a confirmation guard | `flag` | high |
| H03 | `command`-type hook is expected to run slowly (archives, network calls, heavy computation) and blocks the event loop | `flag` - move to background or restructure | medium |
| H04 | Project and user scope define the same matcher with conflicting behavior | `flag` - document precedence; decide whether duplication is intentional | medium |
| H05 | Hook event references a non-existent event name (e.g. `PreToolUseFailure`) | `flag` - correct event is `PostToolUseFailure` | high |
| H06 | Hook uses `type: "http"` or `type: "mcp_tool"` or `type: "agent"` or `type: "prompt"` without required fields | `flag` - missing required schema fields for that handler type | medium |

Emit `action: "keep"` when none of H01-H06 applies.

Common correct uses for reference (do not flag these as wrong):
- `PostToolUse` matcher `Edit|Write` -> formatter (`prettier`, `ruff format`, `tofu fmt`)
- `Stop` -> notification command
- `PreToolUse` matcher `Bash` -> additional validation
- `UserPromptSubmit` -> context injection (e.g. mode reminder)
- `SessionStart` -> env bootstrap or project banner

---

## 5f MCP servers

**Sources:** `<project_path>/.mcp.json` and `settings.json` `mcpServers` key at all three
scopes. Compare the Baseline `entities.mcp_servers` list against both files.

| ID  | Check | Action | Severity |
|-----|-------|--------|----------|
| F01 | Same server defined in both `.mcp.json` AND `settings.json` `mcpServers` without documented intent | `flag` - pick one source of truth or document the override intent | medium |
| F02 | Hardcoded secret/token in `.mcp.json` AND `tracked_map[".mcp.json"] == "tracked"` | `flag` - critical leak; replace with `${VAR}` from OS env | critical |
| F03 | Hardcoded secret/token in `.mcp.json` AND `tracked_map[".mcp.json"] == "gitignored"` | `keep` - gitignored personal setup; NOT a finding (profile #2) | low |
| F04 | Same token in both `.mcp.json` and `settings.json` `env` block | `keep` - expected duplication (profile #2); env block does not reach MCP startup | low |
| F05 | `.mcp.json` exists and `tracked_map[".mcp.json"] == "tracked"` but contains secrets | see F02 | critical |
| F06 | `.mcp.json` exists and `tracked_map[".mcp.json"] == "gitignored"` but team `.mcp.json` is needed and is absent | `flag` - team MCP setup undocumented; decide: commit a secrets-free `.mcp.json` with `${VAR}` refs | low |
| F07 | MCP server defined but never referenced in any workflow, and `enableAllProjectMcpServers: true` | `flag` - unused server; remove to shorten MCP init time | low |
| F08 | MCP server targets production infra (prod IP/host, live API) or unauthenticated datastore | `flag` - blast radius finding; severity depends on impact | high |
| F09 | Project is an MCP-server producer (has `server.py`, `mcp[cli]`/FastMCP in deps, or `project.scripts` entry) but `.mcp.json` is absent | `keep` - correct for a producer repo; do NOT flag absent `.mcp.json` | low |

Emit `action: "keep"` for each server that passes all F01-F09 checks.

### Blast radius

For each consumed MCP server, note what it targets. A server pointed at:
- **Production infra** (prod hostname, live panel/API): F08 finding, severity `high`
- **Unauthenticated datastore** (Redis/DB with no password on a public IP): F08 finding,
  severity `critical`

Tag the finding `layer: "mcp"` with `topic_key: "mcp_blast_radius_<server_name>"`.

---

## 5g Settings: env, permissions, model, statusLine

**Applies to:** all three settings scopes (project `settings.json`, project
`settings.local.json`, user `~/.claude/settings.json`).

### env block

| ID  | Check | Action | Severity |
|-----|-------|--------|----------|
| G01 | `env` key value is a literal secret AND file is `tracked` (git ls-files) | `flag` - critical leak; move to gitignored `settings.local.json` or OS env | critical |
| G02 | `env` key value is a literal secret AND file is `gitignored` | `keep` - profile #2; gitignored personal config | low |
| G03 | `env` key name does not match `^[A-Z][A-Z0-9_]*$` AND is NOT a tool-mandated lowercase key (e.g. `TF_TOKEN_<host>`) | `flag` - normalize to SCREAMING_SNAKE_CASE | low |
| G04 | Broad-scope credential (e.g. `*_GLOBAL_API_KEY`) sits alongside narrower scoped tokens with no documented reason | `flag` - least-privilege; one leak = full access | high |

Do NOT normalize `TF_TOKEN_<host>` keys - OpenTofu/Terraform requires lowercase env var names
derived from the host (dots to underscores). Renaming them breaks auth.

### permissions.allow / permissions.deny

**M14 - cross-scope union:** when auditing permissions, do NOT judge allow/deny entries per-file
in isolation. Tag permission findings as `cross_scope: true` so the barrier (C4) evaluates
stale or dangerous entries against the **union** across all scopes (managed > local >
project > user). Arrays **merge and accumulate** across scopes - an entry absent from the
project file may still be active if inherited from the user file.

For every permission entry found in any scope, also read the other scopes' permission arrays
before deciding whether to flag or keep.

| ID  | Check | Action | Severity |
|-----|-------|--------|----------|
| G10 | `permissions.allow` contains `Bash(*)` (unrestricted shell) | `flag` - dangerous blanket permission; enumerate specific patterns | high |
| G11 | `permissions.allow` or `permissions.deny` entry references a command/tool no longer in use | `flag` (cross-scope) - stale entry; verify against union of all scopes before flagging | medium |
| G12 | Personal allowlist entry (machine-specific path, personal tool) in shared `settings.json` (not `settings.local.json`) | `flag` - scope hygiene; move to `settings.local.json` | low |
| G13 | Team allowlist entry in `settings.local.json` (not `settings.json`) | `flag` - should be in shared `settings.json` for team consistency | medium |

For G11: emit `topic_key: "permission_stale_<entry>"` and set the Finding field
`cross_scope: true` (add this field alongside standard contracts.md fields) so the barrier (C4)
can evaluate the union before acting.

### model

| ID  | Check | Action | Severity |
|-----|-------|--------|----------|
| G20 | `model` pinned at project scope with no documented reason | `flag` - document why (testing baseline, cost control, capability need) | low |

### statusLine

| ID  | Check | Action | Severity |
|-----|-------|--------|----------|
| G30 | `statusLine` command is a heavy operation (network call, DB query, slow tool) | `flag` - must complete in <100 ms typical; slow status lines freeze the UI | medium |

### Scope hygiene

| ID  | Check | Action | Severity |
|-----|-------|--------|----------|
| G40 | Personal preference (theme, personal allowlist, personal env var) in shared `settings.json` | `flag` - move to `settings.local.json` | low |
| G41 | Secret in `settings.json` `env` AND `tracked_map["<file>"] == "tracked"` | see G01 (critical) | critical |

---

## 5h Output styles

**Sources:** `<project_path>/.claude/output-styles/*.md` (project scope) and
`~/.claude/output-styles/*.md` (user scope). Built-in styles (Default, Explanatory, Learning,
Proactive) ship with Claude Code - no file needed for those.

The active style is the `outputStyle` key in settings - check all three scopes (project
`settings.json`, `settings.local.json`, user `~/.claude/settings.json`).

| ID  | Check | Action | Severity |
|-----|-------|--------|----------|
| O01 | Custom output-style file exists but no `outputStyle` key in any settings scope references it | `delete` (dead file) or `flag` to activate | low |
| O02 | `outputStyle` key references a style name but no matching file exists and it is not a built-in | `flag` - broken reference; create the file or correct the key | medium |

Emit `action: "keep"` for styles that are defined and referenced, or for the absence of custom
styles (absence is not a finding).

---

## Secrets and gitignore audit (profile #2-4)

Policy source: `${CLAUDE_PLUGIN_ROOT}/skills/audit-claude/references/profile.md` (profiles
#2-4). Do not restate the policy - derive the rules from profile.md.

**Tracking status:** use `Baseline.tracked_map` as the primary source. Only files listed with
`"tracked"` can produce a secret-leak finding. A secret in a `"gitignored"` file is
acceptable per profile #2. A secret in an `"absent"` file cannot leak. For files not in
`tracked_map`, confirm with `git ls-files`.

**Hardcoded secret heuristics** (apply to file content when reading env/mcp/settings files):

- Matches a known token pattern: `ghp_`, `glpat-`, `xoxb-`, `sk-`, `AIza`, `AKIA` prefixes
- A key-value pair where the value is >20 chars of mixed case, digits, and symbols not
  matching a URL or file path
- A field named `token`, `api_key`, `apiKey`, `secret`, `password`, `credential`,
  `private_key`, or similar in a JSON object, with a non-`${VAR}` value

| ID  | Check | Action | Severity |
|-----|-------|--------|----------|
| S01 | Hardcoded secret in a **tracked** file (git ls-files hit) | `flag` - critical leak; rotate the value, replace with `${VAR}` or move to gitignored file | critical |
| S02 | Hardcoded secret in a **gitignored** file | `keep` - profile #2; NOT a finding | low |
| S03 | Committed `.gitignore` names AI-tooling paths (`.claude`, `CLAUDE`, `mcp`, `superpowers`, `AI`) | `flag` - leaks internal tooling to the team; move those exclusions to `.git/info/exclude` | medium |
| S04 | No git layer (`tracked_map` values all `"no-git"`) AND a token-bearing file exists | `flag` - latent leak; add a preemptive `.gitignore` (profile #4) | medium |
| S05 | Real secret (non-placeholder) in a committed `.env.example` | `flag` - critical leak; rotate value, replace with placeholder | critical |
| S06 | `env`<->`.mcp.json` token duplication (same token in both) | `keep` - expected per profile #2; NOT a finding | low |

Do NOT flag `.local/` in a committed `.gitignore`. Do NOT propose moving `.local/` exclusions -
see memory [[local-gitignore-placement]].

For each file audited under this section, emit one Finding:
- `layer: "settings"` for settings files, `layer: "mcp"` for `.mcp.json` files
- `path`: absolute path to the file
- `gist`: one-line summary (e.g. "hardcoded token in tracked .mcp.json - critical leak")
- `detail`: precise recommendation

---

## Cross-scope dedup note

> **Cross-layer dedup is NOT this reviewer's job.** Emit a precise `topic_key` and `gist` on
> every Finding (including `action: "keep"`) so `audit-consolidate` barrier C4 can detect
> permission/precedence conflicts across all reviewer outputs.
>
> **Permission findings** (G10-G13): always tag with `cross_scope: true` so the barrier
> evaluates them against the union of all scopes, not per-file.

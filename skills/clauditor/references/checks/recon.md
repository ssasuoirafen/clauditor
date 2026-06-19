# Recon check - Stage 1 inventory + reality baseline

This document governs what the `clauditor-recon` agent collects. Output shape is defined in
`${CLAUDE_PLUGIN_ROOT}/skills/clauditor/references/contracts.md` (Baseline section) - do not redefine it here.

## What to collect

Collect in parallel (translate the snippets to Glob/Read/Grep tool calls; they are
illustrative shell, not executable):

```text
# Project CLAUDE.md - ROOT first (user keeps it there), .claude/ as fallback (profile #1)
Read: <project>/CLAUDE.md
Read: <project>/.claude/CLAUDE.md               # fallback only

# Project .claude/ surface
Glob: <project>/.claude/**/*
Glob: <project>/.claude/skills/*/SKILL.md
Glob: <project>/.claude/agents/*.md
Glob: <project>/.claude/commands/*.md
Glob: <project>/.claude/rules/*.md
Glob: <project>/.claude/output-styles/*.md
Glob: <project>/.claude/hooks/*

# Settings (all scopes - read each if present)
Read: <project>/.claude/settings.json          # project shared
Read: <project>/.claude/settings.local.json    # project personal (gitignored)
Read: ~/.claude/settings.json                  # user-level
# Inspect keys: hooks, permissions, env, mcpServers, model, statusLine

# MCP server registrations
Read: <project>/.mcp.json                      # may be committed (team-shared) or gitignored (personal)
# Cross-check with settings.json mcpServers key

# Secrets surface + gitignore reality (profile #2-4)
Glob: <project>/.env*                          # read committed .env.example AND gitignored .env/.env.local
Bash: git -C <project> ls-files                # TRACKED files - secrets here = real leak; gitignored = OK
Bash: git -C <project> check-ignore .mcp.json .claude/settings.json CLAUDE.md
Read: <project>/.gitignore                     # COMMITTED - grep for .claude/CLAUDE/mcp/.local/superpowers/AI
Read: <project>/.git/info/exclude              # local excludes
# If <project>/.git is absent -> no-git project; record it (profile #4: unprotected-secrets finding)

# User-level entities (may affect this project)
Glob: ~/.claude/CLAUDE.md
Glob: ~/.claude/skills/*/SKILL.md
Glob: ~/.claude/agents/*.md
Glob: ~/.claude/commands/*.md

# Installed plugins
Glob: ~/.claude/plugins/marketplaces/*/plugins/*/commands/*.md
Glob: ~/.claude/plugins/marketplaces/*/plugins/*/skills/*/SKILL.md
# enabledPlugins key in settings.json lists which are active

# Working artifacts (.local/ is a multi-surface tree - profile #5)
Glob: <project>/.local/**/*
Glob: <project>/.local/docs/**/*               # notes/analysis
Glob: <project>/.local/projects/**/*           # ACTIVE work trackers
Glob: <project>/.local/data/**/*               # payloads - may hold non-regenerable keys/certs

# Auto memory (see "Memory path resolution" below)
# If <memory-dir> is absent -> no memory for this project; note it and skip Stage 2 cleanly.
Glob: <memory-dir>/*.md
Read: <memory-dir>/MEMORY.md
# Parent-scope memory also loads (profile #6) - inventory it too:
Glob: <parent-memory-dir>/*.md                 # slug of <project>'s parent dir
Read: <parent-memory-dir>/MEMORY.md

# Actual stack versions (read whichever exist)
Read: <project>/pyproject.toml      # Python deps
Read: <project>/package.json        # Node
Read: <project>/setup.cfg           # sqlfluff config
Read: <project>/Cargo.toml          # Rust
Read: <project>/go.mod              # Go

# Rule references in CLAUDE.md (reference-style discovery)
Grep pattern: 'rules/|@\.claude|@rules' in <project>/CLAUDE.md   # ROOT (profile #1)
```

## Memory path resolution (M12)

Auto-memory lives at `~/.claude/projects/<encoded>/memory/`. Always anchor derivation to the
**git repo root** - run `git -C <passed-path> rev-parse --show-toplevel` before doing anything
else. If no git repo, fall back to the literal passed path.

### Step 1 - check autoMemoryDirectory first

Read `~/.claude/settings.json`. If an `autoMemoryDirectory` key is present, the memory path is
set explicitly and no encoding is needed - use that path directly (substituting the project slug
as configured). Skip to output.

### Step 2 - glob (primary method)

Use the glob as the primary resolver. It handles on-disk directory name casing automatically
without needing to know the exact encoding:

```
Glob: ~/.claude/projects/*<last-segment-of-git-root>*/memory/MEMORY.md
```

`last-segment` is the final component of the git root path. For example, if the git root is
`C:\Users\foo\Projects\bar`, use `bar`:

```
Glob: ~/.claude/projects/*bar*/memory/MEMORY.md
```

Take the first match. If the glob returns multiple candidates, prefer the one whose full slug
has the longest suffix match with the full git root path.

Derive the parent-scope dir the same way (last segment = parent directory name):

```
Glob: ~/.claude/projects/*Projects*/memory/MEMORY.md
```

### Step 3 - manual derivation (fallback only)

Use only if Step 2 returns no results.

Starting from the git repo root path:

1. Replace each `:` (Windows drive separator) with `-`
2. Replace each `\` (Windows) or `/` (POSIX) path separator with `-`
3. The sequence `:\` collapses to `--`

**Do not assume any particular casing** for the drive letter or path components. On-disk
directory names under `~/.claude/projects/` use mixed case that may not match what you expect.
The glob approach in Step 2 avoids this entirely.

Worked examples (git root as input):

- `C:\Users\foo\Projects\bar` -> encoded: `C--Users-foo-Projects-bar`
  (but glob is safer - on-disk may be `c--Users-foo-Projects-bar` or `C--Users-foo-Projects-bar`)
- `/home/foo/projects/bar` (POSIX) -> `-home-foo-projects-bar`

## Ticket ID collection and status resolution

After completing inventory, collect all ticket identifiers referenced anywhere in:
- memory files (`<memory-dir>/*.md`, `<parent-memory-dir>/*.md`)
- `.local/` files (all files in `local_surface.docs`, `local_surface.projects`)
- `CLAUDE.md` (at path resolved from `claude_md_path`)

Ticket ID pattern: `[A-Z]+-\d+` (e.g. `PROJ-123`, `GH-456`, `LINEAR-789`).

**Interactive mode + tracker MCP reachable:** resolve each unique ticket ID via the Jira/tracker
MCP tool. For each ticket, record its status (e.g. `open`, `closed`, `done`, `resolved`). Stamp
results into `Baseline.ticket_status`:

```json
{
  "PROJ-1":  "closed",
  "PROJ-42": "open",
  "GH-7":    "done"
}
```

Normalize statuses: treat `done`, `resolved`, `closed`, `completed` as `"closed"`; all others
as `"open"`.

**Read-only mode or tracker MCP not reachable:** set each collected ticket ID's status to
`"unknown"` in `Baseline.ticket_status`. Do not call any tracker tool.

## What to record

This becomes the Baseline JSON consumed by all reviewer agents. Populate every field defined in
`${CLAUDE_PLUGIN_ROOT}/skills/clauditor/references/contracts.md`. Key mappings from this stage:

| Baseline field | Source |
|---|---|
| `mode` | prompt argument (read-only \| interactive) |
| `project_path` | audited project path passed to the audit (default: cwd) - NOT necessarily the git root; repo-relative checks use `git -C <project_path> rev-parse --show-toplevel` as the git root, which may differ if the project is nested inside a larger repo (use the passed path as `project_path` in that case) |
| `repo_type` | CLAUDE.md content + gitignore patterns + org/domain signals |
| `project_kind` | pyproject.toml / package.json / presence of `server.py` / IaC files |
| `memory_dir` | resolved abs path from Step 1/2/3, or null |
| `parent_memory_dir` | slug of parent directory, or null |
| `stack_versions` | pyproject.toml / package.json / Cargo.toml / go.mod |
| `entities` | full inventory: skills, agents, commands, rules, hooks, output_styles, mcp_servers, plugins |
| `tracked_map` | `git ls-files` result per sensitive file: `tracked`, `gitignored`, `no-git`, or `absent` (`absent` = file does not exist on disk) |
| `local_surface` | docs / projects / data file lists |
| `claude_md_path` | `root` if `<project>/CLAUDE.md` exists; `.claude` if only `.claude/CLAUDE.md`; `missing` |
| `agents_md_present` | true if `<project>/AGENTS.md` exists |
| `ticket_status` | map of ticket ID -> status string; populated by recon (see "Ticket ID collection" above) |

### Notes for reviewer agents consuming this baseline

- `entities.rules` entries must include a boolean field `has_paths` (true when the rule file has
  `paths:` frontmatter, false otherwise). This is the canonical field name - do NOT use
  `has_paths_frontmatter` or any other variant.
- `entities.agents` entries must include a boolean field `has_tools` (true when the agent file has
  a `tools:` frontmatter line, false otherwise). This is the canonical field name - do NOT use
  `has_tools_frontmatter` or any other variant.
- `entities.mcp_servers` must record source (`.mcp.json` vs `settings.json mcpServers`) and
  gitignore status (consumed by Stage 5f reviewer).
- `tracked_map` must include at minimum: `.mcp.json`, `.claude/settings.json`,
  `.claude/settings.local.json`, `CLAUDE.md`, any `.env*` files found.
- If the project has no git repo, set all `tracked_map` values to `no-git` and note the
  unprotected-secrets risk (profile #4).

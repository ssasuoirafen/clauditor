# Recon check — Stage 1 inventory + reality baseline

This document governs what the `audit-recon` agent collects. Output shape is defined in
`references/contracts.md` (Baseline section) — do not redefine it here.

## What to collect

Collect in parallel (translate the snippets to Glob/Read/Grep tool calls; they are
illustrative shell, not executable):

```text
# Project CLAUDE.md — ROOT first (user keeps it there), .claude/ as fallback (profile #1)
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

# Settings (all scopes — read each if present)
Read: <project>/.claude/settings.json          # project shared
Read: <project>/.claude/settings.local.json    # project personal (gitignored)
Read: ~/.claude/settings.json                  # user-level
# Inspect keys: hooks, permissions, env, mcpServers, model, statusLine

# MCP server registrations
Read: <project>/.mcp.json                      # may be committed (team-shared) or gitignored (personal)
# Cross-check with settings.json mcpServers key

# Secrets surface + gitignore reality (profile #2-4)
Glob: <project>/.env*                          # read committed .env.example AND gitignored .env/.env.local
Bash: git -C <project> ls-files                # TRACKED files — secrets here = real leak; gitignored = OK
Bash: git -C <project> check-ignore .mcp.json .claude/settings.json CLAUDE.md
Read: <project>/.gitignore                     # COMMITTED — grep for .claude/CLAUDE/mcp/.local/superpowers/AI
Read: <project>/.git/info/exclude              # local excludes
# If <project>/.git is absent → no-git project; record it (profile #4: unprotected-secrets finding)

# User-level entities (may affect this project)
Glob: ~/.claude/CLAUDE.md
Glob: ~/.claude/skills/*/SKILL.md
Glob: ~/.claude/agents/*.md
Glob: ~/.claude/commands/*.md

# Installed plugins
Glob: ~/.claude/plugins/marketplaces/*/plugins/*/commands/*.md
Glob: ~/.claude/plugins/marketplaces/*/plugins/*/skills/*/SKILL.md
# enabledPlugins key in settings.json lists which are active

# Working artifacts (.local/ is a multi-surface tree — profile #5)
Glob: <project>/.local/**/*
Glob: <project>/.local/docs/**/*               # notes/analysis
Glob: <project>/.local/projects/**/*           # ACTIVE work trackers
Glob: <project>/.local/data/**/*               # payloads — may hold non-regenerable keys/certs

# Auto memory (see "Memory path resolution" below)
# If <memory-dir> is absent → no memory for this project; note it and skip Stage 2 cleanly.
Glob: <memory-dir>/*.md
Read: <memory-dir>/MEMORY.md
# Parent-scope memory also loads (profile #6) — inventory it too:
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
**git repo root** — run `git -C <passed-path> rev-parse --show-toplevel` before doing anything
else. If no git repo, fall back to the literal passed path.

### Step 1 — check autoMemoryDirectory first

Read `~/.claude/settings.json`. If an `autoMemoryDirectory` key is present, the memory path is
set explicitly and no encoding is needed — use that path directly (substituting the project slug
as configured). Skip to output.

### Step 2 — glob (primary method)

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

### Step 3 — manual derivation (fallback only)

Use only if Step 2 returns no results.

Starting from the git repo root path:

1. Replace each `:` (Windows drive separator) with `-`
2. Replace each `\` (Windows) or `/` (POSIX) path separator with `-`
3. The sequence `:\` collapses to `--`

**Do not assume any particular casing** for the drive letter or path components. On-disk
directory names under `~/.claude/projects/` use mixed case that may not match what you expect.
The glob approach in Step 2 avoids this entirely.

Worked examples (git root as input):

- `C:\Users\foo\Projects\bar` → encoded: `C--Users-foo-Projects-bar`
  (but glob is safer — on-disk may be `c--Users-foo-Projects-bar` or `C--Users-foo-Projects-bar`)
- `/home/foo/projects/bar` (POSIX) → `-home-foo-projects-bar`

## What to record

This becomes the Baseline JSON consumed by all reviewer agents. Populate every field defined in
`references/contracts.md`. Key mappings from this stage:

| Baseline field | Source |
|---|---|
| `mode` | prompt argument (read-only \| interactive) |
| `project_path` | git root from `git rev-parse --show-toplevel` |
| `repo_type` | CLAUDE.md content + gitignore patterns + org/domain signals |
| `project_kind` | pyproject.toml / package.json / presence of `server.py` / IaC files |
| `memory_dir` | resolved abs path from Step 1/2/3, or null |
| `parent_memory_dir` | slug of parent directory, or null |
| `stack_versions` | pyproject.toml / package.json / Cargo.toml / go.mod |
| `entities` | full inventory: skills, agents, commands, rules, hooks, output_styles, mcp_servers, plugins |
| `tracked_map` | `git ls-files` result per sensitive file: `tracked`, `gitignored`, or `no-git` |
| `local_surface` | docs / projects / data file lists |
| `claude_md_path` | `root` if `<project>/CLAUDE.md` exists; `.claude` if only `.claude/CLAUDE.md`; `missing` |
| `agents_md_present` | true if `<project>/AGENTS.md` exists |

### Notes for reviewer agents consuming this baseline

- `entities.rules` entries must include whether each rule has `paths:` frontmatter (consumed by
  Stage 3/4 reviewer).
- `entities.mcp_servers` must record source (`.mcp.json` vs `settings.json mcpServers`) and
  gitignore status (consumed by Stage 5f reviewer).
- `tracked_map` must include at minimum: `.mcp.json`, `.claude/settings.json`,
  `.claude/settings.local.json`, `CLAUDE.md`, any `.env*` files found.
- If the project has no git repo, set all `tracked_map` values to `no-git` and note the
  unprotected-secrets risk (profile #4).

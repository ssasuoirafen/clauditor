# Shared contracts

JSON shapes shared across all audit agents. Every agent reads this file; no agent redefines these shapes.

## Baseline

Output produced by `audit-recon`; consumed by all reviewer agents and `audit-consolidate`.

```json
{
  "mode": "read-only|interactive",
  "project_path": "abs path",
  "repo_type": "personal|avotech|deployment-target|PureGym|no-git",
  "project_kind": "consumer|mcp-producer|infra|web-app",
  "memory_dir": "resolved abs path or null",
  "parent_memory_dir": "abs path or null",
  "stack_versions": { "<tool>": "<version-from-deps>" },
  "entities": {
    "rules":         [{ "name": "...", "has_paths": true }],
    "agents":        [{ "name": "...", "has_tools": true }],
    "skills":        [{ "name": "..." }],
    "commands":      [{ "name": "..." }],
    "hooks":         [{ "name": "..." }],
    "output_styles": [{ "name": "..." }],
    "mcp_servers":   [{ "name": "..." }],
    "plugins":       [{ "name": "..." }]
  },
  "tracked_map": { "<file>": "tracked|gitignored|no-git|absent" },
  "local_surface": { "docs": [], "projects": [], "data": [] },
  "claude_md_path": "root|.claude|missing",
  "agents_md_present": true
}
```

`entities` values are objects (not bare strings) so reviewers can read frontmatter flags (`has_paths`, `has_tools`) without re-globbing.

`tracked_map` value `absent` means the file does not exist on disk (distinct from `gitignored`, which requires the file to be present but excluded).

## Finding

Emitted by every reviewer agent as an array; consumed by `audit-consolidate` for cross-layer dedup and promotion.

Use `path` for a single-file finding; use `paths` (array) when the finding spans multiple files, e.g. a merge; set `path` to the primary/first file for back-compat. `paths` is optional.

```json
{
  "layer": "memory|rules|claude-md|entities|hooks|mcp|settings|output-styles|local-docs",
  "path": "abs path",
  "paths": ["abs path", "..."],
  "topic_key": "short normalized key for cross-layer matching",
  "gist": "one-line normalized statement of the content/issue",
  "severity": "critical|high|medium|low",
  "action": "delete|migrate|merge|add-paths|relabel|flag|keep",
  "detail": "specific recommendation"
}
```

## promotion_signals

Emitted by reviewer agents that feed promotion (memory, claude-md, local-docs); consumed by `audit-consolidate`.

```json
{ "kind": "feedback-cluster|claude-md-procedure|local-runbook", "topic_key": "...", "count": 2, "paths": [] }
```

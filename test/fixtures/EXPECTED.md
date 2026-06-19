# Expected findings - audit fixture

One row per planted issue. Format: `reviewer | file | expected finding`

| reviewer | file | expected finding |
|---|---|---|
| audit-claude-md | sample-project/CLAUDE.md | stack python 3.10 != pyproject >=3.12 |
| audit-claude-md | sample-project/CLAUDE.md | duplicate rule: "Always use snake_case for identifiers" appears twice |
| audit-claude-md | sample-project/CLAUDE.md | multi-step "Adding a new model" procedure is a promotion candidate (move to rule or agent) |
| audit-claude-md | sample-project/AGENTS.md | present but not imported via @AGENTS.md in CLAUDE.md (H7) |
| audit-rules | sample-project/.claude/rules/sql-style.md | file-scoped content but missing paths: frontmatter (add paths:) |
| audit-entities | sample-project/.claude/agents/helper.md | agent definition has no tools: allowlist (L9) |
| audit-security-config | sample-project/.claude/settings.json | hardcoded secret FAKE_TOKEN=secret123 in env in tracked file (leak) |
| audit-security-config | sample-project/.claude/settings.json | hooks command is a prose reminder string, not a shell command (M15) |
| audit-security-config | sample-project/.mcp.json | hardcoded API_TOKEN in tracked .mcp.json (leak) |
| audit-local-docs | sample-project/.local/docs/done-PROJ-1.md | closed-ticket artifact (delete) |
| audit-local-docs | sample-project/.local/data/node-secretkey.pem | non-regenerable key file, must-keep (never delete) |
| audit-memory | memory/feedback_sql_a.md, memory/feedback_sql_b.md | >=2 feedback entries on the same topic (merge or promote to rule) |
| audit-consolidate | (cross) | promotion: 2x sql feedback + sql-style rule -> propose rule consolidation |

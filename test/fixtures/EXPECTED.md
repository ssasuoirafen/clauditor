# Expected findings - audit fixture

One row per planted issue. Format: `reviewer | file | expected finding`

| reviewer | file | expected finding |
|---|---|---|
| clauditor-claude-md | sample-project/CLAUDE.md | stack python 3.10 != pyproject >=3.12 |
| clauditor-claude-md | sample-project/CLAUDE.md | duplicate rule: "Always use snake_case for identifiers" appears twice |
| clauditor-claude-md | sample-project/CLAUDE.md | multi-step "Adding a new model" procedure is a promotion candidate (move to rule or agent) |
| clauditor-claude-md | sample-project/AGENTS.md | present but not imported via @AGENTS.md in CLAUDE.md (H7) |
| clauditor-rules | sample-project/.claude/rules/sql-style.md | file-scoped content but missing paths: frontmatter (add paths:) |
| clauditor-entities | sample-project/.claude/agents/helper.md | agent definition has no tools: allowlist (L9) |
| clauditor-security-config | sample-project/.claude/settings.json | hardcoded secret FAKE_TOKEN=secret123 in env in tracked file (leak) |
| clauditor-security-config | sample-project/.claude/settings.json | hooks command is a prose reminder string, not a shell command (M15) |
| clauditor-security-config | sample-project/.mcp.json | hardcoded API_TOKEN in tracked .mcp.json (leak) |
| clauditor-local-docs | sample-project/.local/docs/done-PROJ-1.md | closed-ticket artifact (delete) |
| clauditor-local-docs | sample-project/.local/docs/zametki-arhitektura.md | language outlier: RU prose while corpus norm is EN - flag, confirm intended audience language (7.6) |
| clauditor-local-docs | sample-project/.local/data/node-secretkey.pem | non-regenerable key file, must-keep (never delete) |
| clauditor-memory | memory/feedback_sql_a.md, memory/feedback_sql_b.md | >=2 feedback entries on the same topic (merge or promote to rule) |
| clauditor-memory | memory/project_done.md | closed-ticket project context (PROJ-42 closed 2024-12-01), stale - delete |
| clauditor-consolidate | (cross) | promotion: 2x sql feedback + sql-style rule -> propose rule consolidation |

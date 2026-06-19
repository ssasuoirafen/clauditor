# Agent Guidelines

This file describes how AI agents should interact with this project.

## Scope

Agents are allowed to read and modify files under `src/` and `tests/`.
Agents must not modify `migrations/` without explicit user instruction.

## Style

Follow the conventions in CLAUDE.md. All generated code must pass `make lint`.

## Testing

Always run `make test` after making changes. Do not mark a task done if tests fail.

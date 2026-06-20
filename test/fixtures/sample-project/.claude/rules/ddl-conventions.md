---
description: DDL authoring conventions for this repo
paths: ["**/*.sql", "migrations/**/*.sql"]
---

# DDL conventions

Normative guidance for writing DDL in this repo.

- Always specify an explicit distribution key on a new table; never rely on the default.
- Name constraints explicitly (`pk_<table>`, `fk_<table>_<ref>`); do not let the engine auto-name them.
- Since Postgres 14, use `ADD COLUMN ... DEFAULT` for non-volatile defaults - it no longer rewrites the table.
- Write idempotent migrations: guard every `CREATE` with `IF NOT EXISTS`.

## Migration status (completed 2026-03-01)

All stages 1-4 of the legacy-schema migration are done. Final audit: 0 violations.

## Changelog

- Fixed issue with missing distribution key in MR #42 (resolved 2026-02-10).
- DWHFR-318 closed: constraint naming applied across all tables.

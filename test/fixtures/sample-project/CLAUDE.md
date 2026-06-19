# Sample Project

## Stack

<!-- planted issue: python version here contradicts pyproject.toml requires-python = ">=3.12" -->
python = 3.10
node = 20
postgres = 15

## Code style

- Always use snake_case for identifiers.
- Never commit secrets to version control.
- Always use snake_case for identifiers.

## Adding a new model

To add a new model, follow these steps:

1. Create a new file under `src/models/` with the model name.
2. Add the model class inheriting from `BaseModel`.
3. Register the model in `src/models/__init__.py`.
4. Add a migration script under `migrations/` for any schema changes.
5. Update `docs/models.md` with the model description and field reference.
6. Run `make test` and confirm all model tests pass.
7. Open a PR and request a review from the team.

## Database conventions

- Use lowercase table and column names.
- Prefer `timestamptz` over `timestamp` for all datetime columns.
- All tables must have a `created_at` and `updated_at` column.

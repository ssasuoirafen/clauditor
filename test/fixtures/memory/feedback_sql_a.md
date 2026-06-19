# Feedback: SQL query formatting

Always use explicit column aliases in SELECT statements. Avoid `SELECT *` in production queries
because it breaks when the underlying table schema changes.

Use `snake_case` for all alias names.

<!-- planted issue: no paths: frontmatter - this rule is clearly scoped to SQL files but missing paths: ["**/*.sql"] -->

# SQL Style Rules

- Use lowercase for all SQL keywords (select, from, where, join, etc.).
- Indent with 2 spaces; do not use tabs.
- Always alias table names in multi-table queries.
- Use explicit JOIN syntax; never implicit comma-join.
- Terminate every statement with a semicolon.
- Column references in SELECT must be fully qualified when joining 2+ tables.
- CTEs are preferred over subqueries for readability.

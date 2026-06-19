# Feedback: SQL column selection

Do not use `SELECT *` - always list columns explicitly. This prevents silent breakage when
columns are added or reordered in the source table. Alias all columns with descriptive names
in `snake_case`.

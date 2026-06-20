-- Minimal migration so ddl-conventions.md paths: glob resolves (avoids an incidental R03 dead-glob finding).
CREATE TABLE IF NOT EXISTS example (
    id integer
);

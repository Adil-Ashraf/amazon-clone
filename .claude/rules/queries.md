---
paths:
  - "app/queries/**"
  - "spec/queries/**"
---

# Query Object Conventions

- Single responsibility: one query concern per class
- Accept context via constructor (`user:` when results are per user)
- Return `ActiveRecord::Relation` for chainability, or `Hash` for aggregations
- Public method: `#call` with optional filter parameters
- Always use `includes`/`preload`/`eager_load` to prevent N+1 queries
- Never modify data in queries -- read-only
- Sanitize user input: `sanitize_sql_like()`, parameterized queries
- Simple one-liner queries should stay as model scopes (full-text search is
  already the `Product.search_full_text` pg_search scope)
- Test per-user isolation: user A's query never returns user B's records

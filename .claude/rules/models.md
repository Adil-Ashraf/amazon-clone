---
paths:
  - "app/models/**"
  - "spec/models/**"
  - "spec/factories/**"
---

# Model Conventions

- Keep models thin: data, validations, associations, scopes, simple predicates only
  (`Product#out_of_stock?`, `#low_stock?`)
- Complex business logic goes in service objects (`app/services/`)
- Use callbacks only for data normalization (`before_validation :downcase_email`) and defaults (`after_initialize`)
- Side effects (emails, API calls, job enqueueing, creating related records) belong in services, not callbacks
- Always specify `dependent:` on `has_many`/`has_one` associations
- Use `enum :status, { pending: 0, paid: 1, shipped: 2 }` (hash syntax with explicit integers)
- Validate presence at both model and database level (`null: false` in migration)
- Money columns are integer cents (`price_cents`) validated with `only_integer`
- Ownership is per user: records belong to a `User` directly (`Cart`, `Order`) or
  through one (`CartItem` via `Cart`, `OrderItem` via `Order`). There is no
  account or tenant layer.
- Use scopes for reusable queries; use query objects (`app/queries/`) for complex ones
- Every model must have a factory in `spec/factories/` with traits for each state
- Test with Shoulda Matchers: `validate_presence_of`, `belong_to`, `have_many`

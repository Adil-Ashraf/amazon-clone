---
paths:
  - "app/services/**"
  - "spec/services/**"
---

# Service Object Conventions

- Namespace by domain: `Carts::CartService`, `Orders::CheckoutService`.
- No `ApplicationService` base class. Don't create one (YAGNI) — two plain
  Ruby classes don't need a shared parent.
- A single-operation service exposes `#call` (`Orders::CheckoutService.new(user:,
  shipping_attributes:).call`). An aggregate service that owns one object's
  mutations may expose named methods instead (`Carts::CartService#add_item`,
  `#update_quantity`, `#remove_item`).
- Take collaborators and inputs through the constructor or keyword arguments.
- Domain failures raise namespaced error classes defined on the service
  (`Carts::CartService::InsufficientStockError`,
  `Orders::CheckoutService::EmptyCartError`). Controllers rescue them and
  render a message; they never leak as 500s.
- When the caller needs a multi-part outcome rather than a single record,
  return a `Data.define` result instead of a loose hash. Don't add one when a
  record or an exception already says everything.
- Wrap multi-row writes in `ActiveRecord::Base.transaction` so a failure
  leaves nothing half-written.
- When rows must be locked, lock them in a stable order (e.g. by `product_id`)
  so concurrent operations can't deadlock. Re-check invariants (stock) after
  taking the lock.
- Specs live in `spec/services/`. Cover the success path's DB effects and
  every error class, including that a failure changes nothing (use
  `not_to change` around the call).

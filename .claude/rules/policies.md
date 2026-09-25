---
paths:
  - "app/policies/**"
  - "spec/policies/**"
---

# Pundit Policy Conventions

- One policy per model: `app/policies/order_policy.rb`, inheriting `ApplicationPolicy`
- Default deny: return `false` unless explicitly allowed
- Isolation is per user. The roles are **owner**, **another signed-in user**
  and **guest** — there is no admin role. Ownership checks compare
  `record.user_id == user.id` (see `CartPolicy`, `OrderPolicy`).
- Scope through `current_user` associations first, authorize second:
  `current_user.orders.find(id)` makes another user's record a 404 before the
  policy runs; `authorize @order` then states the rule explicitly.
- Add a `Scope` class only when an index can't be expressed as a
  `current_user` association.
- Controllers call `authorize` on every action that touches a user-owned record
- Test every action for owner, another user and guest in `spec/policies/`, and
  the 404 for another user's record in `spec/requests/`

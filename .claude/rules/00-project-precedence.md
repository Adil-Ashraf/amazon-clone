---
paths:
  - "app/**"
  - "spec/**"
  - "config/**"
  - "db/**"
---

# Project Precedence

This file is the single authority for how this repo is built.

**Order of authority — higher wins on any conflict:**

1. This file
2. The other files in `.claude/rules/`
3. `.claude/agents/`, `.claude/skills/` and `.claude/commands/`

## Stack

A **full-stack Rails 8.1 monolith**:

- **ERB views** rendered by the controllers, with shared partials in
  `app/views/shared/`.
- **Hotwire**: Turbo Frames and Turbo Streams, plus Stimulus controllers
  loaded via **importmap** (no Node bundler).
- **Tailwind v4** via `tailwindcss-rails`; design tokens live in `@theme` in
  `app/assets/tailwind/application.css`.
- **Propshaft** for the asset pipeline. **PostgreSQL**, with `pg_search` for
  product search and `pagy` for pagination.

## Where code goes

- Business logic lives in `app/services`: `Carts::CartService` for cart
  mutations, `Orders::CheckoutService` for placing orders. Controllers stay
  thin — parse params, call a service, render or redirect.
- Authorization is per user: a signed-in owner, another user, or a guest.
  There is no admin role and no multi-tenancy. Scope every lookup through
  `current_user` associations first (`current_user.orders.find(id)`,
  `current_user.cart`), so another user's record is a 404; then `authorize`
  with Pundit.
- Views render HTML; Turbo Streams update the page in place; Stimulus adds
  behavior on top of working HTML.

## Money

Money is stored as **integer cents** (`price_cents`, `total_cents`). Never use
floats or decimals for money. Display it only via `format_price_cents`.
`OrderItem#price_cents` is a purchase-time snapshot — never read
`product.price_cents` for a historical order.

## Tests

Tests are **RSpec + FactoryBot + Shoulda Matchers + Capybara** in `spec/`.

- Models: `spec/models/` (Shoulda Matchers for validations and associations);
  services: `spec/services/`; controller flows: `spec/requests/` (HTML and
  Turbo Stream, `sign_in_as(user)`); browser flows: `spec/system/`
  (`sign_in_via_ui(user)`). Helpers live in `spec/support/`.
- Build records with the factories in `spec/factories/` and their traits
  (`with_cart`, `low_stock`, `sold_out`, `electronics`, `books`).
- House rule: perform the action in a `before` block through a named helper;
  each `it` holds expectations only. Transition matchers (`change`,
  `not_to change`, `raise_error`) are the exception — the action goes inside
  the block. Assert on status, redirects, DB state, `turbo-stream[target]` and
  record links — never on CSS classes or copy.

## Commands

Every command runs through Docker; the host Ruby is not used.

- `bin/docker-dev test` — all specs except `spec/system`
- `bin/docker-dev system` — system specs against the chrome service
- `bin/docker-dev lint` — RuboCop
- `bin/docker-dev security` — Brakeman

## UI work

Before any view, CSS or Stimulus work, read `docs/DESIGN.md`.

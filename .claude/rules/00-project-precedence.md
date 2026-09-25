---
paths:
  - "app/**"
  - "test/**"
  - "config/**"
  - "db/**"
---

# Project Precedence

This file wins over every other file in `.claude/rules/` and `.claude/agents/`.
Those come from a generic Rails pack and are a fallback only.

## Stack

This is a **full-stack Rails 8.1 monolith**, not an API-only app:

- **ERB views** rendered by the controllers.
- **Hotwire**: Turbo Frames and Turbo Streams, plus Stimulus controllers
  loaded via **importmap** (no Node bundler).
- **Tailwind v4** via `tailwindcss-rails`; design tokens live in `@theme` in
  `app/assets/tailwind/application.css`.
- **Propshaft** for the asset pipeline.

Views, helpers, `respond_to`, Turbo Stream responses and system tests are all
expected and normal here.

## Where code goes

- Business logic lives in `app/services`: `Carts::CartService` for cart
  mutations, `Orders::CheckoutService` for placing orders. Controllers stay
  thin — parse params, call a service, render or redirect.
- Authorization goes through **Pundit**. Always scope lookups through
  `current_user` (e.g. `current_user.orders.find(id)`), so another user's
  record is a 404, not a leak.

## Money

Money is stored as **integer cents** (`price_cents`, `total_cents`). Never use
floats or decimals for money. Display it only via `format_price_cents`.
`OrderItem#price_cents` is a purchase-time snapshot — never read
`product.price_cents` for a historical order.

## Tests

Tests are **Minitest + fixtures** in `test/` — NOT RSpec, NOT FactoryBot.

- Services: `test/services/`; request flows: `test/integration/`
  (`ActionDispatch::IntegrationTest`, `sign_in_as(user)` from `test_helper.rb`);
  browser flows: `test/system/`.
- Reuse and extend `test/fixtures/*.yml` rather than building records inline.

Any rule in `.claude/rules/` or `.claude/agents/` that assumes RSpec, `spec/`,
FactoryBot, or an API-only app (JSON-only responses, serializers, no views)
**does not apply** to this repo.

## UI work

Before any view, CSS or Stimulus work, read `docs/DESIGN.md`.

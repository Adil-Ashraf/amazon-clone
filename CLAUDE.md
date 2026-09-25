# Amazon Clone

Full-stack **Rails 8.1 monolith**: ERB views, Hotwire (Turbo Frames/Streams +
Stimulus via importmap), Tailwind v4 via `tailwindcss-rails` (`@theme` in
`app/assets/tailwind/application.css`), Propshaft. Not API-only.

## Conventions

- Business logic lives in `app/services` (`Carts::CartService`,
  `Orders::CheckoutService`). Controllers stay thin.
- Authorization via Pundit; always scope lookups through `current_user`.
- Money is integer cents; display only via `format_price_cents`.
  `OrderItem#price_cents` is a purchase-time snapshot.
- Tests are Minitest + fixtures in `test/` (not RSpec, not FactoryBot).
  Services in `test/services`, request flows in `test/integration`
  (`sign_in_as(user)` helper), browser flows in `test/system`.
- Before any view/CSS/Stimulus work, read `docs/DESIGN.md`.
- `.claude/rules/00-project-precedence.md` overrides the generic rules pack;
  anything there assuming RSpec, `spec/`, FactoryBot or an API-only app does
  not apply.

## Commands

Always run Rails commands through Docker: bin/docker-dev test | system | lint |
security | console | bash. The host Ruby is not used.

```sh
bin/docker-dev test       # bin/rails test (unit, service, integration)
bin/docker-dev system     # bin/rails test:system against the chrome service
bin/docker-dev lint       # bin/rubocop
bin/docker-dev security   # bin/brakeman --no-pager
```

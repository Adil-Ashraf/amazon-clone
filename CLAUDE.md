# Amazon Clone

Full-stack **Rails 8.1 monolith**: ERB views, Hotwire (Turbo Frames/Streams +
Stimulus via importmap), Tailwind v4 via `tailwindcss-rails` (`@theme` in
`app/assets/tailwind/application.css`), Propshaft. Controllers render HTML.

## Conventions

- Business logic lives in `app/services` (`Carts::CartService`,
  `Orders::CheckoutService`). Controllers stay thin.
- Authorization via Pundit; always scope lookups through `current_user`.
- Money is integer cents; display only via `format_price_cents`.
  `OrderItem#price_cents` is a purchase-time snapshot.
- Tests are RSpec + FactoryBot + Shoulda Matchers + Capybara in `spec/`: models,
  services, requests (`sign_in_as`), system (`sign_in_via_ui`), `spec/factories`.
- Before any view/CSS/Stimulus work, read `docs/DESIGN.md`.
- `.claude/rules/00-project-precedence.md` is the authority, then the other
  `.claude/rules/`, then agents, skills and commands.

## Commands

Always run Rails commands through Docker: bin/docker-dev test | system | lint |
security | console | bash. The host Ruby is not used.

- `bin/docker-dev test` runs `bundle exec rspec` excluding `spec/system`
- `bin/docker-dev system` runs `bundle exec rspec spec/system` against the chrome service
- `bin/docker-dev lint` runs `bin/rubocop`; `security` runs `bin/brakeman --no-pager`
- `docker compose up` starts the app on http://localhost:3000

## Commits

- Commits are authored by the configured git user only.
- Never add "Co-Authored-By", "Generated with Claude Code" or any AI trailer/footer.
- Never put prompt text, instructions or conversation content in commit messages.
- Conventional Commits: subject of at most 72 characters (`feat:`, `fix:`,
  `chore:`, `docs:`, `test:`, `refactor:`), then optionally a short body
  explaining what changed and why, in plain engineering language.
- Don't use `--no-verify`, and don't change git config.

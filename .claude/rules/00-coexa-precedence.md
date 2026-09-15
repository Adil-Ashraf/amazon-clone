---
paths:
  - "app/**/*.rb"
  - "components/**/*.rb"
  - "spec/**/*.rb"
  - "db/migrate/**/*.rb"
---

# Coexa Precedence

## API-only — there is no view layer

Coexa is a **Rails 8 API-only backend**. The frontend is a separate
application. Ignore any view-layer advice from the generic pack or from Rails
convention generally:

- **No** views, ERB, ViewComponents, Turbo, Stimulus, Tailwind, Hotwire,
  presenters, decorators, form objects, helpers, system specs, or Capybara.
- **No** `respond_to`, `format.html`, `render :template`, or Turbo Stream
  responses. Every endpoint returns JSON.
- The layers that exist: **controllers → policies → use cases / services →
  queries → models**, with **serializers** shaping every response.
- **No `@instance_variables` for rendering.** There is no template to expose
  them to. Use local variables and pass them explicitly. An ivar is only
  justified for memoization across filters (`@contact ||= ...`).
- The one exception: `app/views/**/*_mailer/**` holds Action Mailer templates.
  That is the only ERB in the repo and the only place view guidance applies.

If a generated file would be a view, presenter, component, or form object,
stop — the correct answer here is a serializer or a use case.

## Precedence

The other files in `.claude/rules/` come from a generic Rails pack
(`ThibautBaissac/rails_ai_agents`). They are a fallback, not the standard.

**Order of authority — higher wins on any conflict:**

1. `docs/standards/RAILS_API_CODE_STANDARDS.md`
2. `docs/standards/RAILS_RSPEC_STANDARDS.md`
3. Conventions already established in the component you are editing
4. Everything else in `.claude/rules/` and `.claude/agents/`

Read the two standards docs before applying any generic Rails advice. Where the
generic rules are vaguer than the standards, follow the standards.

## Known conflicts with the generic pack

- **Business logic location.** The pack says "logic goes in `app/services/`".
  Here it goes in the owning component's command/use case with one `.call`
  entry point and explicit keyword arguments. Root `app/use_cases`,
  `app/policies`, `app/serializers`, and `app/controllers/api/v1` are only for
  their existing responsibilities.
- **Where code lives.** Most code is under `components/<name>/app/...`, not
  top-level `app/`. Follow the target component's existing structure.
- **Testing.** The pack's `testing.md` is generic. `RAILS_RSPEC_STANDARDS.md`
  governs: spec type, required coverage per object kind, mocking limits, and
  the canonical spec pattern.

## Things the generic pack does not cover at all

- **Component boundaries.** Cross-component calls go through the documented
  public facade (`Accounts::Api`, `Authorization::Api`, `Billing::Api`). Never
  touch another component's internal model/service or query its tables.
  Packwerk is the minimum check, not permission for runtime coupling.
- **Tenant isolation.** Scope every lookup through the current tenant *before*
  authorization. A cross-tenant resource normally returns `404`. Request specs
  for protected tenant endpoints must include a direct cross-tenant UUID
  attempt.
- **Response envelopes.** Preserve `{ "data": ... }` and `{ "error": ... }`.
  Errors carry a stable `code` and `request_id`. Render through the
  established serializer — never an Active Record object or an ad-hoc hash.
- **`Current` state.** `Current.user`, `Current.tenant`, `Current.membership`,
  `Current.session`, `Current.api_key` are request-boundary only. Jobs rebuild
  their own state.
- **API contract.** When the public API changes, update rswag/OpenAPI coverage
  in the same change.

## Checks

Run focused specs first, then `bin/ci` for the complete local validation suite.
It covers:

- Ruby style
- Architecture checks
- Database preparation and schema drift
- RSpec with SimpleCov and its coverage summary
- Security checks
- Documentation and agent-instruction linting
- OpenAPI generation, validation, and drift detection
- GitHub Actions workflow linting

GitHub Actions exposes these categories as independent jobs so failures are
visible and actionable. Treat `bin/ci` and `.github/workflows/ci.yml` as the
authoritative sources for the exact checks and commands. State what you ran and
what you did not.

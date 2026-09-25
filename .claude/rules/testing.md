---
paths:
  - "spec/**"
---

# Testing Conventions

RSpec + FactoryBot + Shoulda Matchers + Capybara, all in `spec/`.

**House rule, non-negotiable:** perform the action under test in a `before`
hook (via a named helper), and keep each `it` to the expectation alone. Never
call `get`/`post`/`patch`/`put`/`delete` or the subject's entry point inside an
`it` block. The only exception is a transition matcher — `expect { ... }.to
change(...)`, `not_to change`, `raise_error` — where the action must be inside
the block.

- TDD approach: RED (failing test) -> GREEN (minimal implementation) -> REFACTOR
- Use `subject { build(:entity) }` for validation specs
- Use `let` (lazy) by default; avoid `let!` unless records must exist before the example runs (e.g., scope tests)
- One behavior per `it` block
- Use `context` blocks to group by scenario
- Use FactoryBot: `build` over `create` when persistence isn't needed
- Use Shoulda Matchers for validations and associations
- Request specs (`spec/requests/`) over controller specs. Test authentication
  AND authorization: guest → redirect to sign in, another user's record → 404.
- Turbo Stream requests send `headers: { "Accept" => "text/vnd.turbo-stream.html" }`
  and assert the `turbo-stream[target]` ids (`turbo_stream_targets` helper).
- System specs (Capybara, `spec/system/`) only for a few critical browser
  flows — guest browsing and the purchase flow. Everything else is a request,
  service or model spec.
- Assert on behavior — status, redirects, DB state, Turbo Stream targets,
  product/order links — never on CSS classes or copy.
- Shared helpers live in `spec/support/`: `sign_in_as(user)` for request specs,
  `sign_in_via_ui(user)` for system specs, `response_link_hrefs` and
  `turbo_stream_targets` for reading responses.
- Run with `bin/docker-dev test` and `bin/docker-dev system`; run
  `bin/docker-dev lint` after writing specs.

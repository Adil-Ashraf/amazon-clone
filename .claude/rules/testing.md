---
paths:
  - "spec/**/*.rb"
---

# Testing Conventions

`docs/standards/RAILS_RSPEC_STANDARDS.md` is authoritative. These are generic
defaults that fill gaps; the standard wins on any conflict.

**House rule, non-negotiable:** perform the action under test in a `before`
hook (via a named helper), and keep each `it` to the expectation alone. Never
call `get`/`post`/`patch`/`put`/`delete` or the subject's entry point inside an
`it` block. The only exception is a transition matcher — `expect { ... }.to
change(...)`, `not_to change`, `raise_error` — where the action must be inside
the block.

- TDD approach: RED (failing test) -> GREEN (minimal implementation) -> REFACTOR
- Use `subject { build(:entity) }` for validation specs
- Prefer explicit setup in each test for clarity over `let!`
- Use `let` (lazy) by default; avoid `let!` unless records must exist before the example runs (e.g., scope tests)
- One behavior per `it` block
- Use `context` blocks to group by scenario
- Use FactoryBot: `build` over `create` when persistence isn't needed
- Request specs (`spec/requests/`) over controller specs
- Test authentication AND authorization in request specs
- Use Shoulda Matchers for validations and associations
- Run `bundle exec rubocop -a` after writing specs

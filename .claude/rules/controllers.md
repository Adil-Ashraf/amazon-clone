---
paths:
  - "app/controllers/**/*.rb"
  - "components/*/app/controllers/**/*.rb"
  - "spec/requests/**/*.rb"
---

# Controller Conventions

- Keep controllers thin: orchestrate, don't implement business logic
- Delegate to service objects for anything beyond simple CRUD
- Always `authorize` with Pundit on every action
- Use `policy_scope(Model)` for index queries (multi-tenant isolation)
- Use strong parameters (`params.require(:x).permit(...)`)
- Shape every response through a serializer (`app/serializers/`) — never a raw Active Record object, never an ad-hoc hash
- Follow REST conventions: index, show, new, create, edit, update, destroy
- JSON only. No `respond_to`, no `format.html`, no Turbo Streams — the frontend is a separate application
- No `@instance_variables` for rendering. Use local variables and pass them explicitly to the serializer; an ivar only earns its place when memoizing across filters (e.g. `@contact ||= ...`)
- Test with request specs in `spec/requests/`, not controller specs
- Always test: authentication, authorization (404 for unauthorized), valid/invalid params

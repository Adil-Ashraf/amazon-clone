---
name: rails-architecture
description: >-
  Guides modern Rails 8 code architecture decisions and patterns. Use when
  deciding where to put code, choosing between patterns (service objects vs
  concerns vs query objects), designing feature architecture, refactoring
  for better organization, or when user mentions architecture, code
  organization, design patterns, or layered design. WHEN NOT: Implementing
  specific patterns (use specialist agents like service-agent or query-agent),
  writing tests, or debugging runtime errors.
model: sonnet
effort: high
---

# Modern Rails 8 Architecture Patterns

This app is a full-stack monolith: ERB views, Turbo Frames/Streams, Stimulus
via importmap, Tailwind v4, Pundit, services in `app/services`.
`.claude/rules/00-project-precedence.md` is the authority.

## Architecture Decision Tree

```
Where should this code go?
|
+- Response shaping?              -> View / partial / helper (@view-agent);
|                                    Turbo Stream template for partial page updates
+- Client-side behavior?          -> Stimulus controller (@view-agent)
+- Complex business logic?        -> Service Object (@service-agent)
+- Complex database query?        -> Query Object (@query-agent)
+- Shared behavior across models? -> Concern (/rails-concern skill)
+- Authorization logic?           -> Policy (@policy-agent)
+- Multi-record workflow?         -> Service with a transaction (@service-agent)
+- Async/background work?         -> Job (@job-agent, /solid-queue-setup skill)
+- Transactional email?           -> Mailer (@mailer-agent)
+- Data validation only?          -> Model (@model-agent)
+- HTTP request/response only?    -> Controller (@controller-agent)
```

## Layer Responsibilities

| Layer | Responsibility | Should NOT contain |
|-------|---------------|-------------------|
| **Controller** | HTTP, params, choosing a response (HTML / Turbo Stream) | Business logic, queries beyond loading what the view needs |
| **Model** | Data, validations, relations, simple predicates | Display logic, HTTP |
| **Service** | Business logic, orchestration, transactions | HTTP, display logic |
| **Query** | Complex database queries | Business logic |
| **Policy** | Authorization rules (owner / other user / guest) | Business logic |
| **View / partial** | HTML markup, Turbo Frame/Stream targets | Queries, business rules |
| **Helper** | Formatting (`format_price_cents`), small markup builders | Business logic, queries |
| **Stimulus controller** | Progressive client-side behavior | Business rules, HTML string building |
| **Job** | Async processing | HTTP, display logic |
| **Mailer** | Email composition | Business logic |

## When NOT to Abstract

| Situation | Keep It Simple | Don't Create |
|-----------|----------------|--------------|
| Simple CRUD (< 10 lines) | Keep in controller | Service object |
| Used only once | Inline the code | Abstraction |
| Simple query with 1-2 conditions | Model scope | Query object |
| Two services | Plain classes | `ApplicationService` base class |

## When TO Abstract

| Signal | Action |
|--------|--------|
| Same code in 3+ places | Extract to concern/service/partial |
| Controller action > 15 lines | Extract to service |
| Model > 300 lines | Extract concerns |
| Complex conditionals | Extract to policy/service |
| Query joins 3+ tables | Extract to query object |
| Same markup in 3+ views | Extract to `app/views/shared/` partial |

See /extraction-timing skill for detailed extraction guidance.

## Core Patterns

### Skinny Controllers

```ruby
# GOOD: thin controller delegates to a service and rescues its errors
class CheckoutsController < ApplicationController
  def create
    order = Orders::CheckoutService.new(user: current_user, shipping_attributes: shipping_params).call
    redirect_to order_path(order), notice: "Order placed! Thanks for your purchase."
  rescue Orders::CheckoutService::InsufficientStockError => e
    render_new_with_error(e.message) # 422
  end
end
```

### Services Raise Namespaced Errors

Services return the record they produce and raise namespaced errors for
domain failures (`Orders::CheckoutService::EmptyCartError`). Use a
`Data.define` result only for multi-part outcomes.

### Per-User Isolation by Default

```ruby
# GOOD: scoped through the signed-in user; another user's order is a 404
def show
  @order = current_user.orders.find(params[:id])
  authorize @order
end
```

### Turbo Streams for In-Place Updates

```erb
<%# app/views/cart_items/_sync.turbo_stream.erb %>
<%= turbo_stream.replace "cart_count" do %>
  <%= render "shared/cart_count_badge" %>
<% end %>
```

## Rails 8 Specific Features

| Feature | Purpose | Skill/Agent |
|---------|---------|-------------|
| Authentication | `has_secure_password` + `User.authenticate_by` | /authentication-flow |
| Background Jobs | Solid Queue (database-backed) | /solid-queue-setup, @job-agent |
| Caching | Solid Cache (database-backed) | /caching-strategies |
| Frontend | Turbo + Stimulus via importmap, Tailwind v4 | @view-agent |
| Assets | Propshaft | (built-in) |
| Deployment | Railway, via the repo's `Dockerfile` | (built-in) |

## Testing Strategy by Layer

| Layer | Test Type | Focus |
|-------|-----------|-------|
| Model | Model spec | Validations (Shoulda Matchers), scopes, predicates |
| Service | Service spec | Business logic, error classes, rollback |
| Query | Query spec | Results, per-user isolation |
| Policy | Policy spec | Owner / other user / guest |
| Controller | Request spec | HTML + Turbo Stream flow, authn/authz, status, targets |
| System | Capybara | A few critical browser flows |

## New Feature Checklist

1. **Model** - Define data structure (@migration-agent, @model-agent)
2. **Policy** - Add authorization rules (@policy-agent)
3. **Service** - Create for complex logic (@service-agent)
4. **Query** - Add for complex queries (@query-agent)
5. **Controller** - Keep it thin, HTML + Turbo Stream (@controller-agent)
6. **Views** - Partials, Turbo Frame/Stream targets, Stimulus (@view-agent, read `docs/DESIGN.md`)
7. **Mailer** - Add transactional emails (@mailer-agent)
8. **Job** - Add background processing (@job-agent)

## References

- See [layer-interactions.md](references/layer-interactions.md) for layer communication patterns
- See [service-patterns.md](references/service-patterns.md) for service object patterns
- See [query-patterns.md](references/query-patterns.md) for query object patterns
- See [error-handling.md](references/error-handling.md) for error handling strategies
- See [testing-strategy.md](references/testing-strategy.md) for the testing pyramid

---
paths:
  - "app/controllers/**"
  - "spec/requests/**"
---

# Controller Conventions

- Keep controllers thin: parse params, call a service, render or redirect.
  Business logic goes in `app/services` (`Carts::CartService`,
  `Orders::CheckoutService`).
- Follow REST conventions and the routes in `config/routes.rb`
  (singular `resource :cart`, `resource :checkout`, `resource :session`).
- Responses are HTML and Turbo Stream. Use `respond_to` with `format.turbo_stream`
  as the primary path and a `format.html` fallback (redirect or render) so the
  action still works without JavaScript. Turbo Stream templates live next to
  the HTML ones (`app/views/cart_items/create.turbo_stream.erb`).
- Instance variables for views are normal (`@cart`, `@cart_items`, `@order`).
  Set only what the template needs; load it with `includes` to avoid N+1.
- Require sign-in with `before_action :require_login` (defined in
  `ApplicationController`) on anything user-specific.
- Scope every lookup through `current_user` associations first —
  `current_user.orders.find(params[:id])`, `current_user.cart.cart_items.find(...)`
  — so another user's record raises `RecordNotFound` (404). Then `authorize`
  with Pundit.
- Rescue a service's namespaced errors (e.g.
  `Orders::CheckoutService::InsufficientStockError`) in the action and turn
  them into a flash, a Turbo Stream message, or `render :new, status:
  :unprocessable_content`. Invalid forms re-render with 422.
- Use strong parameters (`params.require(:order).permit(...)`).
- Test with request specs in `spec/requests/`, never controller specs. Cover:
  authentication (guest → redirect to sign in), authorization (another user's
  record → 404), valid and invalid params (redirect vs 422), and for Turbo
  Stream actions the response media type and `turbo-stream[target]` ids.

# Layer Interactions

How the layers of this app communicate, using its two real flows: checkout
(HTML form → redirect) and add to cart (Turbo Stream).

## Flow 1: Checkout (HTML)

### 1. Controller (entry point)

```ruby
# app/controllers/checkouts_controller.rb
class CheckoutsController < ApplicationController
  before_action :require_login                       # guest → sign in

  def create
    order = Orders::CheckoutService.new(               # business logic
      user: current_user, shipping_attributes: shipping_params
    ).call
    redirect_to order_path(order), notice: "Order placed! Thanks for your purchase."
  rescue Orders::CheckoutService::EmptyCartError => e
    redirect_to cart_path, alert: e.message
  rescue Orders::CheckoutService::InsufficientStockError => e
    render_new_with_error(e.message)                 # 422, re-render the form
  rescue ActiveRecord::RecordInvalid => e
    render_new_with_error(nil, order: e.record)      # 422 with field errors
  end
end
```

### 2. Service (business logic)

`Orders::CheckoutService#call` locks product rows in `product_id` order,
re-checks stock, creates the order with snapshotted `price_cents`, decrements
stock and empties the cart — all in one transaction. It returns the `Order`
or raises a namespaced error; any raise rolls everything back.

### 3. Models (data and validations)

```ruby
class Order < ApplicationRecord
  belongs_to :user
  has_many :order_items, dependent: :destroy

  enum :status, { pending: 0, paid: 1, shipped: 2 }

  validates :total_cents, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :shipping_name, :shipping_address_line1, :shipping_city, :shipping_state, :shipping_zip, presence: true
end
```

### 4. Policy (authorization) and the order page

```ruby
# app/controllers/orders_controller.rb
def show
  @order = current_user.orders.find(params[:id]) # scope first: another user's order → 404
  authorize @order                                # then the policy states the rule
end
```

### 5. View

`app/views/orders/show.html.erb` renders `@order.order_items` and prices via
`format_price_cents(item.price_cents)` — the snapshot, never the live
product price.

## Flow 2: Add to cart (Turbo Stream)

```ruby
# app/controllers/cart_items_controller.rb
def create
  product = Product.find(params[:product_id])
  quantity = params[:quantity].presence&.to_i || 1

  begin
    Carts::CartService.new(@cart).add_item(product: product, quantity: quantity)
    @status_message = "Added to cart."
    @status_variant = :success
  rescue Carts::CartService::InsufficientStockError => e
    @status_message = e.message
    @status_variant = :error
  end

  load_cart_items # renders create.turbo_stream.erb
end
```

```erb
<%# app/views/cart_items/create.turbo_stream.erb %>
<%= render "sync" %>                          <%# replaces cart_count and cart_items %>
<%= turbo_stream.update "add_to_cart_status" do %>
  <%= render "shared/toast", variant: @status_variant, message: @status_message %>
<% end %>
```

The page never reloads: Turbo applies each `<turbo-stream>` to the element
with the matching id. Stimulus (`dismissible_controller`) lets the user close
the toast.

## Layer Communication Rules

### Who Can Call Whom

```
Controller → Service, Query, Policy, Model (to load records for the view)
Service    → Model, Query, other Services, Job, Mailer
Query      → Model (read-only)
Job        → Service, Mailer
View       → Helpers, Partials, Policy (to hide actions), loaded records
Stimulus   → the DOM it is attached to, Turbo Frames via src
```

### Who Should NOT Call Whom

```
Model    → Controller, Service, Job (avoid callbacks that do this)
Query    → Service, Job (read-only)
View     → Model queries, Service (render what the controller loaded)
Helper   → Service, Job (formatting only)
Stimulus → business rules (the server decides; JS enhances)
```

## Data Flow Patterns

### Pattern 1: Simple read

```
Request → Controller (scope through current_user) → View (ERB)
```

### Pattern 2: Business operation, full page

```
Request → Controller → Service (transaction) → Models
                    ↘ redirect (success) | render :new, 422 (rescued error)
```

### Pattern 3: Business operation, in place

```
Request (Accept: turbo-stream) → Controller → Service → Models
                              ↘ *.turbo_stream.erb → replace/update target ids
```

## Testing Each Layer

| Layer | Test Type | What to Test |
|-------|-----------|--------------|
| Model | Model spec | Validations (Shoulda Matchers), associations, predicates |
| Service | Service spec | DB effects, error classes, rollback |
| Query | Query spec | Results, per-user isolation |
| Policy | Policy spec | Owner / other user / guest |
| Controller | Request spec | Status, redirects, DB state, Turbo Stream targets, 404 for others' records |
| Job | Job spec | Execution, side effects |
| Mailer | Mailer spec | Recipients, content |
| Browser flow | System spec | A few critical paths end to end |

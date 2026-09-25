# Error Handling Strategies

In this app, services raise namespaced errors for domain failures and HTML /
Turbo Stream controllers rescue them into a flash, a message stream, or a
422 re-render. Nothing a user can trigger should surface as a 500.

## Domain Errors Live on the Service

```ruby
module Orders
  class CheckoutService
    class EmptyCartError < StandardError; end
    class InsufficientStockError < StandardError; end

    def call
      raise EmptyCartError, "Your cart is empty." if @user.cart.cart_items.none?
      # ...
      raise InsufficientStockError, "Only #{product.stock} left in stock for \"#{product.name}\"."
    end
  end
end
```

- One class per failure the caller must handle differently.
- The message is safe to show the user.
- Raising inside `ActiveRecord::Base.transaction` rolls the whole operation back.

## Controller Layer: Rescue per Action

### Full-page form (HTML)

```ruby
# app/controllers/checkouts_controller.rb
def create
  order = Orders::CheckoutService.new(user: current_user, shipping_attributes: shipping_params).call
  redirect_to order_path(order), notice: "Order placed! Thanks for your purchase."
rescue Orders::CheckoutService::EmptyCartError => e
  redirect_to cart_path, alert: e.message          # nothing to check out: send them back
rescue Orders::CheckoutService::InsufficientStockError => e
  render_new_with_error(e.message)                 # 422, form re-rendered with the message
rescue ActiveRecord::RecordInvalid => e
  render_new_with_error(nil, order: e.record)      # 422, field errors from the record
end

private

def render_new_with_error(message, order: nil)
  @cart = current_user.cart
  @cart_items = @cart.cart_items.includes(:product).order(:created_at)
  @order = order || current_user.orders.new(shipping_params)
  flash.now[:alert] = message if message
  render :new, status: :unprocessable_content
end
```

### In-place update (Turbo Stream)

The response is still 200: the stream carries the message into the page.

```ruby
# app/controllers/cart_items_controller.rb
def create
  product = Product.find(params[:product_id])

  begin
    Carts::CartService.new(@cart).add_item(product: product, quantity: quantity)
    @status_message = "Added to cart."
    @status_variant = :success
  rescue Carts::CartService::InsufficientStockError => e
    @status_message = e.message
    @status_variant = :error
  end

  load_cart_items
end
```

```erb
<%# app/views/cart_items/create.turbo_stream.erb %>
<%= turbo_stream.update "add_to_cart_status" do %>
  <%= render "shared/toast", variant: @status_variant, message: @status_message %>
<% end %>
```

## Application-wide Rescues

```ruby
# app/controllers/application_controller.rb
rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

def user_not_authorized
  redirect_to root_path, alert: "You are not authorized to do that."
end
```

`ActiveRecord::RecordNotFound` needs no rescue: Rails renders the 404 page.
That is what makes `current_user.orders.find(other_users_order_id)` a 404.

## Status Mapping

| Situation | Response |
|---|---|
| Guest on a protected page | redirect to `new_session_path` (`require_login`) |
| Missing or another user's record | 404 (`RecordNotFound`) |
| Pundit denial | redirect to root with alert |
| Invalid form / domain error on a page | `render :new, status: :unprocessable_content` |
| Domain error on a Turbo Stream action | 200 with a message stream |
| Out-of-range or garbage `?page=` | redirect to a valid page |

## Validation Errors

Re-render the form with the invalid record so the view shows its errors
through `app/views/shared/_error_messages.html.erb`:

```ruby
@user = User.new(registration_params)
if @user.save
  # ...
else
  render :new, status: :unprocessable_content
end
```

## When a Result Object Helps

Raise for failures. Return a `Data.define` result only when a *successful*
call has several parts the caller needs (e.g. items added plus products
skipped):

```ruby
Result = Data.define(:cart_items, :skipped_products)
```

## Logging Errors

```ruby
rescue Orders::CheckoutService::InsufficientStockError => e
  Rails.logger.info("checkout.insufficient_stock user_id=#{current_user.id} #{e.message}")
  render_new_with_error(e.message)
```

Log expected domain failures at `info`; let unexpected exceptions propagate
so they reach the error page and the logs at `error`.

## Checklist

- [ ] Each domain failure is a namespaced error class on the service
- [ ] Every error class is rescued by each controller that calls the service
- [ ] Full-page failures re-render with 422; Turbo Stream failures show a message stream
- [ ] Another user's record is a 404, never a redirect that confirms it exists
- [ ] Request specs cover each rescued error (status and DB unchanged)

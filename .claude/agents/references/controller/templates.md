# Controller Templates (HTML + Turbo Stream)

Modeled on this app's controllers. Every template follows
`.claude/rules/controllers.md`: thin actions, `require_login`, lookups scoped
through `current_user`, Pundit `authorize`, service errors rescued.

## 1. Turbo Stream mutation controller (like `CartItemsController`)

```ruby
# app/controllers/cart_items_controller.rb
class CartItemsController < ApplicationController
  before_action :require_login
  before_action :set_cart

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

    load_cart_items
    respond_to do |format|
      format.turbo_stream                       # create.turbo_stream.erb
      format.html { redirect_to cart_path, notice: @status_message }
    end
  end

  def update
    cart_item = @cart.cart_items.find(params[:id]) # another user's item → 404

    begin
      Carts::CartService.new(@cart).update_quantity(cart_item: cart_item, quantity: params[:quantity].to_i)
    rescue Carts::CartService::InsufficientStockError => e
      @cart_flash_message = e.message
    end

    load_cart_items
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to cart_path, alert: @cart_flash_message }
    end
  end

  def destroy
    cart_item = @cart.cart_items.find(params[:id])
    Carts::CartService.new(@cart).remove_item(cart_item: cart_item)

    load_cart_items
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to cart_path }
    end
  end

  private

  def set_cart
    @cart = current_user.cart
    authorize @cart, :update?
  end

  def load_cart_items
    @cart_items = @cart.cart_items.includes(:product).order(:created_at)
  end
end
```

The matching stream template updates stable target ids:

```erb
<%# app/views/cart_items/create.turbo_stream.erb %>
<%= render "sync" %>

<%= turbo_stream.update "add_to_cart_status" do %>
  <%= render "shared/toast", variant: @status_variant, message: @status_message %>
<% end %>
```

```erb
<%# app/views/cart_items/_sync.turbo_stream.erb %>
<%= turbo_stream.replace "cart_count" do %>
  <%= render "shared/cart_count_badge" %>
<% end %>

<%= turbo_stream.replace "cart_items" do %>
  <div id="cart_items">
    <%= render "carts/cart", cart: @cart, cart_items: @cart_items %>
  </div>
<% end %>
```

## 2. Read-only, owner-scoped controller (like `OrdersController`)

```ruby
class OrdersController < ApplicationController
  before_action :require_login

  def index
    @orders = current_user.orders.order(created_at: :desc)
  end

  def show
    @order = current_user.orders.find(params[:id])
    authorize @order
  end
end
```

## 3. Form controller calling a single-operation service (like `CheckoutsController`)

```ruby
class CheckoutsController < ApplicationController
  before_action :require_login

  def new
    @cart = current_user.cart
    @cart_items = @cart.cart_items.includes(:product).order(:created_at)
    @order = current_user.orders.new(shipping_name: current_user.name)

    redirect_to cart_path, alert: "Your cart is empty." if @cart_items.none?
  end

  def create
    order = Orders::CheckoutService.new(user: current_user, shipping_attributes: shipping_params).call
    redirect_to order_path(order), notice: "Order placed! Thanks for your purchase."
  rescue Orders::CheckoutService::EmptyCartError => e
    redirect_to cart_path, alert: e.message
  rescue Orders::CheckoutService::InsufficientStockError => e
    render_new_with_error(e.message)
  rescue ActiveRecord::RecordInvalid => e
    render_new_with_error(nil, order: e.record)
  end

  private

  def shipping_params
    params.require(:order).permit(
      :shipping_name, :shipping_address_line1, :shipping_address_line2,
      :shipping_city, :shipping_state, :shipping_zip
    ).to_h.symbolize_keys
  end

  def render_new_with_error(message, order: nil)
    @cart = current_user.cart
    @cart_items = @cart.cart_items.includes(:product).order(:created_at)
    @order = order || current_user.orders.new(shipping_params)
    flash.now[:alert] = message if message
    render :new, status: :unprocessable_content
  end
end
```

## 4. Public listing with a Turbo Frame (like `ProductsController#index`)

Guests can browse. Category links and live search target the
`products_results` Turbo Frame, so only the results region reloads; the same
URL still renders a full page without JavaScript.

```ruby
def index
  @categories = Category.order(:name)
  @selected_category = Category.find_by(slug: params[:category]) if params[:category].present?
  @query = params[:query].to_s.strip

  scope = Product.includes(:category)
  scope = scope.where(category: @selected_category) if @selected_category
  scope = @query.present? ? scope.search_full_text(@query) : scope.order(:name)

  @pagy, @products = pagy(scope, limit: PER_PAGE)
end
```

## Error handling

| Situation | Response |
|---|---|
| Guest on a protected action | `require_login` → redirect to `new_session_path` |
| Another user's record | `current_user.<assoc>.find` raises `RecordNotFound` → 404 |
| Pundit denial | `rescue_from Pundit::NotAuthorizedError` → redirect to root with alert |
| Invalid form / service error on a page | `render :new, status: :unprocessable_content` with `flash.now[:alert]` |
| Service error on a Turbo Stream action | 200 with a stream that shows the message (toast / `cart_flash`) |

## HTTP status codes

| Code | Symbol | When |
|---|---|---|
| 200 | `:ok` | Page render, Turbo Stream response |
| 302/303 | redirect | After a successful form submit, sign in/out |
| 404 | `:not_found` | Missing or another user's record |
| 422 | `:unprocessable_content` | Invalid form, insufficient stock at checkout |

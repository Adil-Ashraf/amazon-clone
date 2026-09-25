# Service Object Patterns

This app's conventions (`.claude/rules/services.md`): plain Ruby classes
namespaced by domain, no `ApplicationService` base class, `#call` for a single
operation or named methods for an aggregate, domain failures raised as
namespaced error classes, `Data.define` only for multi-part outcomes.

## Pattern 1: Aggregate Service with Named Methods

One object's mutations behind intention-revealing methods
(`app/services/carts/cart_service.rb`):

```ruby
module Carts
  class CartService
    class InsufficientStockError < StandardError; end

    def initialize(cart)
      @cart = cart
    end

    def add_item(product:, quantity: 1)
      cart_item = @cart.cart_items.find_or_initialize_by(product: product)
      new_quantity = (cart_item.new_record? ? 0 : cart_item.quantity) + quantity
      raise InsufficientStockError, "Only #{product.stock} left in stock" if new_quantity > product.stock

      cart_item.quantity = new_quantity
      cart_item.save!
      cart_item
    end

    def update_quantity(cart_item:, quantity:)
      return remove_item(cart_item: cart_item) if quantity <= 0
      raise InsufficientStockError, "Only #{cart_item.product.stock} left in stock" if quantity > cart_item.product.stock

      cart_item.update!(quantity: quantity)
      cart_item
    end

    def remove_item(cart_item:)
      cart_item.destroy!
      cart_item
    end
  end
end
```

## Pattern 2: Single Operation with Transaction and Row Locks

(`app/services/orders/checkout_service.rb`)

```ruby
module Orders
  class CheckoutService
    class EmptyCartError < StandardError; end
    class InsufficientStockError < StandardError; end

    def initialize(user:, shipping_attributes:)
      @user = user
      @shipping_attributes = shipping_attributes
    end

    def call
      cart = @user.cart
      raise EmptyCartError, "Your cart is empty." if cart.cart_items.none?

      order = nil

      ActiveRecord::Base.transaction do
        # Lock in a stable order (product_id) so concurrent checkouts can't deadlock.
        cart_items = cart.cart_items.includes(:product).order(:product_id).to_a
        cart_items.each { |cart_item| cart_item.product.lock! }

        # Re-check invariants under the lock.
        cart_items.each do |cart_item|
          next if cart_item.quantity <= cart_item.product.stock

          raise InsufficientStockError, "Only #{cart_item.product.stock} left in stock for \"#{cart_item.product.name}\"."
        end

        total_cents = cart_items.sum { |cart_item| cart_item.product.price_cents * cart_item.quantity }
        order = @user.orders.create!(@shipping_attributes.merge(status: :paid, total_cents: total_cents))

        cart_items.each do |cart_item|
          # Snapshot the price at purchase time.
          order.order_items.create!(product: cart_item.product, quantity: cart_item.quantity, price_cents: cart_item.product.price_cents)
          cart_item.product.decrement!(:stock, cart_item.quantity)
        end

        cart.cart_items.destroy_all
      end

      order
    end
  end
end
```

Any raise inside the transaction rolls everything back, so a failure leaves
stock, cart and orders untouched.

## Pattern 3: Multi-Part Outcome with `Data.define`

Only when the caller needs more than one value back:

```ruby
module Orders
  class ReorderService
    Result = Data.define(:cart_items, :skipped_products)

    def initialize(user:, order:)
      @user = user
      @order = order
    end

    def call
      skipped = []
      added = @order.order_items.includes(:product).filter_map do |item|
        Carts::CartService.new(@user.cart).add_item(product: item.product, quantity: item.quantity)
      rescue Carts::CartService::InsufficientStockError
        skipped << item.product
        nil
      end

      Result.new(cart_items: added, skipped_products: skipped)
    end
  end
end
```

## Pattern 4: Injected Dependencies

Default collaborators in the constructor keep the service testable:

```ruby
module Orders
  class ConfirmationService
    def initialize(order:, mailer: OrderMailer)
      @order = order
      @mailer = mailer
    end

    def call
      @mailer.with(order: @order).confirmation.deliver_later
      @order
    end
  end
end
```

## Controller Usage

```ruby
def create
  order = Orders::CheckoutService.new(user: current_user, shipping_attributes: shipping_params).call
  redirect_to order_path(order), notice: "Order placed! Thanks for your purchase."
rescue Orders::CheckoutService::InsufficientStockError => e
  render_new_with_error(e.message) # 422
end
```

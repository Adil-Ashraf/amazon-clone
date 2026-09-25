# Service Object Patterns

Conventions (`.claude/rules/services.md`): plain Ruby classes namespaced by
domain; no `ApplicationService` base class; `#call` for a single operation,
named methods for an aggregate; domain failures raise namespaced errors;
`Data.define` only for multi-part outcomes; multi-row writes in a
transaction; row locks in a stable order.

## Basic Service Structure

```ruby
# app/services/<domain>/<verb>_service.rb
module Orders
  class CheckoutService
    class EmptyCartError < StandardError; end

    def initialize(user:, shipping_attributes:)
      @user = user
      @shipping_attributes = shipping_attributes
    end

    def call
      raise EmptyCartError, "Your cart is empty." if @user.cart.cart_items.none?

      ActiveRecord::Base.transaction do
        # ... returns the created order
      end
    end
  end
end
```

## Service Categories

### 1. Command Services (single write operation)

`Orders::CheckoutService#call` — one operation, one transaction, returns the
`Order` or raises `EmptyCartError` / `InsufficientStockError`.

### 2. Aggregate Services (one object's mutations)

`Carts::CartService` owns cart mutations behind named methods:

```ruby
service = Carts::CartService.new(current_user.cart)
service.add_item(product: product, quantity: 2)
service.update_quantity(cart_item: line, quantity: 0) # removes the line
service.remove_item(cart_item: line)
```

Each raises `Carts::CartService::InsufficientStockError` when stock would be
exceeded.

### 3. Read Services (complex reads that don't fit a query object)

```ruby
module Reports
  class SalesSummaryService
    Summary = Data.define(:revenue_cents, :orders_count, :top_products)

    def initialize(range:)
      @range = range
    end

    def call
      orders = Order.paid.where(created_at: @range)
      Summary.new(
        revenue_cents: orders.sum(:total_cents),
        orders_count: orders.count,
        top_products: TopProductsQuery.new(range: @range).call
      )
    end
  end
end
```

### 4. Integration Services (external APIs)

Wrap the gateway, translate its failures into this app's error classes:

```ruby
module Payments
  class ChargeService
    class CardDeclinedError < StandardError; end

    def initialize(order:, gateway: StripeGateway.new)
      @order = order
      @gateway = gateway
    end

    def call
      @gateway.charge(amount: @order.total_cents, currency: "usd")
    rescue StripeGateway::CardDeclined => e
      raise CardDeclinedError, e.message
    end
  end
end
```

### 5. Orchestrator Services (several services in one workflow)

Let the inner services raise; one transaction keeps the workflow atomic:

```ruby
module Orders
  class PlaceService
    def initialize(user:, shipping_attributes:, payment_method_id:)
      @user = user
      @shipping_attributes = shipping_attributes
      @payment_method_id = payment_method_id
    end

    def call
      ActiveRecord::Base.transaction do
        order = Orders::CheckoutService.new(user: @user, shipping_attributes: @shipping_attributes).call
        Payments::ChargeService.new(order: order).call
        order
      end
    end
  end
end
```

## Dependency Injection Patterns

### Constructor Injection (Preferred)

```ruby
class Orders::ConfirmationService
  def initialize(order:, mailer: OrderMailer)
    @order = order
    @mailer = mailer
  end
end
```

### Testing with Doubles

```ruby
RSpec.describe Payments::ChargeService do
  let(:order) { build(:order, total_cents: 2500) }
  let(:gateway) { instance_double(StripeGateway) }

  def charge
    described_class.new(order: order, gateway: gateway).call
  end

  context "when the card is declined" do
    before { allow(gateway).to receive(:charge).and_raise(StripeGateway::CardDeclined, "declined") }

    it "raises CardDeclinedError" do
      expect { charge }.to raise_error(described_class::CardDeclinedError)
    end
  end
end
```

## Error Handling

Raise namespaced errors in the service; rescue them in the controller:

```ruby
def create
  order = Orders::CheckoutService.new(user: current_user, shipping_attributes: shipping_params).call
  redirect_to order_path(order)
rescue Orders::CheckoutService::EmptyCartError => e
  redirect_to cart_path, alert: e.message
rescue Orders::CheckoutService::InsufficientStockError => e
  render_new_with_error(e.message) # 422
end
```

See [error-handling.md](error-handling.md).

## Service Naming Conventions

| Pattern | Example | Use Case |
|---------|---------|----------|
| `Domain::VerbService` | `Orders::CheckoutService` | Single operation (`#call`) |
| `Domain::NounService` | `Carts::CartService` | Aggregate with named methods |

## Checklist

- [ ] Namespaced by domain; no base class
- [ ] `#call` for one operation, or named methods for an aggregate
- [ ] Domain failures are namespaced error classes on the service
- [ ] Dependencies injected via constructor
- [ ] Transaction for multi-row writes; locks in a stable order
- [ ] Spec covers the success DB effects, each error class, and rollback

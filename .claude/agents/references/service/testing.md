# Service Object: RSpec Tests

Specs live in `spec/services/<domain>/`. Follow the house rule: the call goes
in a `before` block through a named helper; transition matchers (`change`,
`not_to change`, `raise_error`) wrap the call.

## Single-Operation Service

```ruby
# spec/services/orders/checkout_service_spec.rb
require "rails_helper"

RSpec.describe Orders::CheckoutService do
  let(:shipping) do
    { shipping_name: "Test User", shipping_address_line1: "1 Spec Street",
      shipping_city: "Specville", shipping_state: "CA", shipping_zip: "90210" }
  end
  let(:user) { create(:user, :with_cart) }
  let(:headphones) { create(:product, price_cents: 9999, stock: 10) }

  def checkout
    described_class.new(user: user, shipping_attributes: shipping).call
  end

  context "with a cart of in-stock lines" do
    before { create(:cart_item, cart: user.cart, product: headphones, quantity: 2) }

    it "creates one order" do
      expect { checkout }.to change(Order, :count).by(1)
    end

    context "after checkout" do
      let!(:order) { checkout }

      it "totals price times quantity" do
        expect(order.total_cents).to eq(2 * 9999)
      end

      it "snapshots each line's price" do
        expect(order.order_items.pluck(:price_cents)).to eq([ 9999 ])
      end

      it "decrements stock" do
        expect(headphones.reload.stock).to eq(8)
      end
    end
  end

  context "with an empty cart" do
    it "raises EmptyCartError" do
      expect { checkout }.to raise_error(described_class::EmptyCartError)
    end
  end
end
```

## Aggregate Service with Named Methods

```ruby
# spec/services/carts/cart_service_spec.rb
RSpec.describe Carts::CartService do
  let(:cart) { create(:cart) }
  let(:product) { create(:product, stock: 10) }
  let!(:line) { create(:cart_item, cart: cart, product: product, quantity: 1) }

  def update_quantity(quantity)
    described_class.new(cart).update_quantity(cart_item: line, quantity: quantity)
  end

  context "with a quantity within stock" do
    before { update_quantity(5) }

    it "sets the new quantity" do
      expect(line.reload.quantity).to eq(5)
    end
  end

  context "with a quantity of 0" do
    it "removes the line" do
      expect { update_quantity(0) }.to change { cart.cart_items.count }.by(-1)
    end
  end

  context "with a quantity above stock" do
    it "raises InsufficientStockError" do
      expect { update_quantity(11) }.to raise_error(described_class::InsufficientStockError)
    end
  end
end
```

## Testing Rollback

A raised domain error must leave the database untouched. Rescue inside the
`not_to change` block so the matcher sees the state after the failure:

```ruby
context "when a line exceeds stock" do
  before { headphones.update!(stock: 1) } # cart wants 2

  it "creates no order or order items" do
    expect { checkout rescue nil }.not_to change { [ Order.count, OrderItem.count ] }
  end

  it "leaves stock unchanged" do
    expect { checkout rescue nil }.not_to change { headphones.reload.stock }
  end

  it "leaves the cart unchanged" do
    expect { checkout rescue nil }.not_to change { user.cart.cart_items.reload.pluck(:product_id, :quantity) }
  end
end
```

## Testing Side Effects with an Injected Collaborator

```ruby
RSpec.describe Orders::ConfirmationService do
  let(:order) { create(:order) }
  let(:mailer) { class_double(OrderMailer) }
  let(:message) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }

  before do
    allow(mailer).to receive_message_chain(:with, :confirmation).and_return(message)
    described_class.new(order: order, mailer: mailer).call
  end

  it "enqueues the confirmation email" do
    expect(message).to have_received(:deliver_later)
  end
end
```

## Testing a `Data.define` Result

```ruby
context "when one product is out of stock" do
  let(:result) { described_class.new(user: user, order: order).call }

  it "reports the skipped product" do
    expect(result.skipped_products).to contain_exactly(sold_out_product)
  end
end
```

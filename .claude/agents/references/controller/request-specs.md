# Request Specs (HTML + Turbo Stream)

Modeled on `spec/requests/cart_items_spec.rb`. House rule: the request goes
in a `before` block through a named helper; `it` blocks hold expectations
only; transition matchers (`change`, `not_to change`) wrap the helper call.

Helpers from `spec/support/`:
- `sign_in_as(user, password: "password123")` — posts to `session_path`
- `turbo_stream_targets` — the `target` ids of every `<turbo-stream>` in the response
- `response_link_hrefs` — every `a[href]` in the response
- `exclude` — negated `include`

## Turbo Stream actions

```ruby
require "rails_helper"

RSpec.describe "Cart items", type: :request do
  let(:turbo_stream_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }
  let(:user) { create(:user, :with_cart) }
  let(:product) { create(:product, stock: 10) }

  describe "POST /cart_items" do
    def add_to_cart(product_id:, quantity: nil)
      post cart_items_path, params: { product_id: product_id, quantity: quantity }.compact, headers: turbo_stream_headers
    end

    context "as a guest" do
      it "creates no line" do
        expect { add_to_cart(product_id: product.id) }.not_to change(CartItem, :count)
      end

      context "after the request" do
        before { add_to_cart(product_id: product.id) }

        it { expect(response).to redirect_to(new_session_path) }
      end
    end

    context "when signed in" do
      before { sign_in_as(user) }

      it "creates a line in the user's cart" do
        expect { add_to_cart(product_id: product.id, quantity: 2) }.to change { user.cart.cart_items.count }.by(1)
      end

      context "after adding" do
        before { add_to_cart(product_id: product.id, quantity: 2) }

        it { expect(response).to have_http_status(:ok) }
        it { expect(response.media_type).to eq("text/vnd.turbo-stream.html") }

        it "updates the cart count and cart items streams" do
          expect(turbo_stream_targets).to include("cart_count", "cart_items")
        end
      end

      context "with a sold-out product" do
        let(:product) { create(:product, :sold_out) }

        it "creates no line" do
          expect { add_to_cart(product_id: product.id) }.not_to change(CartItem, :count)
        end
      end
    end
  end

  describe "PATCH /cart_items/:id" do
    let!(:line) { create(:cart_item, cart: user.cart, product: product, quantity: 1) }

    def update_line(target, quantity)
      patch cart_item_path(target), params: { quantity: quantity }, headers: turbo_stream_headers
    end

    before { sign_in_as(user) }

    context "for another user's cart item" do
      let(:other_line) { create(:cart_item, cart: create(:cart), quantity: 1) }

      before { update_line(other_line, 3) }

      it { expect(response).to have_http_status(:not_found) }

      it "leaves the quantity unchanged" do
        expect(other_line.reload.quantity).to eq(1)
      end
    end
  end
end
```

## HTML form actions

```ruby
RSpec.describe "Checkouts", type: :request do
  let(:user) { create(:user, :with_cart) }
  let(:product) { create(:product, stock: 10) }
  let!(:line) { create(:cart_item, cart: user.cart, product: product) }

  describe "POST /checkout" do
    def place_order(attributes = attributes_for(:order).slice(
      :shipping_name, :shipping_address_line1, :shipping_city, :shipping_state, :shipping_zip
    ))
      post checkout_path, params: { order: attributes }
    end

    before { sign_in_as(user) }

    context "with a valid cart" do
      it "creates an order for the user" do
        expect { place_order }.to change { user.orders.count }.by(1)
      end

      context "after placing the order" do
        before { place_order }

        it { expect(response).to redirect_to(order_path(user.orders.last)) }
      end
    end

    context "with insufficient stock" do
      before do
        line.update!(quantity: 10)
        product.update!(stock: 1)
        place_order
      end

      it { expect(response).to have_http_status(:unprocessable_content) }
    end
  end
end
```

## Listing pages: assert links, not copy

```ruby
context "when signed in" do
  before do
    sign_in_as(user)
    get orders_path
  end

  it "links only to the current user's orders" do
    expect(response_link_hrefs).to include(order_path(own_order)).and exclude(order_path(other_order))
  end
end
```

## Checklist per action

- Guest → redirect to `new_session_path`
- Another user's record → 404, DB unchanged
- Valid params → redirect or 200, DB changed
- Invalid params / service error → 422 (HTML) or a message stream (Turbo), DB unchanged
- Turbo Stream → media type and `turbo_stream_targets`
- Never assert CSS classes or copy

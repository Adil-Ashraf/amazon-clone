# RSpec Test Examples

Drawn from this app's `spec/`. Every example follows the house rule: the
action goes in a `before` block through a named helper, each `it` holds
expectations only, and transition matchers (`change`, `not_to change`,
`raise_error`) wrap the action.

## Model Test

```ruby
# spec/models/product_spec.rb
require "rails_helper"

RSpec.describe Product, type: :model do
  subject { build(:product) }

  describe "associations" do
    it { is_expected.to belong_to(:category) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_numericality_of(:price_cents).only_integer.is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:stock).only_integer.is_greater_than_or_equal_to(0) }
  end

  describe "stock predicates" do
    context "when sold out" do
      let(:product) { build(:product, :sold_out) }

      it { expect(product).to be_out_of_stock }
      it { expect(product).not_to be_low_stock }
    end

    context "when low on stock" do
      let(:product) { build(:product, :low_stock) }

      it { expect(product).to be_low_stock }
    end
  end
end
```

For a model with a normalizing callback, perform the validation in `before`:

```ruby
describe "email normalization" do
  let(:user) { build(:user, email: "Mixed.Case@Example.COM") }

  before { user.validate }

  it "downcases the email before validation" do
    expect(user.email).to eq("mixed.case@example.com")
  end
end
```

## Service Test

```ruby
# spec/services/carts/cart_service_spec.rb
require "rails_helper"

RSpec.describe Carts::CartService do
  let(:cart) { create(:cart) }
  let(:service) { described_class.new(cart) }
  let(:product) { create(:product, stock: 10) }

  describe "#add_item" do
    def add_item(quantity)
      service.add_item(product: product, quantity: quantity)
    end

    context "when the product is already in the cart" do
      let!(:line) { create(:cart_item, cart: cart, product: product, quantity: 1) }

      it "does not create a second line" do
        expect { add_item(3) }.not_to change { cart.cart_items.count }
      end

      context "after adding" do
        before { add_item(3) }

        it "merges the quantities" do
          expect(line.reload.quantity).to eq(4)
        end
      end

      context "when the merged quantity would exceed stock" do
        it "raises InsufficientStockError" do
          expect { add_item(10) }.to raise_error(described_class::InsufficientStockError)
        end
      end
    end
  end
end
```

A failure must change nothing — assert that with `not_to change` around the call:

```ruby
# spec/services/orders/checkout_service_spec.rb
context "when a line exceeds stock" do
  before { novel.update!(stock: 2) } # cart wants 3

  it "creates no order or order items" do
    expect { checkout rescue nil }.not_to change { [ Order.count, OrderItem.count ] }
  end

  it "leaves stock unchanged" do
    expect { checkout rescue nil }.not_to change { [ headphones.reload.stock, novel.reload.stock ] }
  end
end
```

## Request Test (preferred over controller specs)

HTML action:

```ruby
# spec/requests/orders_spec.rb
require "rails_helper"

RSpec.describe "Orders", type: :request do
  let(:user) { create(:user) }
  let!(:own_order) { create(:order, user: user) }
  let!(:other_order) { create(:order) }

  describe "GET /orders/:id" do
    def get_order(order)
      get order_path(order)
    end

    before { sign_in_as(user) }

    context "for the current user's order" do
      before { get_order(own_order) }

      it { expect(response).to have_http_status(:ok) }
    end

    context "for another user's order" do
      before { get_order(other_order) }

      it { expect(response).to have_http_status(:not_found) }
    end
  end
end
```

Turbo Stream action:

```ruby
# spec/requests/cart_items_spec.rb
let(:turbo_stream_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

def add_to_cart(product_id:, quantity: nil)
  post cart_items_path, params: { product_id: product_id, quantity: quantity }.compact, headers: turbo_stream_headers
end

context "after adding" do
  before do
    sign_in_as(user)
    add_to_cart(product_id: product.id, quantity: 2)
  end

  it { expect(response.media_type).to eq("text/vnd.turbo-stream.html") }

  it "updates the cart count and cart items streams" do
    expect(turbo_stream_targets).to include("cart_count", "cart_items")
  end
end
```

## Query Object Test

```ruby
# spec/queries/recent_orders_query_spec.rb
require "rails_helper"

RSpec.describe RecentOrdersQuery do
  subject(:query) { described_class.new(user: user) }

  let(:user) { create(:user) }
  let!(:recent) { create(:order, user: user, created_at: 2.days.ago) }
  let!(:old) { create(:order, user: user, created_at: 60.days.ago) }
  let!(:someone_elses) { create(:order, created_at: 1.day.ago) }

  it "returns only the user's orders from the last 30 days" do
    expect(query.call).to contain_exactly(recent)
  end
end
```

## Pundit Policy Test

Roles are guest, owner and another user — there is no admin.

```ruby
# spec/policies/order_policy_spec.rb
require "rails_helper"

RSpec.describe OrderPolicy, type: :policy do
  subject(:policy) { described_class.new(user, order) }

  let(:order) { build(:order) }

  context "as a guest" do
    let(:user) { nil }

    it { expect(policy.show?).to be(false) }
  end

  context "as the owner" do
    let(:user) { order.user }

    it { expect(policy.show?).to be(true) }
  end

  context "as another user" do
    let(:user) { build(:user) }

    it { expect(policy.show?).to be(false) }
  end
end
```

## System Test (end-to-end)

Only for a few critical browser flows. Interact through labels and buttons;
assert on paths, links and stable ids.

```ruby
# spec/system/purchase_flow_spec.rb
require "rails_helper"

RSpec.describe "Purchase flow", type: :system do
  let(:user) { create(:user, :with_cart) }
  let!(:product) { create(:product, stock: 10) }

  def add_to_cart(product)
    visit product_path(product)
    click_button "Add to Cart"
    find("#cart_count", text: "1") # wait for the Turbo Stream to land
  end

  context "after adding a product to the cart" do
    before do
      sign_in_via_ui(user)
      add_to_cart(product)
      visit cart_path
    end

    it "lists the product in the cart" do
      expect(find("#cart_items")).to have_link(href: product_path(product))
    end
  end
end
```

## Anti-Patterns to Avoid

```ruby
# Don't do this!
RSpec.describe "Orders", type: :request do
  # Action inside `it` -- breaks the house rule
  it "shows the order" do
    get order_path(order)
    expect(response).to have_http_status(:ok)
  end

  # Asserting copy and CSS classes -- breaks on every redesign
  it "shows a success banner" do
    expect(response.body).to include("bg-green-100")
    expect(response.body).to include("Order placed!")
  end

  # Tests multiple behaviors at once
  it "creates the order and empties the cart and decrements stock" do
    # ...
  end
end
```

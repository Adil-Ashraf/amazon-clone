# Testing Strategy by Layer

RSpec + FactoryBot + Shoulda Matchers + Capybara, all in `spec/`.
`.claude/rules/testing.md` holds the house rule: the action goes in a
`before` block via a named helper, `it` blocks hold expectations only,
transition matchers (`change`, `not_to change`, `raise_error`) wrap the action.

## Test Pyramid

```
          /\
         /  \      System specs (spec/system) — a few critical browser flows
        /----\
       /      \    Request specs (spec/requests) — every controller action,
      /        \   HTML and Turbo Stream, authn/authz
     /----------\
    /            \ Model, service, policy, query specs — most of the suite
   /______________\
```

Run with `bin/docker-dev test` (everything except system) and
`bin/docker-dev system`.

## 1. Model and Service Specs (the base)

### Model Specs

```ruby
# spec/models/order_spec.rb
RSpec.describe Order, type: :model do
  subject { build(:order) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:order_items).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to define_enum_for(:status).with_values(pending: 0, paid: 1, shipped: 2) }
    it { is_expected.to validate_numericality_of(:total_cents).only_integer.is_greater_than_or_equal_to(0) }
  end
end
```

### Service Specs

```ruby
# spec/services/orders/checkout_service_spec.rb
def checkout
  described_class.new(user: user, shipping_attributes: shipping).call
end

it "creates one order" do
  expect { checkout }.to change(Order, :count).by(1)
end

context "after checkout" do
  let!(:order) { checkout }

  it "snapshots each line's price" do
    expect(order.order_items.pluck(:price_cents)).to contain_exactly(9999, 1499)
  end
end

context "when a line exceeds stock" do
  before { novel.update!(stock: 2) }

  it "raises InsufficientStockError" do
    expect { checkout }.to raise_error(described_class::InsufficientStockError)
  end

  it "leaves stock unchanged" do
    expect { checkout rescue nil }.not_to change { novel.reload.stock }
  end
end
```

### Policy and Query Specs

```ruby
# spec/policies/order_policy_spec.rb
context "as another user" do
  let(:user) { build(:user) }

  it { expect(policy.show?).to be(false) }
end
```

Query specs assert results and per-user isolation: user A's query never
returns user B's records.

## 2. Request Specs (the middle)

Every controller action, over HTML and Turbo Stream. Cover authentication
(guest → sign in), authorization (another user's record → 404), valid and
invalid params, and Turbo Stream target ids.

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

  it "updates the cart count and cart items streams" do
    expect(turbo_stream_targets).to include("cart_count", "cart_items")
  end
end

context "for another user's cart item" do
  before do
    sign_in_as(user)
    patch cart_item_path(other_line), params: { quantity: 3 }, headers: turbo_stream_headers
  end

  it { expect(response).to have_http_status(:not_found) }
end
```

Listing pages assert record links, not copy:

```ruby
it "links only to the current user's orders" do
  expect(response_link_hrefs).to include(order_path(own_order)).and exclude(order_path(other_order))
end
```

## 3. System Specs (the tip)

Only for flows that need a real browser: Turbo Streams landing, Stimulus
behavior, multi-page journeys. Today: guest browsing and the purchase flow.

```ruby
# spec/system/purchase_flow_spec.rb
context "after checking out" do
  before do
    sign_in_via_ui(user)
    add_to_cart(product)
    check_out
  end

  it "shows the new order" do
    expect(page).to have_current_path(order_path(user.orders.last)).and have_link(href: product_path(product))
  end
end
```

## Test Helpers

`spec/support/` provides:

| Helper | For |
|---|---|
| `sign_in_as(user)` | Request specs — posts to `session_path` |
| `sign_in_via_ui(user)` | System specs — fills in the sign-in form |
| `turbo_stream_targets` | Target ids of every `<turbo-stream>` in the response |
| `response_link_hrefs` | Every `a[href]` in the response |
| `exclude` | Negated `include` matcher |

### Factory Traits

```ruby
create(:user, :with_cart)
create(:product, :sold_out)      # stock 0
create(:product, :low_stock)     # stock 2
create(:category, :electronics)  # real slug, so icons and colours resolve
```

## What Not to Assert

- CSS classes (`bg-green-100`) or copy ("Order placed!") — both change with the design
- Implementation details (private methods, instance variables)

## Checklist

- [ ] Every model: associations and validations with Shoulda Matchers, plus its methods
- [ ] Every service: success DB effects, each error class, rollback on failure
- [ ] Every policy: owner, another user, guest
- [ ] Every controller action: request spec for guest, owner, another user, valid/invalid params
- [ ] Turbo Stream actions: media type and target ids
- [ ] New critical browser flow: one system spec

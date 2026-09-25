# Pundit Testing and Controller Usage Reference

The project does not use the `pundit-matchers` gem: call the predicates
directly. Cover **guest**, **owner** and **another user** for every predicate,
and assert the 404 for another user's record in the request spec.

## Complete Policy Test (OrderPolicy)

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

## Test with Several Predicates (CartPolicy)

```ruby
# spec/policies/cart_policy_spec.rb
RSpec.describe CartPolicy, type: :policy do
  subject(:policy) { described_class.new(user, cart) }

  let(:cart) { build(:cart) }

  %i[show? update?].each do |predicate|
    describe "##{predicate}" do
      context "as the owner" do
        let(:user) { cart.user }

        it { expect(policy.public_send(predicate)).to be(true) }
      end

      context "as another user" do
        let(:user) { build(:user) }

        it { expect(policy.public_send(predicate)).to be(false) }
      end
    end
  end
end
```

## Test with State-Dependent Rules

```ruby
RSpec.describe OrderPolicy, type: :policy do
  subject(:policy) { described_class.new(order.user, order) }

  context "when the order is pending" do
    let(:order) { build(:order, status: :pending) }

    it { expect(policy.cancel?).to be(true) }
  end

  context "when the order is paid" do
    let(:order) { build(:order, status: :paid) }

    it { expect(policy.cancel?).to be(false) }
  end
end
```

## Controller with Authorization

Scope through `current_user` first, then authorize:

```ruby
# app/controllers/orders_controller.rb
class OrdersController < ApplicationController
  before_action :require_login

  def index
    @orders = current_user.orders.order(created_at: :desc)
  end

  def show
    @order = current_user.orders.find(params[:id]) # another user's order → 404
    authorize @order
  end
end
```

```ruby
# app/controllers/cart_items_controller.rb
before_action :require_login
before_action :set_cart

def set_cart
  @cart = current_user.cart
  authorize @cart, :update?
end
```

## Error Handling in ApplicationController

```ruby
# app/controllers/application_controller.rb
include Pundit::Authorization

rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

def pundit_user
  current_user
end

def user_not_authorized
  redirect_to root_path, alert: "You are not authorized to do that."
end
```

## Request Spec for Authorization

```ruby
context "for another user's order" do
  before do
    sign_in_as(user)
    get order_path(create(:order))
  end

  it { expect(response).to have_http_status(:not_found) }
end
```

## Checks in Views

Hide actions the viewer can't perform; the controller still enforces them.

```erb
<% if policy(@order).cancel? %>
  <%= button_to "Cancel order", cancel_order_path(@order), method: :patch %>
<% end %>
```

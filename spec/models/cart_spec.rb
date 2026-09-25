require "rails_helper"

RSpec.describe Cart, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:cart_items).dependent(:destroy) }
  end

  describe "totals" do
    let(:cart) { create(:cart) }

    before do
      create(:cart_item, cart: cart, product: create(:product, price_cents: 1250), quantity: 2)
      create(:cart_item, cart: cart, product: create(:product, price_cents: 300), quantity: 1)
    end

    it "sums price times quantity across lines as the subtotal" do
      expect(cart.subtotal_cents).to eq(2800)
    end

    it "charges shipping below the free-shipping threshold" do
      expect(cart.shipping_cents).to eq(Order::SHIPPING_FEE_CENTS)
    end

    it "adds shipping to the total" do
      expect(cart.total_cents).to eq(2800 + Order::SHIPPING_FEE_CENTS)
    end
  end
end

require "rails_helper"

RSpec.describe Cart, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:cart_items).dependent(:destroy) }
  end

  describe "#total_cents" do
    let(:cart) { create(:cart) }

    before do
      create(:cart_item, cart: cart, product: create(:product, price_cents: 1250), quantity: 2)
      create(:cart_item, cart: cart, product: create(:product, price_cents: 300), quantity: 1)
    end

    it "sums price times quantity across lines" do
      expect(cart.total_cents).to eq(2800)
    end
  end
end

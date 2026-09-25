require "rails_helper"

RSpec.describe Order, type: :model do
  subject { build(:order) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:order_items).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to define_enum_for(:status).with_values(pending: 0, paid: 1, shipped: 2, out_for_delivery: 3, delivered: 4, cancelled: 5) }
    it { is_expected.to validate_presence_of(:total_cents) }
    it { is_expected.to validate_numericality_of(:total_cents).only_integer.is_greater_than_or_equal_to(0) }

    it { is_expected.to validate_numericality_of(:shipping_cents).only_integer.is_greater_than_or_equal_to(0) }

    %i[shipping_name shipping_address_line1 shipping_city shipping_state shipping_zip].each do |field|
      it { is_expected.to validate_presence_of(field) }
    end
  end

  describe ".shipping_cents_for" do
    it "charges the flat fee below the free-shipping threshold" do
      expect(described_class.shipping_cents_for(Order::FREE_SHIPPING_THRESHOLD_CENTS - 1)).to eq(Order::SHIPPING_FEE_CENTS)
    end

    it "ships free at the threshold" do
      expect(described_class.shipping_cents_for(Order::FREE_SHIPPING_THRESHOLD_CENTS)).to eq(0)
    end
  end

  describe "#subtotal_cents" do
    subject { build(:order, total_cents: 2599, shipping_cents: 599) }

    it "is the total without shipping" do
      expect(subject.subtotal_cents).to eq(2000)
    end
  end
end

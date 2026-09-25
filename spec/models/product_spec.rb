require "rails_helper"

RSpec.describe Product, type: :model do
  subject { build(:product) }

  describe "associations" do
    it { is_expected.to belong_to(:category) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:description) }
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

      it { expect(product).not_to be_out_of_stock }
      it { expect(product).to be_low_stock }
    end

    context "when well stocked" do
      let(:product) { build(:product, stock: Product::LOW_STOCK_THRESHOLD + 1) }

      it { expect(product).not_to be_out_of_stock }
      it { expect(product).not_to be_low_stock }
    end
  end
end

require "rails_helper"

RSpec.describe Product, type: :model do
  subject { build(:product) }

  describe "associations" do
    it { is_expected.to belong_to(:category) }
    it { is_expected.to have_many(:reviews).dependent(:destroy) }
    it { is_expected.to have_many(:wishlist_items).dependent(:destroy) }
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

  describe "markdowns" do
    context "with a compare-at price above the price" do
      let(:product) { build(:product, price_cents: 7500, compare_at_price_cents: 10_000) }

      it { expect(product).to be_valid }
      it { expect(product).to be_on_sale }
      it { expect(product.discount_percent).to eq(25) }
    end

    context "with a compare-at price not above the price" do
      let(:product) { build(:product, price_cents: 7500, compare_at_price_cents: 7500) }

      it { expect(product).not_to be_valid }
    end

    context "without a compare-at price" do
      let(:product) { build(:product) }

      it { expect(product).not_to be_on_sale }
      it { expect(product.discount_percent).to eq(0) }
    end
  end

  describe ".on_sale" do
    let!(:marked_down) { create(:product, :on_sale) }
    let!(:full_price) { create(:product) }

    it "returns only marked-down products" do
      expect(described_class.on_sale).to contain_exactly(marked_down)
    end
  end

  describe ".popular" do
    let!(:bestseller) { create(:product) }
    let!(:unsold) { create(:product) }

    before { create(:order_item, product: bestseller, quantity: 3) }

    it "ranks by units sold" do
      expect(described_class.popular.first).to eq(bestseller)
    end
  end
end

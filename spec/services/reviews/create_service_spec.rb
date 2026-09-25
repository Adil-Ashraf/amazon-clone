require "rails_helper"

RSpec.describe Reviews::CreateService do
  let(:user) { create(:user) }
  let(:product) { create(:product) }
  let(:service) { described_class.new(user: user, product: product) }

  def review(rating: 4, body: "Works well.")
    service.call(rating: rating, body: body)
  end

  context "when the user bought the product" do
    before { create(:order_item, order: create(:order, user: user), product: product) }

    it "creates a review" do
      expect { review }.to change(product.reviews, :count).by(1)
    end

    context "after reviewing" do
      before do
        create(:review, product: product, rating: 5)
        review(rating: 2)
        product.reload
      end

      it "updates the product's review count" do
        expect(product.reviews_count).to eq(2)
      end

      it "updates the product's average rating" do
        expect(product.rating_average).to eq(3.5)
      end
    end

    context "with a blank body" do
      it "creates no review" do
        expect { review(body: "") }.not_to change(Review, :count)
      end

      it "returns the unsaved review with errors" do
        expect(review(body: "").errors[:body]).to be_present
      end
    end

    context "when the user already reviewed it" do
      before { create(:review, user: user, product: product) }

      it "creates no second review" do
        expect { review }.not_to change(Review, :count)
      end
    end
  end

  %i[cancelled pending].each do |status|
    context "when the user's only order for it is #{status}" do
      before { create(:order_item, order: create(:order, user: user, status: status), product: product) }

      it "raises NotPurchasedError" do
        expect { review }.to raise_error(described_class::NotPurchasedError)
      end
    end
  end

  context "when the user never bought the product" do
    it "raises NotPurchasedError" do
      expect { review }.to raise_error(described_class::NotPurchasedError)
    end

    it "creates no review" do
      expect { review rescue nil }.not_to change(Review, :count)
    end
  end
end

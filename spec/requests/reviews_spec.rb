require "rails_helper"

RSpec.describe "Reviews", type: :request do
  let(:user) { create(:user) }
  let(:product) { create(:product) }
  let(:review_params) { { review: { rating: 4, body: "Great value." } } }

  def post_review(params = review_params)
    post product_reviews_path(product), params: params
  end

  context "as a guest" do
    before { post_review }

    it { expect(response).to redirect_to(new_session_path) }
  end

  context "when signed in without buying the product" do
    before { sign_in_as(user) }

    it "creates no review" do
      expect { post_review }.not_to change(Review, :count)
    end

    context "after the request" do
      before { post_review }

      it { expect(response).to redirect_to(product_path(product, anchor: "reviews")) }
    end
  end

  context "when signed in after buying the product" do
    before do
      create(:order_item, order: create(:order, user: user), product: product)
      sign_in_as(user)
    end

    it "creates the review" do
      expect { post_review }.to change { product.reviews.count }.by(1)
    end

    context "with a blank body" do
      it "creates no review" do
        expect { post_review(review: { rating: 4, body: "" }) }.not_to change(Review, :count)
      end
    end

    context "after reviewing" do
      before { post_review }

      it { expect(response).to redirect_to(product_path(product, anchor: "reviews")) }

      it "updates the product's rating" do
        expect(product.reload).to have_attributes(reviews_count: 1, rating_average: 4)
      end
    end
  end
end

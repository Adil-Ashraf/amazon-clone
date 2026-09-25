require "rails_helper"

RSpec.describe "Wishlist items", type: :request do
  let(:turbo_stream_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }
  let(:user) { create(:user) }
  let(:product) { create(:product) }

  describe "GET /wishlist" do
    context "as a guest" do
      before { get wishlist_items_path }

      it { expect(response).to redirect_to(new_session_path) }
    end

    context "when signed in" do
      let!(:saved) { create(:wishlist_item, user: user, product: product) }
      let!(:someone_elses) { create(:wishlist_item) }

      before do
        sign_in_as(user)
        get wishlist_items_path
      end

      it { expect(response).to have_http_status(:ok) }

      it "links only to the user's saved products" do
        expect(response_link_hrefs).to include(product_path(product)).and exclude(product_path(someone_elses.product))
      end
    end
  end

  describe "POST /wishlist" do
    def save_product
      post wishlist_items_path, params: { product_id: product.id }, headers: turbo_stream_headers
    end

    context "as a guest" do
      it "saves nothing" do
        expect { save_product }.not_to change(WishlistItem, :count)
      end
    end

    context "when signed in" do
      before { sign_in_as(user) }

      it "adds the product to the user's wishlist" do
        expect { save_product }.to change { user.wishlist_items.count }.by(1)
      end

      context "when it is already saved" do
        before { create(:wishlist_item, user: user, product: product) }

        it "keeps a single entry" do
          expect { save_product }.not_to change(WishlistItem, :count)
        end
      end

      context "after saving" do
        before { save_product }

        it { expect(response.media_type).to eq("text/vnd.turbo-stream.html") }

        it "updates every heart for the product" do
          expect(turbo_stream_all_targets).to include(".#{ActionView::RecordIdentifier.dom_id(product, :wishlist)}")
        end

        it "adds a toast" do
          expect(turbo_stream_targets).to include("toasts", "wishlist_items", "saved_items")
        end
      end
    end
  end

  describe "DELETE /wishlist/:id" do
    before { sign_in_as(user) }

    context "for the user's own item" do
      let!(:item) { create(:wishlist_item, user: user, product: product) }

      it "removes it" do
        expect { delete wishlist_item_path(item), headers: turbo_stream_headers }.to change(WishlistItem, :count).by(-1)
      end
    end

    context "for another user's item" do
      let!(:item) { create(:wishlist_item) }

      it "removes nothing" do
        expect { delete wishlist_item_path(item) }.not_to change(WishlistItem, :count)
      end

      context "after the request" do
        before { delete wishlist_item_path(item) }

        it { expect(response).to have_http_status(:not_found) }
      end
    end
  end
end

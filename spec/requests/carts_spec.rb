require "rails_helper"

RSpec.describe "Carts", type: :request do
  describe "GET /cart" do
    def get_cart
      get cart_path
    end

    context "as a guest" do
      before { get_cart }

      it { expect(response).to redirect_to(new_session_path) }
    end

    context "when signed in without a cart yet" do
      let(:user) { create(:user) }

      before { sign_in_as(user) }

      it "creates one" do
        expect { get_cart }.to change { Cart.where(user: user).count }.from(0).to(1)
      end

      context "after the request" do
        before { get_cart }

        it { expect(response).to have_http_status(:ok) }
      end
    end

    context "when signed in with a cart" do
      let(:user) { create(:user, :with_cart) }

      before do
        create_list(:product, 3).each { |product| create(:cart_item, cart: user.cart, product: product) }
        sign_in_as(user)
      end

      it "does not create another cart" do
        expect { get_cart }.not_to change(Cart, :count)
      end

      it "preloads each line's category" do
        expect { get_cart }.not_to lazy_load_categories
      end
    end
  end
end

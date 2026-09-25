require "rails_helper"

RSpec.describe "Cart items", type: :request do
  let(:turbo_stream_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }
  let(:user) { create(:user, :with_cart) }
  let(:product) { create(:product, stock: 10) }

  describe "POST /cart_items" do
    def add_to_cart(product_id:, quantity: nil)
      post cart_items_path, params: { product_id: product_id, quantity: quantity }.compact, headers: turbo_stream_headers
    end

    context "as a guest" do
      it "creates no line" do
        expect { add_to_cart(product_id: product.id) }.not_to change(CartItem, :count)
      end

      context "after the request" do
        before { add_to_cart(product_id: product.id) }

        it { expect(response).to redirect_to(new_session_path) }
      end
    end

    context "when signed in" do
      before { sign_in_as(user) }

      it "creates a line in the user's cart" do
        expect { add_to_cart(product_id: product.id, quantity: 2) }.to change { user.cart.cart_items.count }.by(1)
      end

      context "after adding" do
        before { add_to_cart(product_id: product.id, quantity: 2) }

        it { expect(response).to have_http_status(:ok) }
        it { expect(response.media_type).to eq("text/vnd.turbo-stream.html") }

        it "updates the cart count and cart items streams" do
          expect(turbo_stream_targets).to include("cart_count", "cart_items")
        end

        it "stores the requested quantity" do
          expect(user.cart.cart_items.find_by(product: product).quantity).to eq(2)
        end
      end

      context "with a sold-out product" do
        let(:product) { create(:product, :sold_out) }

        it "creates no line" do
          expect { add_to_cart(product_id: product.id) }.not_to change(CartItem, :count)
        end

        context "after the request" do
          before { add_to_cart(product_id: product.id) }

          it { expect(response).to have_http_status(:ok) }

          it "still updates the cart count and cart items streams" do
            expect(turbo_stream_targets).to include("cart_count", "cart_items")
          end
        end
      end
    end
  end

  describe "PATCH /cart_items/:id" do
    let!(:line) { create(:cart_item, cart: user.cart, product: product, quantity: 1) }

    def update_line(target, quantity)
      patch cart_item_path(target), params: { quantity: quantity }, headers: turbo_stream_headers
    end

    before { sign_in_as(user) }

    context "with a quantity within stock" do
      before { update_line(line, 3) }

      it { expect(response).to have_http_status(:ok) }

      it "updates the cart count and cart items streams" do
        expect(turbo_stream_targets).to include("cart_count", "cart_items")
      end

      it "updates the quantity" do
        expect(line.reload.quantity).to eq(3)
      end
    end

    context "with a quantity above stock" do
      before { update_line(line, 999) }

      it { expect(response).to have_http_status(:ok) }

      it "leaves the quantity unchanged" do
        expect(line.reload.quantity).to eq(1)
      end
    end

    context "for another user's cart item" do
      let(:other_line) { create(:cart_item, cart: create(:cart), quantity: 1) }

      before { update_line(other_line, 3) }

      it { expect(response).to have_http_status(:not_found) }

      it "leaves the quantity unchanged" do
        expect(other_line.reload.quantity).to eq(1)
      end
    end
  end

  describe "DELETE /cart_items/:id" do
    let!(:line) { create(:cart_item, cart: user.cart, product: product) }

    def remove_line(target)
      delete cart_item_path(target), headers: turbo_stream_headers
    end

    before { sign_in_as(user) }

    context "for the user's own line" do
      it "removes the line" do
        expect { remove_line(line) }.to change(CartItem, :count).by(-1)
      end

      context "after removing" do
        before { remove_line(line) }

        it { expect(response).to have_http_status(:ok) }

        it "updates the cart count and cart items streams" do
          expect(turbo_stream_targets).to include("cart_count", "cart_items")
        end
      end
    end

    context "for another user's cart item" do
      let!(:other_line) { create(:cart_item, cart: create(:cart)) }

      it "removes nothing" do
        expect { remove_line(other_line) }.not_to change(CartItem, :count)
      end

      context "after the request" do
        before { remove_line(other_line) }

        it { expect(response).to have_http_status(:not_found) }
      end
    end
  end
end

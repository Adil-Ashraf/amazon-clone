require "rails_helper"

RSpec.describe "Checkouts", type: :request do
  let(:shipping) do
    {
      shipping_name: "Test User",
      shipping_address_line1: "1 Spec Street",
      shipping_city: "Specville",
      shipping_state: "CA",
      shipping_zip: "90210"
    }
  end
  let(:user) { create(:user, :with_cart) }
  let(:product) { create(:product, stock: 10) }
  let!(:line) { create(:cart_item, cart: user.cart, product: product, quantity: 1) }

  describe "GET /checkout/new" do
    def get_new_checkout
      get new_checkout_path
    end

    context "as a guest" do
      before { get_new_checkout }

      it { expect(response).to redirect_to(new_session_path) }
    end

    context "when signed in with items in the cart" do
      before do
        sign_in_as(user)
        get_new_checkout
      end

      it { expect(response).to have_http_status(:ok) }
    end

    context "when signed in with an empty cart" do
      before do
        line.destroy!
        sign_in_as(user)
        get_new_checkout
      end

      it { expect(response).to redirect_to(cart_path) }
    end
  end

  describe "POST /checkout" do
    def place_order(attributes = shipping)
      post checkout_path, params: { order: attributes }
    end

    before { sign_in_as(user) }

    context "with a valid cart and shipping details" do
      it "creates an order for the user" do
        expect { place_order }.to change { user.orders.count }.by(1)
      end

      context "after placing the order" do
        before { place_order }

        let(:order) { user.orders.order(:created_at).last }

        it { expect(response).to redirect_to(order_path(order)) }
        it { expect(order).to be_paid }

        it "empties the cart" do
          expect(user.cart.cart_items.reload).to be_empty
        end
      end
    end

    context "with insufficient stock" do
      before do
        line.update!(quantity: 10)
        product.update!(stock: 1)
      end

      it "creates no order" do
        expect { place_order }.not_to change(Order, :count)
      end

      context "after the request" do
        before { place_order }

        it { expect(response).to have_http_status(:unprocessable_content) }

        it "leaves stock unchanged" do
          expect(product.reload.stock).to eq(1)
        end
      end
    end

    context "with missing shipping details" do
      let(:invalid_shipping) { shipping.merge(shipping_city: "") }

      it "creates no order" do
        expect { place_order(invalid_shipping) }.not_to change(Order, :count)
      end

      context "after the request" do
        before { place_order(invalid_shipping) }

        it { expect(response).to have_http_status(:unprocessable_content) }

        it "leaves stock unchanged" do
          expect(product.reload.stock).to eq(10)
        end
      end
    end
  end
end

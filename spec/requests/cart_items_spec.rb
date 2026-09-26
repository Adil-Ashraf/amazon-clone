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

        it "adds a toast" do
          expect(turbo_stream_targets).to include("toasts")
        end

        it "replaces every copy of the product's quick-add control" do
          expect(turbo_stream_all_targets).to include(".#{ActionView::RecordIdentifier.dom_id(product, :quick_add)}")
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

      %w[0 -3 abc 1.5].each do |quantity|
        context "with a quantity of #{quantity.inspect}" do
          it "creates no line" do
            expect { add_to_cart(product_id: product.id, quantity: quantity) }.not_to change(CartItem, :count)
          end

          context "after the request" do
            before { add_to_cart(product_id: product.id, quantity: quantity) }

            it { expect(response).to have_http_status(:ok) }

            it "shows an error on the product page" do
              expect(response_document.at_css('turbo-stream[target="add_to_cart_status"] template').text.strip).to be_present
            end
          end
        end
      end

      context "with a negative quantity for a product already in the cart" do
        let!(:line) { create(:cart_item, cart: user.cart, product: product, quantity: 4) }

        it "leaves the line's quantity unchanged" do
          expect { add_to_cart(product_id: product.id, quantity: -3) }.not_to change { line.reload.quantity }
        end
      end

      context "with an invalid quantity, without Turbo Streams" do
        before do
          post cart_items_path, params: { product_id: product.id, quantity: 0 }, headers: { "HTTP_REFERER" => products_url }
        end

        it { expect(response).to redirect_to(products_url) }

        it "explains the problem" do
          expect(flash[:alert]).to be_present
        end
      end

      context "with lines from several categories in the cart" do
        before do
          create_list(:product, 3).each { |other| create(:cart_item, cart: user.cart, product: other) }
        end

        it "preloads each line's category for the cart stream" do
          expect { add_to_cart(product_id: product.id) }.not_to lazy_load_categories
        end
      end

      context "without Turbo Streams" do
        def add_to_cart_as_html
          post cart_items_path, params: { product_id: product.id }, headers: { "HTTP_REFERER" => products_url }
        end

        it "creates a line" do
          expect { add_to_cart_as_html }.to change { user.cart.cart_items.count }.by(1)
        end

        context "after the request" do
          before { add_to_cart_as_html }

          it { expect(response).to redirect_to(products_url) }
        end
      end
    end

    context "when signed in without a cart yet" do
      let(:user) { create(:user) }

      before { sign_in_as(user) }

      it "creates the cart" do
        expect { add_to_cart(product_id: product.id) }.to change(Cart, :count).by(1)
      end

      context "after the request" do
        before { add_to_cart(product_id: product.id) }

        it { expect(response).to have_http_status(:ok) }

        it "adds the line to the new cart" do
          expect(user.reload.cart.cart_items.pluck(:product_id)).to eq([ product.id ])
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

    %w[-1 abc].each do |quantity|
      context "with a quantity of #{quantity.inspect}" do
        before { update_line(line, quantity) }

        it { expect(response).to have_http_status(:ok) }

        it "keeps the line and its quantity" do
          expect(line.reload.quantity).to eq(1)
        end

        it "shows an error in the cart" do
          expect(response_document.at_css('turbo-stream[target="cart_flash"] template').text.strip).to be_present
        end
      end
    end

    context "without Turbo Streams" do
      before { patch cart_item_path(line), params: { quantity: 3 } }

      it { expect(response).to redirect_to(cart_path) }

      it "updates the quantity" do
        expect(line.reload.quantity).to eq(3)
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

    context "without Turbo Streams" do
      def remove_line_as_html
        delete cart_item_path(line)
      end

      it "removes the line" do
        expect { remove_line_as_html }.to change(CartItem, :count).by(-1)
      end

      context "after removing" do
        before { remove_line_as_html }

        it { expect(response).to redirect_to(cart_path) }
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

  describe "POST /cart_items with buy_now" do
    before { sign_in_as(user) }

    def buy_now
      post cart_items_path, params: { product_id: product.id, quantity: 1, buy_now: "1" }, headers: turbo_stream_headers
    end

    it "adds the product to the cart" do
      expect { buy_now }.to change { user.cart.cart_items.count }.by(1)
    end

    context "after the request" do
      before { buy_now }

      it { expect(response).to redirect_to(new_checkout_path) }
    end
  end

  describe "POST /cart_items/:id/save_for_later" do
    let!(:line) { create(:cart_item, cart: user.cart, product: product) }

    before { sign_in_as(user) }

    def save_for_later(target)
      post save_for_later_cart_item_path(target), headers: turbo_stream_headers
    end

    it "moves the line to the wishlist" do
      expect { save_for_later(line) }.to change(CartItem, :count).by(-1).and change { user.wishlist_items.count }.by(1)
    end

    context "after saving" do
      before { save_for_later(line) }

      it "updates the cart and the saved list" do
        expect(turbo_stream_targets).to include("cart_count", "cart_items", "saved_items")
      end
    end

    context "for another user's cart item" do
      let!(:other_line) { create(:cart_item, cart: create(:cart)) }

      before { save_for_later(other_line) }

      it { expect(response).to have_http_status(:not_found) }
    end
  end
end

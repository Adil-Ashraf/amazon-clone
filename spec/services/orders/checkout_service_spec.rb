require "rails_helper"

RSpec.describe Orders::CheckoutService do
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
  let(:cart) { user.cart }
  let(:headphones) { create(:product, price_cents: 9999, stock: 10) }
  let(:novel) { create(:product, price_cents: 1499, stock: 3) }

  def checkout
    described_class.new(user: user, shipping_attributes: shipping).call
  end

  context "with a cart of in-stock lines" do
    before do
      create(:cart_item, cart: cart, product: headphones, quantity: 2)
      create(:cart_item, cart: cart, product: novel, quantity: 3) # all of its stock
    end

    it "creates one order" do
      expect { checkout }.to change(Order, :count).by(1)
    end

    context "after checkout" do
      let!(:order) { checkout }

      it "is paid, belongs to the user and keeps the shipping details" do
        expect(order).to have_attributes(status: "paid", user: user, shipping_name: "Test User")
      end

      it "totals price times quantity" do
        expect(order.total_cents).to eq((2 * 9999) + (3 * 1499))
      end

      it "snapshots each line's quantity and price" do
        expect(order.order_items.pluck(:product_id, :quantity, :price_cents))
          .to contain_exactly([ headphones.id, 2, 9999 ], [ novel.id, 3, 1499 ])
      end

      it "decrements stock" do
        expect([ headphones.reload.stock, novel.reload.stock ]).to eq([ 8, 0 ])
      end

      it "empties the cart" do
        expect(cart.cart_items.reload).to be_empty
      end
    end

    context "when the product price changes after checkout" do
      let!(:order) { checkout }

      before { headphones.update!(price_cents: 1) }

      it "keeps the snapshotted order item price" do
        expect(order.order_items.find_by(product: headphones).reload.price_cents).to eq(9999)
      end

      it "keeps the order total" do
        expect(order.reload.total_cents).to eq((2 * 9999) + (3 * 1499))
      end
    end

    context "when a line exceeds stock" do
      before { novel.update!(stock: 2) } # cart wants 3

      it "raises InsufficientStockError" do
        expect { checkout }.to raise_error(described_class::InsufficientStockError)
      end

      it "creates no order or order items" do
        expect { checkout rescue nil }.not_to change { [ Order.count, OrderItem.count ] }
      end

      it "leaves stock unchanged" do
        expect { checkout rescue nil }.not_to change { [ headphones.reload.stock, novel.reload.stock ] }
      end

      it "leaves the cart unchanged" do
        expect { checkout rescue nil }.not_to change { cart.cart_items.reload.pluck(:product_id, :quantity).sort }
      end
    end
  end

  context "with an empty cart" do
    it "raises EmptyCartError" do
      expect { checkout }.to raise_error(described_class::EmptyCartError)
    end

    it "creates no order" do
      expect { checkout rescue nil }.not_to change(Order, :count)
    end
  end
end

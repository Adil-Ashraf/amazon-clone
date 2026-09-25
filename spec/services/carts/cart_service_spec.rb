require "rails_helper"

RSpec.describe Carts::CartService do
  let(:cart) { create(:cart) }
  let(:service) { described_class.new(cart) }
  let(:product) { create(:product, stock: 10) }

  describe "#add_item" do
    def add_item(quantity)
      service.add_item(product: product, quantity: quantity)
    end

    context "when the product is not in the cart yet" do
      it "creates a line" do
        expect { add_item(2) }.to change { cart.cart_items.count }.by(1)
      end

      context "after adding" do
        before { add_item(2) }

        it "stores the requested quantity" do
          expect(cart.cart_items.find_by(product: product).quantity).to eq(2)
        end
      end
    end

    context "when the product is already in the cart" do
      let!(:line) { create(:cart_item, cart: cart, product: product, quantity: 1) }

      it "does not create a second line" do
        expect { add_item(3) }.not_to change { cart.cart_items.count }
      end

      context "after adding" do
        before { add_item(3) }

        it "merges the quantities" do
          expect(line.reload.quantity).to eq(4)
        end
      end

      context "when the merged quantity would exceed stock" do
        it "raises InsufficientStockError" do
          expect { add_item(10) }.to raise_error(described_class::InsufficientStockError)
        end

        it "leaves the existing quantity unchanged" do
          expect { add_item(10) rescue nil }.not_to change { line.reload.quantity }
        end
      end
    end

    context "when the product is sold out" do
      let(:product) { create(:product, :sold_out) }

      it "raises InsufficientStockError" do
        expect { add_item(1) }.to raise_error(described_class::InsufficientStockError)
      end

      it "creates no line" do
        expect { add_item(1) rescue nil }.not_to change(CartItem, :count)
      end
    end
  end

  describe "#update_quantity" do
    let!(:line) { create(:cart_item, cart: cart, product: product, quantity: 1) }

    def update_quantity(quantity)
      service.update_quantity(cart_item: line, quantity: quantity)
    end

    context "with a quantity within stock" do
      before { update_quantity(5) }

      it "sets the new quantity" do
        expect(line.reload.quantity).to eq(5)
      end
    end

    context "with a quantity of 0" do
      it "removes the line" do
        expect { update_quantity(0) }.to change { cart.cart_items.count }.by(-1)
      end
    end

    context "with a quantity above stock" do
      it "raises InsufficientStockError" do
        expect { update_quantity(11) }.to raise_error(described_class::InsufficientStockError)
      end

      it "leaves the quantity unchanged" do
        expect { update_quantity(11) rescue nil }.not_to change { line.reload.quantity }
      end
    end
  end
end

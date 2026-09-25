require "rails_helper"

# The heart on a product card saves it in place (Turbo Stream), and Buy Now
# skips the cart and lands on checkout.
RSpec.describe "Wishlist and Buy Now", type: :system do
  let(:user) { create(:user, :with_cart) }
  let!(:product) { create(:product, name: "Linen Throw", stock: 5) }

  before { sign_in_via_ui(user) }

  context "after tapping the heart on a product card" do
    before do
      visit products_path
      find("button[aria-label='Save #{product.name} to wishlist']").click
      find("button[aria-label='Remove #{product.name} from wishlist']") # wait for the stream
    end

    it "saves the product to the wishlist" do
      expect(user.wishlist_items.pluck(:product_id)).to eq([ product.id ])
    end

    context "when visiting the wishlist" do
      before { visit wishlist_items_path }

      it "lists the product" do
        expect(page).to have_link(href: product_path(product))
      end
    end
  end

  context "after choosing Buy Now" do
    before do
      visit product_path(product)
      click_button "Buy Now"
      assert_current_path(new_checkout_path)
    end

    it "puts the product in the cart" do
      expect(user.cart.cart_items.pluck(:product_id)).to eq([ product.id ])
    end
  end

  context "after tapping the heart on the product page" do
    before do
      visit product_path(product)
      find("button[aria-label='Save #{product.name} to wishlist']").click
      find("button[aria-label='Remove #{product.name} from wishlist']") # wait for the stream
    end

    it "saves the product to the wishlist" do
      expect(user.wishlist_items.pluck(:product_id)).to eq([ product.id ])
    end

    it "does not add it to the cart" do
      expect(user.cart.cart_items).to be_empty
    end
  end
end

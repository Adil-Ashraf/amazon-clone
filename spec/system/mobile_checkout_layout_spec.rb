require "rails_helper"

# Checkout on a phone must fit the screen: a long product name used to push
# the grid column past the viewport, clipping the total and Place Order.
RSpec.describe "Mobile checkout layout", type: :system do
  let(:user) { create(:user, :with_cart) }
  let(:product) { create(:product, name: "Stainless Steel Knife Block Set 15-Piece With Extra Long Descriptive Title", stock: 5) }

  def page_overflow
    page.evaluate_script("document.documentElement.scrollWidth - document.documentElement.clientWidth")
  end

  def place_order_button_right_edge
    page.evaluate_script("document.querySelector('#review input[type=submit]').getBoundingClientRect().right")
  end

  before do
    create(:cart_item, cart: user.cart, product: product)
    sign_in_via_ui(user)
  end

  # Headless Chrome won't size a window below 500px, so emulate the phone's
  # viewport through the DevTools protocol instead of resizing.
  def emulate_width(width)
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: width, height: 800, deviceScaleFactor: 1, mobile: true)
  end

  def viewport_width
    page.evaluate_script("document.documentElement.clientWidth")
  end

  after { page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride") }

  [ 390, 375, 360 ].each do |width|
    context "at #{width}px wide" do
      before do
        emulate_width(width)
        visit new_checkout_path
        find("#review")
      end

      it "renders at a true #{width}px viewport" do
        expect(viewport_width).to eq(width)
      end

      it "has no horizontal overflow" do
        expect(page_overflow).to be <= 0
      end

      it "keeps Place Order inside the viewport" do
        expect(place_order_button_right_edge).to be <= width
      end
    end
  end
end

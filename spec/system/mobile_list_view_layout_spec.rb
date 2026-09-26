require "rails_helper"

# The catalog's list view on a phone must fit the screen: the price and the
# Add to Cart / wishlist controls used to sit in one row wider than the column,
# pushing the page 20-50px past the viewport.
RSpec.describe "Mobile list view layout", type: :system do
  before { create(:product, name: "Mechanical Gaming Keyboard RGB Backlit With A Long Name", stock: 5) }

  # Headless Chrome won't size a window below 500px, so emulate the phone's
  # viewport through the DevTools protocol instead of resizing.
  def emulate_width(width)
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: width, height: 800, deviceScaleFactor: 1, mobile: true)
  end

  def page_overflow
    page.evaluate_script("document.documentElement.scrollWidth - document.documentElement.clientWidth")
  end

  after { page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride") }

  [ 390, 360 ].each do |width|
    context "at #{width}px wide" do
      before do
        emulate_width(width)
        visit products_path(view: "list")
        find("article", match: :first)
      end

      it "has no horizontal overflow" do
        expect(page_overflow).to be <= 0
      end

      it "keeps Add to Cart inside the viewport" do
        right_edge = page.evaluate_script("document.querySelector('article form button').getBoundingClientRect().right")
        expect(right_edge).to be <= width
      end
    end
  end
end

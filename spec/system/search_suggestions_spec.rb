require "rails_helper"

# Typing in the header search shows product suggestions (server-rendered,
# pg_search) that open with the mouse or the keyboard. On the catalog they
# appear alongside the live-updating results grid.
RSpec.describe "Search suggestions", type: :system do
  let(:electronics) { create(:category, :electronics) }
  let(:books) { create(:category, :books) }
  let!(:headphones) { create(:product, name: "Wireless Headphones", category: electronics) }
  let!(:novel) { create(:product, name: "Test-Driven Novel", category: books) }

  def type_query(text)
    find_field("query").send_keys(text)
  end

  def suggestions
    find("#search_suggestions_panel")
  end

  before { visit root_path }

  context "after typing two characters" do
    before { type_query("He") }

    it "suggests matching products" do
      expect(suggestions).to have_link(href: product_path(headphones))
    end

    it "offers the full search" do
      expect(suggestions).to have_link(href: products_path(query: "He"))
    end
  end

  context "after typing one character" do
    before do
      type_query("H")
      sleep 0.6 # longer than the debounce
    end

    it "shows no suggestions" do
      expect(page).to have_no_css("#search_suggestions_panel", visible: true)
    end
  end

  context "after choosing a suggestion with the keyboard" do
    before do
      type_query("Novel")
      suggestions.find(:link, href: product_path(novel))
      find_field("query").send_keys(:down, :enter)
      assert_current_path(product_path(novel))
    end

    it "opens the product" do
      expect(page).to have_css("h1", text: novel.name)
    end
  end

  context "after clicking a suggestion" do
    before do
      type_query("Headph")
      suggestions.click_link(href: product_path(headphones))
      assert_current_path(product_path(headphones))
    end

    it "opens the product" do
      expect(page).to have_css("h1", text: headphones.name)
    end
  end

  context "after choosing View all" do
    before do
      type_query("Novel")
      suggestions.click_link(href: products_path(query: "Novel"))
      assert_current_path(products_path(query: "Novel"))
    end

    it "runs the normal search" do
      expect(find("#products_results")).to have_link(href: product_path(novel))
    end
  end

  context "after pressing Enter without choosing a suggestion" do
    before do
      type_query("Novel")
      suggestions.find(:link, href: product_path(novel))
      find_field("query").send_keys(:enter)
      assert_current_path(products_path(query: "Novel"))
    end

    it "runs the normal search" do
      expect(find("#products_results")).to have_link(href: product_path(novel))
    end
  end

  context "with no matching products" do
    before { type_query("zzqq") }

    it "says nothing was found" do
      expect(suggestions).to have_text("No products found").and have_no_css("[role='option']")
    end
  end

  context "after pressing Escape" do
    before do
      type_query("Novel")
      suggestions.find(:link, href: product_path(novel))
      find_field("query").send_keys(:escape)
    end

    it "closes the suggestions" do
      expect(page).to have_no_css("#search_suggestions_panel", visible: true)
    end
  end

  context "after clicking outside" do
    before do
      type_query("Novel")
      suggestions.find(:link, href: product_path(novel))
      find("main").click
    end

    it "closes the suggestions" do
      expect(page).to have_no_css("#search_suggestions_panel", visible: true)
    end
  end

  context "on a phone" do
    after { page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride") }

    before do
      page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: 390, height: 800, deviceScaleFactor: 1, mobile: true)
      visit root_path
      find("button[aria-controls='mobile_search']").click
      find_field("mobile_query").send_keys("Novel")
    end

    it "suggests matching products" do
      expect(find("#mobile_search_suggestions_panel")).to have_link(href: product_path(novel))
    end
  end

  context "on the catalog" do
    def grid
      find("#products_results")
    end

    context "after typing" do
      before do
        visit products_path(category: electronics.slug)
        type_query("Head")
        assert_current_path(products_path(category: electronics.slug, query: "Head"))
      end

      it "shows suggestions" do
        expect(suggestions).to have_link(href: product_path(headphones))
      end

      it "still updates the results grid within the category" do
        expect(grid).to have_link(href: product_path(headphones)).and have_no_link(href: product_path(novel))
      end
    end

    context "after choosing a suggestion with the keyboard" do
      before do
        visit products_path
        type_query("Novel")
        suggestions.find(:link, href: product_path(novel))
        find_field("query").send_keys(:down, :enter)
        assert_current_path(product_path(novel))
      end

      it "opens the product" do
        expect(page).to have_css("h1", text: novel.name)
      end
    end

    context "after choosing View all with the keyboard" do
      before do
        visit products_path(category: electronics.slug)
        type_query("Head")
        suggestions.find(:link, href: products_path(query: "Head"))
        find_field("query").send_keys(:up, :enter)
      end

      it "keeps the category filter" do
        assert_current_path(products_path(category: electronics.slug, query: "Head"))
      end

      it "closes the suggestions" do
        expect(page).to have_no_css("#search_suggestions_panel", visible: true)
      end
    end

    context "after pressing Escape" do
      before do
        visit products_path
        type_query("Novel")
        suggestions.find(:link, href: product_path(novel))
        find_field("query").send_keys(:escape)
      end

      it "closes the suggestions but keeps the results" do
        expect(page).to have_no_css("#search_suggestions_panel", visible: true)
      end

      it "keeps the searched results in the grid" do
        expect(grid).to have_link(href: product_path(novel)).and have_no_link(href: product_path(headphones))
      end
    end

    context "on a phone" do
      after { page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride") }

      before do
        page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: 390, height: 800, deviceScaleFactor: 1, mobile: true)
        visit products_path
        find("button[aria-controls='mobile_search']").click
        find_field("mobile_query").send_keys("Novel")
        assert_current_path(products_path(query: "Novel"))
      end

      it "shows suggestions and updates the grid" do
        expect(find("#mobile_search_suggestions_panel")).to have_link(href: product_path(novel))
      end
    end
  end
end

require "rails_helper"

# On the catalog, the header search updates the results as you type (a
# debounced Turbo Frame visit backed by pg_search), keeps the URL shareable,
# and keeps the other listing params.
RSpec.describe "Live search", type: :system do
  let(:electronics) { create(:category, :electronics) }
  let(:books) { create(:category, :books) }
  let!(:headphones) { create(:product, name: "Wireless Headphones", category: electronics) }
  let!(:speaker) { create(:product, name: "Bluetooth Speaker", category: electronics) }
  let!(:novel) { create(:product, name: "Test-Driven Novel", category: books) }

  def type_query(text)
    find_field("query").send_keys(text)
  end

  def clear_query
    field = find_field("query")
    field.value.length.times { field.send_keys(:backspace) }
  end

  def results
    find("#products_results")
  end

  def count_turbo_loads
    page.execute_script("window.turboLoads = 0; addEventListener('turbo:load', () => window.turboLoads++)")
  end

  def wait_for_turbo_load
    page.document.synchronize do
      raise Capybara::ExpectationNotMet, "Turbo visit still running" unless page.evaluate_script("window.turboLoads > 0")
    end
  end

  context "after typing without pressing Enter" do
    before do
      visit products_path
      type_query("Headph")
      assert_current_path(products_path(query: "Headph")) # waits for the debounced visit
    end

    it "shows only matching products" do
      expect(results).to have_link(href: product_path(headphones)).and have_no_link(href: product_path(novel))
    end

    it "keeps the search box and its text" do
      expect(find_field("query").value).to eq("Headph")
    end
  end

  context "after clearing the search" do
    before do
      visit products_path(query: "Headphones")
      clear_query
      assert_current_path(products_path)
    end

    it "shows the full listing again" do
      expect(results).to have_link(href: product_path(headphones)).and have_link(href: product_path(novel))
    end
  end

  context "when a newer query replaces an older one quickly" do
    before do
      visit products_path
      type_query("Headphones")
      clear_query
      type_query("Novel")
      assert_current_path(products_path(query: "Novel"))
    end

    it "shows the results for the newest query" do
      expect(results).to have_link(href: product_path(novel)).and have_no_link(href: product_path(headphones))
    end
  end

  context "within a category" do
    before do
      visit products_path(category: electronics.slug)
      type_query("Speaker")
      assert_current_path(products_path(category: electronics.slug, query: "Speaker"))
    end

    it "keeps the category filter" do
      expect(results).to have_link(href: product_path(speaker)).and have_no_link(href: product_path(headphones))
    end
  end

  context "after searching and going back" do
    before do
      visit products_path
      count_turbo_loads
      type_query("Novel")
      assert_current_path(products_path(query: "Novel"))
      wait_for_turbo_load # Back in the same instant the URL changes would land mid-visit
      page.go_back
      assert_current_path(products_path)
    end

    it "shows the listing from before the search" do
      expect(results).to have_link(href: product_path(headphones))
    end

    it "empties the search box to match" do
      expect(find_field("query").value).to eq("")
    end
  end

  context "when pressing Enter on a page without results" do
    before do
      visit root_path
      type_query("Novel")
      find_field("query").send_keys(:enter)
      assert_current_path(products_path(query: "Novel"))
    end

    it "runs a normal search" do
      expect(results).to have_link(href: product_path(novel))
    end
  end

  context "on a phone" do
    def emulate_phone
      page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: 390, height: 800, deviceScaleFactor: 1, mobile: true)
    end

    after { page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride") }

    before do
      emulate_phone
      visit products_path
      find("button[aria-controls='mobile_search']").click
      find_field("mobile_query").send_keys("Novel")
      assert_current_path(products_path(query: "Novel"))
    end

    it "updates the results as you type" do
      expect(results).to have_link(href: product_path(novel)).and have_no_link(href: product_path(headphones))
    end
  end
end

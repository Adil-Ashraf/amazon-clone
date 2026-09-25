require "rails_helper"

# The storefront has to work for a visitor who is not signed in.
RSpec.describe "Guest browsing", type: :system do
  let(:electronics) { create(:category, :electronics) }
  let(:books) { create(:category, :books) }
  let!(:headphones) { create(:product, name: "Wireless Headphones", category: electronics) }
  let!(:novel) { create(:product, name: "Test-Driven Novel", category: books) }

  def filter_by_category(category)
    find("a[href='#{products_path(category: category.slug)}']", match: :first).click
  end

  def search_for(query)
    fill_in "query", with: query
    find_field("query").send_keys(:enter)
  end

  before { visit root_path }

  context "on the storefront" do
    it "shows every product" do
      expect(page).to have_link(href: product_path(headphones)).and have_link(href: product_path(novel))
    end
  end

  context "after filtering by category" do
    before { filter_by_category(books) }

    it "shows only products in that category" do
      expect(page).to have_link(href: product_path(novel)).and have_no_link(href: product_path(headphones))
    end
  end

  context "after searching" do
    before { search_for("Headphones") }

    it "shows only matching products" do
      expect(page).to have_link(href: product_path(headphones)).and have_no_link(href: product_path(novel))
    end
  end
end

require "application_system_test_case"

# Covers the one hard requirement the assignment brief calls out explicitly:
# the storefront has to work for a visitor who is not signed in.
class GuestBrowsingTest < ApplicationSystemTestCase
  test "a signed-out visitor can browse, filter by category, and search" do
    visit root_path

    assert_text "All Products"
    assert_text products(:headphones).name

    click_on categories(:books).name

    assert_text products(:novel).name
    assert_no_text products(:headphones).name

    fill_in "query", with: "Headphones"
    click_button "Search"

    assert_text products(:headphones).name
    assert_no_text products(:novel).name
  end
end

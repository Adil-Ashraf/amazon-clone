require "rails_helper"

# The header account menu is a Stimulus disclosure: it has to open, close on
# Esc and on a click outside, and hold the sign-out button.
RSpec.describe "Account menu", type: :system do
  let(:user) { create(:user, :with_cart) }

  def menu_button
    find("button[aria-controls='account_menu']")
  end

  def open_menu
    menu_button.click
    find("#account_menu", visible: true)
  end

  before { sign_in_via_ui(user) }

  context "when opened" do
    before { open_menu }

    it "shows who is signed in" do
      expect(find("#account_menu")).to have_text(user.email)
    end

    it "marks the button as expanded" do
      expect(page).to have_css("button[aria-controls='account_menu'][aria-expanded='true']")
    end
  end

  context "after pressing Esc" do
    before do
      open_menu
      page.send_keys(:escape)
    end

    it "closes the menu" do
      expect(page).to have_no_css("#account_menu", visible: true)
    end
  end

  context "after clicking outside" do
    before do
      open_menu
      find("main").click
    end

    it "closes the menu" do
      expect(page).to have_no_css("#account_menu", visible: true)
    end
  end

  context "after signing out from the menu" do
    before do
      open_menu
      find("#account_menu form[action='#{session_path}'] button").click
    end

    it "shows the sign-in link again" do
      expect(page).to have_link(href: new_session_path)
    end
  end
end

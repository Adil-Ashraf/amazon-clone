require "rails_helper"

RSpec.describe "Account", type: :request do
  let(:user) { create(:user) }
  let!(:order) { create(:order, user: user) }

  context "as a guest" do
    before { get account_path }

    it { expect(response).to redirect_to(new_session_path) }
  end

  context "when signed in" do
    before do
      sign_in_as(user)
      get account_path
    end

    it { expect(response).to have_http_status(:ok) }

    it "links to recent orders" do
      expect(response_link_hrefs).to include(order_path(order))
    end
  end
end

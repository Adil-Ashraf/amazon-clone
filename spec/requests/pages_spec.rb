require "rails_helper"

RSpec.describe "Pages", type: :request do
  PagesController::PAGES.each do |page|
    context "GET /pages/#{page}" do
      before { get page_path(page) }

      it { expect(response).to have_http_status(:ok) }
    end
  end

  context "for an unknown page" do
    before { get "/pages/unknown" }

    it { expect(response).to have_http_status(:not_found) }
  end
end

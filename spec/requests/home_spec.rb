require "rails_helper"

RSpec.describe "Home", type: :request do
  let(:electronics) { create(:category, :electronics) }
  let!(:deal) { create(:product, :on_sale, category: electronics) }
  let!(:regular) { create(:product, category: electronics) }

  describe "GET /" do
    before { get root_path }

    it { expect(response).to have_http_status(:ok) }

    it "links to today's deals" do
      expect(response_link_hrefs).to include(product_path(deal))
    end

    it "links to each category" do
      expect(response_link_hrefs).to include(products_path(category: electronics.slug))
    end
  end

  context "after viewing a product" do
    before do
      get product_path(regular)
      get root_path
    end

    it "shows it under recently viewed" do
      expect(response_document.css("section[aria-labelledby='recent_heading'] a[href='#{product_path(regular)}']")).to be_present
    end
  end
end

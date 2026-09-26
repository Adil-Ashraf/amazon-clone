require "rails_helper"

RSpec.describe "Search suggestions", type: :request do
  let(:electronics) { create(:category, :electronics) }
  let(:books) { create(:category, :books) }
  let!(:headphones) { create(:product, name: "Wireless Headphones", category: electronics) }
  let!(:novel) { create(:product, name: "Test-Driven Novel", category: books) }

  def suggest(query, frame: "search_suggestions")
    get search_suggestions_path(query: query), headers: { "Turbo-Frame" => frame }
  end

  def suggestion_hrefs
    response_document.css("[role='option']").map { |option| option["href"] }
  end

  describe "GET /search_suggestions" do
    context "as a guest with a matching query" do
      before { suggest("Headph") }

      it { expect(response).to have_http_status(:ok) }

      it "suggests the matching product" do
        expect(suggestion_hrefs).to include(product_path(headphones)).and exclude(product_path(novel))
      end

      it "links to the full search for the query" do
        expect(suggestion_hrefs).to include(products_path(query: "Headph"))
      end

      it "renders into the requesting frame" do
        expect(response_document.at_css("turbo-frame#search_suggestions")).to be_present
      end
    end

    context "with more matches than the limit" do
      before do
        create_list(:product, SearchSuggestionsController::LIMIT + 2, name: "Desk Lamp", category: electronics)
        suggest("Lamp")
      end

      it "suggests at most the limit, plus the full-search link" do
        expect(suggestion_hrefs.count { |href| href.match?(%r{\A/products/\d+\z}) }).to eq(SearchSuggestionsController::LIMIT)
      end
    end

    context "with no matches" do
      before { suggest("zzqq") }

      it "suggests nothing" do
        expect(suggestion_hrefs).to be_empty
      end
    end

    context "with a query shorter than the minimum" do
      before { suggest("H") }

      it "suggests nothing" do
        expect(suggestion_hrefs).to be_empty
      end
    end

    context "from the mobile search box" do
      before { suggest("Novel", frame: "mobile_search_suggestions") }

      it "renders into the mobile frame" do
        expect(response_document.at_css("turbo-frame#mobile_search_suggestions")).to be_present
      end
    end

    context "with an unexpected frame header" do
      before { suggest("Novel", frame: "evil_frame") }

      it "falls back to the default frame" do
        expect(response_document.css("turbo-frame").map { |frame| frame["id"] }).to eq([ "search_suggestions" ])
      end
    end
  end
end

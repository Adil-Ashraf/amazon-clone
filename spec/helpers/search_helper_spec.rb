require "rails_helper"

RSpec.describe SearchHelper, type: :helper do
  describe "#search_form_data" do
    context "off the catalog" do
      subject(:data) { helper.search_form_data(live: false) }

      it "runs only the suggestions controller" do
        expect(data[:controller]).to eq("search-suggest")
      end

      it "points it at the suggestions endpoint" do
        expect(data[:search_suggest_url_value]).to eq(search_suggestions_path)
      end
    end

    context "on the catalog" do
      subject(:data) { helper.search_form_data(live: true) }

      it "runs live search alongside suggestions" do
        expect(data[:controller].split).to eq(%w[live-search search-suggest])
      end

      it "keeps the suggestions actions" do
        expect(data[:action]).to include("submit->live-search#submit", "submit->search-suggest#submitted")
      end

      it "targets the results frame" do
        expect(data[:live_search_frame_value]).to eq("products_results")
      end
    end
  end

  describe "#search_input_data" do
    it "wires only suggestions off the catalog" do
      expect(helper.search_input_data(live: false)).not_to have_key(:live_search_target)
    end

    it "wires both controllers' input actions on the catalog" do
      expect(helper.search_input_data(live: true)[:action])
        .to include("input->live-search#search", "input->search-suggest#search", "keydown->search-suggest#navigate")
    end
  end

  describe "#search_input_aria" do
    it "makes the input a combobox for its panel" do
      expect(helper.search_input_aria("search_suggestions"))
        .to include(role: "combobox", "aria-controls": "search_suggestions_panel", "aria-expanded": "false")
    end
  end
end

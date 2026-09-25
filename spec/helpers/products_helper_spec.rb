require "rails_helper"

RSpec.describe ProductsHelper, type: :helper do
  describe "#product_image_tag" do
    let(:photo_url) { "https://images.example.test/photo-1.jpg" }

    def render_image(product)
      @fragment = Nokogiri::HTML.fragment(helper.product_image_tag(product))
    end

    context "with a verified photo" do
      let(:product) { build(:product, name: "Wireless Headphones", image_url: photo_url) }

      before { render_image(product) }

      it "renders the photo with the product name as alt text" do
        expect(@fragment.at_css("img[src='#{photo_url}']")["alt"]).to eq("Wireless Headphones")
      end

      it "keeps the designed tile underneath, hidden from assistive tech" do
        expect(@fragment.at_css("[role='img']")["aria-hidden"]).to eq("true")
      end

      it "wires the load-failure fallback" do
        expect(@fragment.at_css("[data-controller='product-image'] img[data-action='error->product-image#fallback']")).to be_present
      end
    end

    context "without a photo" do
      let(:product) { build(:product, name: "Paper Shredder", image_url: nil) }

      before { render_image(product) }

      it "renders no img" do
        expect(@fragment.css("img")).to be_empty
      end

      it "renders the designed tile labelled with the product name" do
        expect(@fragment.at_css("[role='img'][aria-label='Paper Shredder']")["aria-hidden"]).to be_nil
      end
    end
  end
end

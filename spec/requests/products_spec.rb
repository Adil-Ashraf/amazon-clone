require "rails_helper"

RSpec.describe "Products", type: :request do
  let(:electronics) { create(:category, :electronics) }
  let(:books) { create(:category, :books) }
  let!(:headphones) { create(:product, name: "Wireless Headphones", category: electronics) }
  let!(:novel) { create(:product, name: "Test-Driven Novel", category: books) }

  describe "GET /products" do
    def get_products(params = {})
      get products_path(params)
    end

    context "as a guest" do
      before { get_products }

      it { expect(response).to have_http_status(:ok) }

      it "links to every product" do
        expect(response_link_hrefs).to include(product_path(headphones), product_path(novel))
      end
    end

    context "filtered by category" do
      before { get_products(category: books.slug) }

      it { expect(response).to have_http_status(:ok) }

      it "links only to products in that category" do
        expect(response_link_hrefs).to include(product_path(novel)).and exclude(product_path(headphones))
      end
    end

    context "with a search query" do
      before { get_products(query: "headphones") }

      it { expect(response).to have_http_status(:ok) }

      it "links only to matching products" do
        expect(response_link_hrefs).to include(product_path(headphones)).and exclude(product_path(novel))
      end
    end

    context "with a page past the last page" do
      before { get_products(page: 999) }

      it "redirects to the last page" do
        expect(response).to redirect_to(products_path(page: 1))
      end
    end

    context "with a page past the last page and a category" do
      before { get_products(category: books.slug, page: 999) }

      it "keeps the category when redirecting" do
        expect(response).to redirect_to(products_path(category: books.slug, page: 1))
      end
    end

    %w[garbage 0 -3 2abc].each do |page|
      context "with the non-positive-integer page #{page.inspect}" do
        before { get_products(page: page) }

        it "redirects to the first page without a page param" do
          expect(response).to redirect_to(products_path)
        end
      end
    end

    context "with an invalid page, a category and a query" do
      before { get_products(category: "books", query: "novel", page: "garbage") }

      it "keeps the category and query when redirecting" do
        expect(response).to redirect_to(products_path(category: "books", query: "novel"))
      end
    end

    context "with an unknown sort" do
      before { get_products(sort: "price_cents; DROP TABLE products") }

      it { expect(response).to have_http_status(:ok) }

      it "still links to every product" do
        expect(response_link_hrefs).to include(product_path(headphones), product_path(novel))
      end
    end

    context "sorted by price" do
      let!(:cheap) { create(:product, price_cents: 100, category: books) }
      let!(:pricey) { create(:product, price_cents: 99_900, category: books) }

      def product_link_order
        response_link_hrefs.uniq & [ product_path(cheap), product_path(pricey) ]
      end

      context "low to high" do
        before { get_products(sort: "price_asc") }

        it "lists the cheaper product first" do
          expect(product_link_order).to eq([ product_path(cheap), product_path(pricey) ])
        end
      end

      context "high to low" do
        before { get_products(sort: "price_desc") }

        it "lists the pricier product first" do
          expect(product_link_order).to eq([ product_path(pricey), product_path(cheap) ])
        end
      end

      context "with a query" do
        before do
          cheap.update!(name: "Cheap Lamp")
          pricey.update!(name: "Pricey Lamp")
          get_products(query: "lamp", sort: "price_desc")
        end

        it "orders the matches by price" do
          expect(product_link_order).to eq([ product_path(pricey), product_path(cheap) ])
        end
      end
    end

    context "with a page past the last page and a sort" do
      before { get_products(sort: "price_desc", page: 999) }

      it "keeps the sort when redirecting" do
        expect(response).to redirect_to(products_path(sort: "price_desc", page: 1))
      end
    end

    context "with a valid page that exists" do
      before do
        create_list(:product, ProductsController::PER_PAGE, category: books)
        get_products(page: 2)
      end

      it { expect(response).to have_http_status(:ok) }
    end
  end

  describe "GET /products/:id" do
    def get_product(id)
      get product_path(id: id)
    end

    context "for a product with a verified photo" do
      let(:photo_url) { "https://images.example.test/headphones.jpg" }

      before do
        headphones.update!(image_url: photo_url)
        get_product(headphones.id)
      end

      it "shows the photo with the product name as alt text" do
        expect(response_document.at_css("img[src='#{photo_url}']")["alt"]).to eq(headphones.name)
      end
    end

    context "for a product without a photo" do
      before { get_product(novel.id) }

      it "shows the designed tile labelled with the product name" do
        expect(response_document.css("[role='img'][aria-label='#{novel.name}']")).to be_present
      end

      it "shows no product photo" do
        expect(response_document.css("img[src^='https://']")).to be_empty
      end
    end

    context "for an existing product" do
      before { get_product(headphones.id) }

      it { expect(response).to have_http_status(:ok) }
    end

    context "for a missing product" do
      before { get_product(0) }

      it { expect(response).to have_http_status(:not_found) }
    end
  end
end

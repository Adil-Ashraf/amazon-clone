require "rails_helper"

# db/seeds/product_images.yml must give every seeded product its own photo,
# so a fresh `db:seed` never leaves a product without one.
RSpec.describe "Seeded product images" do
  let(:seeded_names) { Rails.root.join("db/seeds.rb").read.scan(/\{ name: "((?:[^"\\]|\\.)*)"/).flatten }
  let(:images) { YAML.load_file(Rails.root.join("db/seeds/product_images.yml")) }
  let(:photo_ids) { images.values.map { |url| url[%r{images\.unsplash\.com/(photo-[0-9a-f-]+)}, 1] } }

  it "reads the full seeded catalog" do
    expect(seeded_names.size).to eq(110)
  end

  it "has a photo for every seeded product" do
    expect(seeded_names - images.keys).to be_empty
  end

  it "only lists seeded products" do
    expect(images.keys - seeded_names).to be_empty
  end

  it "uses an Unsplash photo URL for every entry" do
    expect(photo_ids).to all(be_present)
  end

  it "never reuses a photo" do
    expect(photo_ids.uniq.size).to eq(photo_ids.size)
  end
end

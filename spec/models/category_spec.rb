require "rails_helper"

RSpec.describe Category, type: :model do
  subject { build(:category) }

  describe "associations" do
    it { is_expected.to have_many(:products).dependent(:restrict_with_error) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:slug) }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_uniqueness_of(:slug) }
  end

  context "with a known slug" do
    let(:category) { build(:category, :electronics) }

    it "resolves its icon" do
      expect(category.icon_key).to eq(:chip)
    end

    it "resolves its colour" do
      expect(category.color_hex).to eq("#2563eb")
    end
  end

  context "with an unknown slug" do
    let(:category) { build(:category) }

    it "falls back to the default icon" do
      expect(category.icon_key).to eq(Category::DEFAULT_ICON_KEY)
    end
  end
end

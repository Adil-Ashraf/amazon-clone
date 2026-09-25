require "rails_helper"

RSpec.describe WishlistItem, type: :model do
  subject { build(:wishlist_item) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:product) }
  end

  describe "validations" do
    it { is_expected.to validate_uniqueness_of(:product_id).scoped_to(:user_id) }
  end
end

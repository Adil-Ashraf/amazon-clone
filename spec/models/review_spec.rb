require "rails_helper"

RSpec.describe Review, type: :model do
  subject { build(:review) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:product).counter_cache(true) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:body) }
    it { is_expected.to validate_length_of(:body).is_at_most(2000) }
    it { is_expected.to validate_numericality_of(:rating).only_integer.is_in(1..5) }
    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:product_id).with_message("has already reviewed this product") }
  end
end

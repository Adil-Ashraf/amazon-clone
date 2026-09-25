require "rails_helper"

RSpec.describe CartItem, type: :model do
  subject { build(:cart_item) }

  describe "associations" do
    it { is_expected.to belong_to(:cart) }
    it { is_expected.to belong_to(:product) }
  end

  describe "validations" do
    it { is_expected.to validate_numericality_of(:quantity).only_integer.is_greater_than(0) }
  end
end

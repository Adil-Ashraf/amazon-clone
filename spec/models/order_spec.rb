require "rails_helper"

RSpec.describe Order, type: :model do
  subject { build(:order) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:order_items).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to define_enum_for(:status).with_values(pending: 0, paid: 1, shipped: 2) }
    it { is_expected.to validate_presence_of(:total_cents) }
    it { is_expected.to validate_numericality_of(:total_cents).only_integer.is_greater_than_or_equal_to(0) }

    %i[shipping_name shipping_address_line1 shipping_city shipping_state shipping_zip].each do |field|
      it { is_expected.to validate_presence_of(field) }
    end
  end
end

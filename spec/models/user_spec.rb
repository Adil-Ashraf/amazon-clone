require "rails_helper"

RSpec.describe User, type: :model do
  subject { build(:user) }

  describe "associations" do
    it { is_expected.to have_one(:cart).dependent(:destroy) }
    it { is_expected.to have_many(:orders).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to have_secure_password }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).ignoring_case_sensitivity }
    it { is_expected.to validate_length_of(:password).is_at_least(8) }
    it { is_expected.not_to allow_value("not-an-email").for(:email) }
  end

  describe "#ensure_cart!" do
    context "without a cart" do
      let(:user) { create(:user) }

      it "creates one" do
        expect { user.ensure_cart! }.to change(Cart, :count).by(1)
      end

      it "returns the user's cart" do
        expect(user.ensure_cart!).to eq(Cart.find_by!(user: user))
      end
    end

    context "with a cart" do
      let!(:user) { create(:user, :with_cart) }

      it "returns it without creating another" do
        expect { expect(user.ensure_cart!).to eq(user.cart) }.not_to change(Cart, :count)
      end
    end

    # Another request created the cart after this user object looked for one.
    context "when a cart appeared since the user last checked" do
      let(:user) { create(:user) }
      let!(:existing) do
        user.cart # caches "no cart"
        Cart.create!(user_id: user.id)
      end

      it "returns that cart without creating another" do
        expect { expect(user.ensure_cart!).to eq(existing) }.not_to change(Cart, :count)
      end
    end
  end

  describe "email normalization" do
    let(:user) { build(:user, email: "Mixed.Case@Example.COM") }

    before { user.validate }

    it "downcases the email before validation" do
      expect(user.email).to eq("mixed.case@example.com")
    end
  end
end

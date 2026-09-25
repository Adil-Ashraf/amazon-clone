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

  describe "email normalization" do
    let(:user) { build(:user, email: "Mixed.Case@Example.COM") }

    before { user.validate }

    it "downcases the email before validation" do
      expect(user.email).to eq("mixed.case@example.com")
    end
  end
end

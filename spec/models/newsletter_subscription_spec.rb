require "rails_helper"

RSpec.describe NewsletterSubscription, type: :model do
  subject { build(:newsletter_subscription) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to allow_value("reader@example.com").for(:email) }
    it { is_expected.not_to allow_value("not-an-email").for(:email) }
  end

  describe "email normalization" do
    let(:subscription) { build(:newsletter_subscription, email: "  Reader@Example.COM ") }

    before { subscription.validate }

    it "strips and downcases the email" do
      expect(subscription.email).to eq("reader@example.com")
    end
  end
end

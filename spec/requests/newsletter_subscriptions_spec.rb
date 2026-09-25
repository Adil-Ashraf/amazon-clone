require "rails_helper"

RSpec.describe "Newsletter subscriptions", type: :request do
  let(:turbo_stream_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

  def subscribe(email)
    post newsletter_subscriptions_path, params: { email: email }, headers: turbo_stream_headers
  end

  it "stores a valid email" do
    expect { subscribe("reader@example.com") }.to change(NewsletterSubscription, :count).by(1)
  end

  it "stores nothing for an invalid email" do
    expect { subscribe("nope") }.not_to change(NewsletterSubscription, :count)
  end

  context "when already subscribed" do
    before { create(:newsletter_subscription, email: "reader@example.com") }

    it "keeps a single subscription" do
      expect { subscribe("Reader@example.com") }.not_to change(NewsletterSubscription, :count)
    end
  end

  context "after subscribing" do
    before { subscribe("reader@example.com") }

    it "replaces the form" do
      expect(turbo_stream_targets).to include("newsletter_form")
    end
  end
end

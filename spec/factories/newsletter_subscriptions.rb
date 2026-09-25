FactoryBot.define do
  factory :newsletter_subscription do
    sequence(:email) { |n| "reader#{n}@example.com" }
  end
end

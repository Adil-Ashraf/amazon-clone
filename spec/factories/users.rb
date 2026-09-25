FactoryBot.define do
  factory :user do
    name { "Test User" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }

    trait :with_cart do
      after(:create) { |user| create(:cart, user: user) }
    end
  end
end

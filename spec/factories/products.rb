FactoryBot.define do
  factory :product do
    sequence(:name) { |n| "Product #{n}" }
    description { "A product used only in specs." }
    price_cents { 1000 }
    stock { 10 }
    category

    trait :low_stock do
      stock { 2 }
    end

    trait :sold_out do
      stock { 0 }
    end
  end
end

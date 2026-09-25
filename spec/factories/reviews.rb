FactoryBot.define do
  factory :review do
    user
    product
    rating { 5 }
    body { "Does exactly what it says." }
  end
end

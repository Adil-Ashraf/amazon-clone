FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "Category #{n}" }
    sequence(:slug) { |n| "category-#{n}" }

    # Real slugs, so Category::ICON_KEYS / COLOR_HEXES / IMAGE_URLS resolve.
    trait :electronics do
      name { "Electronics" }
      slug { "electronics" }
    end

    trait :books do
      name { "Books" }
      slug { "books" }
    end
  end
end

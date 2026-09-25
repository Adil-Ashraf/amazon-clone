class Review < ApplicationRecord
  belongs_to :user
  belongs_to :product, counter_cache: true

  validates :rating, presence: true, numericality: { only_integer: true, in: 1..5 }
  validates :body, presence: true, length: { maximum: 2000 }
  validates :user_id, uniqueness: { scope: :product_id, message: "has already reviewed this product" }
end

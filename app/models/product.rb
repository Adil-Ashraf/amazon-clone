class Product < ApplicationRecord
  include PgSearch::Model

  belongs_to :category

  validates :name, presence: true
  validates :description, presence: true
  validates :price_cents, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :stock, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  pg_search_scope :search_full_text,
    against: [ :name, :description ],
    using: { tsearch: { prefix: true } }
end

class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  # price_cents is a snapshot taken at purchase time; never read product.price_cents
  # for historical orders, since the live product price can change after purchase.
  validates :price_cents, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end

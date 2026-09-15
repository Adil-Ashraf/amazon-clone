class Order < ApplicationRecord
  belongs_to :user

  has_many :order_items, dependent: :destroy

  enum :status, { pending: 0, paid: 1, shipped: 2 }

  validates :total_cents, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :shipping_name, :shipping_address_line1, :shipping_city, :shipping_state, :shipping_zip, presence: true
end
